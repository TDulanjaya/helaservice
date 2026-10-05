import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class AppConfig {
  AppConfig._();

  /// Loads remote config values when the app starts.
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

      // Fetch new values in the background.
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

  /// Safely get string from Remote Config with optional fallback
  static String getString(String key, {String fallback = ''}) {
    try {
      final value = FirebaseRemoteConfig.instance.getString(key);
      return value.trim().isNotEmpty ? value.trim() : fallback;
    } catch (_) {
      return fallback;
    }
  }

  static String _localOtpApiUrl = '';

  /// Optional override for local testing (e.g. `http://10.0.2.2:3000/api`)
  static void setOtpApiUrl(String url) {
    _localOtpApiUrl = url.trim();
  }

  /// Base URL for Vercel OTP endpoints (Remote Config key: `otp_api_url`)
  static String get otpApiUrl {
    if (_localOtpApiUrl.isNotEmpty) return _localOtpApiUrl;
    return getString('otp_api_url', fallback: 'https://helaservice.vercel.app/api');
  }
}
