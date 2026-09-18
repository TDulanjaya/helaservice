import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../customer/screens/home_discovery_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeDiscoveryScreen()),
    );
  }

  Future<void> _submitPhone() async {
    final digits = _phoneController.text.replaceAll(' ', '');
    if (digits.length < 9) return;
    setState(() => _sending = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _sending = false);
    _goHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _HeroCard(),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: _goHome,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: AppColors.surfaceLowest,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    _GoogleMark(),
                    SizedBox(width: 10),
                    Text('Continue with Google',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('or sign in with phone number',
                        style: TextStyle(
                            color: AppColors.outline,
                            fontSize: 11,
                            letterSpacing: 0.5)),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Mobile Number',
                    style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                    color: AppColors.surfaceLowest,
                    borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Text('🇱🇰 +94',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Container(
                        width: 1, height: 20, color: AppColors.outlineVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 11,
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          hintText: '77 123 4567',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text("We'll send a 6-digit verification code via SMS.",
                    style: TextStyle(color: AppColors.outline, fontSize: 12)),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Get Started',
                trailingIcon: Icons.arrow_forward,
                loading: _sending,
                onPressed: _submitPhone,
              ),
              const SizedBox(height: 20),
              _HelpdeskCard(),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  style:
                      const TextStyle(color: AppColors.outline, fontSize: 12),
                  children: [
                    const TextSpan(text: 'By continuing, you agree to our '),
                    TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(color: AppColors.primary)),
                    const TextSpan(text: ' and '),
                    TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(color: AppColors.primary)),
                    const TextSpan(text: '.'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.lock, size: 14, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text(
                      '256-bit Secure Citizen Protocol • Dialog & Mobitel ready',
                      style: TextStyle(color: AppColors.outline, fontSize: 11)),
                ],
              ),
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
    return SizedBox(
      width: 18,
      height: 18,
      child: Stack(children: const [
        Positioned(top: 0, left: 0, child: _Dot(Color(0xFF4285F4))),
        Positioned(top: 0, right: 0, child: _Dot(Color(0xFFEA4335))),
        Positioned(bottom: 0, left: 0, child: _Dot(Color(0xFFFBBC05))),
        Positioned(bottom: 0, right: 0, child: _Dot(Color(0xFF34A853))),
      ]),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot(this.color);
  @override
  Widget build(BuildContext context) => Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.surfaceLow,
            AppColors.surfaceContainer
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.surfaceLowest,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)
              ],
            ),
            child:
                const Icon(Icons.handyman, color: AppColors.primary, size: 34),
          ),
          const SizedBox(height: 12),
          const PillBadgeRow(),
          const SizedBox(height: 12),
          const Text(
            'Fast, trusted home services in Sri Lanka',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.3),
          ),
          const SizedBox(height: 6),
          const Text(
            'Verified technicians & master artisans right at your doorstep in minutes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: const [
              _FeatureChip(icon: Icons.verified, label: 'Police Vetted'),
              _FeatureChip(icon: Icons.bolt, label: 'Instant Match'),
              _FeatureChip(icon: Icons.shield, label: 'Job Warranty'),
            ],
          ),
        ],
      ),
    );
  }
}

class PillBadgeRow extends StatelessWidget {
  const PillBadgeRow({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(999)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Island-wide verified network',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          SizedBox(width: 4),
          Text('🇱🇰'),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _HelpdeskCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: AppColors.surfaceLowest,
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.support_agent,
                color: AppColors.secondaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('24/7 Islandwide Helpdesk',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text.rich(TextSpan(
                  style: TextStyle(
                      color: AppColors.onSurfaceVariant, fontSize: 12),
                  children: [
                    TextSpan(text: 'Urgent breakdown? Call '),
                    TextSpan(
                        text: '1340',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600)),
                  ],
                )),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(999)),
            child: const Text('HOTLINE',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
