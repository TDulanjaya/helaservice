import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart' as pv;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/firestore_paths.dart';
import '../../../state/role_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/icon_square_button.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/permission_utils.dart';
import '../../../services/storage_service.dart';
import '../../../services/auth_service.dart';
import '../../../utils/nic_validator.dart';
import '../../../utils/provider_routing_helper.dart';
import '../../customer/screens/home_discovery_screen.dart';
import '../../provider/screens/provider_dashboard_screen.dart';
import '../../provider/screens/provider_pending_screen.dart';

// compress identity photo
Uint8List _compressNicImage(Uint8List rawBytes) {
  final image = img.decodeImage(rawBytes);
  if (image == null) {
    throw Exception('Failed to decode the captured document.');
  }

  // resize under 1600 pixels
  img.Image working = image;
  if (working.width > 1600 || working.height > 1600) {
    if (working.width > working.height) {
      working = img.copyResize(working,
          width: 1600, interpolation: img.Interpolation.linear);
    } else {
      working = img.copyResize(working,
          height: 1600, interpolation: img.Interpolation.linear);
    }
  }

  const targetMaxBytes = 600 * 1024;
  final qualitySteps = [85, 75, 65, 55, 45, 35];

  Uint8List? result;
  for (final quality in qualitySteps) {
    final encoded =
        Uint8List.fromList(img.encodeJpg(working, quality: quality));
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
      throw Exception(
          'NIC image is too large even after compression. Please retake the photo.');
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
  String? _frontKey;
  String? _backKey;
  String? _selfieKey;

  bool _isUploadingFront = false;
  bool _isUploadingBack = false;
  bool _isUploadingSelfie = false;
  bool _isSubmitting = false;
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    _checkExistingStatus();
    _restoreUploadedKeys().then((_) => _recoverLostPhoto());
  }

  static const String _pendingSlotKey = 'nic_pending_photo_slot';

  String? get _uploadsPrefKey {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid == null ? null : 'nic_uploaded_keys_$uid';
  }

  // show uploaded photos
  Future<void> _restoreUploadedKeys() async {
    final prefKey = _uploadsPrefKey;
    if (prefKey == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(prefKey);
      if (raw == null || !mounted) return;
      final saved = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      setState(() {
        _frontKey ??= saved['front'] as String?;
        _backKey ??= saved['back'] as String?;
        _selfieKey ??= saved['selfie'] as String?;
        _front = _frontKey != null;
        _back = _backKey != null;
        _selfie = _selfieKey != null;
      });
    } catch (e) {
      debugPrint('[NicVerificationScreen] restore keys failed: $e');
    }
  }

  Future<void> _saveUploadedKeys() async {
    final prefKey = _uploadsPrefKey;
    if (prefKey == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          prefKey,
          jsonEncode({
            if (_frontKey != null) 'front': _frontKey,
            if (_backKey != null) 'back': _backKey,
            if (_selfieKey != null) 'selfie': _selfieKey,
          }));
    } catch (_) {}
  }

  Future<void> _clearUploadedKeys() async {
    final prefKey = _uploadsPrefKey;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefKey != null) await prefs.remove(prefKey);
      await prefs.remove(_pendingSlotKey);
    } catch (_) {}
  }

  Future<void> _setPendingSlot(String? docType) async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (docType == null) {
        await prefs.remove(_pendingSlotKey);
      } else {
        await prefs.setString(_pendingSlotKey, docType);
      }
    } catch (_) {}
  }

  // upload recovered photo
  Future<void> _recoverLostPhoto() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final slot = prefs.getString(_pendingSlotKey);
      final lost = await ImagePicker().retrieveLostData();
      await prefs.remove(_pendingSlotKey);
      if (lost.isEmpty || slot == null || !mounted) return;
      final files = lost.files;
      final file = lost.file ??
          ((files != null && files.isNotEmpty) ? files.first : null);
      if (file == null) return;
      await _handleUpload(slot, recovered: file);
    } catch (e) {
      debugPrint('[NicVerificationScreen] recover photo failed: $e');
    }
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

  Future<void> _handleUpload(String docType, {XFile? recovered}) async {
    if (recovered == null) {
      final allowed = await PermissionUtils.requestCameraWithRationale(
        context,
        title: docType == 'selfie'
            ? context.l10n.takeProfilePhoto
            : context.l10n.nationalIdVerification,
        description: docType == 'selfie'
            ? context.l10n.uploadClearFacePhoto
            : context.l10n.permissionCameraDesc,
      );
      if (!allowed) return;
    }

    setState(() {
      if (docType == 'front') _isUploadingFront = true;
      if (docType == 'back') _isUploadingBack = true;
      if (docType == 'selfie') _isUploadingSelfie = true;
    });

    try {
      final picker = ImagePicker();
      if (recovered == null) await _setPendingSlot(docType);
      final XFile? photo = recovered ??
          await picker.pickImage(
            source: ImageSource.camera,
            maxWidth: 1600,
            maxHeight: 1600,
            imageQuality: 85,
            preferredCameraDevice:
                docType == 'selfie' ? CameraDevice.front : CameraDevice.rear,
          );
      if (recovered == null) await _setPendingSlot(null);

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

      final key = await StorageService.instance.uploadBytes(
        imageBytes,
        filename: '$docType.jpg',
        purpose: 'nic',
      );

      if (mounted) {
        setState(() {
          if (docType == 'front') {
            _front = true;
            _frontKey = key;
          } else if (docType == 'back') {
            _back = true;
            _backKey = key;
          } else if (docType == 'selfie') {
            _selfie = true;
            _selfieKey = key;
          }
        });
        await _saveUploadedKeys();
      }
    } catch (e) {
      debugPrint('[NicVerificationScreen] Upload failed for $docType: $e');
      if (mounted) {
        final friendlyMsg = NicValidator.mapProfileError(e, context.l10n);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyMsg),
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

      var cleanNic = NicValidator.cleanNic(profile?.nic);
      if (cleanNic.isEmpty && uid.isNotEmpty) {
        try {
          final kycSnap = await FirebaseFirestore.instance
              .collection(FirestorePaths.technicians)
              .doc(uid)
              .collection('private')
              .doc('kyc')
              .get();
          if (kycSnap.exists) {
            final kycData = kycSnap.data();
            final fallbackNic = (kycData?['nic'] as String?) ??
                (kycData?['nicNumber'] as String?);
            cleanNic = NicValidator.cleanNic(fallbackNic);
          }
        } on FirebaseException catch (e) {
          debugPrint('[NicVerificationScreen] error loading kyc nic: ${e.code}');
        } catch (_) {
          debugPrint('[NicVerificationScreen] unexpected error loading kyc nic');
        }
      }

      await FirebaseFirestore.instance
          .collection(FirestorePaths.verificationQueue)
          .doc(uid)
          .set({
        'providerId': uid,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        if (_frontKey != null) 'nicFrontKey': _frontKey,
        if (_backKey != null) 'nicBackKey': _backKey,
        'name': profile?.displayName.isNotEmpty == true
            ? profile!.displayName
            : (authUser?.displayName ?? ''),
        'trade': profile?.serviceCategory?.isNotEmpty == true
            ? profile!.serviceCategory!
            : '',
        'location':
            profile?.district?.isNotEmpty == true ? profile!.district! : '',
        'nicNumber': cleanNic,
        if (cleanNic.isNotEmpty) 'nic': cleanNic,
        'phone': profile?.phone?.isNotEmpty == true
            ? profile!.phone!
            : (authUser?.phoneNumber ?? ''),
        'preferredLanguage': profile?.preferredLanguage?.isNotEmpty == true
            ? profile!.preferredLanguage!
            : '',
      }, SetOptions(merge: true));

      // save private kyc details
      await FirebaseFirestore.instance
          .collection(FirestorePaths.technicians)
          .doc(uid)
          .collection('private')
          .doc('kyc')
          .set({
        if (cleanNic.isNotEmpty) 'nic': cleanNic,
        if (_frontKey != null) 'nicFrontKey': _frontKey,
        if (_backKey != null) 'nicBackKey': _backKey,
        if (_selfieKey != null) 'selfieKey': _selfieKey,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // save private contact info
      await FirebaseFirestore.instance
          .collection(FirestorePaths.technicians)
          .doc(uid)
          .collection('private')
          .doc('details')
          .set({
        if (cleanNic.isNotEmpty) 'nic': cleanNic,
        'phone': profile?.phone ?? authUser?.phoneNumber ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // request server nic hash
      await AuthService().requestNicHash();
      await _clearUploadedKeys();

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSubmitted = true;
        });
      }
    } catch (e) {
      debugPrint('[NicVerificationScreen] Submit failed: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        final friendlyMsg = NicValidator.mapProfileError(e, context.l10n);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyMsg),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // pick screen by role and approval
  void _navigateBackOrDashboard() {
    final nav = Navigator.of(context);
    final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
    final user = roleProvider.currentUser;
    final isApproved =
        roleProvider.isApprovedProvider || (user?.isVerified ?? false);

    if (user != null && isLockedNewProvider(user, isApproved)) {
      if (kDebugMode) {
        debugPrint('[navdbg] -> pending from nic_verification_screen.dart');
      }
      nav.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              const ProviderPendingScreen(isExistingCustomer: false),
        ),
        (route) => false,
      );
      return;
    }

    if (isApproved) {
      if (kDebugMode) {
        debugPrint('[navdbg] -> dashboard from nic_verification_screen.dart');
      }
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ProviderDashboardScreen()),
        (route) => false,
      );
      return;
    }

    // return to customer home
    if (kDebugMode) {
      debugPrint('[navdbg] -> customer home from nic_verification_screen.dart');
    }
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeDiscoveryScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _navigateBackOrDashboard();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            context.l10n.nationalIdVerification,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: context.themeInk,
            ),
          ),
          leading: Center(
            child: IconSquareButton.small(
              icon: Icons.chevron_left_rounded,
              onTap: _navigateBackOrDashboard,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
      ),
    );
  }

  Widget _buildSubmittedView() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 24, 24,
          widget.showBottomNav ? AppBottomNav.contentBottomPadding : 24),
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
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                onPressed: _navigateBackOrDashboard,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 16, 16,
          widget.showBottomNav ? AppBottomNav.contentBottomPadding : 24),
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
        const SizedBox(height: 24),
        PrimaryButton(
          label: _isSubmitting
              ? context.l10n.uploadingToVault
              : context.l10n.submitForVerification,
          trailingIcon: Icons.arrow_forward_rounded,
          onPressed: (_front && _back && _selfie && !_isSubmitting)
              ? _handleSubmit
              : null,
        ),
        const SizedBox(height: 12),
        const SizedBox(height: 4),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_rounded,
                  size: 13, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                context.l10n.endToEndEncryptedVault,
                style:
                    TextStyle(fontSize: 11, color: context.themeTextSecondary),
              ),
            ],
          ),
        ),
      ],
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_rounded,
                          size: 12, color: AppColors.primary),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                    ? (context.isDark
                        ? const Color(0xFF14241B)
                        : const Color(0xFFE8F5E9))
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
