import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/icon_square_button.dart';
import '../../../shared/widgets/google_sign_in_button.dart';
import '../../../state/role_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/otp_service.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/auth_error_l10n.dart';
import '../../../models/user_profile.dart';
import 'complete_profile_screen.dart';
import 'role_choice_screen.dart';
import 'email_otp_screen.dart';
import '../../customer/screens/home_discovery_screen.dart';
import '../../provider/screens/provider_dashboard_screen.dart';
import '../../provider/screens/provider_pending_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (fullName.isEmpty || fullName.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pleaseEnterFullName),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.enterEmailError),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.passwordLengthError),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.passwordMismatchError),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final currentLocale = mounted ? context.l10n.localeName : 'en';
    setState(() => _isLoading = true);

    try {
      await AuthService().signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: fullName,
      );

      await OtpService().sendEmailOtp(email, purpose: 'signup', language: currentLocale);

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EmailOtpScreen(
            email: email,
            purpose: 'signup',
          ),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RegisterScreen EmailOtp Error] $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('Exception:')
                  ? e.toString().replaceFirst('Exception: ', '')
                  : authErrorMessage(context, e),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _routeAfterOtp(UserProfile user) {
    if (user.role == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => RoleChoiceScreen(user: user),
        ),
        (route) => false,
      );
    } else if (!user.isProfileComplete) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => CompleteProfileScreen(initialProfile: user),
        ),
        (route) => false,
      );
    } else if (user.role == AppRole.provider) {
      final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
      if (roleProvider.isApprovedProvider || user.isVerified) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const ProviderDashboardScreen(),
          ),
          (route) => false,
        );
      } else {
        final isExistingCustomer = user.initialRole == 'customer';
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => ProviderPendingScreen(
              isExistingCustomer: isExistingCustomer,
            ),
          ),
          (route) => false,
        );
      }
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const HomeDiscoveryScreen(),
        ),
        (route) => false,
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final currentLocale = mounted ? context.l10n.localeName : 'en';
    setState(() => _isGoogleLoading = true);

    try {
      // register can create account
      final profile = await AuthService().signInWithGoogle(allowCreate: true);

      if (!mounted) return;

      final fbUser = AuthService().currentFirebaseUser;
      bool isVerified = profile.emailOtpVerified;
      if (fbUser != null && !isVerified) {
        final tokenRes = await fbUser.getIdTokenResult();
        isVerified = tokenRes.claims?['emailOtp'] == true;
      }

      if (!isVerified) {
        await OtpService().sendEmailOtp(profile.email, purpose: 'signup', language: currentLocale);

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => EmailOtpScreen(
              email: profile.email,
              purpose: 'signup',
            ),
          ),
          (route) => false,
        );
        return;
      }

      if (!mounted) return;
      final roleProvider =
          pv.Provider.of<RoleProvider>(context, listen: false);
      roleProvider.setUser(profile);
      _routeAfterOtp(profile);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[RegisterScreen GoogleSignIn Error] $e');
      }
      if (mounted) {
        final rawErr = e.toString();
        if (!rawErr.contains('cancelled') &&
            !rawErr.contains('ABORTED') &&
            !rawErr.contains('12501')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authErrorMessage(context, e)),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
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
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: context.themeTextPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterFormContent(BuildContext context, Color isFieldBg, {required bool isWideLayout}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconSquareButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          context.l10n.createAccount,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: context.themeTextPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.createAccountSubtitle,
          style: TextStyle(
            fontSize: 13.5,
            color: context.themeTextSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          context.l10n.fullName,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.themeTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _fullNameController,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(color: context.themeTextPrimary, fontSize: 14.5),
          decoration: InputDecoration(
            hintText: context.l10n.hintFullName,
            hintStyle: TextStyle(
              color: context.themeTextSecondary.withValues(alpha: 0.6),
            ),
            prefixIcon: Icon(
              Icons.person_outline_rounded,
              size: 20,
              color: context.themeTextSecondary,
            ),
            filled: true,
            fillColor: isFieldBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: context.themeBorder, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: context.themeBorder, width: 1.5),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide:
                  BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          context.l10n.emailAddress,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.themeTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: context.themeBorder, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: context.themeBorder, width: 1.5),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide:
                  BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          context.l10n.password,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.themeTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: TextStyle(color: context.themeTextPrimary, fontSize: 14.5),
          decoration: InputDecoration(
            hintText: context.l10n.atLeast6Characters,
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: context.themeBorder, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: context.themeBorder, width: 1.5),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide:
                  BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          context.l10n.confirmPassword,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.themeTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          style: TextStyle(color: context.themeTextPrimary, fontSize: 14.5),
          decoration: InputDecoration(
            hintText: context.l10n.reEnterPassword,
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
                _obscureConfirmPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: context.themeTextSecondary,
              ),
              onPressed: () => setState(() =>
                  _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            filled: true,
            fillColor: isFieldBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: context.themeBorder, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: context.themeBorder, width: 1.5),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide:
                  BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: context.l10n.continueText,
          loading: _isLoading,
          onPressed:
              (_isLoading || _isGoogleLoading) ? null : _handleRegister,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
                child: Divider(color: context.themeBorder, thickness: 1)),
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
            Expanded(
                child: Divider(color: context.themeBorder, thickness: 1)),
          ],
        ),
        GoogleSignInButton(
          isLoading: _isGoogleLoading,
          onPressed: (_isGoogleLoading || _isLoading)
              ? null
              : () => _handleGoogleSignIn(),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.l10n.alreadyHaveAccount,
              style: TextStyle(
                fontSize: 13.5,
                color: context.themeTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Text(
                context.l10n.logIn,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
              constraints: const BoxConstraints(maxWidth: 980),
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
                              context.l10n.registerBannerSubtitle,
                              style: TextStyle(
                                fontSize: 14.5,
                                color: context.themeTextSecondary,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 36),
                            _buildFeaturePill(context, Icons.speed_rounded, 'Direct quote requests in minutes'),
                            const SizedBox(height: 14),
                            _buildFeaturePill(context, Icons.security_rounded, 'Bank-grade encrypted communications'),
                            const SizedBox(height: 14),
                            _buildFeaturePill(context, Icons.stars_rounded, 'Community rated professionals'),
                          ],
                        ),
                      ),
                    ),
                    // right form
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: _buildRegisterFormContent(context, isFieldBg, isWideLayout: true),
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
              constraints: const BoxConstraints(maxWidth: 520),
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
                child: _buildRegisterFormContent(context, isFieldBg, isWideLayout: false),
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
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: _buildRegisterFormContent(context, isFieldBg, isWideLayout: false),
        ),
      ),
    );
  }
}
