import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_router.dart';
import 'theme/app_theme.dart';
import 'state/role_provider.dart';
import 'features/auth/screens/auth_screen.dart';

void main() {
  runApp(const HelaServiceApp());
}

class HelaServiceApp extends StatelessWidget {
  const HelaServiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RoleProvider(),
      child: MaterialApp(
        title: 'HelaService',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routes: appRoutes,
        home: const AuthScreen(),
      ),
    );
  }
}
