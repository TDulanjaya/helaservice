import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../state/role_provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/otp_service.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/auth_error_l10n.dart';
import 'home_discovery_screen.dart';
import '../../auth/screens/email_otp_screen.dart';

class CustomerRegisterScreen extends StatefulWidget {
  const CustomerRegisterScreen({super.key});

  @override
  State<CustomerRegisterScreen> createState() => _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState extends State<CustomerRegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _agreed = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.enterFullName),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.enterValidEmail),
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

    setState(() => _isLoading = true);

    try {
      await OtpService().sendEmailOtp(email);

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EmailOtpScreen(
            email: email,
            onVerified: () async {
              final phone = _phoneController.text.trim().isNotEmpty
                  ? AuthService.formatSriLankanPhoneNumber(_phoneController.text.trim())
                  : null;

              final profile = await AuthService().signUpWithEmailAndPassword(
                email: email,
                password: password,
                displayName: name,
                role: AppRole.customer,
                phone: phone,
              );

              if (!mounted) return;

              final roleProvider =
                  pv.Provider.of<RoleProvider>(context, listen: false);
              roleProvider.setUser(profile);

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeDiscoveryScreen()),
                (route) => false,
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFieldBg = context.isDark ? context.themeSurfaceLow : Colors.white;

    return Scaffold(
      backgroundColor: context.themeBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isFieldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.themeBorder, width: 1.5),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: context.themeTextPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
        title: Text(
          context.l10n.createCustomerAccount,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.themeTextPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              Text(
                context.l10n.customerRegisterSubtitle,
                style: TextStyle(
                  fontSize: 13.5,
                  color: context.themeTextSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              _Field(
                label: context.l10n.fullNameLabel,
                controller: _nameController,
                hint: context.l10n.hintFullName,
                prefixIcon: Icons.person_outline,
                isDarkField: context.isDark,
              ),
              const SizedBox(height: 16),
              _Field(
                label: context.l10n.emailAddressLabel,
                controller: _emailController,
                hint: context.l10n.hintEmail,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                isDarkField: context.isDark,
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.passwordLabel,
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
                      hintText: context.l10n.atLeast6Chars,
                      hintStyle: TextStyle(
                        color: context.themeTextSecondary.withValues(alpha: 0.6),
                      ),
                      prefixIcon: Icon(Icons.lock_outline, size: 20, color: context.themeTextSecondary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                          color: context.themeTextSecondary,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
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
                ],
              ),
              const SizedBox(height: 16),
              _Field(
                label: context.l10n.customerPhoneLabel,
                controller: _phoneController,
                hint: '77 123 4567',
                keyboardType: TextInputType.phone,
                prefixText: '+94 ',
                prefixIcon: Icons.phone_outlined,
                isDarkField: context.isDark,
              ),
              const SizedBox(height: 20),
              CheckboxListTile(
                value: _agreed,
                onChanged: (v) => setState(() => _agreed = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                title: Text(
                  context.l10n.agreeTerms,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.themeTextSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: context.l10n.createAccount,
                loading: _isLoading,
                onPressed: _agreed && !_isLoading ? _createAccount : null,
              ),
              const SizedBox(height: 20),
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
                      context.l10n.signIn,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final String? prefixText;
  final IconData? prefixIcon;
  final bool isDarkField;

  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.prefixText,
    this.prefixIcon,
    required this.isDarkField,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDarkField ? context.themeSurfaceLow : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.themeTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: context.themeTextPrimary, fontSize: 14.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: context.themeTextSecondary.withValues(alpha: 0.6),
            ),
            prefixText: prefixText,
            prefixStyle: TextStyle(
              fontWeight: FontWeight.w700,
              color: context.themeTextPrimary,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20, color: context.themeTextSecondary)
                : null,
            filled: true,
            fillColor: bg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: context.themeBorder,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: context.themeBorder,
                width: 1.5,
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
