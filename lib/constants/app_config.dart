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
}
