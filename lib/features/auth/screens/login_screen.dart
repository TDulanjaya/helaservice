import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../state/role_provider.dart';
import '../../../app_router.dart';
import '../../customer/screens/home_discovery_screen.dart';
import '../../provider/screens/provider_dashboard_screen.dart';
import '../../admin/admin_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AppRole _selectedRole = AppRole.customer;
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

  void _continue() {
    final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
    roleProvider.setRole(_selectedRole);

    Widget destination;
    switch (_selectedRole) {
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
  }

  void _goToRegister() {
    final route = _selectedRole == AppRole.provider
        ? AppRoutes.providerRegister
        : AppRoutes.customerRegister;
    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _selectedRole == AppRole.admin;

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
                    child: const Icon(Icons.bolt, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'HelaService',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'Welcome back',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Log in to continue as a customer, provider or admin',
                style: TextStyle(fontSize: 13.5, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEDE4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _RolePill(
                      label: 'Customer',
                      selected: _selectedRole == AppRole.customer,
                      onTap: () => setState(() => _selectedRole = AppRole.customer),
                    ),
                    _RolePill(
                      label: 'Provider',
                      selected: _selectedRole == AppRole.provider,
                      onTap: () => setState(() => _selectedRole = AppRole.provider),
                    ),
                    _RolePill(
                      label: 'Admin',
                      selected: _selectedRole == AppRole.admin,
                      onTap: () => setState(() => _selectedRole = AppRole.admin),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (!isAdmin) ...[
                OutlinedButton(
                  onPressed: _continue,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: AppColors.outline.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      _GoogleMark(),
                      SizedBox(width: 10),
                      Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.outline.withOpacity(0.3))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('or', style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
                    ),
                    Expanded(child: Divider(color: AppColors.outline.withOpacity(0.3))),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(14),
                      child: Text('🇱🇰 +94', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    hintText: '77 123 4567',
                    filled: true,
                    fillColor: AppColors.surfaceLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.outline.withOpacity(0.3)),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                PrimaryButton(label: 'Get Started', onPressed: _continue),
                const SizedBox(height: 18),
                Center(
                  child: TextButton(
                    onPressed: _goToRegister,
                    child: Text.rich(
                      TextSpan(
                        text: 'New here? ',
                        style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 13),
                        children: [
                          TextSpan(
                            text: _selectedRole == AppRole.provider
                                ? 'Register as a service provider'
                                : 'Create a customer account',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Work email',
                    filled: true,
                    fillColor: AppColors.surfaceLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.outline.withOpacity(0.3)),
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
                      borderSide: BorderSide(color: AppColors.outline.withOpacity(0.3)),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                PrimaryButton(label: 'Log In to Admin Console', onPressed: _continue),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    'Lost access? Contact your operations lead for a reset link.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
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

class _RolePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RolePill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: selected
                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? AppColors.onSurface : AppColors.onSurfaceVariant,
            ),
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
      width: 18,
      height: 18,
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
      child: Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    );
  }
}
