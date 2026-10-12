import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _prefKey = 'app_locale_code';
  Locale _locale;

  LocaleProvider({Locale initialLocale = const Locale('en')})
      : _locale = initialLocale;

  static Future<Locale> loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefKey);
      if (savedCode != null && ['en', 'si', 'ta'].contains(savedCode)) {
        return Locale(savedCode);
      }
    } catch (_) {}
    return const Locale('en');
  }

  Locale get locale => _locale;

  String get languageCode => _locale.languageCode;

  Future<void> setLocale(Locale newLocale, {String? userId}) async {
    if (!['en', 'si', 'ta'].contains(newLocale.languageCode)) return;
    if (_locale.languageCode == newLocale.languageCode) return;

    _locale = newLocale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, newLocale.languageCode);
    } catch (_) {}

    final currentUid = (userId != null && userId.isNotEmpty)
        ? userId
        : FirebaseAuth.instance.currentUser?.uid;

    if (currentUid != null && currentUid.isNotEmpty) {
      try {
        await AuthService().updateUserField(currentUid, {
          'language': newLocale.languageCode,
          'preferredLanguage': newLocale.languageCode,
        });
      } catch (_) {}
    }
  }

  String get languageDisplayName {
    switch (_locale.languageCode) {
      case 'si':
        return 'සිංහල (Sinhala)';
      case 'ta':
        return 'தமிழ் (Tamil)';
      case 'en':
      default:
        return 'English';
    }
  }

  String get flagEmoji => '';

  static String getDisplayNameForCode(String code) {
    switch (code) {
      case 'si':
        return 'සිංහල (Sinhala)';
      case 'ta':
        return 'தமிழ் (Tamil)';
      case 'en':
      default:
        return 'English';
    }
  }

  static String getFlagForCode(String code) => '';
}
