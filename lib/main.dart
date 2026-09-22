import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import 'app_router.dart';
import 'state/role_provider.dart';
import 'state/theme_provider.dart';
import 'theme/app_theme.dart';
import 'features/splash/splash_screen.dart';

void main() {
  runApp(const HelaServiceApp());
}

class HelaServiceApp extends StatelessWidget {
  const HelaServiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return pv.MultiProvider(
      providers: [
        pv.ChangeNotifierProvider<RoleProvider>(create: (_) => RoleProvider()),
        pv.ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
      ],
      child: pv.Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'HelaService',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeProvider.mode,
            home: const SplashScreen(),
            routes: appRoutes,
          );
        },
      ),
    );
  }
}
