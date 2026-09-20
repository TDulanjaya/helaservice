import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import 'app_router.dart';
import 'state/role_provider.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const HelaServiceApp());
}

class HelaServiceApp extends StatelessWidget {
  const HelaServiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return pv.ChangeNotifierProvider<RoleProvider>(
      create: (_) => RoleProvider(),
      child: MaterialApp(
        title: 'HelaService',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        initialRoute: AppRoutes.login,
        routes: appRoutes,
      ),
    );
  }
}
