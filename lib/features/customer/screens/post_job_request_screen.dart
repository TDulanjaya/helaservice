import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/app_theme.dart';
import '../../../models/job_request.dart';
import '../../../models/job_location.dart';
import '../../../models/admin_models.dart';
import '../../../repositories/job_request_repository.dart';
import '../../../repositories/category_repository.dart';
import '../../../utils/l10n_extension.dart';
import 'job_quotes_screen.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/icon_square_button.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/job_location_picker.dart';
import '../../../services/storage_service.dart';
import '../../../utils/permission_utils.dart';

class PostJobRequestScreen extends StatefulWidget {
  const PostJobRequestScreen({super.key});

  @override
  State<PostJobRequestScreen> createState() => _PostJobRequestScreenState();
}

class _PostJobRequestScreenState extends State<PostJobRequestScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  String? _selectedCategory;
  JobLocation? _selectedLocation;
  final List<XFile> _photos = [];
  bool _submitting = false;
  String _bookingType = 'asap';
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  String _scheduledSlot = 'morning';

  static const int _maxPhotos = 4;

  String _getSlotLabel(BuildContext context, String slotKey) {
    switch (slotKey) {
      case 'morning':
        return context.l10n.slotMorning;
      case 'afternoon':
        return context.l10n.slotAfternoon;
      case 'evening':
        return context.l10n.slotEvening;
      default:
        return slotKey;
    }
  }

  Future<void> _pickScheduledDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate.isBefore(now) ? now : _scheduledDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (_photos.length >= _maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.maxPhotosAllowed)),
      );
      return;
    }

    if (source == ImageSource.camera) {
      final allowed = await PermissionUtils.requestCameraWithRationale(context);
      if (!allowed) return;
    } else {
      final allowed = await PermissionUtils.requestGalleryWithRationale(context);
      if (!allowed) return;
    }

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
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
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
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

  Future<void> _pickLocation() async {
    final result = await JobLocationPicker.pickLocation(
      context,
      initialLocation: _selectedLocation,
    );

    if (result != null) {
      setState(() => _selectedLocation = result);
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

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pleaseSelectServiceLocation),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final scheduledSlotLabel =
        _bookingType == 'scheduled' ? _getSlotLabel(context, _scheduledSlot) : null;

    setState(() => _submitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Not logged in');
      }

      final List<String> photoUrls = [];
      for (final photo in _photos) {
        final uploaded =
            await StorageService.instance.uploadFile(File(photo.path));
        photoUrls.add(uploaded);
      }

      final request = JobRequest(
        customerId: user.uid,
        customerName:
            user.displayName ?? user.email?.split('@').first ?? 'Customer',
        customerPhone: user.phoneNumber ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        photoUrls: photoUrls,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        district: _selectedLocation!.label,
        address: _selectedLocation!.address,
        landmark: _selectedLocation!.landmark,
        bookingType: _bookingType,
        scheduledDate: _bookingType == 'scheduled' ? _scheduledDate : null,
        scheduledSlot: scheduledSlotLabel,
      );

      final requestId = await JobRequestRepository().createJobRequest(request);

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

              // category picker
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
                stream: CategoryRepository().streamLiveCategories(),
                builder: (context, snapshot) {
                  final dbCategories = snapshot.data ?? [];
                  if (dbCategories.isEmpty &&
                      snapshot.connectionState != ConnectionState.waiting) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: context.themeSurfaceLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.themeBorder),
                      ),
                      child: Text(
                        'No services available yet',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.themeTextSecondary,
                        ),
                      ),
                    );
                  }

                  return DropdownButtonFormField<String>(
                    initialValue: dbCategories.any((c) => c.id == _selectedCategory)
                        ? _selectedCategory
                        : null,
                    decoration: InputDecoration(
                      hintText: context.l10n.selectTradeCategory,
                      hintStyle: TextStyle(
                          fontSize: 13, color: context.themeTextSecondary),
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
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    items: dbCategories
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(
                                c.name,
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

              // job title
              Text(context.l10n.jobTitle,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800)),
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

              // job description
              Text(context.l10n.jobDescription,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800)),
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

              // photos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.l10n.photosOfIssue,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800)),
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
                                  color:
                                      AppColors.primary.withValues(alpha: 0.7),
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
              const SizedBox(height: 20),

              // timing selection
              Text(
                context.l10n.selectTimeSlot,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: context.themeInk,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _bookingType = 'asap'),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                        decoration: BoxDecoration(
                          color: _bookingType == 'asap'
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : context.themeSurfaceLow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _bookingType == 'asap'
                                ? AppColors.primary
                                : context.themeBorder,
                            width: _bookingType == 'asap' ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 18,
                              color: _bookingType == 'asap' ? AppColors.primary : context.themeTextSecondary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                context.l10n.bookingTypeAsap,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: _bookingType == 'asap' ? FontWeight.w800 : FontWeight.w600,
                                  color: _bookingType == 'asap' ? AppColors.primary : context.themeInk,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _bookingType = 'scheduled'),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                        decoration: BoxDecoration(
                          color: _bookingType == 'scheduled'
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : context.themeSurfaceLow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _bookingType == 'scheduled'
                                ? AppColors.primary
                                : context.themeBorder,
                            width: _bookingType == 'scheduled' ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 18,
                              color: _bookingType == 'scheduled' ? AppColors.primary : context.themeTextSecondary,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                context.l10n.bookingTypeScheduled,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: _bookingType == 'scheduled' ? FontWeight.w800 : FontWeight.w600,
                                  color: _bookingType == 'scheduled' ? AppColors.primary : context.themeInk,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_bookingType == 'scheduled') ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _pickScheduledDate(context),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: context.themeSurfaceLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.themeBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_note_rounded, size: 20, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text(
                          '${_scheduledDate.year}/${_scheduledDate.month.toString().padLeft(2, '0')}/${_scheduledDate.day.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: context.themeInk,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Column(
                  children: ['morning', 'afternoon', 'evening'].map((slot) {
                    final isSel = _scheduledSlot == slot;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        onTap: () => setState(() => _scheduledSlot = slot),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            color: isSel
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : context.themeSurfaceLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSel ? AppColors.primary : context.themeBorder,
                              width: isSel ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSel ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                color: isSel ? AppColors.primary : context.themeTextSecondary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _getSlotLabel(context, slot),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                    color: isSel ? AppColors.primary : context.themeInk,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 20),

              // service location selection
              Text(
                '${context.l10n.serviceLocation} *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: context.themeInk,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickLocation,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.themeSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedLocation != null
                          ? AppColors.primary
                          : context.themeBorder,
                      width: _selectedLocation != null ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _selectedLocation != null
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : Colors.black.withValues(
                                alpha: context.isDark ? 0.2 : 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _selectedLocation != null
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : context.themeSurfaceLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _selectedLocation != null
                              ? Icons.location_on_rounded
                              : Icons.add_location_alt_rounded,
                          color: _selectedLocation != null
                              ? AppColors.primary
                              : context.themeTextSecondary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedLocation != null
                                  ? (_selectedLocation!.label ?? 'Job Location')
                                  : 'Select Job Location',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: context.themeInk,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _selectedLocation != null
                                  ? _selectedLocation!.address
                                  : 'Tap to pick via GPS, map pin, or saved addresses',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.themeTextSecondary,
                              ),
                            ),
                            if (_selectedLocation?.landmark != null &&
                                _selectedLocation!.landmark!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Note: ${_selectedLocation!.landmark}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _selectedLocation != null ? 'Change' : 'Set Pin',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: AppColors.primary, size: 18),
                    ],
                  ),
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    );
  }
}
