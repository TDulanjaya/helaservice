import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import 'provider_dashboard_screen.dart';

class NicVerificationScreen extends StatefulWidget {
  final bool showBottomNav;

  const NicVerificationScreen({super.key, this.showBottomNav = true});

  @override
  State<NicVerificationScreen> createState() => _NicVerificationScreenState();
}

class _NicVerificationScreenState extends State<NicVerificationScreen> {
  bool _front = false;
  bool _back = false;
  bool _selfie = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('National ID (NIC) Verification')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const PillBadgeChip(label: 'Step 2 of 3'),
          const SizedBox(height: 10),
          const Text(
              'Verify your identity to start receiving jobs island-wide across Sri Lanka.',
              style: TextStyle(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              const Icon(Icons.shield, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Verified Artisan Network — Sri Lanka',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(
                        'Government & Police vetted channel. Uploaded documents are encrypted with '
                        '256-bit bank-grade security and stored in an isolated credential vault.',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          _UploadStep(
            index: 1,
            title: 'NIC Front Side',
            description:
                'Clear photo of the front side showing your portrait and NIC number.',
            uploaded: _front,
            uploadIcon: Icons.add_a_photo,
            uploadLabel: 'Capture or Upload Front',
            hint: 'JPEG, PNG or HEIC (Up to 10MB)',
            tip: 'Tip: Lay flat on a contrasting surface, avoid phone shadow.',
            onTap: () => setState(() => _front = true),
          ),
          const SizedBox(height: 14),
          _UploadStep(
            index: 2,
            title: 'NIC Back Side',
            description:
                'Back side showing your registered residential address and clear barcode.',
            uploaded: _back,
            uploadIcon: Icons.document_scanner,
            uploadLabel: 'Capture or Upload Back',
            hint: 'Ensure all 4 card corners are in frame',
            onTap: () => setState(() => _back = true),
          ),
          const SizedBox(height: 14),
          _UploadStep(
            index: 3,
            title: 'Selfie Holding Your NIC',
            description:
                'Hold your National ID card next to your face, both equally in focus.',
            uploaded: _selfie,
            uploadIcon: Icons.photo_camera_front,
            uploadLabel: 'Open Camera',
            hint: 'Live portrait test',
            tip:
                'Do not wear sunglasses, caps, or masks. Do not cover your name or photo.',
            onTap: () => setState(() => _selfie = true),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: AppColors.surfaceLowest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04), blurRadius: 10)
                ]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(children: [
                  Icon(Icons.verified, color: AppColors.primary, size: 18),
                  SizedBox(width: 6),
                  Text('Fast-Track Verification Checklist',
                      style: TextStyle(fontWeight: FontWeight.bold))
                ]),
                SizedBox(height: 10),
                _ChecklistRow(
                    icon: Icons.timer,
                    title: 'Fast turnaround:',
                    body:
                        'Approvals take less than 2 hours (Mon-Sat, 8 AM - 6 PM).'),
                SizedBox(height: 8),
                _ChecklistRow(
                    icon: Icons.sms,
                    title: 'SMS alert:',
                    body:
                        'Instant approval message to your registered mobile number.'),
                SizedBox(height: 8),
                _ChecklistRow(
                    icon: Icons.wb_sunny,
                    title: 'Quality standard:',
                    body: 'Natural daylight photos get accepted first try.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.headset_mic, size: 16),
              label: const Text('Call Partner Support 1340 (Toll Free)'),
            ),
          ),
          const SizedBox(height: 8),
          PrimaryButton(
            label: 'Submit for Verification',
            trailingIcon: Icons.arrow_forward,
            onPressed: (_front && _back && _selfie)
                ? () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (_) => const ProviderDashboardScreen()),
                    )
                : null,
          ),
          const SizedBox(height: 8),
          Center(
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.lock, size: 13, color: AppColors.outline),
                  SizedBox(width: 4),
                  Text('End-to-end encrypted • HelaService Sri Lanka ID Vault',
                      style: TextStyle(fontSize: 11, color: AppColors.outline)),
                ]),
          ),
        ],
      ),
      bottomNavigationBar: widget.showBottomNav
          ? AppBottomNav(
              currentIndex: 2,
              items: const [
                NavItem(Icons.radar, 'Jobs'),
                NavItem(Icons.payments, 'Earnings'),
                NavItem(Icons.verified_user, 'Verification'),
                NavItem(Icons.manage_accounts, 'Profile'),
              ],
            )
          : null,
    );
  }
}


class PillBadgeChip extends StatelessWidget {
  final String label;
  const PillBadgeChip({super.key, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: const [
        Icon(Icons.verified_user, size: 13, color: AppColors.primary),
        SizedBox(width: 4),
        Text('Step 2 of 3',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary)),
      ]),
    );
  }
}

class _UploadStep extends StatelessWidget {
  final int index;
  final String title;
  final String description;
  final bool uploaded;
  final IconData uploadIcon;
  final String uploadLabel;
  final String hint;
  final String? tip;
  final VoidCallback onTap;

  const _UploadStep({
    required this.index,
    required this.title,
    required this.description,
    required this.uploaded,
    required this.uploadIcon,
    required this.uploadLabel,
    required this.hint,
    this.tip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.surfaceLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.primary,
                child: Text('$index',
                    style: const TextStyle(fontSize: 11, color: Colors.white))),
            const SizedBox(width: 8),
            Expanded(
                child: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold))),
            Icon(uploaded ? Icons.check_circle : Icons.pending,
                size: 16,
                color: uploaded ? AppColors.primary : AppColors.outline),
            const SizedBox(width: 4),
            Text(uploaded ? 'Attached' : 'Required',
                style: TextStyle(
                    fontSize: 11,
                    color: uploaded ? AppColors.primary : AppColors.outline)),
          ]),
          const SizedBox(height: 6),
          Text(description,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                border: Border.all(
                    color:
                        uploaded ? AppColors.primary : AppColors.outlineVariant,
                    style: BorderStyle.solid,
                    width: uploaded ? 1.5 : 1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(children: [
                Icon(uploaded ? Icons.check_circle : uploadIcon,
                    color: uploaded ? AppColors.primary : AppColors.outline),
                const SizedBox(height: 6),
                Text(uploaded ? 'Photo attached • Tap to replace' : uploadLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12)),
                Text(hint,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.outline)),
              ]),
            ),
          ),
          if (tip != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.lightbulb,
                  size: 13, color: AppColors.secondaryContainer),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(tip!,
                      style: const TextStyle(
                          fontSize: 10.5, color: AppColors.onSurfaceVariant))),
            ]),
          ],
        ],
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _ChecklistRow(
      {required this.icon, required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
                style: const TextStyle(
                    fontSize: 12, color: AppColors.onSurfaceVariant),
                children: [
                  TextSpan(
                      text: '$title ',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface)),
                  TextSpan(text: body),
                ]),
          ),
        ),
      ],
    );
  }
}
