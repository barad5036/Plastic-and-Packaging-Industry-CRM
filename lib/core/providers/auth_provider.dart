import 'dart:async';

import 'package:crm/core/network/api_client.dart';
import 'package:crm/core/network/remote_config_service.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({bool? firebaseEnabled})
    : _firebaseEnabled = firebaseEnabled ?? Firebase.apps.isNotEmpty,
      _firebaseAuth = (firebaseEnabled ?? Firebase.apps.isNotEmpty)
          ? FirebaseAuth.instance
          : null;

  static const String _tokenKey = 'token';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';

  final ApiClient _apiClient = ApiClient();
  final bool _firebaseEnabled;
  final FirebaseAuth? _firebaseAuth;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isDemoMode = false;

  User? _firebaseUser;
  String? _localUserEmail;
  String? _localUserName;
  StreamSubscription<User?>? _authSubscription;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isDemoMode => _isDemoMode;
  bool get isFirebaseAvailable => _firebaseEnabled && _firebaseAuth != null;
  User? get firebaseUser => _firebaseUser;
  String? get userEmail => _firebaseUser?.email ?? _localUserEmail;
  String? get userName => _firebaseUser?.displayName ?? _localUserName;

  /// Initialize auth state listener.
  /// Call this once after Firebase.initializeApp().
  Future<void> checkAuthStatus() async {
    _authSubscription?.cancel();

    if (!isFirebaseAvailable) {
      await _restoreLocalSession();
      notifyListeners();
      return;
    }

    _authSubscription = _firebaseAuth!.authStateChanges().listen(
      _onAuthStateChanged,
    );
    // Immediate check for current user
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser != null) {
      _firebaseUser = currentUser;
      _localUserEmail = currentUser.email;
      _localUserName = currentUser.displayName;
      _isAuthenticated = true;
      _isDemoMode = false;
      // Ensure backend JWT is available for API calls
      await _ensureBackendToken(currentUser.email ?? '');
      notifyListeners();
    }
  }

  void _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    if (user != null) {
      _localUserEmail = user.email;
      _localUserName = user.displayName;
      _isAuthenticated = true;
      _isDemoMode = false;
      await _ensureBackendToken(user.email ?? '');
    } else {
      _isAuthenticated = false;
      _isDemoMode = false;
      await _clearStoredSession();
    }
    notifyListeners();
  }

  Future<void> _restoreLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    _localUserEmail = prefs.getString(_userEmailKey);
    _localUserName = prefs.getString(_userNameKey);
    _isAuthenticated = token != null && token.isNotEmpty;
    _isDemoMode = token == 'demo-token';

    if (!_isAuthenticated) {
      _localUserEmail = null;
      _localUserName = null;
    }
  }

  Future<void> _persistLocalIdentity({
    required String email,
    String? name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmedName = name?.trim();

    _localUserEmail = email;
    _localUserName = (trimmedName != null && trimmedName.isNotEmpty)
        ? trimmedName
        : null;

    await prefs.setString(_userEmailKey, email);
    if (_localUserName != null) {
      await prefs.setString(_userNameKey, _localUserName!);
    } else {
      await prefs.remove(_userNameKey);
    }
  }

  Future<void> _clearStoredSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
    _localUserEmail = null;
    _localUserName = null;
  }

  /// After Firebase auth, also get a JWT from the Go backend for API calls.
  Future<void> _ensureBackendToken(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingToken = prefs.getString(_tokenKey);
      if (existingToken != null && existingToken != 'demo-token') return;

      // Login to the backend with credentials from Firebase Remote Config
      final rc = RemoteConfigService();
      if (!rc.hasCredentials) {
        await _persistLocalIdentity(email: email);
        if (prefs.getString(_tokenKey) == null) {
          await prefs.setString(_tokenKey, 'demo-token');
        }
        _isDemoMode = true;
        return;
      }

      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {'email': rc.adminEmail, 'password': rc.adminPassword},
      );
      final token = response.data['token'];
      if (token != null) {
        await prefs.setString(_tokenKey, token as String);
        await _persistLocalIdentity(email: email);
        _isDemoMode = false;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        rethrow;
      }
      // Backend unreachable — set demo token so the app can still show UI
      final prefs = await SharedPreferences.getInstance();
      await _persistLocalIdentity(email: email);
      if (prefs.getString(_tokenKey) == null) {
        await prefs.setString(_tokenKey, 'demo-token');
      }
      _isDemoMode = true;
    }
  }

  Future<void> _loginWithBackend(String email, String password) async {
    final response = await _apiClient.dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    final responseData = response.data;
    final token = responseData is Map ? responseData['token'] : null;
    final user = responseData is Map ? responseData['user'] : null;
    final resolvedEmail = user is Map && user['email'] is String
        ? user['email'] as String
        : email;
    final resolvedName = user is Map && user['name'] is String
        ? user['name'] as String
        : null;

    if (token is! String || token.isEmpty) {
      throw StateError('Missing backend auth token');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await _persistLocalIdentity(email: resolvedEmail, name: resolvedName);

    _firebaseUser = null;
    _isAuthenticated = true;
    _isDemoMode = false;
  }

  Future<void> _registerWithBackend(
    String email,
    String password, {
    String? displayName,
  }) async {
    final fallbackName = email.split('@').first;
    await _apiClient.dio.post(
      '/auth/register',
      data: {
        'name': (displayName != null && displayName.trim().isNotEmpty)
            ? displayName.trim()
            : fallbackName,
        'email': email,
        'password': password,
      },
    );

    await _loginWithBackend(email, password);
  }

  /// Login with email/password directly via the custom Go backend.
  /// This bypasses Firebase Auth's reCAPTCHA checks which fail on Android without proper Play Integrity setup.
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _loginWithBackend(email, password);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _mapFirebaseError(e.code);
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _isLoading = false;
      _errorMessage = _mapBackendError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Login failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Login or register with Google via Firebase Auth.
  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!isFirebaseAvailable) {
        _isLoading = false;
        _errorMessage =
            'Google sign-in is unavailable because Firebase is not configured on this platform.';
        notifyListeners();
        return false;
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        _errorMessage = 'Google sign-in was cancelled.';
        notifyListeners();
        return false;
      }

      final googleAuth = await googleUser.authentication;
      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        throw StateError(
          'Google Sign-In is not fully configured. Enable Google provider in Firebase, add your SHA keys, and download the latest google-services.json.',
        );
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth!.signInWithCredential(
        credential,
      );

      _firebaseUser = userCredential.user;
      _localUserEmail = userCredential.user?.email;
      _localUserName = userCredential.user?.displayName;
      _isAuthenticated = true;
      _isDemoMode = false;

      await _ensureBackendToken(userCredential.user?.email ?? '');

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _mapFirebaseError(e.code);
      notifyListeners();
      return false;
    } on StateError catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _isLoading = false;
      _errorMessage =
          'Google sign-in failed. Check Google provider setup in Firebase.';
      notifyListeners();
      return false;
    }
  }

  /// Quick Demo / Guest access without requiring Firebase or remote server.
  Future<bool> loginAsDemo() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, 'demo-token');
    await _persistLocalIdentity(email: 'demo@saleshub.com', name: 'Demo Admin');

    _firebaseUser = null;
    _isAuthenticated = true;
    _isDemoMode = true;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Register a new user directly via the custom Go backend.
  Future<bool> register(
    String email,
    String password, {
    String? displayName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _registerWithBackend(email, password, displayName: displayName);

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _errorMessage = _mapFirebaseError(e.code);
      notifyListeners();
      return false;
    } on DioException catch (e) {
      _isLoading = false;
      _errorMessage = _mapBackendError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Registration failed. Please try again.';
      notifyListeners();
      return false;
    }
  }

  /// Send password reset email via Firebase.
  Future<bool> resetPassword(String email) async {
    if (!isFirebaseAvailable) {
      _errorMessage =
          'Password reset is unavailable because Firebase is not configured on this platform.';
      notifyListeners();
      return false;
    }

    try {
      await _firebaseAuth!.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseError(e.code);
      notifyListeners();
      return false;
    }
  }

  /// Logout from both Firebase and backend.
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    if (_firebaseAuth != null) {
      await _firebaseAuth.signOut();
    }
    await _clearStoredSession();
    _firebaseUser = null;
    _isAuthenticated = false;
    _isDemoMode = false;
    notifyListeners();
  }

  String _mapBackendError(DioException error) {
    final responseData = error.response?.data;
    if (responseData is Map) {
      final message = responseData['error'] ?? responseData['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return 'Unable to reach the server. Check your connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  /// Map Firebase error codes to user-friendly messages.
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      case 'account-exists-with-different-credential':
        return 'This email is already linked to another sign-in method.';
      default:
        return 'Authentication error ($code). Please try again.';
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
