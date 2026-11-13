import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Singleton service that fetches backend admin credentials
/// from Firebase Remote Config.
class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._();

  FirebaseRemoteConfig? _remoteConfig;

  bool _initialized = false;

  bool get isAvailable => Firebase.apps.isNotEmpty;

  bool get hasCredentials =>
      adminEmail.trim().isNotEmpty && adminPassword.trim().isNotEmpty;

  /// Initialize Remote Config with defaults and fetch latest values.
  Future<void> init() async {
    if (_initialized || !isAvailable) return;

    final remoteConfig = FirebaseRemoteConfig.instance;
    _remoteConfig = remoteConfig;

    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );

    // Fallback defaults in case Remote Config is unreachable
    await remoteConfig.setDefaults({'admin': '', 'password': ''});

    try {
      await remoteConfig.fetchAndActivate();
    } catch (_) {
      // Use cached / default values silently
    }

    _initialized = true;
  }

  /// Admin email from Remote Config (`admin` key).
  String get adminEmail => _remoteConfig?.getString('admin') ?? '';

  /// Admin password from Remote Config (`password` key).
  String get adminPassword => _remoteConfig?.getString('password') ?? '';
}
