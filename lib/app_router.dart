import 'package:flutter/material.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/customer/screens/customer_register_screen.dart';
import 'features/customer/screens/home_discovery_screen.dart';
import 'features/provider/screens/provider_register_screen.dart';
import 'features/provider/screens/provider_dashboard_screen.dart';
import 'features/admin/admin_shell.dart';

class AppRoutes {
  static const login = '/';
  static const customerRegister = '/register/customer';
  static const providerRegister = '/register/provider';
  static const home = '/home';
  static const providerDashboard = '/pro/dashboard';
  static const admin = '/admin';
}

Map<String, WidgetBuilder> appRoutes = {
  AppRoutes.login: (_) => const LoginScreen(),
  AppRoutes.customerRegister: (_) => const CustomerRegisterScreen(),
  AppRoutes.providerRegister: (_) => const ProviderRegisterScreen(),
  AppRoutes.home: (_) => const HomeDiscoveryScreen(),
  AppRoutes.providerDashboard: (_) => const ProviderDashboardScreen(),
  AppRoutes.admin: (_) => const AdminShell(),
};
