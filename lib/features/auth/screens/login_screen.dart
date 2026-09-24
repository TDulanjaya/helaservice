import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../state/role_provider.dart';
import '../../../services/auth_service.dart';
import '../../../app_router.dart';
import 'complete_profile_screen.dart';
import 'otp_verification_screen.dart';
import '../../customer/screens/home_discovery_screen.dart';
import '../../provider/screens/provider_dashboard_screen.dart';
import '../../admin/admin_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isAdminMode = false;
  bool _isGoogleLoading = false;
  bool _isPhoneLoading = false;

  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn({String? simulateEmail}) async {
    setState(() => _isGoogleLoading = true);

    try {
      final authService = AuthService();
      final user = await authService.signInWithGoogle(testEmail: simulateEmail);

      if (!mounted) return;

      final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
      roleProvider.setUser(user);

      if (user.isProfileComplete && user.role != null) {
        Widget destination;
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

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => destination),
          (route) => false,
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CompleteProfileScreen(initialProfile: user),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (!msg.contains('cancelled') && !msg.contains('ABORTED')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: $msg'),
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

  void _showGoogleAccountSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const _GoogleMark(),
                  const SizedBox(width: 12),
                  const Text(
                    'Choose Google Account',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Test how the role-agnostic authentication behaves with different account states:',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              _AccountTile(
                title: 'Kasun Fernando (New Account)',
                subtitle: 'First time user -> prompts role selection form',
                badgeText: 'New User Flow',
                badgeColor: AppColors.primary,
                avatarInitials: 'KF',
                onTap: () {
                  Navigator.pop(ctx);
                  _handleGoogleSignIn(
                      simulateEmail: 'kasun.fernando95@gmail.com');
                },
              ),
              const SizedBox(height: 10),
              _AccountTile(
                title: 'Sanduni Perera (Existing Customer)',
                subtitle: 'Directly opens Customer Home Discovery',
                badgeText: 'Saved Customer',
                badgeColor: const Color(0xFF008378),
                avatarInitials: 'SP',
                onTap: () {
                  Navigator.pop(ctx);
                  _handleGoogleSignIn(
                      simulateEmail: 'customer.sample@gmail.com');
                },
              ),
              const SizedBox(height: 10),
              _AccountTile(
                title: 'Sunil Bandara (Existing Electrician)',
                subtitle: 'Directly opens Provider Job Dashboard',
                badgeText: 'Saved Provider',
                badgeColor: const Color(0xFFFEA619),
                avatarInitials: 'SB',
                onTap: () {
                  Navigator.pop(ctx);
                  _handleGoogleSignIn(
                      simulateEmail: 'provider.sample@gmail.com');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _continueWithPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your mobile phone number'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isPhoneLoading = true);

    final authService = AuthService();
    final cleanPhone = AuthService.formatSriLankanPhoneNumber(phone);

    await authService.sendPhoneOtp(
      phoneNumber: cleanPhone,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() => _isPhoneLoading = false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              phoneNumber: cleanPhone,
              initialVerificationId: verificationId,
            ),
          ),
        );
      },
      onError: (errorMsg) {
        if (!mounted) return;
        setState(() => _isPhoneLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.error,
          ),
        );
      },
      onAutoVerified: (user) {
        if (!mounted) return;
        setState(() => _isPhoneLoading = false);
        final roleProvider =
            pv.Provider.of<RoleProvider>(context, listen: false);
        roleProvider.setUser(user);

        if (user.isProfileComplete && user.role != null) {
          Widget destination;
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

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => destination),
            (route) => false,
          );
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CompleteProfileScreen(initialProfile: user),
            ),
          );
        }
      },
    );
  }

  void _loginAdmin() {
    final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
    roleProvider.setRole(AppRole.admin);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AdminShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        const Icon(Icons.bolt, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'HelaService',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              if (!_isAdminMode) ...[
                const Text(
                  'Welcome to HelaService',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Find verified home service professionals or manage your service jobs across Sri Lanka.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 28),
                OutlinedButton(
                  onPressed:
                      _isGoogleLoading ? null : () => _handleGoogleSignIn(),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                        color: AppColors.outline.withOpacity(0.35), width: 1.2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 1,
                    shadowColor: Colors.black.withOpacity(0.04),
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
                          children: const [
                            _GoogleMark(),
                            SizedBox(width: 12),
                            Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _showGoogleAccountSelector,
                    icon: const Icon(Icons.swap_horiz, size: 16),
                    label: const Text(
                      'Test Google Personas (New vs Returning)',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child:
                            Divider(color: AppColors.outline.withOpacity(0.3))),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'or continue with phone',
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                        child:
                            Divider(color: AppColors.outline.withOpacity(0.3))),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Text('🇱🇰 +94',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    hintText: '77 123 4567',
                    filled: true,
                    fillColor: AppColors.surfaceLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          BorderSide(color: AppColors.outline.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                          color: AppColors.outline.withOpacity(0.25)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                PrimaryButton(
                  label: 'Get Started with Phone',
                  loading: _isPhoneLoading,
                  onPressed: _continueWithPhone,
                ),

                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Want to register with a dedicated form?',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pushNamed(
                                context, AppRoutes.customerRegister),
                            child: const Text(
                              'Register as Customer',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                          const Text('•',
                              style:
                                  TextStyle(color: AppColors.onSurfaceVariant)),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(
                                context, AppRoutes.providerRegister),
                            child: const Text(
                              'Register as Provider',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() => _isAdminMode = true),
                    icon: const Icon(Icons.admin_panel_settings_outlined,
                        size: 18),
                    label: const Text(
                      'Admin Console Access',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.outline,
                    ),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => setState(() => _isAdminMode = false),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Admin Console Login',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Access operations dashboard, verification pipeline, and platform metrics.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Work email',
                    hintText: 'admin@helaservice.lk',
                    filled: true,
                    fillColor: AppColors.surfaceLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          BorderSide(color: AppColors.outline.withOpacity(0.3)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    filled: true,
                    fillColor: AppColors.surfaceLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          BorderSide(color: AppColors.outline.withOpacity(0.3)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Log In to Admin Console',
                  onPressed: _loginAdmin,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _isAdminMode = false),
                    child: const Text('Back to Customer & Provider Sign In'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;
  final String avatarInitials;
  final VoidCallback onTap;

  const _AccountTile({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    required this.avatarInitials,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.outline.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: badgeColor.withOpacity(0.15),
              child: Text(
                avatarInitials,
                style: TextStyle(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.outline),
          ],
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
