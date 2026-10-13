import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart' as pv;
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../state/role_provider.dart';
import '../../../state/locale_provider.dart';
import '../../../models/user_profile.dart';
import '../../../models/job_location.dart';
import '../../../services/auth_service.dart';
import '../../../utils/location_utils.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/app_localizations_helpers.dart';
import '../../customer/screens/home_discovery_screen.dart';
import '../../provider/screens/provider_dashboard_screen.dart';
import '../../../services/storage_service.dart';
import '../../../utils/permission_utils.dart';
import '../../../shared/widgets/job_location_picker.dart';
import '../../../shared/widgets/searchable_select_picker.dart';
import '../../../models/admin_models.dart';
import '../../../repositories/category_repository.dart';
import 'role_choice_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  final UserProfile? initialProfile;
  final AppRole? targetRole;

  const CompleteProfileScreen({
    super.key,
    this.initialProfile,
    this.targetRole,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  AppRole _selectedRole = AppRole.customer;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _nicController = TextEditingController();
  final _dailyRateController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _perKmRateController = TextEditingController();
  final _visitFeeController = TextEditingController();

  String _district = 'Colombo';
  String _category = '';
  bool _agreeTerms = false;
  bool _isSubmitting = false;
  bool _detectingLocation = false;

  double? _latitude;
  double? _longitude;

  XFile? _profileImage;
  Uint8List? _profileImageBytes;
  XFile? _nicFrontImage;
  Uint8List? _nicFrontImageBytes;
  XFile? _nicBackImage;
  Uint8List? _nicBackImageBytes;
  final ImagePicker _picker = ImagePicker();

  static List<String> get _districts =>
      LocationUtils.districtCoordinates.keys.toList();

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    if (widget.targetRole != null) {
      _selectedRole = widget.targetRole!;
    } else if (profile != null && profile.role != null) {
      _selectedRole = profile.role!;
    }

    final rawName = profile?.displayName ?? '';
    final cleanName = rawName.contains('@') ? '' : rawName;
    _nameController = TextEditingController(text: cleanName);
    _phoneController.text = profile?.phone ?? '';

    if (_selectedRole == AppRole.provider) {
      _addressController.text = profile?.address ?? '';
      _latitude = profile?.latitude;
      _longitude = profile?.longitude;
      if (profile?.district != null && _districts.contains(profile!.district)) {
        _district = profile.district!;
      }
      if (profile?.serviceCategory != null &&
          profile!.serviceCategory!.isNotEmpty) {
        _category = profile.serviceCategory!;
      }
      if (profile?.dailyRateLkr != null) {
        _dailyRateController.text = profile!.dailyRateLkr.toString();
      }
      if (profile?.hourlyRateLkr != null) {
        _hourlyRateController.text = profile!.hourlyRateLkr.toString();
      }
      if (profile?.perKmRateLkr != null) {
        _perKmRateController.text = profile!.perKmRateLkr.toString();
      }
      if (profile?.visitFeeLkr != null) {
        _visitFeeController.text = profile!.visitFeeLkr.toString();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _nicController.dispose();
    _dailyRateController.dispose();
    _hourlyRateController.dispose();
    _perKmRateController.dispose();
    _visitFeeController.dispose();
    super.dispose();
  }

  Future<void> _detectGpsLocation() async {
    final granted =
        await PermissionUtils.requestLocationWithRationale(context);
    if (!granted) return;

    setState(() => _detectingLocation = true);

    try {
      final pos = await LocationUtils.getCurrentPosition();
      if (pos != null) {
        setState(() {
          _latitude = pos.latitude;
          _longitude = pos.longitude;
          if (_addressController.text.trim().isEmpty) {
            _addressController.text = '$_district, Sri Lanka';
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.authGpsLocationDetected(
                  pos.latitude.toStringAsFixed(4),
                  pos.longitude.toStringAsFixed(4),
                ),
              ),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.gpsLocationError),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _detectingLocation = false);
      }
    }
  }

  Future<void> _pickOnMap() async {
    final picked = await JobLocationPicker.pickLocation(
      context,
      title: context.l10n.setServiceLocation,
      initialLocation: _latitude != null && _longitude != null
          ? JobLocation(
              latitude: _latitude!,
              longitude: _longitude!,
              address: _addressController.text.trim(),
            )
          : null,
    );

    if (picked != null) {
      setState(() {
        _latitude = picked.latitude;
        _longitude = picked.longitude;
        if (picked.address.isNotEmpty) {
          _addressController.text = picked.address;
        }
      });
    }
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final ok = await PermissionUtils.requestCameraWithRationale(
        context,
        title: context.l10n.takeProfilePhoto,
        description: context.l10n.profileTrustPhotoRationale,
      );
      if (!ok) return;
    } else {
      final ok = await PermissionUtils.requestGalleryWithRationale(
        context,
        title: context.l10n.selectProfilePhoto,
        description: context.l10n.profileChooseGalleryPhoto,
      );
      if (!ok) return;
    }

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _profileImage = picked;
          _profileImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n.failedToPickPhoto}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickNicImage(bool isFront, ImageSource source) async {
    if (source == ImageSource.camera) {
      final ok = await PermissionUtils.requestCameraWithRationale(
        context,
        title: isFront ? context.l10n.captureNicFront : context.l10n.captureNicBack,
        description: context.l10n.captureNicPrompt,
      );
      if (!ok) return;
    } else {
      final ok = await PermissionUtils.requestGalleryWithRationale(
        context,
        title: isFront ? context.l10n.selectNicFront : context.l10n.selectNicBack,
        description: context.l10n.selectNicGalleryPrompt,
      );
      if (!ok) return;
    }

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          if (isFront) {
            _nicFrontImage = picked;
            _nicFrontImageBytes = bytes;
          } else {
            _nicBackImage = picked;
            _nicBackImageBytes = bytes;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n.failedToPickPhoto}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showProfilePhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.themeSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.themeBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                context.l10n.profilePhoto,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.themeTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.primary),
                title: Text(context.l10n.takePhoto,
                    style: TextStyle(color: context.themeTextPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickProfileImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.primary),
                title: Text(context.l10n.chooseFromGallery,
                    style: TextStyle(color: context.themeTextPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickProfileImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNicSourceSheet(bool isFront) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.themeSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.themeBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isFront
                    ? context.l10n.uploadNicFront
                    : context.l10n.uploadNicBack,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.themeTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: AppColors.primary),
                title: Text(context.l10n.takePhoto,
                    style: TextStyle(color: context.themeTextPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickNicImage(isFront, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: AppColors.primary),
                title: Text(context.l10n.chooseFromGallery,
                    style: TextStyle(color: context.themeTextPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickNicImage(isFront, ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.agreeTerms),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
    final localeProvider =
        pv.Provider.of<LocaleProvider>(context, listen: false);
    final current = widget.initialProfile ?? roleProvider.currentUser;

    // provider validations
    if (_selectedRole == AppRole.provider) {
      if (_profileImage == null &&
          (current?.photoUrl == null || current!.photoUrl!.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.profilePhotoRequired),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (_nicFrontImage == null &&
          (current?.nicFrontUrl == null || current!.nicFrontUrl!.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.nicFrontRequired),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (_latitude == null ||
          _longitude == null ||
          _addressController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.providerBaseLocationRequired),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final daily = int.tryParse(_dailyRateController.text.trim());
      final hourly = int.tryParse(_hourlyRateController.text.trim());
      final perKm = int.tryParse(_perKmRateController.text.trim());
      final visitFee = int.tryParse(_visitFeeController.text.trim());

      if (daily == null && hourly == null && perKm == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.atLeastOneRateRequired),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (daily != null && (daily < 1 || daily > 100000)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.dailyRateRangeError),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (hourly != null && (hourly < 1 || hourly > 20000)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.hourlyRateRangeError),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (perKm != null && (perKm < 1 || perKm > 1000)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.perKmRateRangeError),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (visitFee != null && (visitFee < 0 || visitFee > 20000)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.visitFeeRangeError),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      String? photoUploadedUrl;
      if (_profileImage != null) {
        photoUploadedUrl = await StorageService.instance.uploadPickedImage(
          _profileImage!,
          purpose: 'profile_photo',
          preloadedBytes: _profileImageBytes,
        );
      }

      String? nicFrontKey;
      String? nicBackKey;
      if (_nicFrontImage != null) {
        nicFrontKey = await StorageService.instance.uploadPickedImage(
          _nicFrontImage!,
          purpose: 'nic',
          preloadedBytes: _nicFrontImageBytes,
        );
      }
      if (_nicBackImage != null) {
        nicBackKey = await StorageService.instance.uploadPickedImage(
          _nicBackImage!,
          purpose: 'nic',
          preloadedBytes: _nicBackImageBytes,
        );
      }

      final uid = current?.id ??
          AuthService().currentFirebaseUser?.uid ??
          'usr_${DateTime.now().millisecondsSinceEpoch}';

      final UserProfile updatedProfile;

      if (_selectedRole == AppRole.customer) {
        // customer profile has no static location
        updatedProfile = (current ??
                UserProfile(
                  id: uid,
                  email: '',
                  displayName: _nameController.text.trim(),
                ))
            .copyWith(
          displayName: _nameController.text.trim(),
          role: AppRole.customer,
          isProfileComplete: true,
          photoUrl: photoUploadedUrl ?? current?.photoUrl,
          photoStatus:
              photoUploadedUrl != null ? 'pending' : current?.photoStatus,
          phone: _phoneController.text.trim().isNotEmpty
              ? AuthService.formatSriLankanPhoneNumber(
                  _phoneController.text.trim())
              : null,
          preferredLanguage: localeProvider.languageCode,
        );
      } else {
        // provider base location required
        updatedProfile = (current ??
                UserProfile(
                  id: uid,
                  email: '',
                  displayName: _nameController.text.trim(),
                ))
            .copyWith(
          displayName: _nameController.text.trim(),
          role: AppRole.provider,
          isProfileComplete: true,
          photoUrl: photoUploadedUrl ?? current?.photoUrl,
          photoStatus:
              photoUploadedUrl != null ? 'pending' : current?.photoStatus,
          phone: _phoneController.text.trim().isNotEmpty
              ? AuthService.formatSriLankanPhoneNumber(
                  _phoneController.text.trim())
              : null,
          district: _district,
          address: _addressController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          nic: _nicController.text.trim(),
          nicFrontKey: nicFrontKey ?? current?.nicFrontKey,
          nicBackKey: nicBackKey ?? current?.nicBackKey,
          certificationUrls: current?.certificationUrls ?? const [],
          certificationsStatus: current?.certificationsStatus,
          serviceCategory: _category,
          dailyRateLkr: int.tryParse(_dailyRateController.text.trim()),
          hourlyRateLkr: int.tryParse(_hourlyRateController.text.trim()),
          perKmRateLkr: int.tryParse(_perKmRateController.text.trim()),
          visitFeeLkr: int.tryParse(_visitFeeController.text.trim()) ?? 0,
          preferredLanguage: localeProvider.languageCode,
        );
      }

      await roleProvider.completeUserProfile(updatedProfile);

      if (!mounted) return;

      if (_selectedRole == AppRole.customer) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeDiscoveryScreen()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ProviderDashboardScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.failedToCompleteProfile(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
    required IconData icon,
    required bool isDark,
    String? prefixText,
    String? labelText,
  }) {
    final bg = isDark ? context.themeSurfaceLow : Colors.white;
    return InputDecoration(
      labelText: labelText,
      hintText: hint,
      hintStyle: TextStyle(
        color: context.themeTextSecondary.withValues(alpha: 0.6),
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: context.themeTextSecondary, size: 20),
      prefixText: prefixText,
      prefixStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: context.themeTextPrimary,
      ),
      filled: true,
      fillColor: bg,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = pv.Provider.of<RoleProvider>(context);
    final localeProvider = pv.Provider.of<LocaleProvider>(context);
    final profile = widget.initialProfile ?? roleProvider.currentUser;
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
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: context.themeTextPrimary),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (_) => const HomeDiscoveryScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ),
          ),
        ),
        title: Text(
          _selectedRole == AppRole.provider
              ? context.l10n.completeProviderProfileTitle
              : context.l10n.completeProfileTitle,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: context.themeTextPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (profile != null)
                      Container(
                        padding: const EdgeInsets.all(14),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: isFieldBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: context.themeBorder, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            UserAvatar(
                              uid: profile.id,
                              displayName: profile.displayName,
                              email: profile.email,
                              photoUrl: profile.photoUrl,
                              radius: 20,
                              backgroundColor: const Color(0xFF1E293B),
                              textColor: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.email.isNotEmpty
                                        ? profile.email
                                        : profile.displayName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: context.themeTextPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded,
                                          color: AppColors.success, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        context.l10n.accountVerified,
                                        style: const TextStyle(
                                          color: AppColors.success,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // language selection
                    Text(
                      context.l10n.preferredLanguage,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.themeTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 48,
                      padding: const EdgeInsets.all(4),
                      margin: const EdgeInsets.only(bottom: 22),
                      decoration: BoxDecoration(
                        color: isFieldBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: context.themeBorder, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          _SegmentedLanguageItem(
                            label: 'English',
                            selected: localeProvider.languageCode == 'en',
                            onTap: () =>
                                localeProvider.setLocale(const Locale('en')),
                          ),
                          _SegmentedLanguageItem(
                            label: 'සිංහල',
                            selected: localeProvider.languageCode == 'si',
                            onTap: () =>
                                localeProvider.setLocale(const Locale('si')),
                          ),
                          _SegmentedLanguageItem(
                            label: 'தமிழ்',
                            selected: localeProvider.languageCode == 'ta',
                            onTap: () =>
                                localeProvider.setLocale(const Locale('ta')),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // role display
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedRole == AppRole.provider
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : isFieldBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedRole == AppRole.provider
                              ? AppColors.primary.withValues(alpha: 0.35)
                              : context.themeBorder,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _selectedRole == AppRole.provider
                                  ? Icons.handyman_outlined
                                  : Icons.home_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      _selectedRole == AppRole.provider
                                          ? context.l10n.roleProvider
                                          : context.l10n.roleCustomer,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: context.themeTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        context.l10n.statusSelected,
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedRole == AppRole.provider
                                      ? context.l10n.providingServicesAcrossSriLanka
                                      : context.l10n.requestingDomesticServices,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: context.themeTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              final roleProvider = pv.Provider.of<RoleProvider>(
                                  context,
                                  listen: false);
                              final current = widget.initialProfile ??
                                  roleProvider.currentUser;
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RoleChoiceScreen(user: current),
                                ),
                              );
                            },
                            child: Text(
                              context.l10n.change,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // profile photo
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _showProfilePhotoSourceSheet,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: context.themeSurfaceLow,
                                    border: Border.all(
                                      color: _selectedRole == AppRole.provider
                                          ? AppColors.primary
                                          : context.themeBorder,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: _profileImageBytes != null
                                        ? Image.memory(
                                            _profileImageBytes!,
                                            fit: BoxFit.cover,
                                          )
                                        : (profile?.photoUrl != null &&
                                                profile!.photoUrl!.isNotEmpty)
                                            ? Image.network(
                                                profile.photoUrl!,
                                                fit: BoxFit.cover,
                                              )
                                            : Icon(
                                                Icons.person_rounded,
                                                size: 48,
                                                color: context
                                                    .themeTextSecondary,
                                              ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _selectedRole == AppRole.provider
                                ? '${context.l10n.profilePhoto} *'
                                : '${context.l10n.profilePhoto} (${context.l10n.optional})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.themeTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // full name
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
                      controller: _nameController,
                      style: TextStyle(
                          color: context.themeTextPrimary, fontSize: 14.5),
                      decoration: _inputDecoration(
                        context,
                        hint: context.l10n.fullNameAsNic,
                        icon: Icons.person_outline,
                        isDark: context.isDark,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return context.l10n.fullName;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // phone number
                    Text(
                      context.l10n.phoneLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.themeTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(
                          color: context.themeTextPrimary, fontSize: 14.5),
                      decoration: _inputDecoration(
                        context,
                        hint: context.l10n.phonePlaceholderPattern,
                        icon: Icons.phone_outlined,
                        isDark: context.isDark,
                        prefixText: '+94 ',
                      ),
                      validator: (val) {
                        if (val == null || val.trim().length < 9) {
                          return context.l10n.phoneNumber;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // provider only fields
                    if (_selectedRole == AppRole.provider) ...[
                      // category
                      StreamBuilder<List<CategoryRow>>(
                        stream: CategoryRepository().streamLiveCategories(),
                        builder: (context, snapshot) {
                          final liveCats = snapshot.data ?? [];
                          if (liveCats.isEmpty &&
                              snapshot.connectionState !=
                                  ConnectionState.waiting) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: context.themeSurfaceLow,
                                borderRadius: BorderRadius.circular(14),
                                border:
                                    Border.all(color: context.themeBorder),
                              ),
                              child: Text(
                                context.l10n.noServicesAvailableYet,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.themeTextSecondary,
                                ),
                              ),
                            );
                          }
                          final effectiveVal =
                              liveCats.any((c) => c.id == _category)
                                  ? _category
                                  : (liveCats.isNotEmpty
                                      ? liveCats.first.id
                                      : '');
                          if (_category.isEmpty && liveCats.isNotEmpty) {
                            WidgetsBinding.instance
                                .addPostFrameCallback((_) {
                              if (mounted && _category.isEmpty) {
                                setState(() => _category = effectiveVal);
                              }
                            });
                          }

                          return SearchableSelectPicker<String>(
                            label: context.l10n.serviceCategory,
                            selectedValue: effectiveVal.isNotEmpty
                                ? effectiveVal
                                : null,
                            prefixIcon: Icons.handyman_outlined,
                            isDarkField: context.isDark,
                            modalTitle: context.l10n.selectServiceCategory,
                            searchHint: context.l10n.searchCategoryHint,
                            items: liveCats.map((c) {
                              return SearchableSelectItem<String>(
                                value: c.id,
                                label: c.name,
                                icon: c.icon,
                              );
                            }).toList(),
                            onSelected: (val) =>
                                setState(() => _category = val),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // district
                      SearchableSelectPicker<String>(
                        label: context.l10n.district,
                        selectedValue: _district,
                        prefixIcon: Icons.map_outlined,
                        isDarkField: context.isDark,
                        modalTitle: context.l10n.district,
                        searchHint: context.l10n.searchDistrictHint,
                        items: _districts.map((d) {
                          final localizedName =
                              LocalizedData.getDistrict(context, d);
                          return SearchableSelectItem<String>(
                            value: d,
                            label: localizedName,
                            subtitle: localizedName != d ? d : null,
                            icon: Icons.location_on_outlined,
                          );
                        }).toList(),
                        onSelected: (val) => setState(() => _district = val),
                      ),
                      const SizedBox(height: 16),

                      // base location card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isFieldBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: (_latitude != null && _longitude != null)
                                ? AppColors.primary
                                : context.themeBorder,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.my_location,
                                      color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.l10n.baseWorkshopLocation,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13.5,
                                          color: context.themeTextPrimary,
                                        ),
                                      ),
                                      Text(
                                        context.l10n.baseLocationDispatchNotice,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: context.themeTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _detectingLocation
                                        ? null
                                        : _detectGpsLocation,
                                    icon: _detectingLocation
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        : const Icon(
                                            Icons.my_location_rounded,
                                            size: 16),
                                    label: Text(context.l10n.useGps),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _pickOnMap,
                                    icon: const Icon(
                                        Icons.pin_drop_rounded,
                                        size: 16),
                                    label: Text(_latitude != null
                                        ? context.l10n.updatePinButton
                                        : context.l10n.pickOnMapButton),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_latitude != null && _longitude != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle_rounded,
                                        color: AppColors.primary, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${context.l10n.location}: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _addressController,
                              style: TextStyle(
                                  color: context.themeTextPrimary,
                                  fontSize: 14),
                              decoration: _inputDecoration(
                                context,
                                hint: context.l10n.workshopAddressRequiredLabel,
                                icon: Icons.location_on_outlined,
                                isDark: context.isDark,
                              ),
                              validator: (val) {
                                if (_selectedRole == AppRole.provider &&
                                    (val == null || val.trim().isEmpty)) {
                                  return context.l10n.operatingAddressRequiredError;
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // identity card number
                      Text(
                        '${context.l10n.nicNumber} *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.themeTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nicController,
                        style: TextStyle(
                            color: context.themeTextPrimary,
                            fontSize: 14.5),
                        decoration: _inputDecoration(
                          context,
                          hint: 'e.g. 199012345678 or 901234567V',
                          icon: Icons.badge_outlined,
                          isDark: context.isDark,
                        ),
                        validator: (val) {
                          if (_selectedRole == AppRole.provider &&
                              (val == null || val.trim().isEmpty)) {
                            return context.l10n.enterNicError;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // identity card photos
                      Row(
                        children: [
                          Expanded(
                            child: _DocUploadBox(
                              label: context.l10n.nicFront,
                              file: _nicFrontImage,
                              bytes: _nicFrontImageBytes,
                              networkUrl: profile?.nicFrontUrl,
                              onTap: () => _showNicSourceSheet(true),
                              isDark: context.isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _DocUploadBox(
                              label: context.l10n.nicBack,
                              file: _nicBackImage,
                              bytes: _nicBackImageBytes,
                              networkUrl: profile?.nicBackUrl,
                              onTap: () => _showNicSourceSheet(false),
                              isDark: context.isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // provider usual rates
                      Text(
                        context.l10n.yourUsualRates,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: context.themeTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.yourUsualRatesSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.themeTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _dailyRateController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: context.themeTextPrimary, fontSize: 14),
                        decoration: _inputDecoration(
                          context,
                          hint: context.l10n.dailyRateHint,
                          icon: Icons.calendar_today_outlined,
                          prefixText: 'LKR ',
                          labelText: context.l10n.dailyRate,
                          isDark: context.isDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _hourlyRateController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: context.themeTextPrimary, fontSize: 14),
                        decoration: _inputDecoration(
                          context,
                          hint: context.l10n.hourlyRateHint,
                          icon: Icons.timer_outlined,
                          prefixText: 'LKR ',
                          labelText: context.l10n.hourlyRate,
                          isDark: context.isDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _perKmRateController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: context.themeTextPrimary, fontSize: 14),
                        decoration: _inputDecoration(
                          context,
                          hint: context.l10n.perKmRateHint,
                          icon: Icons.directions_car_outlined,
                          prefixText: 'LKR ',
                          labelText: context.l10n.perKmTravelRate,
                          isDark: context.isDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _visitFeeController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: context.themeTextPrimary, fontSize: 14),
                        decoration: _inputDecoration(
                          context,
                          hint: context.l10n.visitFeeOptionalHint,
                          icon: Icons.meeting_room_outlined,
                          prefixText: 'LKR ',
                          labelText: context.l10n.standardVisitFee,
                          isDark: context.isDark,
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // terms checkbox
                    CheckboxListTile(
                      value: _agreeTerms,
                      onChanged: (val) =>
                          setState(() => _agreeTerms = val ?? false),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppColors.primary,
                      title: Text(
                        context.l10n.agreeTerms,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: context.themeTextSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // submit button
                    PrimaryButton(
                      label: _selectedRole == AppRole.provider
                          ? context.l10n.completeProviderRegistration
                          : context.l10n.saveProfile,
                      loading: _isSubmitting,
                      onPressed: _agreeTerms && !_isSubmitting ? _submit : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DocUploadBox extends StatelessWidget {
  final String label;
  final XFile? file;
  final Uint8List? bytes;
  final String? networkUrl;
  final VoidCallback onTap;
  final bool isDark;

  const _DocUploadBox({
    required this.label,
    this.file,
    this.bytes,
    this.networkUrl,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = bytes != null || file != null || (networkUrl != null && networkUrl!.isNotEmpty);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? context.themeSurfaceLow : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasImage ? AppColors.primary : context.themeBorder,
            width: hasImage ? 1.5 : 1,
          ),
        ),
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: bytes != null
                        ? Image.memory(bytes!, fit: BoxFit.cover)
                        : (networkUrl != null && networkUrl!.isNotEmpty
                            ? Image.network(networkUrl!, fit: BoxFit.cover)
                            : const SizedBox.shrink()),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 12, color: Colors.white),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.upload_file_rounded,
                      color: AppColors.primary, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.themeTextPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }
}

class _SegmentedLanguageItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentedLanguageItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : context.themeTextSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
