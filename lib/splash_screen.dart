import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import 'theme/app_theme.dart';
import 'state/role_provider.dart';
import 'models/user_profile.dart';
import 'models/admin_user.dart';
import 'services/auth_service.dart';
import 'repositories/admin_repository.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/complete_profile_screen.dart';
import 'features/customer/screens/home_discovery_screen.dart';
import 'features/provider/screens/provider_dashboard_screen.dart';
import 'features/admin/admin_shell.dart';

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
    final minDelay = Future.delayed(const Duration(milliseconds: 900));
    final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);

    final fbUser = AuthService().currentFirebaseUser;
    if (fbUser == null) {
      await minDelay;
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    try {
      final adminUser = await roleProvider.resolveAdminStatus(fbUser.uid);
      if (adminUser != null) {
        if (adminUser.status == AdminStatus.suspended) {
          await AuthService().signOut();
          await minDelay;
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your admin access is suspended.')),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
          return;
        }

        AdminRepository().touchLastActive(fbUser.uid);

        await minDelay;
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminShell()),
        );
        return;
      }
    } catch (_) {}

    // Route customers and providers to their home screen.
    UserProfile? user = roleProvider.currentUser;
    if (user == null) {
      try {
        user = await AuthService().fetchCurrentUserProfile();
        if (user != null) {
          roleProvider.setUser(user);
        }
      } catch (_) {}
    }

    await minDelay;
    if (!mounted) return;

    Widget destination = const LoginScreen();
    if (user == null) {
      destination = const LoginScreen();
    } else if (!roleProvider.isProfileCompleted || user.role == null) {
      destination = CompleteProfileScreen(initialProfile: user);
    } else {
      switch (user.role!) {
        case AppRole.customer:
        case AppRole.admin: // Never route to AdminShell from users.role, treat as customer
          destination = const HomeDiscoveryScreen();
          break;
        case AppRole.provider:
          destination = const ProviderDashboardScreen();
          break;
      }
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Image.asset(
                        'assets/images/app_logo.png',
                        width: 128,
                        height: 128,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'HelaService',
                    style: TextStyle(
                      color: AppColors.onPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  '© 2026 HelaService. All rights reserved.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.onPrimary.withValues(alpha: 0.65),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
