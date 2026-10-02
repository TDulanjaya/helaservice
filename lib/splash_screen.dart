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
import 'utils/l10n_extension.dart';

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
            SnackBar(content: Text(context.l10n.adminAccessSuspended)),
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

    // Route users to their home screen
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
        case AppRole.admin: // Admin role here routes as customer
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
      backgroundColor: const Color(0xFF0B0C0E),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 320,
                        height: 320,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.16),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.28),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 36,
                              offset: const Offset(0, 10),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.l10n.appTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 26),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: const SizedBox(
                      width: 72,
                      height: 4,
                      child: LinearProgressIndicator(
                        backgroundColor: Color(0xFF232529),
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  '© 2026 Thisara Dulanjaya. All rights reserved.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.45),
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
