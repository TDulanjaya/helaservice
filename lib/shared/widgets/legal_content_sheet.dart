import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/l10n_extension.dart';

// in-app modal sheet displaying privacy policy and terms
class LegalContentSheet extends StatelessWidget {
  final int initialTabIndex;

  const LegalContentSheet({super.key, this.initialTabIndex = 0});

  static void show(BuildContext context, {int initialTabIndex = 0}) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => LegalContentSheet(initialTabIndex: initialTabIndex),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTabIndex,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: context.themeSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.themeBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            TabBar(
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: context.themeTextSecondary,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              tabs: [
                Tab(text: context.l10n.privacyPolicy),
                Tab(text: context.l10n.termsOfService),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: [
                  _buildPrivacyTab(context),
                  _buildTermsTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          context.l10n.privacyPolicy,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'HelaService values your privacy. We collect personal data such as contact numbers, service locations, and artisan identity verification documents strictly to facilitate direct home service connections in Sri Lanka.',
          style: TextStyle(
              fontSize: 13.5, height: 1.5, color: context.themeTextSecondary),
        ),
        const SizedBox(height: 16),
        _buildSectionHeader('1. Information We Collect'),
        Text(
          context.l10n.privacyDataCollectionPoints,
          style: TextStyle(
              fontSize: 13, height: 1.6, color: context.themeTextSecondary),
        ),
        const SizedBox(height: 16),
        _buildSectionHeader('2. Data Usage & Security'),
        Text(
          'Your data is encrypted in transit and securely stored. We never sell your personal information to third parties. Contact numbers are only shared between parties after a quote is accepted.',
          style: TextStyle(
              fontSize: 13, height: 1.5, color: context.themeTextSecondary),
        ),
        const SizedBox(height: 16),
        _buildSectionHeader('3. Account Deletion'),
        Text(
          'You may request complete account deletion at any time in app settings. All identification records and account data will be permanently removed.',
          style: TextStyle(
              fontSize: 13, height: 1.5, color: context.themeTextSecondary),
        ),
      ],
    );
  }

  Widget _buildTermsTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          context.l10n.termsOfService,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'By using HelaService, you agree to these Terms of Service. Please read them carefully.',
          style: TextStyle(
              fontSize: 13.5, height: 1.5, color: context.themeTextSecondary),
        ),
        const SizedBox(height: 16),
        _buildSectionHeader('1. Direct Cash Settlements'),
        Text(
          'HelaService connects customers with independent service artisans. All service payments are made directly in cash upon job completion and PIN verification.',
          style: TextStyle(
              fontSize: 13, height: 1.5, color: context.themeTextSecondary),
        ),
        const SizedBox(height: 16),
        _buildSectionHeader('2. Safety & Verification'),
        Text(
          'Artisans undergo identity verification. Customers and providers must treat each other with respect. Fraudulent behavior or harassment will lead to immediate account termination.',
          style: TextStyle(
              fontSize: 13, height: 1.5, color: context.themeTextSecondary),
        ),
        const SizedBox(height: 16),
        _buildSectionHeader('3. Disclaimers'),
        Text(
          'HelaService provides a coordination platform. While we enforce verification checks, services are contracted directly between customer and artisan.',
          style: TextStyle(
              fontSize: 13, height: 1.5, color: context.themeTextSecondary),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
      ),
    );
  }
}
