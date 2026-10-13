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
import '../../../utils/schedule_helpers.dart';
import 'job_quotes_screen.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/icon_square_button.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/job_location_picker.dart';
import '../../../services/storage_service.dart';
import '../../../services/video_service.dart';
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
  ProcessedVideoResult? _processedVideo;
  bool _processingVideo = false;
  String? _uploadProgressText;
  double _uploadProgressFraction = 0.0;
  bool _uploadFailed = false;
  bool _submitting = false;
  String _scheduleMode = ScheduleHelpers.modeAsap;
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _fromTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _toTime = const TimeOfDay(hour: 12, minute: 0);

  static const int _maxPhotos = 10;

  Future<void> _pickScheduledDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate.isBefore(now) ? now : _scheduledDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _pickScheduledTime(BuildContext context, bool isFrom) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isFrom ? _fromTime : _toTime,
    );
    if (picked != null) {
      final snappedMinute = (picked.minute / 15).round() * 15;
      final adjusted = snappedMinute == 60
          ? TimeOfDay(hour: (picked.hour + 1) % 24, minute: 0)
          : TimeOfDay(hour: picked.hour, minute: snappedMinute);

      setState(() {
        if (isFrom) {
          _fromTime = adjusted;
        } else {
          _toTime = adjusted;
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<bool> _confirmLargeFileIfExceeds20Mb(String path) async {
    try {
      final size = await File(path).length();
      if (size > 20 * 1024 * 1024) {
        if (!mounted) return false;
        final res = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: ctx.themeSurface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              context.l10n.largeMediaWarningTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: Text(
              context.l10n.largeMediaWarningMessage,
              style: TextStyle(fontSize: 13, color: ctx.themeTextSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(context.l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(context.l10n.proceed),
              ),
            ],
          ),
        );
        return res ?? false;
      }
    } catch (_) {}
    return true;
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
        final ok = await _confirmLargeFileIfExceeds20Mb(picked.path);
        if (ok && mounted) {
          setState(() => _photos.add(picked));
        }
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

  void _showVideoSourceSheet() {
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
              Text(context.l10n.addIssueVideoMax,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.videocam_rounded, color: AppColors.primary),
                title: Text(context.l10n.recordVideo),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickVideo(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library_rounded, color: AppColors.primary),
                title: Text(context.l10n.chooseFromGallery),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickVideo(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickVideo(ImageSource source) async {
    if (source == ImageSource.camera) {
      final allowed = await PermissionUtils.requestCameraWithRationale(context);
      if (!allowed) return;
    } else {
      final allowed = await PermissionUtils.requestGalleryWithRationale(context);
      if (!allowed) return;
    }

    try {
      final picked = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 120),
      );
      if (picked == null) return;
      final ok = await _confirmLargeFileIfExceeds20Mb(picked.path);
      if (!ok) return;

      setState(() => _processingVideo = true);

      try {
        final processed = await VideoService.instance.processJobVideo(File(picked.path));
        setState(() {
          _processedVideo = processed;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().contains('120')
                  ? context.l10n.videoExceedsMax120s
                  : context.l10n.failedToProcessVideo('$e')),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _processingVideo = false);
      }
    } catch (e) {
      debugPrint('Error picking video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorPickingVideo), backgroundColor: AppColors.error),
        );
      }
    }
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

    final schedRes = ScheduleHelpers.computeScheduleWindow(
      mode: _scheduleMode,
      date: _scheduledDate,
      fromTime: _fromTime,
      toTime: _toTime,
    );
    if (!schedRes.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(schedRes.errorMessage ?? 'Invalid schedule selection'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final defaultCustomerRole = context.l10n.roleCustomer;
    final timeRangeSlot = '${_fromTime.format(context)} - ${_toTime.format(context)}';

    setState(() {
      _submitting = true;
      _uploadFailed = false;
      _uploadProgressFraction = 0.0;
      _uploadProgressText = 'Preparing media...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Not logged in');
      }

      final List<JobMediaItem> photosList = [];
      for (int i = 0; i < _photos.length; i++) {
        setState(() {
          _uploadProgressFraction = 0.0;
          _uploadProgressText = 'Uploading photo ${i + 1} of ${_photos.length}...';
        });
        final rawBytes = await File(_photos[i].path).readAsBytes();
        final stripped = StorageService.instance.stripExifAndCompressImage(rawBytes);
        JobMediaUploadResult? res;
        for (int attempt = 0; attempt < 3; attempt++) {
          try {
            final photoName = 'photo_$i.jpg';
            res = await StorageService.instance.uploadJobMedia(
              bytes: stripped,
              filename: photoName,
              contentType: 'image/jpeg',
              onProgress: (sent, total) {
                if (mounted) {
                  setState(() {
                    _uploadProgressFraction = total > 0 ? (sent / total) : 0.0;
                    final sentMb = (sent / (1024 * 1024)).toStringAsFixed(1);
                    final totalMb = (total / (1024 * 1024)).toStringAsFixed(1);
                    _uploadProgressText = 'Photo ${i + 1}/${_photos.length}: $sentMb MB / $totalMb MB';
                  });
                }
              },
            );
            break;
          } catch (e) {
            if (attempt == 2) {
              setState(() => _uploadFailed = true);
              rethrow;
            }
            await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          }
        }
        if (res != null) {
          photosList.add(JobMediaItem(url: res.url, key: res.key));
        }
      }

      JobVideoItem? videoItem;
      if (_processedVideo != null) {
        setState(() {
          _uploadProgressFraction = 0.0;
          _uploadProgressText = 'Uploading video thumbnail...';
        });
        final thumbBytes = await _processedVideo!.thumbnailFile.readAsBytes();
        final thumbStripped = StorageService.instance.stripExifAndCompressImage(thumbBytes);
        JobMediaUploadResult? thumbRes;
        for (int attempt = 0; attempt < 3; attempt++) {
          try {
            thumbRes = await StorageService.instance.uploadJobMedia(
              bytes: thumbStripped,
              filename: 'video_thumb.jpg',
              contentType: 'image/jpeg',
            );
            break;
          } catch (e) {
            if (attempt == 2) {
              setState(() => _uploadFailed = true);
              rethrow;
            }
            await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          }
        }

        setState(() {
          _uploadProgressFraction = 0.0;
          _uploadProgressText = 'Uploading video file...';
        });
        final videoBytes = await _processedVideo!.compressedFile.readAsBytes();
        JobMediaUploadResult? videoRes;
        for (int attempt = 0; attempt < 3; attempt++) {
          try {
            const videoName = 'video.mp4';
            videoRes = await StorageService.instance.uploadJobMedia(
              bytes: videoBytes,
              filename: videoName,
              contentType: 'video/mp4',
              onProgress: (sent, total) {
                if (mounted) {
                  setState(() {
                    _uploadProgressFraction = total > 0 ? (sent / total) : 0.0;
                    final sentMb = (sent / (1024 * 1024)).toStringAsFixed(1);
                    final totalMb = (total / (1024 * 1024)).toStringAsFixed(1);
                    _uploadProgressText = 'Video: $sentMb MB / $totalMb MB';
                  });
                }
              },
            );
            break;
          } catch (e) {
            if (attempt == 2) {
              setState(() => _uploadFailed = true);
              rethrow;
            }
            await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          }
        }

        if (thumbRes != null && videoRes != null) {
          videoItem = JobVideoItem(
            url: videoRes.url,
            key: videoRes.key,
            thumbUrl: thumbRes.url,
            durationSec: _processedVideo!.durationSec,
          );
        }
      }

      final request = JobRequest(
        customerId: user.uid,
        customerName:
            user.displayName ?? user.email?.split('@').first ?? defaultCustomerRole,
        customerPhone: user.phoneNumber ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        photoUrls: photosList.map((p) => p.url).toList(),
        photos: photosList,
        video: videoItem,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        district: _selectedLocation!.label,
        address: _selectedLocation!.address,
        landmark: _selectedLocation!.landmark,
        accuracyMeters: _selectedLocation!.accuracyMeters,
        houseNo: _selectedLocation!.houseNo,
        street: _selectedLocation!.street,
        city: _selectedLocation!.city,
        directions: _selectedLocation!.directions,
        bookingType: _scheduleMode == ScheduleHelpers.modeAsap ? 'asap' : 'scheduled',
        scheduleMode: _scheduleMode,
        scheduledDate: schedRes.scheduledDate,
        scheduledStartAt: schedRes.scheduledStartAt,
        scheduledEndAt: schedRes.scheduledEndAt,
        scheduledSlot: _scheduleMode == ScheduleHelpers.modeDateOnly
            ? 'anytime'
            : (_scheduleMode == ScheduleHelpers.modeTimeRange
                ? timeRangeSlot
                : null),
      );

      final requestId = await JobRequestRepository().createJobRequest(request);

      // Clean up local temp video caches
      await VideoService.instance.cleanCache();

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
        setState(() {
          _uploadFailed = true;
          _uploadProgressText = 'Upload failed: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n.failedToSubmitRequest}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          if (!_uploadFailed) {
            _uploadProgressText = null;
          }
        });
      }
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
                        context.l10n.noServicesAvailableYet,
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
              const SizedBox(height: 16),

              // video section (optional, max 120s)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.l10n.videoOfIssueOptional,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w800)),
                  Text(_processedVideo != null ? '1/1' : '0/1 (max 120s)',
                      style: TextStyle(
                          fontSize: 11.5, color: context.themeTextSecondary)),
                ],
              ),
              const SizedBox(height: 8),
              if (_processingVideo)
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: context.themeSurfaceLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.themeBorder),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          context.l10n.optimizingVideoNotice,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_processedVideo != null)
                Row(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _processedVideo!.thumbnailFile,
                            width: 120,
                            height: 85,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned.fill(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${_processedVideo!.durationSec}s',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _processedVideo = null;
                            }),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else
                InkWell(
                  onTap: _showVideoSourceSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 64,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: context.themeSurfaceLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.videocam_outlined, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                context.l10n.addShortVideo,
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                context.l10n.addShortVideoSubtitle,
                                style: TextStyle(fontSize: 11, color: context.themeTextSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

              // Mode chips: ASAP, Date Only, Time Range
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded, size: 16),
                        const SizedBox(width: 4),
                        Text(context.l10n.scheduleModeAsap),
                      ],
                    ),
                    selected: _scheduleMode == ScheduleHelpers.modeAsap,
                    onSelected: (sel) {
                      if (sel) setState(() => _scheduleMode = ScheduleHelpers.modeAsap);
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _scheduleMode == ScheduleHelpers.modeAsap
                          ? AppColors.primary
                          : context.themeTextSecondary,
                    ),
                  ),
                  ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 16),
                        const SizedBox(width: 4),
                        Text(context.l10n.scheduleModeDateOnly),
                      ],
                    ),
                    selected: _scheduleMode == ScheduleHelpers.modeDateOnly,
                    onSelected: (sel) {
                      if (sel) setState(() => _scheduleMode = ScheduleHelpers.modeDateOnly);
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _scheduleMode == ScheduleHelpers.modeDateOnly
                          ? AppColors.primary
                          : context.themeTextSecondary,
                    ),
                  ),
                  ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded, size: 16),
                        const SizedBox(width: 4),
                        Text(context.l10n.scheduleModeTimeRange),
                      ],
                    ),
                    selected: _scheduleMode == ScheduleHelpers.modeTimeRange,
                    onSelected: (sel) {
                      if (sel) setState(() => _scheduleMode = ScheduleHelpers.modeTimeRange);
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _scheduleMode == ScheduleHelpers.modeTimeRange
                          ? AppColors.primary
                          : context.themeTextSecondary,
                    ),
                  ),
                ],
              ),

              if (_scheduleMode != ScheduleHelpers.modeAsap) ...[
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
                if (ScheduleHelpers.isToday(_scheduledDate) && !ScheduleHelpers.canChooseTodayForDateOnly()) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.l10n.scheduleTodayPastCutoff,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.warning),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],

              if (_scheduleMode == ScheduleHelpers.modeDateOnly) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.l10n.scheduleAnyTime,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_scheduleMode == ScheduleHelpers.modeTimeRange) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.scheduleFrom,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () => _pickScheduledTime(context, true),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: context.themeSurfaceLow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.themeBorder),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _fromTime.format(context),
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                  ),
                                  const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.scheduleTo,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () => _pickScheduledTime(context, false),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: context.themeSurfaceLow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.themeBorder),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _toTime.format(context),
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                  ),
                                  const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                                  ? (_selectedLocation!.label ?? context.l10n.selectJobLocation)
                                  : context.l10n.selectJobLocation,
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
                                  : context.l10n.tapToPickLocationDesc,
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
                        _selectedLocation != null ? context.l10n.change : context.l10n.setPin,
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

              if (_uploadProgressText != null || _uploadFailed) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _uploadFailed
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _uploadFailed
                          ? AppColors.error.withValues(alpha: 0.3)
                          : AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (_submitting) ...[
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                          ] else if (_uploadFailed) ...[
                            const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.error),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              _uploadProgressText ?? context.l10n.uploadFailedAttempts,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: _uploadFailed ? AppColors.error : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_submitting && _uploadProgressFraction > 0) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _uploadProgressFraction,
                            minHeight: 6,
                            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                      ],
                      if (_uploadFailed) ...[
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _submitRequest,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: Text(context.l10n.uploadRetry),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (_selectedLocation == null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_off_rounded, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.l10n.locationRequiredHint,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: PrimaryButton(
                  label: context.l10n.postJobGetQuotes,
                  loading: _submitting,
                  onPressed: (_selectedLocation == null || _submitting)
                      ? null
                      : _submitRequest,
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
