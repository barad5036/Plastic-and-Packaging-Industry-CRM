import 'package:flutter/foundation.dart';
import 'package:crm/core/network/remote_config_service.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  late Dio dio;
  static ApiClient? _instance;
  static bool _initialized = false;

  /// Production backend URL (Vercel).
  static const String _productionUrl = 'https://server-rho-two-45.vercel.app';

  /// Local backend URL for desktop debug sessions.
  static const String _localDesktopUrl = 'http://127.0.0.1:8080';

  /// Override via --dart-define=API_BASE_URL=... when you want to test a different backend.
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String _resolvedBaseUrl = _productionUrl;

  static String _normalizeBaseUrl(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static bool get _shouldPreferLocalDebugServer {
    if (kIsWeb || !kDebugMode) {
      return false;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return true;
      default:
        return false;
    }
  }

  static Future<bool> _hasConnectedDatabase(String url) async {
    try {
      final response = await Dio(
        BaseOptions(
          baseUrl: url,
          connectTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 2),
        ),
      ).get('/health');

      final data = response.data;
      if (data is Map) {
        return data['database'] == 'connected';
      }
    } catch (_) {
      // Ignore probe failures and allow fallback.
    }

    return false;
  }

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    final configured = _configuredBaseUrl.trim();
    if (configured.isNotEmpty) {
      _resolvedBaseUrl = _normalizeBaseUrl(configured);
      _initialized = true;
      return;
    }

    final localReady = _shouldPreferLocalDebugServer
        ? await _hasConnectedDatabase(_localDesktopUrl)
        : false;
    final productionReady = await _hasConnectedDatabase(_productionUrl);

    if (localReady) {
      _resolvedBaseUrl = _localDesktopUrl;
    } else if (productionReady) {
      _resolvedBaseUrl = _productionUrl;
    } else {
      _resolvedBaseUrl = _productionUrl;
    }

    _initialized = true;
  }

  /// Resolves the backend base URL.
  /// Priority: explicit `--dart-define` override > debug local backend > production Vercel URL.
  static String get baseUrl {
    if (_configuredBaseUrl.trim().isNotEmpty) {
      return _normalizeBaseUrl(_configuredBaseUrl.trim());
    }

    return _resolvedBaseUrl;
  }

  factory ApiClient() {
    _instance ??= ApiClient._internal();
    return _instance!;
  }

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token');
          if (token != null && token != 'demo-token') {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // If we get a 401, the token is invalid — clear it
          if (e.response?.statusCode == 401) {
            final prefs = await SharedPreferences.getInstance();
            final currentToken = prefs.getString('token');
            if (currentToken != null && currentToken != 'demo-token') {
              // Try to re-authenticate with Remote Config credentials
              try {
                final rc = RemoteConfigService();
                if (!rc.hasCredentials) {
                  return handler.next(e);
                }
                final loginResp =
                    await Dio(
                      BaseOptions(
                        baseUrl: baseUrl,
                        connectTimeout: const Duration(seconds: 5),
                      ),
                    ).post(
                      '/auth/login',
                      data: {
                        'email': rc.adminEmail,
                        'password': rc.adminPassword,
                      },
                    );
                final newToken = loginResp.data['token'];
                if (newToken != null) {
                  await prefs.setString('token', newToken as String);
                  // Retry the original request with the new token
                  e.requestOptions.headers['Authorization'] =
                      'Bearer $newToken';
                  final cloneReq = await dio.fetch(e.requestOptions);
                  return handler.resolve(cloneReq);
                }
              } catch (_) {
                // Re-auth failed, let the error propagate
              }
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  /// Force a fresh token by logging into the backend.
  /// Call this once after login to ensure a real JWT is stored.
  static Future<void> ensureRealToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token == 'demo-token') {
      try {
        final rc = RemoteConfigService();
        if (!rc.hasCredentials) {
          return;
        }
        final resp =
            await Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 5),
              ),
            ).post(
              '/auth/login',
              data: {'email': rc.adminEmail, 'password': rc.adminPassword},
            );
        final newToken = resp.data['token'];
        if (newToken != null) {
          await prefs.setString('token', newToken as String);
        }
      } catch (_) {
        // Server unreachable — keep whatever we have
      }
    }
  }
}
