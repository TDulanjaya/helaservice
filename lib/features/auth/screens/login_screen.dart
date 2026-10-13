import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/google_sign_in_button.dart';
import '../../../state/role_provider.dart';
import '../../../services/auth_service.dart';
import '../../../models/user_profile.dart';
import '../../../models/admin_user.dart';
import '../../../repositories/admin_repository.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/auth_error_l10n.dart';
import 'complete_profile_screen.dart';
import 'role_choice_screen.dart';
import 'register_screen.dart';
import 'email_otp_screen.dart';
import '../../../services/otp_service.dart';
import '../../customer/screens/home_discovery_screen.dart';
import '../../provider/screens/provider_dashboard_screen.dart';
import '../../admin/admin_shell.dart';
import '../../../utils/map_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isGoogleLoading = false;
  bool _isEmailLoading = false;
  bool _obscurePassword = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.clear();
    _passwordController.clear();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _routeUser(UserProfile user) async {
    final currentLocale = mounted ? context.l10n.localeName : 'en';

    // check if user is banned
    if (user.isBanned) {
      await AuthService().signOut();
      if (!mounted) return;
      _showAccountSuspendedDialog(user.banReason);
      return;
    }

    if (!mounted) return;
    final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
    roleProvider.setUser(user);

    final fbUser = AuthService().currentFirebaseUser;
    if (fbUser != null) {
      try {
        final adminUser = await roleProvider.resolveAdminStatus(fbUser.uid);
        if (adminUser != null) {
          if (adminUser.status == AdminStatus.suspended) {
            await AuthService().signOut();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.adminAccessSuspended),
                backgroundColor: AppColors.error,
              ),
            );
            return;
          }

          final tokenResult = await fbUser.getIdTokenResult();
          final admin2faUntil = (tokenResult.claims?['admin2faUntil'] as num?)?.toInt() ?? 0;
          final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
          final is2faValid = admin2faUntil > nowSec;

          if (!is2faValid) {
            await OtpService().sendEmailOtp(
              fbUser.email ?? user.email,
              purpose: 'admin_login',
              language: currentLocale,
            );
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => EmailOtpScreen(
                  email: fbUser.email ?? user.email,
                  purpose: 'admin_login',
                ),
              ),
              (route) => false,
            );
            return;
          }

          AdminRepository().touchLastActive(fbUser.uid);

          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AdminShell()),
            (route) => false,
          );
          return;
        }
      } catch (_) {}

      // check if regular user verified email
      final tokenResult = await fbUser.getIdTokenResult();
      final hasEmailOtpClaim = tokenResult.claims?['emailOtp'] == true;
      final isEmailOtpVerified = hasEmailOtpClaim || user.emailOtpVerified;

      if (!isEmailOtpVerified) {
        await OtpService().sendEmailOtp(
          fbUser.email ?? user.email,
          purpose: 'signup',
          language: currentLocale,
        );
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => EmailOtpScreen(
              email: fbUser.email ?? user.email,
              purpose: 'signup',
            ),
          ),
          (route) => false,
        );
        return;
      }
    }

    if (user.role == null) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => RoleChoiceScreen(user: user)),
        (route) => false,
      );
      return;
    }

    if (!user.isProfileComplete) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => CompleteProfileScreen(initialProfile: user),
        ),
        (route) => false,
      );
      return;
    }

    if (user.role == AppRole.provider) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ProviderDashboardScreen()),
        (route) => false,
      );
      return;
    }

    if (user.role == AppRole.customer || user.role == AppRole.admin) {
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeDiscoveryScreen()),
        (route) => false,
      );
      return;
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);

    try {
      // login only, no new accounts
      final user = await AuthService().signInWithGoogle(allowCreate: false);

      if (!mounted) return;
      await _routeUser(user);
    } on AuthFlowException catch (e) {
      if (!mounted) return;
      if (e.code == AuthFlowException.googleNoAccount) {
        _showGoogleNoAccountDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.authErrNetwork),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[LoginScreen GoogleSignIn Error] $e');
      }
      if (!mounted) return;
      final msg = AuthService.getReadableAuthError(e);
      if (!msg.contains('cancelled') &&
          !msg.contains('ABORTED') &&
          !msg.contains('12501')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${context.l10n.googleSignInExisting}: ${authErrorMessage(context, e)}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  void _showGoogleNoAccountDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: context.themeBorder, width: 1.5),
        ),
        title: Text(
          ctx.l10n.googleNoAccountTitle,
          style: TextStyle(
            color: context.themeInk,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        content: Text(
          ctx.l10n.googleNoAccountMessage,
          style: TextStyle(
            color: context.themeTextSecondary,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ctx.l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              );
            },
            child: Text(
              ctx.l10n.createAccount,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEmailSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.enterEmailError),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.enterPasswordError),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isEmailLoading = true);

    try {
      final authService = AuthService();
      final user = await authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;
      await _routeUser(user);
    } catch (e) {
      if (!mounted) return;
      final errorMsg = authErrorMessage(context, e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isEmailLoading = false);
      }
    }
  }

  void _showForgotPasswordDialog() {
    final resetController =
        TextEditingController(text: _emailController.text.trim());
    bool isResetting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: context.themeSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: context.themeBorder, width: 1.5),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lock_reset, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.resetPassword,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.themeTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.resetPasswordDesc,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.themeTextSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.emailAddress,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: context.themeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: resetController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: context.themeTextPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: context.l10n.hintEmail,
                      prefixIcon: Icon(Icons.email_outlined, size: 20, color: context.themeTextSecondary),
                      filled: true,
                      fillColor: context.isDark ? context.themeSurfaceLow : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: context.themeBorder, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: context.themeBorder, width: 1.5),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  context.l10n.cancel,
                  style: TextStyle(
                    color: context.themeTextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: isResetting
                    ? null
                    : () async {
                        final email = resetController.text.trim();
                        if (email.isEmpty) return;

                        setDialogState(() => isResetting = true);
                        try {
                          await AuthService().sendPasswordResetEmail(email);
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.l10n.passwordResetSent(email),
                              ),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        } catch (e) {
                          if (!ctx.mounted) return;
                          setDialogState(() => isResetting = false);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text(authErrorMessage(context, e)),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isResetting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : Text(
                        context.l10n.sendResetLink,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAccountSuspendedDialog(String? reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.block_flipped, color: AppColors.error, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.l10n.accountSuspendedTitle,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.accountSuspendedDesc,
              style: TextStyle(fontSize: 13.5, color: context.themeTextSecondary, height: 1.4),
            ),
            if (reason != null && reason.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.suspensionReasonLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reason,
                      style: TextStyle(fontSize: 12.5, color: context.themeTextPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.ok),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              MapLauncher.openPhoneCall('1340');
            },
            icon: const Icon(Icons.phone, size: 16),
            label: Text(context.l10n.contactHelpline),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturePill(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: context.themeTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildFormContent(BuildContext context, Color isFieldBg, {required bool showHeader}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showHeader) ...[
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                context.l10n.appTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.themeTextPrimary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
        ],
        Text(
          context.l10n.loginTitle,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: context.themeTextPrimary,
            height: 1.25,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.loginSubtitle,
          style: TextStyle(
            fontSize: 13.5,
            color: context.themeTextSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),

        Text(
          context.l10n.emailAddress,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.themeTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(color: context.themeTextPrimary, fontSize: 14.5),
          decoration: InputDecoration(
            hintText: context.l10n.hintEmail,
            hintStyle: TextStyle(
              color: context.themeTextSecondary.withValues(alpha: 0.6),
            ),
            prefixIcon: Icon(
              Icons.email_outlined,
              size: 20,
              color: context.themeTextSecondary,
            ),
            filled: true,
            fillColor: isFieldBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: context.themeBorder, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: context.themeBorder, width: 1.5),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 18),
        Text(
          context.l10n.password,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.themeTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: TextStyle(color: context.themeTextPrimary, fontSize: 14.5),
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              size: 20,
              color: context.themeTextSecondary,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: context.themeTextSecondary,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: isFieldBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: context.themeBorder, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: context.themeBorder, width: 1.5),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: _showForgotPasswordDialog,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                context.l10n.forgotPassword,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 18),
        PrimaryButton(
          label: context.l10n.signIn,
          loading: _isEmailLoading,
          onPressed: (_isEmailLoading || _isGoogleLoading) ? null : _handleEmailSignIn,
        ),

        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Divider(color: context.themeBorder, thickness: 1)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                context.l10n.orContinueWith,
                style: TextStyle(
                  color: context.themeTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(child: Divider(color: context.themeBorder, thickness: 1)),
          ],
        ),

        const SizedBox(height: 20),
        GoogleSignInButton(
          isLoading: _isGoogleLoading,
          text: context.l10n.googleSignInExisting,
          onPressed: (_isGoogleLoading || _isEmailLoading) ? null : () => _handleGoogleSignIn(),
        ),

        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isFieldBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.themeBorder, width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.newToHelaService,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.themeTextSecondary,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegisterScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.isDark ? Colors.white : const Color(0xFF141517),
                  foregroundColor: context.isDark ? const Color(0xFF141517) : Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  context.l10n.createAccount,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFieldBg = context.isDark ? context.themeSurfaceLow : Colors.white;
    final width = MediaQuery.of(context).size.width;

    // wide desktop dual pane
    if (width >= 960) {
      return Scaffold(
        backgroundColor: context.themeBg,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Container(
                decoration: BoxDecoration(
                  color: context.themeSurface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: context.themeBorder, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: context.isDark ? 0.35 : 0.06),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // left brand hero
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.all(44),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: context.isDark ? 0.12 : 0.08),
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(26)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Image.asset('assets/images/app_logo.png', width: 56, height: 56),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              context.l10n.appTitle,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: context.themeTextPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              context.l10n.loginSubtitle,
                              style: TextStyle(
                                fontSize: 14.5,
                                color: context.themeTextSecondary,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 36),
                            _buildFeaturePill(context, Icons.verified_user_outlined, 'Verified Service Artisans'),
                            const SizedBox(height: 14),
                            _buildFeaturePill(context, Icons.navigation_outlined, 'Live GPS Motorcycle Tracking'),
                            const SizedBox(height: 14),
                            _buildFeaturePill(context, Icons.price_check_outlined, 'Transparent Local Quotes'),
                          ],
                        ),
                      ),
                    ),
                    // right form
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(44),
                        child: _buildFormContent(context, isFieldBg, showHeader: false),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // tablet or desktop centered card
    if (width >= 600) {
      return Scaffold(
        backgroundColor: context.themeBg,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(36),
                decoration: BoxDecoration(
                  color: context.themeSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: context.themeBorder, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _buildFormContent(context, isFieldBg, showHeader: true),
              ),
            ),
          ),
        ),
      );
    }

    // mobile layout
    return Scaffold(
      backgroundColor: context.themeBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: _buildFormContent(context, isFieldBg, showHeader: true),
        ),
      ),
    );
  }
}
