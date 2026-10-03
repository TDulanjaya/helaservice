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
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/icon_square_button.dart';
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

  // translate upload error message
  String _localizedUploadError(Object e, int? tooLargeKb) {
    final raw = e.toString();
    if (tooLargeKb != null && raw.contains('Image size is too large')) {
      return context.l10n.provNicImageTooLarge(tooLargeKb);
    }
    if (raw.contains('Failed to decode the captured document')) {
      return context.l10n.provNicDecodeFailed;
    }
    if (raw.contains('NIC image is too large even after compression')) {
      return context.l10n.provNicTooLargeAfterCompression;
    }
    if (raw.contains('User not authenticated')) {
      return context.l10n.provUserNotAuthenticated;
    }
    return raw;
  }

  Future<void> _handleUpload(String docType) async {
    int? tooLargeKb;
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
        tooLargeKb = (imageBytes.lengthInBytes / 1024).round();
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
                Text(context.l10n.failedToUploadPhoto(
                    _localizedUploadError(e, tooLargeKb))),
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
          SnackBar(content: Text(context.l10n.failedToSubmitVerification(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.nationalIdVerification,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: context.themeInk,
          ),
        ),
        leading: Navigator.canPop(context)
            ? Center(
                child: IconSquareButton.small(
                  icon: Icons.chevron_left_rounded,
                  onTap: () => Navigator.maybePop(context),
                ),
              )
            : null,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: context.themeAmberTint,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  context.l10n.step2Of3,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isSubmitted ? _buildSubmittedView() : _buildFormView(),
      bottomNavigationBar: widget.showBottomNav
          ? AppBottomNav(
              currentIndex: 2,
              items: [
                NavItem(Icons.radar, context.l10n.navJobs),
                NavItem(Icons.payments, context.l10n.navEarnings),
                NavItem(Icons.verified_user, context.l10n.navVerification),
                NavItem(Icons.manage_accounts, context.l10n.navProfile),
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
              Text(
                context.l10n.verificationUnderReview,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  context.l10n.statusPendingReviewCaps,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                context.l10n.nicUnderReviewDesc,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    color: context.themeTextSecondary,
                    height: 1.4),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: context.l10n.returnToDashboard,
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
      padding: EdgeInsets.fromLTRB(16, 16, 16, widget.showBottomNav ? AppBottomNav.contentBottomPadding : 24),
      children: [
        Text(
          context.l10n.nationalIdVerification,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: context.themeInk,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.verifyIdentitySubtitle,
          style: TextStyle(fontSize: 13, color: context.themeTextSecondary),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.isDark ? const Color(0xFF1E1A14) : const Color(0xFFFFF9E6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: context.isDark ? 0.4 : 0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.verifiedArtisanNetworkSriLanka,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: context.themeInk,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.nicSecureStorageDesc,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: context.themeTextSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _UploadStep(
          index: 1,
          title: context.l10n.nicFrontSide,
          description: context.l10n.nicFrontSideDesc,
          uploaded: _front,
          isLoading: _isUploadingFront,
          uploadIcon: Icons.add_a_photo_outlined,
          uploadLabel: context.l10n.captureOrUploadFront,
          hint: context.l10n.nicUploadFileLimitHint,
          tip: context.l10n.nicFrontTip,
          onTap: () => _handleUpload('front'),
        ),
        const SizedBox(height: 14),
        _UploadStep(
          index: 2,
          title: context.l10n.nicBackSide,
          description: context.l10n.nicBackSideDesc,
          uploaded: _back,
          isLoading: _isUploadingBack,
          uploadIcon: Icons.document_scanner_outlined,
          uploadLabel: context.l10n.captureOrUploadBack,
          hint: context.l10n.nicUploadFileLimitHint,
          tip: context.l10n.nicBackTip,
          onTap: () => _handleUpload('back'),
        ),
        const SizedBox(height: 14),
        _UploadStep(
          index: 3,
          title: context.l10n.selfieHoldingNic,
          description: context.l10n.selfieHoldingNicDesc,
          uploaded: _selfie,
          isLoading: _isUploadingSelfie,
          uploadIcon: Icons.photo_camera_front_outlined,
          uploadLabel: context.l10n.openCamera,
          hint: context.l10n.livePortraitTest,
          tip: context.l10n.selfieTip,
          onTap: () => _handleUpload('selfie'),
        ),
        const SizedBox(height: 18),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.fastTrackVerificationChecklist,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: context.themeInk,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ChecklistRow(
                icon: Icons.timer_outlined,
                title: context.l10n.fastTurnaroundTitle,
                body: context.l10n.fastTurnaroundBody,
              ),
              const SizedBox(height: 10),
              _ChecklistRow(
                icon: Icons.chat_bubble_outline_rounded,
                title: context.l10n.smsAlertTitle,
                body: context.l10n.smsAlertBody,
              ),
              const SizedBox(height: 10),
              _ChecklistRow(
                icon: Icons.wb_sunny_outlined,
                title: context.l10n.qualityStandardTitle,
                body: context.l10n.qualityStandardBody,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(
          label: _isSubmitting
              ? context.l10n.uploadingToVault
              : context.l10n.submitForVerification,
          trailingIcon: Icons.arrow_forward_rounded,
          onPressed: (_front && _back && _selfie && !_isSubmitting)
              ? _handleSubmit
              : null,
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton.icon(
            onPressed: () => MapLauncher.openPhoneCall('1340'),
            icon: const Icon(Icons.headset_mic_rounded, size: 16),
            label: Text(
              context.l10n.callPartnerSupport,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_rounded, size: 13, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                context.l10n.endToEndEncryptedVault,
                style: TextStyle(fontSize: 11, color: context.themeTextSecondary),
              ),
            ],
          ),
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
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_user_rounded, size: 13, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
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
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: context.themeInk,
                  ),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (uploaded)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_rounded, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        context.l10n.attachedStatus,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    context.l10n.requiredStatus,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(fontSize: 12, color: context.themeTextSecondary),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: isLoading ? null : onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: uploaded
                    ? (context.isDark ? const Color(0xFF14241B) : const Color(0xFFE8F5E9))
                    : context.themeSurfaceLow,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: uploaded
                      ? AppColors.primary.withValues(alpha: 0.5)
                      : context.themeBorder,
                  width: uploaded ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      uploaded ? Icons.check_circle_rounded : uploadIcon,
                      size: 28,
                      color: uploaded
                          ? AppColors.primary
                          : context.themeTextSecondary,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    isLoading
                        ? context.l10n.uploadingToVault
                        : (uploaded
                            ? context.l10n.photoAttachedTapReplace
                            : uploadLabel),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: uploaded ? AppColors.primary : context.themeInk,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.themeTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (tip != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 13, color: AppColors.secondaryContainer),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tip!,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.themeTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
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
  const _ChecklistRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 12, color: context.themeTextSecondary),
              children: [
                TextSpan(
                  text: '$title ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.themeTextPrimary,
                  ),
                ),
                TextSpan(text: body),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
