import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../state/role_provider.dart';
import '../../../services/auth_service.dart';
import '../../../models/user_profile.dart';
import '../../../models/admin_user.dart';
import '../../../repositories/admin_repository.dart';
import '../../../utils/l10n_extension.dart';
import 'complete_profile_screen.dart';
import 'register_screen.dart';
import '../../customer/screens/home_discovery_screen.dart';
import '../../provider/screens/provider_dashboard_screen.dart';
import '../../admin/admin_shell.dart';

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
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _routeUser(UserProfile user) async {
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
              const SnackBar(
                content: Text('Your admin access is suspended.'),
                backgroundColor: AppColors.error,
              ),
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

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CompleteProfileScreen(initialProfile: user),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);

    try {
      final authService = AuthService();
      final user = await authService.signInWithGoogle();

      if (!mounted) return;
      await _routeUser(user);
    } catch (e) {
      if (!mounted) return;
      final msg = AuthService.getReadableAuthError(e);
      if (!msg.contains('cancelled') && !msg.contains('ABORTED')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In: $msg'),
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
      final errorMsg = AuthService.getReadableAuthError(e);
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
                      hintText: 'name@example.com',
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
                                  'Password reset link sent to $email. Please check your inbox.'),
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
                                  Text(AuthService.getReadableAuthError(e)),
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

  @override
  Widget build(BuildContext context) {
    final isFieldBg = context.isDark ? context.themeSurfaceLow : Colors.white;

    return Scaffold(
      backgroundColor: context.themeBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: 32),
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
                  hintText: 'name@example.com',
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
                  hintStyle: TextStyle(
                    color: context.themeTextSecondary.withValues(alpha: 0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    size: 20,
                    color: context.themeTextSecondary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: context.themeTextSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
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
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: (_isGoogleLoading || _isEmailLoading) ? null : () => _handleGoogleSignIn(),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isFieldBg,
                    side: BorderSide(color: context.themeBorder, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isGoogleLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: AppColors.primary,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const _GoogleMark(),
                            const SizedBox(width: 12),
                            Text(
                              context.l10n.googleSignIn,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                                color: context.themeTextPrimary,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 36),
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        children: [
          _Dot(color: Color(0xFF4285F4), alignment: Alignment.topLeft),
          _Dot(color: Color(0xFFEA4335), alignment: Alignment.topRight),
          _Dot(color: Color(0xFFFBBC05), alignment: Alignment.bottomLeft),
          _Dot(color: Color(0xFF34A853), alignment: Alignment.bottomRight),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final Alignment alignment;
  const _Dot({required this.color, required this.alignment});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
