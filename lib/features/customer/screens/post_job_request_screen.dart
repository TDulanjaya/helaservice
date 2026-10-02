import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart' as pv;
import '../../../theme/app_theme.dart';
import '../../../models/job_request.dart';
import '../../../models/admin_models.dart';
import '../../../repositories/job_request_repository.dart';
import '../../../repositories/category_repository.dart';
import '../../../state/role_provider.dart';
import '../../../utils/location_utils.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/app_localizations_helpers.dart';
import 'job_quotes_screen.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/icon_square_button.dart';
import '../../../shared/widgets/primary_button.dart';

class PostJobRequestScreen extends StatefulWidget {
  const PostJobRequestScreen({super.key});

  @override
  State<PostJobRequestScreen> createState() => _PostJobRequestScreenState();
}

class _PostJobRequestScreenState extends State<PostJobRequestScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  String? _selectedCategory;
  String _selectedDistrict = 'Colombo';
  final List<XFile> _photos = [];
  double? _latitude;
  double? _longitude;
  bool _detectingLocation = false;
  bool _submitting = false;

  static const int _maxPhotos = 4;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
      final user = roleProvider.currentUser;
      if (user != null) {
        if (user.address != null && user.address!.isNotEmpty) {
          _addressController.text = user.address!;
        }
        if (user.district != null &&
            LocationUtils.districtCoordinates.containsKey(user.district)) {
          setState(() {
            _selectedDistrict = user.district!;
            final coords =
                LocationUtils.getDistrictCoordinates(_selectedDistrict);
            _latitude = user.latitude ?? coords.lat;
            _longitude = user.longitude ?? coords.lng;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_photos.length >= _maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.maxPhotosAllowed)),
      );
      return;
    }
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 60,
      );
      if (picked != null) {
        setState(() => _photos.add(picked));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n.failedToPickImage}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.themeSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.l10n.addPhoto,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: Text(context.l10n.takePhoto),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: AppColors.primary),
                title: Text(context.l10n.chooseFromGallery),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _detectLocation() async {
    setState(() => _detectingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(context.l10n.enableLocationServices)),
          );
        }
        setState(() => _detectingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.locationPermissionDenied)),
            );
          }
          setState(() => _detectingLocation = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    context.l10n.locationPermissionPermanentlyDenied)),
          );
        }
        setState(() => _detectingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n.failedToDetectLocation}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _detectingLocation = false);
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.selectCategoryError)),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Not logged in');
      }

      final List<String> photoUrls = [];
      for (final photo in _photos) {
        final bytes = await File(photo.path).readAsBytes();
        final base64Str = base64Encode(bytes);
        photoUrls.add('data:image/jpeg;base64,$base64Str');
      }

      final districtCoords =
          LocationUtils.getDistrictCoordinates(_selectedDistrict);
      final resolvedLat = _latitude ?? districtCoords.lat;
      final resolvedLng = _longitude ?? districtCoords.lng;
      final resolvedAddress = _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : '$_selectedDistrict, Sri Lanka';

      final request = JobRequest(
        customerId: user.uid,
        customerName: user.displayName ?? user.email?.split('@').first ?? 'Customer',
        customerPhone: user.phoneNumber ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        photoUrls: photoUrls,
        latitude: resolvedLat,
        longitude: resolvedLng,
        address: resolvedAddress,
      );

      final requestId =
          await JobRequestRepository().createJobRequest(request);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => JobQuotesScreen(
              requestId: requestId,
              jobTitle: request.title,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n.failedToSubmitRequest}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.themeBg,
        leading: Center(
          child: IconSquareButton.small(
            icon: Icons.chevron_left_rounded,
            onTap: () => Navigator.maybePop(context),
          ),
        ),
        title: Text(
          context.l10n.postJobGetQuotes,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: context.themeInk,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              AppCard(
                color: context.themeAmberTint,
                borderColor: AppColors.primary.withValues(alpha: 0.3),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.campaign_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.describeJobOrRepair,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: context.themeInk,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.describeJobSubtitle,
                            style: TextStyle(
                              fontSize: 12,
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

              const SizedBox(height: 18),
              Text(
                context.l10n.category,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: context.themeInk,
                ),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<CategoryRow>>(
                stream: CategoryRepository().streamCategoryRows(),
                builder: (context, snapshot) {
                  final dbCategories = (snapshot.data ?? [])
                      .where((c) => c.status.toLowerCase() == 'active')
                      .map((c) => c.name)
                      .toList();
                  final categoryList =
                      dbCategories.isNotEmpty ? dbCategories : _categories;

                  return DropdownButtonFormField<String>(
                    initialValue: categoryList.contains(_selectedCategory) ? _selectedCategory : null,
                    decoration: InputDecoration(
                      hintText: context.l10n.selectTradeCategory,
                      hintStyle:
                          TextStyle(fontSize: 13, color: context.themeTextSecondary),
                      filled: true,
                      fillColor: context.themeSurfaceLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: context.themeBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: context.themeBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.primary, width: 2),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: categoryList
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(
                                LocalizedData.getCategory(context, c),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? context.l10n.selectCategoryError
                        : null,
                  );
                },
              ),

              const SizedBox(height: 16),
              Text(context.l10n.jobTitle,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(fontSize: 13),
                decoration: _inputDecoration(
                  context,
                  hint: context.l10n.jobTitleHint,
                  icon: Icons.title,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.l10n.enterJobTitleError
                    : null,
              ),

              const SizedBox(height: 16),
              Text(context.l10n.jobDescription,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(fontSize: 13),
                maxLines: 4,
                decoration: _inputDecoration(
                  context,
                  hint: context.l10n.jobDescriptionHint,
                  icon: Icons.notes,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.l10n.addDescriptionError
                    : null,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.l10n.photosOfIssue,
                      style:
                          const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                  Text('${_photos.length}/$_maxPhotos',
                      style: TextStyle(
                          fontSize: 11.5, color: context.themeTextSecondary)),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._photos.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(entry.value.path),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _photos.removeAt(entry.key)),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (_photos.length < _maxPhotos)
                      GestureDetector(
                        onTap: _showPhotoSourceSheet,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: context.themeSurfaceLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                width: 1.5),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined,
                                  color: AppColors.primary.withValues(alpha: 0.7),
                                  size: 26),
                              const SizedBox(height: 4),
                              Text(context.l10n.add,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: context.themeTextSecondary,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                context.l10n.serviceLocation,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: context.themeInk,
                ),
              ),
              const SizedBox(height: 8),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.districtLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.themeTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDistrict,
                      dropdownColor: context.themeSurface,
                      style: TextStyle(color: context.themeInk, fontSize: 13.5),
                      decoration: _inputDecoration(
                        context,
                        hint: context.l10n.selectDistrict,
                        icon: Icons.map_outlined,
                      ),
                      items: LocationUtils.districtCoordinates.keys.map((d) {
                        return DropdownMenuItem(
                          value: d,
                          child: Text(LocalizedData.getDistrict(context, d)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedDistrict = val;
                            final coords =
                                LocationUtils.getDistrictCoordinates(val);
                            _latitude = coords.lat;
                            _longitude = coords.lng;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    Text(
                      context.l10n.addressOrAreaOptional,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.themeTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _addressController,
                      style: TextStyle(fontSize: 13.5, color: context.themeInk),
                      decoration: _inputDecoration(
                        context,
                        hint: context.l10n.addressOrAreaHint,
                        icon: Icons.home_outlined,
                      ),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: _detectingLocation ? null : _detectLocation,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: context.themeSoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.themeBorder),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_detectingLocation)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            else
                              Icon(
                                _latitude != null && _detectingLocation == false
                                    ? Icons.my_location_rounded
                                    : Icons.location_searching_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                            const SizedBox(width: 8),
                            Text(
                              _detectingLocation
                                  ? context.l10n.detectingGps
                                  : (_latitude != null
                                      ? context.l10n.gpsLocationSet
                                      : context.l10n.useExactLiveGps),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
              SizedBox(
                height: 54,
                child: PrimaryButton(
                  label: context.l10n.postJobGetQuotes,
                  loading: _submitting,
                  onPressed: _submitRequest,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context,
      {required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 13, color: context.themeMuted),
      prefixIcon: Icon(icon, size: 20, color: context.themeMuted),
      filled: true,
      fillColor: context.themeSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: context.themeBorder, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: context.themeBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    );
  }
}
