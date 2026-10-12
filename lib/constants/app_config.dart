import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class AppConfig {
  AppConfig._();

  // load remote config on startup
  static Future<void> initializeRemoteConfig() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval:
              kDebugMode ? Duration.zero : const Duration(hours: 1),
        ),
      );

      // fetch latest values
      await remoteConfig
          .fetchAndActivate()
          .timeout(const Duration(seconds: 8), onTimeout: () => false);

      if (kDebugMode) {
        final allKeys = remoteConfig.getAll().keys.toList();
        debugPrint('[AppConfig] Remote Config initialized. Keys present: $allKeys');
      }
    } catch (e) {
      debugPrint('[AppConfig] Firebase Remote Config init warning: $e');
    }
  }

  // get string config or fallback
  static String getString(String key, {String fallback = ''}) {
    try {
      final value = FirebaseRemoteConfig.instance.getString(key);
      return value.trim().isNotEmpty ? value.trim() : fallback;
    } catch (_) {
      return fallback;
    }
  }

  static String _localOtpApiUrl = '';

  // override for local testing if needed
  static void setOtpApiUrl(String url) {
    _localOtpApiUrl = url.trim();
  }

  // api base url
  static String get otpApiUrl {
    if (_localOtpApiUrl.isNotEmpty) return _localOtpApiUrl;
    return getString('otp_api_url', fallback: 'https://helaservice.vercel.app/api');
  }

  // api secret key
  static String get apiSecretKey {
    final key = getString('api_secret_key', fallback: '');
    if (key.isEmpty) {
      debugPrint('[AppConfig] Warning: Firebase Remote Config is missing api_secret_key.');
    }
    return key;
  }

  // support contact details from remote config
  static String get supportPhone => getString('support_phone', fallback: '');
  static String get supportEmail => getString('support_email', fallback: '');
}
