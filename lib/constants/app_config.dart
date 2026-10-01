import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class AppConfig {
  AppConfig._();

  // Remote Config holds the map key. No key is hardcoded.
  static String _stadiaMapsKey = '';

  static final ValueNotifier<String> stadiaMapsKeyNotifier =
      ValueNotifier<String>(_stadiaMapsKey);

  static String get stadiaMapsKey => _stadiaMapsKey;
  static bool get hasStadiaMapsKey => _stadiaMapsKey.isNotEmpty;

  /// Finds the map API key from Remote Config parameters.
  static String _findMapKey(FirebaseRemoteConfig rc) {
    const candidates = [
      'STADIA_MAPS_KEY',
      'stadia_maps_key',
      'stadiaMapsKey',
      'STADIA_KEY',
      'stadia_key',
      'MAPS_API_KEY',
      'maps_api_key',
      'MAP_API_KEY',
      'map_api_key',
      'MAP_KEY',
      'map_key',
    ];

    for (final c in candidates) {
      final val = rc.getString(c).trim();
      if (val.isNotEmpty) {
        return val;
      }
    }

    // Search parameter names ignoring case.
    for (final entry in rc.getAll().entries) {
      final lowerKey = entry.key.toLowerCase();
      if (lowerKey.contains('stadia') ||
          (lowerKey.contains('map') && lowerKey.contains('key'))) {
        final val = entry.value.asString().trim();
        if (val.isNotEmpty) {
          return val;
        }
      }
    }

    return '';
  }

  /// Loads remote config values when the app starts.
  static Future<void> initializeRemoteConfig() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      // Use cached values first so startup is instant.
      final cachedKey = _findMapKey(remoteConfig);
      if (cachedKey.isNotEmpty) {
        _stadiaMapsKey = cachedKey;
        stadiaMapsKeyNotifier.value = cachedKey;
        debugPrint('[AppConfig] Loaded map key from Remote Config local cache.');
      }

      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval:
              kDebugMode ? Duration.zero : const Duration(hours: 1),
        ),
      );

      await remoteConfig.setDefaults({
        'STADIA_MAPS_KEY': '',
      });

      // Fetch new values in the background.
      await remoteConfig
          .fetchAndActivate()
          .timeout(const Duration(seconds: 8), onTimeout: () => false);

      final freshKey = _findMapKey(remoteConfig);
      if (freshKey.isNotEmpty && freshKey != _stadiaMapsKey) {
        _stadiaMapsKey = freshKey;
        stadiaMapsKeyNotifier.value = freshKey;
        debugPrint('[AppConfig] Activated fresh map key from Remote Config.');
      }

      if (kDebugMode) {
        final allKeys = remoteConfig.getAll().keys.toList();
        debugPrint('[AppConfig] Remote Config initialized. Keys present: $allKeys');
        debugPrint(
            '[AppConfig] Map key configured: ${hasStadiaMapsKey ? "YES (length: ${_stadiaMapsKey.length})" : "NO (using resilient CartoDB/OSM fallback)"}');
      }
    } catch (e) {
      debugPrint('[AppConfig] Firebase Remote Config init warning: $e');
      try {
        final fallbackKey = _findMapKey(FirebaseRemoteConfig.instance);
        if (fallbackKey.isNotEmpty) {
          _stadiaMapsKey = fallbackKey;
          stadiaMapsKeyNotifier.value = fallbackKey;
        }
      } catch (_) {}
    }
  }
}

