import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/l10n_extension.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _prefKey = 'app_theme_mode';
  ThemeMode _mode;

  ThemeProvider({ThemeMode initialMode = ThemeMode.system}) : _mode = initialMode;

  static Future<ThemeMode> loadSavedMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString(_prefKey);
      if (savedStr == 'light') return ThemeMode.light;
      if (savedStr == 'dark') return ThemeMode.dark;
      if (savedStr == 'system') return ThemeMode.system;
    } catch (_) {}
    return ThemeMode.system;
  }

  ThemeMode get mode => _mode;

  bool isDark(BuildContext context) {
    if (_mode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _mode == ThemeMode.dark;
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, mode.name);
    } catch (_) {}
  }

  void setLight() => setMode(ThemeMode.light);
  void setDark() => setMode(ThemeMode.dark);
  void setSystem() => setMode(ThemeMode.system);

  void toggle(BuildContext context) {
    if (isDark(context)) {
      setMode(ThemeMode.light);
    } else {
      setMode(ThemeMode.dark);
    }
  }

  String getModeDisplayName(BuildContext context) {
    final l10n = context.l10n;
    switch (_mode) {
      case ThemeMode.light:
        return l10n.themeLight;
      case ThemeMode.dark:
        return l10n.themeDark;
      case ThemeMode.system:
        return l10n.themeSystem;
    }
  }

  /// Non-localized theme name for persistence / logging only.
  String get modeName => _mode.name;

  IconData get modeIcon {
    switch (_mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  static IconData getIconForMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  /// Non-localized name for persistence / logging only.
  static String getNameForMode(ThemeMode mode) => mode.name;
}
