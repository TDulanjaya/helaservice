import 'dart:io';
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
import '../../../utils/location_utils.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/app_localizations_helpers.dart';
import '../../../repositories/category_repository.dart';
import '../../../models/admin_models.dart';
import '../../customer/screens/home_discovery_screen.dart';
import '../../provider/screens/provider_dashboard_screen.dart';
import '../../../services/storage_service.dart';
import '../../../utils/permission_utils.dart';
import '../../../shared/widgets/searchable_select_picker.dart';

class CompleteProfileScreen extends StatefulWidget {
  final UserProfile? initialProfile;

  const CompleteProfileScreen({super.key, this.initialProfile});

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

  String _district = 'Colombo';
  String _category = 'Electrical Services';
  bool _agreeTerms = false;
  bool _isSubmitting = false;
  bool _detectingLocation = false;

  double? _latitude;
  double? _longitude;

  XFile? _profileImage;
  XFile? _nicFrontImage;
  XFile? _nicBackImage;
  final List<XFile> _certificationImages = [];
  final ImagePicker _picker = ImagePicker();

  static List<String> get _districts =>
      LocationUtils.districtCoordinates.keys.toList();

  static const List<String> _categories = [
    'Electrical Services',
    'Plumbing & Sanitary',
    'AC & Refrigeration',
    'Carpentry & Woodwork',
    'Masonry & Construction',
    'Appliance Repair',
    'House Painting',
    'Roofing & Waterproofing',
  ];

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    final rawName = profile?.displayName ?? '';
    final cleanName = rawName.contains('@') ? '' : rawName;
    _nameController = TextEditingController(text: cleanName);
    _phoneController.text = profile?.phone ?? '';
    _addressController.text = profile?.address ?? '';
    _latitude = profile?.latitude;
    _longitude = profile?.longitude;
    if (profile?.district != null && _districts.contains(profile!.district)) {
      _district = profile.district!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _nicController.dispose();
    super.dispose();
  }

  Future<void> _detectGpsLocation() async {
    final granted = await PermissionUtils.requestLocationWithRationale(context);
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
                    pos.longitude.toStringAsFixed(4)),
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

  Future<void> _pickProfileImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final ok = await PermissionUtils.requestCameraWithRationale(context,
          title: 'Take Profile Photo',
          description:
              'A clear photo of your face builds trust with clients and speeds up verification.');
      if (!ok) return;
    } else {
      final ok = await PermissionUtils.requestGalleryWithRationale(context,
          title: 'Select Profile Photo',
          description:
              'Choose a professional portrait photo from your gallery.');
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
        setState(() {
          _profileImage = picked;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.authFailedToPickProfilePhoto('$e')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showProfileImageSourceSheet() {
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
                context.l10n.uploadProfilePhoto,
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

  Future<void> _pickNicImage(bool isFront, ImageSource source) async {
    if (source == ImageSource.camera) {
      final ok = await PermissionUtils.requestCameraWithRationale(context,
          title: isFront ? 'Scan NIC Front' : 'Scan NIC Back',
          description:
              'Capture a clear, readable photo of your National Identity Card.');
      if (!ok) return;
    } else {
      final ok = await PermissionUtils.requestGalleryWithRationale(context,
          title: isFront ? 'Select NIC Front' : 'Select NIC Back',
          description:
              'Select your National Identity Card photo from gallery.');
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
        setState(() {
          if (isFront) {
            _nicFrontImage = picked;
          } else {
            _nicBackImage = picked;
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

  Future<void> _pickCertificationImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      final ok = await PermissionUtils.requestCameraWithRationale(context,
          title: 'Capture Certificate / License',
          description:
              'Photograph your NVQ, trade certificate, or vocational license for verification.');
      if (!ok) return;
    } else {
      final ok = await PermissionUtils.requestGalleryWithRationale(context,
          title: 'Select Certificate / License',
          description:
              'Choose your qualification certificate from gallery or files.');
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
        setState(() {
          _certificationImages.add(picked);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick certificate: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showCertificationSourceSheet() {
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
                'Upload Trade Certificate / License',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.themeTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: Text(context.l10n.takePhoto, style: TextStyle(color: context.themeTextPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickCertificationImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: Text(context.l10n.chooseFromGallery, style: TextStyle(color: context.themeTextPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickCertificationImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceSheet(bool isFront) {
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
      if (_nicFrontImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.nicFrontRequired),
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
        photoUploadedUrl = await StorageService.instance.uploadFile(File(_profileImage!.path));
      }

      String? nicFrontUploadedUrl;
      String? nicBackUploadedUrl;
      if (_nicFrontImage != null) {
        nicFrontUploadedUrl = await StorageService.instance.uploadFile(File(_nicFrontImage!.path));
      }
      if (_nicBackImage != null) {
        nicBackUploadedUrl = await StorageService.instance.uploadFile(File(_nicBackImage!.path));
      }

      final List<String> certUploadedUrls = [];
      for (final cert in _certificationImages) {
        final url = await StorageService.instance.uploadFile(File(cert.path));
        certUploadedUrls.add(url);
      }

      final updatedProfile = (current ??
              UserProfile(
                id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
                email: '',
                displayName: _nameController.text.trim(),
              ))
          .copyWith(
        displayName: _nameController.text.trim(),
        role: _selectedRole,
        isProfileComplete: true,
        photoUrl: photoUploadedUrl ?? current?.photoUrl,
        photoStatus: photoUploadedUrl != null ? 'pending' : current?.photoStatus,
        phone: _phoneController.text.trim(),
        district: _district,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : '$_district, Sri Lanka',
        latitude: _latitude,
        longitude: _longitude,
        nic: _selectedRole == AppRole.provider
            ? _nicController.text.trim()
            : null,
        nicFrontUrl: nicFrontUploadedUrl ?? current?.nicFrontUrl,
        nicBackUrl: nicBackUploadedUrl ?? current?.nicBackUrl,
        certificationUrls: certUploadedUrls.isNotEmpty
            ? certUploadedUrls
            : (current?.certificationUrls ?? const []),
        certificationsStatus: certUploadedUrls.isNotEmpty
            ? 'pending'
            : current?.certificationsStatus,
        serviceCategory: _selectedRole == AppRole.provider ? _category : null,
        preferredLanguage: localeProvider.languageCode,
      );

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
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ),
        title: Text(
          context.l10n.completeProfileTitle,
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
                    margin: const EdgeInsets.only(bottom: 22),
                    decoration: BoxDecoration(
                      color: isFieldBg,
                      borderRadius: BorderRadius.circular(18),
                      border:
                          Border.all(color: context.themeBorder, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        UserAvatar(
                          uid: profile.id,
                          displayName: profile.displayName,
                          email: profile.email,
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
                                  const Icon(Icons.check,
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
                    border: Border.all(color: context.themeBorder, width: 1.5),
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
                Text(
                  context.l10n.selectAccountType,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.themeTextPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _RoleCard(
                        title: context.l10n.roleCustomer,
                        description: context.l10n.customerRoleDesc,
                        icon: Icons.home_outlined,
                        selected: _selectedRole == AppRole.customer,
                        onTap: () =>
                            setState(() => _selectedRole = AppRole.customer),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleCard(
                        title: context.l10n.roleProvider,
                        description: context.l10n.providerRoleDesc,
                        icon: Icons.handyman_outlined,
                        selected: _selectedRole == AppRole.provider,
                        onTap: () =>
                            setState(() => _selectedRole = AppRole.provider),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
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
                    hint: '07X XXXXXXX',
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
                SearchableSelectPicker<String>(
                  label: context.l10n.district,
                  selectedValue: _district,
                  prefixIcon: Icons.map_outlined,
                  isDarkField: context.isDark,
                  modalTitle: context.l10n.district,
                  searchHint: 'Search district...',
                  items: _districts.map((d) {
                    final localizedName = LocalizedData.getDistrict(context, d);
                    final sin = LocalizedData.districts[d]?['si'] ?? '';
                    final tam = LocalizedData.districts[d]?['ta'] ?? '';
                    return SearchableSelectItem<String>(
                      value: d,
                      label: localizedName,
                      subtitle: localizedName != d ? d : null,
                      icon: Icons.location_on_outlined,
                      searchTerms: [d, sin, tam],
                    );
                  }).toList(),
                  onSelected: (val) {
                    setState(() {
                      _district = val;
                      if (_addressController.text.trim().isEmpty ||
                          _addressController.text.contains(', Sri Lanka')) {
                        _addressController.text = '$val, Sri Lanka';
                      }
                    });
                  },
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isFieldBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: context.themeBorder,
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
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.my_location,
                                color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.l10n.jobLocationGps,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                    color: context.themeTextPrimary,
                                  ),
                                ),
                                Text(
                                  context.l10n.gpsHint,
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
                      if (_latitude == null)
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton.icon(
                            onPressed:
                                _detectingLocation ? null : _detectGpsLocation,
                            icon: _detectingLocation
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : const Icon(Icons.gps_fixed, size: 16),
                            label: Text(
                              context.l10n.detectGps,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: AppColors.primary, width: 1.5),
                              foregroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        )
                      else ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: context.themeSuccessTint,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline_rounded,
                                  size: 16, color: context.themeSuccess),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${context.l10n.gpsDetected} · ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                                  style: TextStyle(
                                    color: context.themeSuccess,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: OutlinedButton.icon(
                            onPressed:
                                _detectingLocation ? null : _detectGpsLocation,
                            icon: _detectingLocation
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : const Icon(Icons.refresh_rounded, size: 16),
                            label: Text(
                              context.l10n.refreshGps,
                              style: const TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w700),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: context.themeBorder, width: 1.5),
                              foregroundColor: context.themeTextPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        context.l10n.address,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.themeTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _addressController,
                        style: TextStyle(
                            color: context.themeTextPrimary, fontSize: 14.5),
                        decoration: _inputDecoration(
                          context,
                          hint: context.l10n.addressHint,
                          icon: Icons.home_outlined,
                          isDark: context.isDark,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedRole == AppRole.provider) ...[
                  const SizedBox(height: 24),
                  Text(
                    context.l10n.roleProvider,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: context.themeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isFieldBg,
                      borderRadius: BorderRadius.circular(18),
                      border:
                          Border.all(color: context.themeBorder, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _showProfileImageSourceSheet,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: context.isDark
                                  ? context.themeBg
                                  : const Color(0xFFF6F5F2),
                              border: Border.all(
                                color: _profileImage != null
                                    ? AppColors.primary
                                    : context.themeBorder,
                                width: 1.5,
                              ),
                              image: _profileImage != null
                                  ? DecorationImage(
                                      image:
                                          FileImage(File(_profileImage!.path)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _profileImage == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt_outlined,
                                        size: 24,
                                        color: context.themeTextSecondary,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        context.l10n.addPhoto,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: context.themeTextSecondary,
                                        ),
                                      ),
                                    ],
                                  )
                                : Align(
                                    alignment: Alignment.bottomRight,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.edit,
                                          size: 12, color: Colors.white),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    context.l10n.profilePhoto,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: context.themeTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.error
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      context.l10n.requiredField,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.l10n.uploadClearFacePhoto,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: context.themeTextSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<List<CategoryRow>>(
                    stream: CategoryRepository().streamCategoryRows(),
                    builder: (context, snapshot) {
                      final liveCats = (snapshot.data ?? [])
                          .where((c) => c.status.toLowerCase() == 'active')
                          .map((c) => c.name)
                          .toList();
                      final allCats =
                          liveCats.isNotEmpty ? liveCats : _categories;
                      final effectiveVal = allCats.contains(_category)
                          ? _category
                          : (allCats.isNotEmpty ? allCats.first : 'Electrical Services');

                      return SearchableSelectPicker<String>(
                        label: context.l10n.primaryCategory,
                        selectedValue: effectiveVal,
                        prefixIcon: Icons.bolt_outlined,
                        isDarkField: context.isDark,
                        modalTitle: context.l10n.category,
                        searchHint: 'Search category...',
                        items: allCats.map((c) {
                          final localized = LocalizedData.getCategory(context, c);
                          final sin = LocalizedData.categories[c]?['si'] ?? '';
                          final tam = LocalizedData.categories[c]?['ta'] ?? '';
                          return SearchableSelectItem<String>(
                            value: c,
                            label: localized,
                            subtitle: localized != c ? c : null,
                            icon: Icons.handyman_outlined,
                            searchTerms: [c, sin, tam],
                          );
                        }).toList(),
                        onSelected: (val) => setState(() => _category = val),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.nicNumber,
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
                        color: context.themeTextPrimary, fontSize: 14.5),
                    decoration: _inputDecoration(
                      context,
                      hint: context.l10n.provNicHintExample,
                      icon: Icons.badge_outlined,
                      isDark: context.isDark,
                    ),
                    validator: (val) {
                      if (_selectedRole == AppRole.provider &&
                          (val == null || val.trim().isEmpty)) {
                        return context.l10n.nicNumber;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.nicFront,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.themeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _NicUploadBox(
                          label: context.l10n.nicFront,
                          image: _nicFrontImage,
                          onTap: () => _showImageSourceSheet(true),
                          isDark: context.isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NicUploadBox(
                          label: context.l10n.nicBack,
                          image: _nicBackImage,
                          onTap: () => _showImageSourceSheet(false),
                          isDark: context.isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Trade Certifications & Licenses',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.themeTextPrimary,
                        ),
                      ),
                      Text(
                        '(Optional)',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: context.themeTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Upload NVQ certificates, trade licenses, or vocational diplomas to earn a Verified Artisan badge.',
                    style: TextStyle(fontSize: 11.5, color: context.themeTextSecondary, height: 1.3),
                  ),
                  const SizedBox(height: 10),
                  if (_certificationImages.isNotEmpty) ...[
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _certificationImages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, idx) {
                          final file = _certificationImages[idx];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(file.path),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () => setState(() => _certificationImages.removeAt(idx)),
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  OutlinedButton.icon(
                    onPressed: _showCertificationSourceSheet,
                    icon: const Icon(Icons.upload_file_outlined, size: 18),
                    label: Text(
                      _certificationImages.isEmpty ? 'Add Certificate / License' : 'Add Another Certificate',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: context.themeBorder, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _agreeTerms,
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) =>
                            setState(() => _agreeTerms = val ?? false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.l10n.agreeTerms,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: context.themeTextSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: _isSubmitting
                      ? context.l10n.statusPending
                      : context.l10n.completeRegistration,
                  onPressed: _isSubmitting ? null : _submit,
                  loading: _isSubmitting,
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

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
    required IconData icon,
    required bool isDark,
    String? prefixText,
  }) {
    final isFieldBg = isDark ? context.themeSurfaceLow : Colors.white;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: context.themeTextSecondary.withValues(alpha: 0.6),
      ),
      prefixText: prefixText,
      prefixStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: context.themeTextPrimary,
      ),
      prefixIcon: Icon(icon, size: 20, color: context.themeTextSecondary),
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
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final isFieldBg = isDark ? context.themeSurfaceLow : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.primary.withValues(alpha: 0.08) : isFieldBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : context.themeBorder,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E2024)
                        : const Color(0xFFF2EFE9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: selected
                        ? AppColors.primary
                        : context.themeTextSecondary,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? AppColors.primary : context.themeBorder,
                      width: selected ? 2 : 1.5,
                    ),
                  ),
                  child: selected
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: context.themeTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: context.themeTextSecondary,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NicUploadBox extends StatelessWidget {
  final String label;
  final XFile? image;
  final VoidCallback onTap;
  final bool isDark;

  const _NicUploadBox({
    required this.label,
    required this.image,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isFieldBg = isDark ? context.themeSurfaceLow : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: isFieldBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: image != null ? AppColors.primary : context.themeBorder,
            width: 1.5,
          ),
        ),
        child: image != null
            ? FutureBuilder<Uint8List>(
                future: image!.readAsBytes(),
                builder: (ctx, snap) {
                  if (snap.hasData) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(snap.data!, fit: BoxFit.cover),
                          Container(
                            color: Colors.black38,
                            padding: const EdgeInsets.all(6),
                            alignment: Alignment.bottomCenter,
                            child: Text(
                              '$label (${context.l10n.tapToChange})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2));
                },
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.credit_card_outlined,
                      color: context.themeTextSecondary, size: 24),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.themeTextPrimary,
                    ),
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
    final isDark = context.isDark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? context.themeSurfaceHigh : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected && !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? context.themeTextPrimary
                  : context.themeTextSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
