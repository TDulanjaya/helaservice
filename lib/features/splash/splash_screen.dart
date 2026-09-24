import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import '../../theme/app_theme.dart';
import '../../state/role_provider.dart';
import '../auth/screens/login_screen.dart';
import '../auth/screens/complete_profile_screen.dart';
import '../customer/screens/home_discovery_screen.dart';
import '../provider/screens/provider_dashboard_screen.dart';
import '../admin/admin_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _resolveDestination();
  }

  Future<void> _resolveDestination() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
    final user = roleProvider.currentUser;

    Widget destination = const LoginScreen();
    if (user == null) {
      destination = const LoginScreen();
    } else if (!roleProvider.isProfileCompleted || user.role == null) {
      destination = CompleteProfileScreen(initialProfile: user);
    } else {
      switch (user.role!) {
        case AppRole.customer:
          destination = const HomeDiscoveryScreen();
          break;
        case AppRole.provider:
          destination = const ProviderDashboardScreen();
          break;
        case AppRole.admin:
          destination = const AdminShell();
          break;
      }
    }

    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => destination));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.bolt, color: AppColors.primary, size: 34),
            ),
            const SizedBox(height: 16),
            const Text(
              'HelaService',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
