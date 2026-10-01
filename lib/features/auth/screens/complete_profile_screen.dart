import 'dart:convert';
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
    _nameController = TextEditingController(text: profile?.displayName ?? '');
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
                'GPS Location detected: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
              ),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not obtain GPS location. Please ensure location is enabled.'),
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
            content: Text('Failed to pick profile photo: $e'),
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
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: Text(context.l10n.takePhoto, style: TextStyle(color: context.themeTextPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickProfileImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: Text(context.l10n.chooseFromGallery, style: TextStyle(color: context.themeTextPrimary)),
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
            content: Text('Failed to pick photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
                isFront ? context.l10n.uploadNicFront : context.l10n.uploadNicBack,
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
                  _pickNicImage(isFront, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: Text(context.l10n.chooseFromGallery, style: TextStyle(color: context.themeTextPrimary)),
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
    final localeProvider = pv.Provider.of<LocaleProvider>(context, listen: false);
    final current = widget.initialProfile ?? roleProvider.currentUser;

    if (_selectedRole == AppRole.provider) {
      if (_profileImage == null && (current?.photoUrl == null || current!.photoUrl!.isEmpty)) {
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
      String? photoBase64;
      if (_profileImage != null) {
        final bytes = await _profileImage!.readAsBytes();
        photoBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }

      String? nicFrontBase64;
      String? nicBackBase64;
      if (_nicFrontImage != null) {
        final bytes = await _nicFrontImage!.readAsBytes();
        nicFrontBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      }
      if (_nicBackImage != null) {
        final bytes = await _nicBackImage!.readAsBytes();
        nicBackBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
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
        photoUrl: photoBase64 ?? current?.photoUrl,
        phone: _phoneController.text.trim(),
        district: _district,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : '$_district, Sri Lanka',
        latitude: _latitude,
        longitude: _longitude,
        nic: _selectedRole == AppRole.provider ? _nicController.text.trim() : null,
        nicFrontUrl: nicFrontBase64,
        nicBackUrl: nicBackBase64,
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

    return Scaffold(
      backgroundColor: context.themeBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
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
                      color: context.themeSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.themeBorder),
                    ),
                    child: Row(
                      children: [
                        UserAvatar(
                          uid: profile.id,
                          displayName: profile.displayName,
                          email: profile.email,
                          radius: 20,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                          textColor: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.email.isNotEmpty ? profile.email : profile.displayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: context.themeTextPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                context.l10n.accountVerified,
                                style: TextStyle(
                                  color: context.themeTextSecondary,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: context.themeSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.themeBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.language,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            context.l10n.preferredLanguage,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: context.themeTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _LanguageChip(
                            label: 'English',
                            selected: localeProvider.languageCode == 'en',
                            onTap: () =>
                                localeProvider.setLocale(const Locale('en')),
                          ),
                          const SizedBox(width: 8),
                          _LanguageChip(
                            label: 'සිංහල',
                            selected: localeProvider.languageCode == 'si',
                            onTap: () =>
                                localeProvider.setLocale(const Locale('si')),
                          ),
                          const SizedBox(width: 8),
                          _LanguageChip(
                            label: 'தமிழ்',
                            selected: localeProvider.languageCode == 'ta',
                            onTap: () =>
                                localeProvider.setLocale(const Locale('ta')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Text(
                  context.l10n.selectAccountType,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.themeTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _RoleCard(
                        title: context.l10n.roleCustomer,
                        description: context.l10n.customerRoleDesc,
                        icon: Icons.person_pin_circle_outlined,
                        selected: _selectedRole == AppRole.customer,
                        onTap: () => setState(() => _selectedRole = AppRole.customer),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleCard(
                        title: context.l10n.roleProvider,
                        description: context.l10n.providerRoleDesc,
                        icon: Icons.handyman_outlined,
                        selected: _selectedRole == AppRole.provider,
                        onTap: () => setState(() => _selectedRole = AppRole.provider),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                Text(
                  _selectedRole == AppRole.customer ? context.l10n.roleCustomer : context.l10n.roleProvider,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.themeTextPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  context.l10n.fullName,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: context.themeTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: context.themeTextPrimary, fontSize: 14),
                  decoration: _inputDecoration(
                    context,
                    hint: context.l10n.fullNameAsNic,
                    icon: Icons.person_outline,
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
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: context.themeTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: context.themeTextPrimary, fontSize: 14),
                  decoration: _inputDecoration(
                    context,
                    hint: '07X XXXXXXX',
                    icon: Icons.phone_outlined,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 9) {
                      return context.l10n.phoneNumber;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),
                Text(
                  context.l10n.district,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: context.themeTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _district,
                  dropdownColor: context.themeSurface,
                  style: TextStyle(color: context.themeTextPrimary, fontSize: 14),
                  decoration: _inputDecoration(
                    context,
                    hint: context.l10n.district,
                    icon: Icons.map_outlined,
                  ),
                  items: _districts.map((d) {
                    return DropdownMenuItem(
                      value: d,
                      child: Text(LocalizedData.getDistrict(context, d)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _district = val);
                  },
                ),

                const SizedBox(height: 20),
                Text(
                  context.l10n.jobLocationGps,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.themeTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.themeSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _latitude != null ? AppColors.primary : context.themeBorder,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.my_location, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _latitude != null
                                      ? '${context.l10n.gpsDetected}: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                                      : context.l10n.detectGps,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
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
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: OutlinedButton.icon(
                          onPressed: _detectingLocation ? null : _detectGpsLocation,
                          icon: _detectingLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.gps_fixed, size: 16),
                          label: Text(
                            _latitude != null ? context.l10n.refreshGps : context.l10n.detectGps,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                TextFormField(
                  controller: _addressController,
                  style: TextStyle(color: context.themeTextPrimary, fontSize: 14),
                  decoration: _inputDecoration(
                    context,
                    hint: context.l10n.address,
                    icon: Icons.home_outlined,
                  ),
                ),

                if (_selectedRole == AppRole.provider) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        context.l10n.profilePhoto,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: context.themeTextPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          context.l10n.requiredField,
                          style: const TextStyle(
                            fontSize: 10.5,
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
                      fontSize: 12,
                      color: context.themeTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: _showProfileImageSourceSheet,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: context.themeSurfaceLow,
                              border: Border.all(
                                color: _profileImage != null ? AppColors.primary : context.themeBorder,
                                width: 2.5,
                              ),
                              image: _profileImage != null
                                  ? DecorationImage(
                                      image: FileImage(File(_profileImage!.path)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _profileImage == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.add_a_photo_outlined,
                                        size: 30,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        context.l10n.addPhoto,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: context.themeTextSecondary,
                                        ),
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                        ),
                        if (_profileImage != null)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _showProfileImageSourceSheet,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  Text(
                    context.l10n.category,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: context.themeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    context.l10n.primaryCategory,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: context.themeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
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
                          : (allCats.isNotEmpty ? allCats.first : null);

                      return DropdownButtonFormField<String>(
                        initialValue: effectiveVal,
                        dropdownColor: context.themeSurface,
                        style: TextStyle(color: context.themeTextPrimary, fontSize: 14),
                        decoration: _inputDecoration(
                          context,
                          hint: context.l10n.category,
                          icon: Icons.category_outlined,
                        ),
                        items: allCats.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text(LocalizedData.getCategory(context, c)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _category = val);
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                  Text(
                    context.l10n.nicNumber,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: context.themeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nicController,
                    style: TextStyle(color: context.themeTextPrimary, fontSize: 14),
                    decoration: _inputDecoration(
                      context,
                      hint: '199012345678 / 901234567V',
                      icon: Icons.badge_outlined,
                    ),
                    validator: (val) {
                      if (_selectedRole == AppRole.provider && (val == null || val.trim().isEmpty)) {
                        return context.l10n.nicNumber;
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),
                  Text(
                    context.l10n.nicFront,
                    style: TextStyle(
                      fontSize: 12.5,
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
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NicUploadBox(
                          label: context.l10n.nicBack,
                          image: _nicBackImage,
                          onTap: () => _showImageSourceSheet(false),
                        ),
                      ),
                    ],
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        onChanged: (val) => setState(() => _agreeTerms = val ?? false),
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

                const SizedBox(height: 24),
                PrimaryButton(
                  label: _isSubmitting ? context.l10n.statusPending : context.l10n.completeRegistration,
                  onPressed: _isSubmitting ? () {} : _submit,
                  loading: _isSubmitting,
                ),
              ],
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
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: context.themeTextSecondary),
      filled: true,
      fillColor: context.themeSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.themeBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.themeBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.08) : context.themeSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : context.themeBorder,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.primary : context.themeTextSecondary,
              size: 26,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: selected ? AppColors.primary : context.themeTextPrimary,
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

  const _NicUploadBox({
    required this.label,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: context.themeSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: image != null ? AppColors.primary : context.themeBorder,
            style: image != null ? BorderStyle.solid : BorderStyle.solid,
          ),
        ),
        child: image != null
            ? FutureBuilder<Uint8List>(
                future: image!.readAsBytes(),
                builder: (ctx, snap) {
                  if (snap.hasData) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(snap.data!, fit: BoxFit.cover),
                          Container(
                            color: Colors.black26,
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
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                },
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: context.themeTextSecondary, size: 26),
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

class _LanguageChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : context.themeSurfaceLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : context.themeBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.language,
                size: 18,
                color: selected ? Colors.white : AppColors.primary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                  color: selected ? Colors.white : context.themeTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
