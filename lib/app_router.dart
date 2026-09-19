import 'package:flutter/material.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/customer/screens/home_discovery_screen.dart';
import 'features/provider/screens/provider_dashboard_screen.dart';

import 'features/admin/admin_shell.dart';

class AppRoutes {
  static const auth = '/auth';
  static const home = '/home';
  static const providerDashboard = '/pro/dashboard';
  static const admin = '/admin';
}

Map<String, WidgetBuilder> appRoutes = {
  AppRoutes.auth: (_) => const AuthScreen(),
  AppRoutes.home: (_) => const HomeDiscoveryScreen(),
  AppRoutes.providerDashboard: (_) => const ProviderDashboardScreen(),
  AppRoutes.admin: (_) => const AdminShell(),
};
