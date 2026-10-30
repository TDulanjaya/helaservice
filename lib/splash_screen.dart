import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart' as pv;
import 'theme/app_theme.dart';
import 'state/role_provider.dart';
import 'models/user_profile.dart';
import 'models/admin_user.dart';
import 'services/auth_service.dart';
import 'services/app_version_service.dart';
import 'services/notification_service.dart';
import 'services/session_guard.dart';
import 'repositories/admin_repository.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/email_otp_screen.dart';
import 'features/auth/screens/role_choice_screen.dart';
import 'features/auth/screens/complete_profile_screen.dart';
import 'features/customer/screens/home_discovery_screen.dart';
import 'features/provider/screens/provider_dashboard_screen.dart';
import 'features/provider/screens/provider_pending_screen.dart';
import 'features/admin/admin_shell.dart';
import 'utils/l10n_extension.dart';
import 'utils/provider_routing_helper.dart';

// app splash screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // show retry when offline
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    SessionGuard.enterAuthScreen();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _resolveDestination();
    });
  }

  @override
  void dispose() {
    SessionGuard.exitAuthScreen();
    super.dispose();
  }

  void _retry() {
    setState(() => _offline = false);
    _resolveDestination();
  }

  Future<void> _resolveDestination() async {
    final minDelay = Future.delayed(const Duration(milliseconds: 900));
    final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);

    // check minimum app version requirement asynchronously
    AppVersionService.instance.checkMinimumVersion(context).catchError((_) {});

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

        var tokenResult = await fbUser.getIdTokenResult();
        final authTime = tokenResult.authTime?.millisecondsSinceEpoch != null
            ? (tokenResult.authTime!.millisecondsSinceEpoch ~/ 1000)
            : null;
        var rawLoginTimes = tokenResult.claims?['loginOtpTimes'];
        var loginOtpTimes = (rawLoginTimes is List)
            ? rawLoginTimes.map((e) => (e as num).toInt()).toList()
            : <int>[];
        var isLoginOtpVerified =
            authTime != null && loginOtpTimes.contains(authTime);

        // try refreshing token in case claims updated
        if (!isLoginOtpVerified) {
          await fbUser.getIdToken(true);
          tokenResult = await fbUser.getIdTokenResult();
          rawLoginTimes = tokenResult.claims?['loginOtpTimes'];
          loginOtpTimes = (rawLoginTimes is List)
              ? rawLoginTimes.map((e) => (e as num).toInt()).toList()
              : <int>[];
          isLoginOtpVerified =
              authTime != null && loginOtpTimes.contains(authTime);
        }

        if (isLoginOtpVerified) {
          AdminRepository().touchLastActive(fbUser.uid);
          await minDelay;
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminShell()),
          );
          return;
        } else {
          // admin otp required for this session
          final sendOnOpen = authTime == null ||
              !SessionGuard.hasOtpBeenSent(fbUser.uid, authTime);
          if (authTime != null && sendOnOpen) {
            SessionGuard.markOtpSent(fbUser.uid, authTime);
          }
          await minDelay;
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => EmailOtpScreen(
                email: fbUser.email ?? '',
                purpose: 'admin_login',
                sendOnOpen: sendOnOpen,
              ),
            ),
            (route) => false,
          );
          return;
        }
      }
    } catch (_) {}

    // navigate user
    UserProfile? user = roleProvider.currentUser;
    if (user == null) {
      try {
        // load profile
        user =
            await AuthService().fetchCurrentUserProfile(throwOnNetwork: true);
      } on AuthFlowException {
        await minDelay;
        if (!mounted) return;
        setState(() => _offline = true);
        return;
      } catch (_) {}

      if (user == null) {
        // no profile so go to login
        await AuthService().signOut();
        await minDelay;
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }
      roleProvider.setUser(user);
    }
    final UserProfile profile = user;

    // start notification listeners and token sync
    NotificationService.instance.initialize();

    if (profile.isBanned) {
      await roleProvider.logout();
      await minDelay;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.accountSuspendedDesc),
          backgroundColor: AppColors.error,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    // check if user verified email
    try {
      var tokenResult = await fbUser.getIdTokenResult();
      var hasEmailOtpClaim = tokenResult.claims?['emailOtp'] == true;

      // refresh token if claim is missing
      if (profile.emailOtpVerified && !hasEmailOtpClaim) {
        await fbUser.getIdToken(true);
        tokenResult = await fbUser.getIdTokenResult();
        hasEmailOtpClaim = tokenResult.claims?['emailOtp'] == true;
      }

      final isEmailOtpVerified = hasEmailOtpClaim || profile.emailOtpVerified;

      if (!isEmailOtpVerified) {
        await minDelay;
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => EmailOtpScreen(
              email: fbUser.email ?? profile.email,
              purpose: 'signup',
              sendOnOpen: true,
            ),
          ),
          (route) => false,
        );
        return;
      }

      // check if this device session has completed login otp
      final authTime = tokenResult.authTime?.millisecondsSinceEpoch != null
          ? (tokenResult.authTime!.millisecondsSinceEpoch ~/ 1000)
          : null;
      var rawLoginTimes = tokenResult.claims?['loginOtpTimes'];
      var loginOtpTimes = (rawLoginTimes is List)
          ? rawLoginTimes.map((e) => (e as num).toInt()).toList()
          : <int>[];
      var isLoginOtpVerified =
          authTime != null && loginOtpTimes.contains(authTime);

      if (!isLoginOtpVerified) {
        await fbUser.getIdToken(true);
        tokenResult = await fbUser.getIdTokenResult();
        rawLoginTimes = tokenResult.claims?['loginOtpTimes'];
        loginOtpTimes = (rawLoginTimes is List)
            ? rawLoginTimes.map((e) => (e as num).toInt()).toList()
            : <int>[];
        isLoginOtpVerified =
            authTime != null && loginOtpTimes.contains(authTime);
      }

      if (!isLoginOtpVerified) {
        final sendOnOpen = authTime == null ||
            !SessionGuard.hasOtpBeenSent(fbUser.uid, authTime);
        if (authTime != null && sendOnOpen) {
          SessionGuard.markOtpSent(fbUser.uid, authTime);
        }
        await minDelay;
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => EmailOtpScreen(
              email: fbUser.email ?? profile.email,
              purpose: 'login',
              sendOnOpen: sendOnOpen,
            ),
          ),
          (route) => false,
        );
        return;
      }
    } catch (_) {}

    await minDelay;
    if (!mounted) return;

    final appDest = resolveAppDestination(
      profile: profile,
      isAuthorizedAdmin: roleProvider.isAuthorizedAdmin,
      isEmailOtpVerified: true,
      isTechnicianApproved: roleProvider.isApprovedProvider,
    );
    if (kDebugMode) {
      debugPrint('[navdbg] splash resolved AppDestination: $appDest');
    }

    Widget destination;
    switch (appDest) {
      case AppDestination.roleChoice:
        destination = RoleChoiceScreen(user: profile);
        break;
      case AppDestination.completeProfile:
        destination = CompleteProfileScreen(initialProfile: profile);
        break;
      case AppDestination.providerDashboard:
        if (kDebugMode) {
          debugPrint('[navdbg] -> dashboard from splash_screen.dart');
        }
        destination = const ProviderDashboardScreen();
        break;
      case AppDestination.providerPendingNew:
        if (kDebugMode) {
          debugPrint('[navdbg] -> pending from splash_screen.dart');
        }
        destination = const ProviderPendingScreen(isExistingCustomer: false);
        break;
      case AppDestination.providerPendingCustomer:
        if (kDebugMode) {
          debugPrint('[navdbg] -> customer home from splash_screen.dart');
        }
        destination = const HomeDiscoveryScreen();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.providerPendingCustomerToast),
                backgroundColor: AppColors.primary,
              ),
            );
          }
        });
        break;
      case AppDestination.homeDiscovery:
      default:
        if (kDebugMode) {
          debugPrint('[navdbg] -> customer home from splash_screen.dart');
        }
        destination = const HomeDiscoveryScreen();
        break;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0B0C0E),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
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
                                color:
                                    AppColors.primary.withValues(alpha: 0.35),
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
                    if (_offline) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          context.l10n.splashNoConnection,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _retry,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: const Color(0xFF17140F),
                        ),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(context.l10n.retryAction),
                      ),
                    ] else
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: const SizedBox(
                          width: 72,
                          height: 4,
                          child: LinearProgressIndicator(
                            backgroundColor: Color(0xFF232529),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
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
      ),
    );
  }
}
