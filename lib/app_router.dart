import 'package:flutter/material.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/complete_profile_screen.dart';
import 'features/customer/screens/customer_profile_screen.dart';
import 'features/customer/screens/home_discovery_screen.dart';
import 'features/provider/screens/provider_dashboard_screen.dart';
import 'features/provider/screens/provider_profile_screen.dart';
import 'features/admin/admin_shell.dart';
import 'features/admin/screens/admin_profile_screen.dart';
import 'features/admin/screens/admin_management_screen.dart';
import 'features/customer/screens/emergency_dispatch_screen.dart';

class AppRoutes {
  static const login = '/login';
  static const completeProfile = '/complete-profile';
  static const customerProfile = '/customer/profile';
  static const providerProfile = '/provider/profile';
  static const home = '/home';
  static const providerDashboard = '/pro/dashboard';
  static const admin = '/admin';
  static const adminProfile = '/admin/profile';
  static const adminManagement = '/admin/management';
  static const emergencyDispatch = '/emergency/dispatch';
}

Map<String, WidgetBuilder> appRoutes = {
  AppRoutes.login: (_) => const LoginScreen(),
  AppRoutes.completeProfile: (_) => const CompleteProfileScreen(),
  AppRoutes.customerProfile: (_) => const CustomerProfileScreen(),
  AppRoutes.providerProfile: (_) => const ProviderProfileScreen(),
  AppRoutes.home: (_) => const HomeDiscoveryScreen(),
  AppRoutes.providerDashboard: (_) => const ProviderDashboardScreen(),
  AppRoutes.admin: (_) => const AdminShell(),
  AppRoutes.adminProfile: (_) => const AdminProfileScreen(),
  AppRoutes.adminManagement: (_) => const AdminManagementScreen(),
  AppRoutes.emergencyDispatch: (_) => const EmergencyDispatchScreen(),
};
