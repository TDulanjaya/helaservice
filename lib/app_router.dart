import 'package:flutter/material.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/complete_profile_screen.dart';
import 'features/customer/screens/customer_register_screen.dart';
import 'features/customer/screens/customer_profile_screen.dart';
import 'features/customer/screens/home_discovery_screen.dart';
import 'features/provider/screens/provider_register_screen.dart';
import 'features/provider/screens/provider_dashboard_screen.dart';
import 'features/provider/screens/provider_profile_screen.dart';
import 'features/admin/admin_shell.dart';
import 'features/admin/screens/admin_profile_screen.dart';

class AppRoutes {
  static const login = '/';
  static const completeProfile = '/complete-profile';
  static const customerRegister = '/register/customer';
  static const customerProfile = '/customer/profile';
  static const providerRegister = '/register/provider';
  static const providerProfile = '/provider/profile';
  static const home = '/home';
  static const providerDashboard = '/pro/dashboard';
  static const admin = '/admin';
  static const adminProfile = '/admin/profile';
}

Map<String, WidgetBuilder> appRoutes = {
  AppRoutes.login: (_) => const LoginScreen(),
  AppRoutes.completeProfile: (_) => const CompleteProfileScreen(),
  AppRoutes.customerRegister: (_) => const CustomerRegisterScreen(),
  AppRoutes.customerProfile: (_) => const CustomerProfileScreen(),
  AppRoutes.providerRegister: (_) => const ProviderRegisterScreen(),
  AppRoutes.providerProfile: (_) => const ProviderProfileScreen(),
  AppRoutes.home: (_) => const HomeDiscoveryScreen(),
  AppRoutes.providerDashboard: (_) => const ProviderDashboardScreen(),
  AppRoutes.admin: (_) => const AdminShell(),
  AppRoutes.adminProfile: (_) => const AdminProfileScreen(),
};



