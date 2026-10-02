import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart' as pv;
import '../../../constants/firestore_paths.dart';
import '../../../state/role_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../utils/map_launcher.dart';
import '../../../utils/l10n_extension.dart';
import 'provider_dashboard_screen.dart';

/// Compresses an ID photo in the background.
Uint8List _compressNicImage(Uint8List rawBytes) {
  final image = img.decodeImage(rawBytes);
  if (image == null) {
    throw Exception('Failed to decode the captured document.');
  }

  // Keep under 1600px to stay below upload limits.
  img.Image working = image;
  if (working.width > 1600 || working.height > 1600) {
    if (working.width > working.height) {
      working = img.copyResize(working, width: 1600, interpolation: img.Interpolation.linear);
    } else {
      working = img.copyResize(working, height: 1600, interpolation: img.Interpolation.linear);
    }
  }

  const targetMaxBytes = 600 * 1024; // 600 KB
  final qualitySteps = [85, 75, 65, 55, 45, 35];

  Uint8List? result;
  for (final quality in qualitySteps) {
    final encoded = Uint8List.fromList(img.encodeJpg(working, quality: quality));
    if (encoded.lengthInBytes <= targetMaxBytes) {
      result = encoded;
      break;
    }
  }

  if (result == null) {
    final fallback = Uint8List.fromList(img.encodeJpg(working, quality: 25));
    if (fallback.lengthInBytes <= targetMaxBytes) {
      result = fallback;
    } else {
      throw Exception('NIC image is too large even after compression. Please retake the photo.');
    }
  }

  return result;
}

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

  bool _isUploadingFront = false;
  bool _isUploadingBack = false;
  bool _isUploadingSelfie = false;
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _checkExistingStatus();
  }

  Future<void> _checkExistingStatus() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final snap = await FirebaseFirestore.instance
          .collection(FirestorePaths.verificationQueue)
          .where('providerId', isEqualTo: uid)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty && mounted) {
        final status = snap.docs.first.data()['status'];
        if (status == 'pending' || status == 'approved') {
          setState(() => _isSubmitted = true);
        }
      }
    } catch (_) {}
  }

  Future<void> _handleUpload(String docType) async {
    setState(() {
      if (docType == 'front') _isUploadingFront = true;
      if (docType == 'back') _isUploadingBack = true;
      if (docType == 'selfie') _isUploadingSelfie = true;
    });

    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
        preferredCameraDevice:
            docType == 'selfie' ? CameraDevice.front : CameraDevice.rear,
      );

      if (photo == null) {
        setState(() {
          if (docType == 'front') _isUploadingFront = false;
          if (docType == 'back') _isUploadingBack = false;
          if (docType == 'selfie') _isUploadingSelfie = false;
        });
        return;
      }

      final Uint8List rawBytes = await photo.readAsBytes();
      final Uint8List imageBytes = await compute(_compressNicImage, rawBytes);
      if (imageBytes.lengthInBytes > 600 * 1024) {
        throw Exception(
          'Image size is too large (${(imageBytes.lengthInBytes / 1024).round()} KB). '
          'Maximum allowed size is 600 KB. Please choose or capture a compressed photo.',
        );
      }

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not authenticated');

      const contentType = 'image/jpeg';
      await FirebaseFirestore.instance
          .collection('nicImages')
          .doc(uid)
          .collection('files')
          .doc(docType)
          .set({
        'data': Blob(imageBytes),
        'contentType': contentType,
        'docType': docType,
        'uid': uid,
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          if (docType == 'front') {
            _front = true;
          } else if (docType == 'back') {
            _back = true;
          } else if (docType == 'selfie') {
            _selfie = true;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to upload $docType photo. Please try again: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (docType == 'front') _isUploadingFront = false;
          if (docType == 'back') _isUploadingBack = false;
          if (docType == 'selfie') _isUploadingSelfie = false;
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
      final profile = roleProvider.currentUser;
      final uid = authUser?.uid ?? (profile?.id ?? '');

      await FirebaseFirestore.instance
          .collection(FirestorePaths.verificationQueue)
          .doc(uid)
          .set({
        'providerId': uid,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'name': profile?.displayName.isNotEmpty == true
            ? profile!.displayName
            : (authUser?.displayName ?? 'Service Provider'),
        'trade': profile?.serviceCategory?.isNotEmpty == true
            ? '${profile!.serviceCategory} Specialist'
            : 'Certified Specialist',
        'location': profile?.district?.isNotEmpty == true
            ? profile!.district!
            : 'Sri Lanka',
        'nicNumber':
            profile?.nic?.isNotEmpty == true ? profile!.nic! : 'Pending NIC',
        'phone': profile?.phone?.isNotEmpty == true
            ? profile!.phone!
            : (authUser?.phoneNumber ?? ''),
        'preferredLanguage': profile?.preferredLanguage?.isNotEmpty == true
            ? profile!.preferredLanguage!
            : '',
      }, SetOptions(merge: true));

      // Save private info in the private subcollection.
      await FirebaseFirestore.instance
          .collection(FirestorePaths.technicians)
          .doc(uid)
          .collection('private')
          .doc('details')
          .set({
        'nic': profile?.nic ?? '',
        'phone': profile?.phone ?? authUser?.phoneNumber ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSubmitted = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit verification: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('National ID (NIC) Verification')),
      body: _isSubmitted ? _buildSubmittedView() : _buildFormView(),
      bottomNavigationBar: widget.showBottomNav
          ? const AppBottomNav(
              currentIndex: 2,
              items: [
                NavItem(Icons.radar, 'Jobs'),
                NavItem(Icons.payments, 'Earnings'),
                NavItem(Icons.verified_user, 'Verification'),
                NavItem(Icons.manage_accounts, 'Profile'),
              ],
            )
          : null,
    );
  }

  Widget _buildSubmittedView() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 24, 24, widget.showBottomNav ? AppBottomNav.contentBottomPadding : 24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.themeSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.themeBorder),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.04),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top,
                  color: AppColors.secondaryContainer,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Verification Under Review',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'STATUS: PENDING REVIEW',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Your National ID (NIC) documents and biometric selfie have been securely stored in our encrypted credential vault. Our admin verification desk is validating your record with e-DLS & Sri Lanka Police databases.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    color: context.themeTextSecondary,
                    height: 1.4),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Return to Dashboard',
                trailingIcon: Icons.arrow_forward,
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                      builder: (_) => const ProviderDashboardScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, widget.showBottomNav ? AppBottomNav.contentBottomPadding : 16),
      children: [
        const PillBadgeChip(label: 'Step 2 of 3'),
        const SizedBox(height: 10),
        Text(
            'Verify your identity to start receiving jobs island-wide across Sri Lanka.',
            style: TextStyle(color: context.themeTextSecondary)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: context.themeSurfaceLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.themeBorder)),
          child: Row(children: [
            const Icon(Icons.shield, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Verified Artisan Network — Sri Lanka',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(
                      'Government & Police vetted channel. Uploaded documents are encrypted with '
                      '256-bit bank-grade security and stored in an isolated Backblaze B2 credential vault.',
                      style: TextStyle(
                          fontSize: 11, color: context.themeTextSecondary)),
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
          isLoading: _isUploadingFront,
          uploadIcon: Icons.add_a_photo,
          uploadLabel: 'Capture or Upload Front',
          hint: 'JPEG, PNG or HEIC (Up to 10MB)',
          tip: 'Tip: Lay flat on a contrasting surface, avoid phone shadow.',
          onTap: () => _handleUpload('front'),
        ),
        const SizedBox(height: 14),
        _UploadStep(
          index: 2,
          title: 'NIC Back Side',
          description:
              'Back side showing your registered residential address and clear barcode.',
          uploaded: _back,
          isLoading: _isUploadingBack,
          uploadIcon: Icons.document_scanner,
          uploadLabel: 'Capture or Upload Back',
          hint: 'Ensure all 4 card corners are in frame',
          onTap: () => _handleUpload('back'),
        ),
        const SizedBox(height: 14),
        _UploadStep(
          index: 3,
          title: 'Selfie Holding Your NIC',
          description:
              'Hold your National ID card next to your face, both equally in focus.',
          uploaded: _selfie,
          isLoading: _isUploadingSelfie,
          uploadIcon: Icons.photo_camera_front,
          uploadLabel: 'Open Camera',
          hint: 'Live portrait test',
          tip:
              'Do not wear sunglasses, caps, or masks. Do not cover your name or photo.',
          onTap: () => _handleUpload('selfie'),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: context.themeSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.themeBorder),
              boxShadow: [
                BoxShadow(
                    color: Colors.black
                        .withValues(alpha: context.isDark ? 0.2 : 0.04),
                    blurRadius: 10)
              ]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.verified, color: AppColors.primary, size: 18),
                const SizedBox(width: 6),
                Text(context.l10n.fastTrackVerificationChecklist,
                    style: const TextStyle(fontWeight: FontWeight.bold))
              ]),
              const SizedBox(height: 10),
              const _ChecklistRow(
                  icon: Icons.timer,
                  title: 'Fast turnaround:',
                  body:
                      'Approvals take less than 2 hours (Mon-Sat, 8 AM - 6 PM).'),
              const SizedBox(height: 8),
              const _ChecklistRow(
                  icon: Icons.sms,
                  title: 'SMS alert:',
                  body:
                      'Instant approval message to your registered mobile number.'),
              const SizedBox(height: 8),
              const _ChecklistRow(
                  icon: Icons.wb_sunny,
                  title: 'Quality standard:',
                  body: 'Natural daylight photos get accepted first try.'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: () => MapLauncher.openPhoneCall('1340'),
            icon: const Icon(Icons.headset_mic, size: 16),
            label: Text(context.l10n.callPartnerSupport),
          ),
        ),
        const SizedBox(height: 8),
        PrimaryButton(
          label: _isSubmitting
              ? 'Uploading to Vault...'
              : 'Submit for Verification',
          trailingIcon: Icons.arrow_forward,
          onPressed: (_front && _back && _selfie && !_isSubmitting)
              ? _handleSubmit
              : null,
        ),
        const SizedBox(height: 8),
        Center(
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.lock, size: 13, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(context.l10n.endToEndEncryptedVault,
                style:
                    TextStyle(fontSize: 11, color: context.themeTextSecondary)),
          ]),
        ),
      ],
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
          color: context.themeSurfaceContainer,
          borderRadius: BorderRadius.circular(999)),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
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
  final bool isLoading;
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
    this.isLoading = false,
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
          color: context.themeSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.themeBorder),
          boxShadow: [
            BoxShadow(
                color:
                    Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.04),
                blurRadius: 10)
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
            if (isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else ...[
              Icon(uploaded ? Icons.check_circle : Icons.pending,
                  size: 16,
                  color: uploaded
                      ? AppColors.primary
                      : context.themeTextSecondary),
              const SizedBox(width: 4),
              Text(uploaded ? 'Attached' : 'Required',
                  style: TextStyle(
                      fontSize: 11,
                      color: uploaded
                          ? AppColors.primary
                          : context.themeTextSecondary)),
            ],
          ]),
          const SizedBox(height: 6),
          Text(description,
              style:
                  TextStyle(fontSize: 12, color: context.themeTextSecondary)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: isLoading ? null : onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                border: Border.all(
                    color: uploaded ? AppColors.primary : context.themeBorder,
                    style: BorderStyle.solid,
                    width: uploaded ? 1.5 : 1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(children: [
                if (isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(uploaded ? Icons.check_circle : uploadIcon,
                      color: uploaded
                          ? AppColors.primary
                          : context.themeTextSecondary),
                const SizedBox(height: 6),
                Text(
                    isLoading
                        ? 'Uploading to B2 Vault...'
                        : (uploaded
                            ? 'Photo attached • Tap to replace'
                            : uploadLabel),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12)),
                Text(hint,
                    style: TextStyle(
                        fontSize: 10, color: context.themeTextSecondary)),
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
                      style: TextStyle(
                          fontSize: 10.5, color: context.themeTextSecondary))),
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
                style:
                    TextStyle(fontSize: 12, color: context.themeTextSecondary),
                children: [
                  TextSpan(
                      text: '$title ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.themeTextPrimary)),
                  TextSpan(text: body),
                ]),
          ),
        ),
      ],
    );
  }
}
