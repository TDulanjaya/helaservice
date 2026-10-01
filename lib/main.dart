import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart' as pv;
import 'firebase_options.dart';
import 'app_router.dart';
import 'state/role_provider.dart';
import 'state/theme_provider.dart';
import 'state/locale_provider.dart';
import 'theme/app_theme.dart';
import 'splash_screen.dart';
import 'constants/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    if (kIsWeb) {
      const siteKey = String.fromEnvironment('RECAPTCHA_ENTERPRISE_SITE_KEY');
      if (siteKey.isEmpty) {
        debugPrint(
          '[AppCheck] ERROR: RECAPTCHA_ENTERPRISE_SITE_KEY is not set. '
          'Skipping App Check activation on web. '
          'Requests will fail once App Check enforcement is enabled.',
        );
      } else {
        await FirebaseAppCheck.instance.activate(
          webProvider: ReCaptchaEnterpriseProvider(siteKey),
        );
      }
    } else {
      await FirebaseAppCheck.instance.activate(
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      );
    }
  } catch (e) {
    debugPrint('[AppCheck] Activation note: $e');
  }

  final initialThemeMode = await ThemeProvider.loadSavedMode();
  final initialLocale = await LocaleProvider.loadSavedLocale();
  await AppConfig.initializeRemoteConfig();
  runApp(HelaServiceApp(
    initialThemeMode: initialThemeMode,
    initialLocale: initialLocale,
  ));
}

class HelaServiceApp extends StatelessWidget {
  final ThemeMode initialThemeMode;
  final Locale initialLocale;

  const HelaServiceApp({
    super.key,
    this.initialThemeMode = ThemeMode.system,
    this.initialLocale = const Locale('en'),
  });

  @override
  Widget build(BuildContext context) {
    return pv.MultiProvider(
      providers: [
        pv.ChangeNotifierProvider<RoleProvider>(create: (_) => RoleProvider()),
        pv.ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(initialMode: initialThemeMode),
        ),
        pv.ChangeNotifierProvider<LocaleProvider>(
          create: (_) => LocaleProvider(initialLocale: initialLocale),
        ),
      ],
      child: pv.Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, _) {
          return MaterialApp(
            key: ValueKey(localeProvider.languageCode),
            title: 'HelaService',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeProvider.mode,
            locale: localeProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: const SplashScreen(),
            routes: appRoutes,
          );
        },
      ),
    );
  }
}
