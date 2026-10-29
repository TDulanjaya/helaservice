import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../../theme/app_theme.dart';
import '../../../models/job_request.dart';
import '../../../models/job_location.dart';
import '../../../models/admin_models.dart';
import '../../../repositories/job_request_repository.dart';
import '../../../repositories/category_repository.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/schedule_helpers.dart';
import 'job_quotes_screen.dart';
import 'emergency_dispatch_screen.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/icon_square_button.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/job_location_picker.dart';
import '../../../services/storage_service.dart';
import '../../../services/video_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/connectivity_service.dart';
import '../../../services/api_client.dart';
import '../../../services/error_reporter.dart';
import '../../../constants/app_config.dart';
import '../../../constants/firestore_paths.dart';
import '../../../utils/location_utils.dart';
import '../../../utils/permission_utils.dart';
import '../../../utils/ticket_error_l10n.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// upload error
class MediaUploadException implements Exception {
  final String message;
  final int? statusCode;
  final bool isRetryable;
  const MediaUploadException(this.message,
      {this.statusCode, this.isRetryable = true});

  @override
  String toString() => message;
}

class PostJobRequestScreen extends StatefulWidget {
  final JobRequest? editJob;
  final JobRequest? prefillJob;

  const PostJobRequestScreen({
    super.key,
    this.editJob,
    this.prefillJob,
  });

  bool get isEditMode => editJob != null;
  bool get isPrefillMode => prefillJob != null;

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
  final List<PickedAttachment> _photos = [];
  final Map<PickedAttachment, JobMediaItem> _uploadedPhotos = {};
  ProcessedVideoResult? _processedVideo;
  JobVideoItem? _uploadedVideoItem;
  JobMediaUploadResult? _uploadedVideoThumb;
  ProcessedVideoResult? _uploadedVideoSource;
  bool _processingVideo = false;
  String? _uploadProgressText;
  double _uploadProgressFraction = 0.0;
  bool _uploadFailed = false;
  bool _saveFailed = false;
  String? _debugErrorDetails;
  bool _submitting = false;
  int _submitGeneration = 0;
  bool _isUploadingMedia = false;
  String _scheduleMode = ScheduleHelpers.modeToday;
  String _scheduledSlot = ScheduleHelpers.slotAnytime;
  DateTime _scheduledDate = DateTime.now();
  TimeOfDay _fromTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _toTime = const TimeOfDay(hour: 12, minute: 0);
  int _flexibleDays = 7;
  bool _loadingInitialData = false;
  bool _hasSkippedOldPhotos = false;
  bool _hasVideoNotCopied = false;
  final Set<String> _originalMediaKeys = {};

  // cache category stream
  late final Stream<List<CategoryRow>> _categoriesStream =
      CategoryRepository().streamLiveCategories();

  bool get _isLocationLocked =>
      widget.isEditMode && (widget.editJob?.hasQuotes ?? false);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    if (!ScheduleHelpers.canChooseToday(now)) {
      _scheduleMode = ScheduleHelpers.modeDate;
      _scheduledDate = now.add(const Duration(days: 1));
    } else {
      _scheduleMode = ScheduleHelpers.modeToday;
      _scheduledDate = now;
      if (!ScheduleHelpers.isSlotAvailableToday(
          ScheduleHelpers.slotAnytime, now)) {
        _scheduledSlot = ScheduleHelpers.slotEvening;
      }
    }

    final initialJob = widget.editJob ?? widget.prefillJob;
    if (initialJob != null) {
      _titleController.text = initialJob.title;
      _descriptionController.text = initialJob.description;
      _selectedCategory = initialJob.category;
      if (widget.isEditMode ||
          (widget.isPrefillMode && initialJob.scheduledDate != null)) {
        _scheduleMode = initialJob.scheduleMode;
        _scheduledSlot =
            initialJob.scheduledSlot ?? ScheduleHelpers.slotAnytime;
        if (initialJob.scheduledDate != null) {
          _scheduledDate = initialJob.scheduledDate!;
        }
        if (initialJob.scheduledStartAt != null) {
          _fromTime = TimeOfDay.fromDateTime(initialJob.scheduledStartAt!);
        }
        if (initialJob.scheduledEndAt != null) {
          _toTime = TimeOfDay.fromDateTime(initialJob.scheduledEndAt!);
        }
        if (initialJob.flexibleWindowDays != null) {
          _flexibleDays = initialJob.flexibleWindowDays!;
        }
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInitialJobDetails(initialJob);
      });
    }
  }

  Future<void> _loadInitialJobDetails(JobRequest job) async {
    if (!mounted) return;
    setState(() => _loadingInitialData = true);

    try {
      // load contact location
      final contact = await JobRequestRepository().getJobPrivateContact(job.id);
      if (contact != null && mounted) {
        final lat =
            (contact['latitude'] as num?)?.toDouble() ?? job.latitude ?? 0.0;
        final lng =
            (contact['longitude'] as num?)?.toDouble() ?? job.longitude ?? 0.0;
        final address = contact['address'] as String? ?? job.address;
        final note = contact['note'] as String? ??
            contact['landmark'] as String? ??
            job.note;
        final houseNo = contact['houseNo'] as String?;
        final street = contact['street'] as String?;
        final city = contact['city'] as String?;
        final directions = contact['directions'] as String?;
        final accuracy = (contact['accuracyMeters'] as num?)?.toDouble();

        setState(() {
          _selectedLocation = JobLocation(
            latitude: lat,
            longitude: lng,
            address: address,
            label: job.district,
            note: note,
            houseNo: houseNo,
            street: street,
            city: city,
            directions: directions,
            accuracyMeters: accuracy,
          );
        });
        _updateCoverage();
      } else if (job.latitude != null && job.longitude != null && mounted) {
        setState(() {
          _selectedLocation = JobLocation(
            latitude: job.latitude!,
            longitude: job.longitude!,
            address: job.address,
            label: job.district,
            note: job.note,
          );
        });
        _updateCoverage();
      }

      // load photos
      if (widget.isPrefillMode && job.isPhotosRemoved) {
        if (mounted) {
          setState(() => _hasSkippedOldPhotos = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.oldPhotosUnavailable)),
          );
        }
      } else if (job.photos.isNotEmpty) {
        int skippedCount = 0;
        for (final p in job.photos) {
          if (!mounted) return;
          if (p.key.isNotEmpty && p.url.contains('/api/media?key=')) {
            _originalMediaKeys.add(p.key);
            try {
              final mediaUri = Uri.parse(
                  '${AppConfig.otpApiUrl}/media?key=${Uri.encodeComponent(p.key)}&mode=json');
              final res = await ApiClient.instance.get(uri: mediaUri);
              if (res.statusCode == 200) {
                final data = jsonDecode(res.body);
                final presignedUrl = data['url'] as String?;
                if (presignedUrl != null) {
                  final imgRes = await http
                      .get(Uri.parse(presignedUrl))
                      .timeout(const Duration(seconds: 15));
                  if (imgRes.statusCode == 200 && mounted) {
                    final rawBytes = imgRes.bodyBytes;
                    final attachment = PickedAttachment(
                      file:
                          XFile.fromData(rawBytes, name: p.key.split('/').last),
                      bytes: rawBytes,
                    );
                    setState(() {
                      _photos.add(attachment);
                      if (widget.isEditMode) {
                        _uploadedPhotos[attachment] = p;
                      }
                    });
                    continue;
                  }
                }
              }
              skippedCount++;
            } catch (e) {
              debugPrint('[PostJobRequest] download photo error: $e');
              skippedCount++;
            }
          } else {
            skippedCount++;
          }
        }
        if (skippedCount > 0 && mounted) {
          setState(() => _hasSkippedOldPhotos = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.oldPhotosUnavailable)),
          );
        }
      }

      // check video
      if (widget.isPrefillMode) {
        if (job.video != null && mounted) {
          setState(() => _hasVideoNotCopied = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.videoNotCopiedNote)),
          );
        }
      } else if (widget.isEditMode && job.video != null) {
        _uploadedVideoItem = job.video;
        _originalMediaKeys.add(job.video!.key);
      }
    } catch (e) {
      debugPrint('[PostJobRequest] initial details load error: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingInitialData = false);
      }
    }
  }

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

  Future<bool> _confirmLargeFileIfExceeds20Mb(int sizeBytes) async {
    try {
      if (sizeBytes > 20 * 1024 * 1024) {
        if (!mounted) return false;
        final res = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: ctx.themeSurface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
      final allowed =
          await PermissionUtils.requestGalleryWithRationale(context);
      if (!allowed) return;
    }

    try {
      // pick photo without heavy compression
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 90,
      );
      if (picked != null) {
        final length = await picked.length();
        final ok = await _confirmLargeFileIfExceeds20Mb(length);
        if (ok && mounted) {
          final bytes = await picked.readAsBytes();
          setState(
              () => _photos.add(PickedAttachment(file: picked, bytes: bytes)));
        }
      }
    } catch (e) {
      debugPrint('[PostJobRequest] Failed to pick image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.failedToPickImage),
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
                leading: const Icon(Icons.videocam_rounded,
                    color: AppColors.primary),
                title: Text(context.l10n.recordVideo),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickVideo(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library_rounded,
                    color: AppColors.primary),
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
      final allowed =
          await PermissionUtils.requestGalleryWithRationale(context);
      if (!allowed) return;
    }

    if (kIsWeb) return;
    try {
      final picked = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: 120),
      );
      if (picked == null) return;
      final length = await picked.length();
      final ok = await _confirmLargeFileIfExceeds20Mb(length);
      if (!ok) return;

      setState(() => _processingVideo = true);

      try {
        final processed =
            await VideoService.instance.processJobVideo(File(picked.path));
        setState(() {
          _processedVideo = processed;
          _uploadedVideoItem = null;
          _uploadedVideoThumb = null;
          _uploadedVideoSource = null;
        });
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[PostJobRequest] process video error: $e');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().contains('120')
                  ? context.l10n.videoExceedsMax120s
                  : context.l10n
                      .failedToProcessVideo(context.l10n.somethingWentWrong)),
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
          SnackBar(
              content: Text(context.l10n.errorPickingVideo),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  int? _coverageProviderCount;

  Future<void> _updateCoverage() async {
    final cat = _selectedCategory;
    final loc = _selectedLocation;
    if (cat == null || loc == null) {
      if (_coverageProviderCount != null) {
        setState(() => _coverageProviderCount = null);
      }
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection(FirestorePaths.technicians)
          .where('category', isEqualTo: cat)
          .where('nicVerified', isEqualTo: true)
          .get();

      int count = 0;
      for (final doc in snap.docs) {
        final d = doc.data();
        if (d['isBanned'] == true) continue;
        final baseLat = (d['baseLatitude'] as num?)?.toDouble() ??
            (d['latitude'] as num?)?.toDouble();
        final baseLng = (d['baseLongitude'] as num?)?.toDouble() ??
            (d['longitude'] as num?)?.toDouble();
        if (baseLat == null || baseLng == null) continue;
        final radius = (d['serviceRadiusKm'] as num?)?.toDouble() ?? 25.0;
        final dist = LocationUtils.calculateDistanceKm(
          loc.latitude,
          loc.longitude,
          baseLat,
          baseLng,
        );
        if (dist <= radius) {
          count++;
        }
      }

      if (mounted) {
        setState(() {
          _coverageProviderCount = count;
        });
      }
    } catch (e) {
      debugPrint('[PostJobRequest] Coverage check error: $e');
    }
  }

  Future<void> _pickLocation() async {
    if (_isLocationLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.locationLockedHasQuotes)),
      );
      return;
    }
    final result = await JobLocationPicker.pickLocation(
      context,
      initialLocation: _selectedLocation,
    );

    if (result != null) {
      setState(() => _selectedLocation = result);
      _updateCoverage();
    }
  }

  Completer<void>? _currentUploadCancelCompleter;

  // pause while offline
  Future<void> _waitForConnectionIfNeeded(int currentGen) async {
    if (_submitGeneration != currentGen) return;
    if (!ConnectivityService.instance.isOffline) return;

    final prevText = _uploadProgressText;
    if (mounted && _submitGeneration == currentGen) {
      setState(() {
        _uploadProgressText = context.l10n.waitingForConnection;
      });
    }

    final completer = Completer<void>();
    void listener() {
      if (!ConnectivityService.instance.isOffline && !completer.isCompleted) {
        completer.complete();
      }
    }

    ConnectivityService.instance.isOfflineNotifier.addListener(listener);
    try {
      while (ConnectivityService.instance.isOffline &&
          _submitGeneration == currentGen) {
        await Future.any([
          completer.future,
          Future.delayed(const Duration(seconds: 1)),
        ]);
      }
    } finally {
      ConnectivityService.instance.isOfflineNotifier.removeListener(listener);
    }

    if (mounted && _submitGeneration == currentGen && prevText != null) {
      setState(() {
        _uploadProgressText = prevText;
      });
    }
  }

  void _cancelMediaUpload() {
    if (!_submitting || !_isUploadingMedia) return;
    _submitGeneration++;
    if (_currentUploadCancelCompleter != null &&
        !_currentUploadCancelCompleter!.isCompleted) {
      _currentUploadCancelCompleter!.complete();
    }
    if (mounted) {
      setState(() {
        _submitting = false;
        _isUploadingMedia = false;
        _uploadFailed = false;
        _saveFailed = false;
        _uploadProgressFraction = 0.0;
        _uploadProgressText = null;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_submitting) return;
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
      slot: _scheduledSlot,
      date: _scheduledDate,
      fromTime: _fromTime,
      toTime: _toTime,
      flexibleDays: _flexibleDays,
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

    DateTime? finalStartAt = schedRes.scheduledStartAt;
    DateTime? finalEndAt = schedRes.scheduledEndAt;
    final isToday = _scheduleMode == ScheduleHelpers.modeToday ||
        (_scheduleMode == ScheduleHelpers.modeDate &&
            ScheduleHelpers.isToday(_scheduledDate));
    if (isToday && finalStartAt != null && finalEndAt != null) {
      // clamp window to now when scheduled for today
      final clamped = ScheduleHelpers.clampWindowToNow(
        startAt: finalStartAt,
        endAt: finalEndAt,
      );
      if (clamped.hasPassed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.timePassedChooseLater),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      finalStartAt = clamped.startAt;
      finalEndAt = clamped.endAt;
    }

    final defaultCustomerRole = context.l10n.roleCustomer;

    _submitGeneration++;
    final currentGen = _submitGeneration;
    final hasMediaToUpload = _photos.isNotEmpty || _processedVideo != null;

    setState(() {
      _submitting = true;
      _isUploadingMedia = hasMediaToUpload;
      _uploadFailed = false;
      _saveFailed = false;
      _uploadProgressFraction = 0.0;
      _uploadProgressText = context.l10n.preparingMedia;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Not logged in');
      }

      if (_submitGeneration != currentGen) return;

      final List<JobMediaItem> photosList = [];
      for (int i = 0; i < _photos.length; i++) {
        if (_submitGeneration != currentGen) return;

        final attachment = _photos[i];
        if (_uploadedPhotos.containsKey(attachment)) {
          photosList.add(_uploadedPhotos[attachment]!);
          continue;
        }

        if (mounted && _submitGeneration == currentGen) {
          setState(() {
            _uploadProgressFraction = 0.0;
            _uploadProgressText =
                context.l10n.uploadingPhotoProgress(i + 1, _photos.length);
          });
        }
        final rawBytes = attachment.bytes;
        final stripped =
            await StorageService.instance.stripExifAndCompressImage(rawBytes);

        if (_submitGeneration != currentGen) return;

        const retryDelays = [
          Duration(seconds: 2),
          Duration(seconds: 5),
          Duration(seconds: 10),
        ];

        JobMediaUploadResult? res;
        for (int attempt = 0; attempt < 3; attempt++) {
          if (_submitGeneration != currentGen) return;
          await _waitForConnectionIfNeeded(currentGen);
          if (_submitGeneration != currentGen) return;

          try {
            final photoName = 'photo_$i.jpg';
            final cancelCompleter = Completer<void>();
            _currentUploadCancelCompleter = cancelCompleter;
            res = await StorageService.instance.uploadJobMedia(
              bytes: stripped,
              filename: photoName,
              contentType: 'image/jpeg',
              cancelTrigger: cancelCompleter.future,
              onProgress: (sent, total) {
                if (mounted && _submitGeneration == currentGen) {
                  setState(() {
                    _uploadProgressFraction = total > 0 ? (sent / total) : 0.0;
                    final sentMb = (sent / (1024 * 1024)).toStringAsFixed(1);
                    final totalMb = (total / (1024 * 1024)).toStringAsFixed(1);
                    _uploadProgressText = context.l10n.uploadPhotoBytesProgress(
                        i + 1, _photos.length, sentMb, totalMb);
                  });
                }
              },
            );
            break;
          } catch (e) {
            if (_submitGeneration != currentGen) return;
            debugPrint('[PostJobRequest] photo $i attempt $attempt error: $e');

            // do not retry 4xx
            if (e is MediaUploadHttpException && !e.isRetryable) {
              throw MediaUploadException(
                e.message,
                statusCode: e.statusCode,
                isRetryable: false,
              );
            }

            if (attempt == 2) {
              final code = e is MediaUploadHttpException ? e.statusCode : null;
              throw MediaUploadException('Photo ${i + 1} upload failed: $e',
                  statusCode: code);
            }

            // backoff
            await Future.delayed(retryDelays[attempt]);
            if (_submitGeneration != currentGen) return;
            await _waitForConnectionIfNeeded(currentGen);
            if (_submitGeneration != currentGen) return;
          }
        }
        if (_submitGeneration != currentGen) return;
        if (res != null) {
          final item = JobMediaItem(url: res.url, key: res.key);
          _uploadedPhotos[attachment] = item;
          photosList.add(item);
        }
      }

      JobVideoItem? videoItem;
      if (_processedVideo != null) {
        if (_submitGeneration != currentGen) return;
        if (_uploadedVideoItem != null &&
            _uploadedVideoSource == _processedVideo) {
          videoItem = _uploadedVideoItem;
        } else {
          JobMediaUploadResult? thumbRes = _uploadedVideoThumb;
          if (thumbRes == null || _uploadedVideoSource != _processedVideo) {
            if (mounted && _submitGeneration == currentGen) {
              setState(() {
                _uploadProgressFraction = 0.0;
                _uploadProgressText = context.l10n.uploadingVideoThumbnail;
              });
            }
            final thumbBytes =
                await _processedVideo!.thumbnailFile.readAsBytes();
            if (_submitGeneration != currentGen) return;

            final thumbStripped = await StorageService.instance
                .stripExifAndCompressImage(thumbBytes);
            if (_submitGeneration != currentGen) return;

            const retryDelays = [
              Duration(seconds: 2),
              Duration(seconds: 5),
              Duration(seconds: 10),
            ];

            for (int attempt = 0; attempt < 3; attempt++) {
              if (_submitGeneration != currentGen) return;
              await _waitForConnectionIfNeeded(currentGen);
              if (_submitGeneration != currentGen) return;

              try {
                final cancelCompleter = Completer<void>();
                _currentUploadCancelCompleter = cancelCompleter;
                thumbRes = await StorageService.instance.uploadJobMedia(
                  bytes: thumbStripped,
                  filename: 'video_thumb.jpg',
                  contentType: 'image/jpeg',
                  cancelTrigger: cancelCompleter.future,
                );
                _uploadedVideoThumb = thumbRes;
                break;
              } catch (e) {
                if (_submitGeneration != currentGen) return;
                debugPrint(
                    '[PostJobRequest] video thumb attempt $attempt error: $e');

                // do not retry 4xx
                if (e is MediaUploadHttpException && !e.isRetryable) {
                  throw MediaUploadException(
                    e.message,
                    statusCode: e.statusCode,
                    isRetryable: false,
                  );
                }

                if (attempt == 2) {
                  final code =
                      e is MediaUploadHttpException ? e.statusCode : null;
                  throw MediaUploadException('Video thumb upload failed: $e',
                      statusCode: code);
                }

                await Future.delayed(retryDelays[attempt]);
                if (_submitGeneration != currentGen) return;
                await _waitForConnectionIfNeeded(currentGen);
                if (_submitGeneration != currentGen) return;
              }
            }
          }

          if (_submitGeneration != currentGen) return;

          if (mounted && _submitGeneration == currentGen) {
            setState(() {
              _uploadProgressFraction = 0.0;
              _uploadProgressText = context.l10n.uploadingVideoFile;
            });
          }
          final videoBytes =
              await _processedVideo!.compressedFile.readAsBytes();
          if (_submitGeneration != currentGen) return;

          const retryDelays = [
            Duration(seconds: 2),
            Duration(seconds: 5),
            Duration(seconds: 10),
          ];

          JobMediaUploadResult? videoRes;
          for (int attempt = 0; attempt < 3; attempt++) {
            if (_submitGeneration != currentGen) return;
            await _waitForConnectionIfNeeded(currentGen);
            if (_submitGeneration != currentGen) return;

            try {
              const videoName = 'video.mp4';
              final cancelCompleter = Completer<void>();
              _currentUploadCancelCompleter = cancelCompleter;
              videoRes = await StorageService.instance.uploadJobMedia(
                bytes: videoBytes,
                filename: videoName,
                contentType: 'video/mp4',
                cancelTrigger: cancelCompleter.future,
                onProgress: (sent, total) {
                  if (mounted && _submitGeneration == currentGen) {
                    setState(() {
                      _uploadProgressFraction =
                          total > 0 ? (sent / total) : 0.0;
                      final sentMb = (sent / (1024 * 1024)).toStringAsFixed(1);
                      final totalMb =
                          (total / (1024 * 1024)).toStringAsFixed(1);
                      _uploadProgressText = context.l10n
                          .uploadVideoBytesProgress(sentMb, totalMb);
                    });
                  }
                },
              );
              break;
            } catch (e) {
              if (_submitGeneration != currentGen) return;
              debugPrint(
                  '[PostJobRequest] video upload attempt $attempt error: $e');

              // do not retry 4xx
              if (e is MediaUploadHttpException && !e.isRetryable) {
                throw MediaUploadException(
                  e.message,
                  statusCode: e.statusCode,
                  isRetryable: false,
                );
              }

              if (attempt == 2) {
                final code =
                    e is MediaUploadHttpException ? e.statusCode : null;
                throw MediaUploadException('Video upload failed: $e',
                    statusCode: code);
              }

              await Future.delayed(retryDelays[attempt]);
              if (_submitGeneration != currentGen) return;
              await _waitForConnectionIfNeeded(currentGen);
              if (_submitGeneration != currentGen) return;
            }
          }

          if (_submitGeneration != currentGen) return;

          if (thumbRes != null && videoRes != null) {
            videoItem = JobVideoItem(
              url: videoRes.url,
              key: videoRes.key,
              thumbUrl: thumbRes.url,
              durationSec: _processedVideo!.durationSec,
            );
            _uploadedVideoItem = videoItem;
            _uploadedVideoSource = _processedVideo;
          }
        }
      }

      if (_submitGeneration != currentGen) return;

      // uploads done, job creation cannot be cancelled
      if (mounted) {
        setState(() {
          _isUploadingMedia = false;
        });
      }

      final request = JobRequest(
        customerId: user.uid,
        customerName: user.displayName ??
            user.email?.split('@').first ??
            defaultCustomerRole,
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
        note: _selectedLocation!.effectiveNote,
        landmark: _selectedLocation!.effectiveNote,
        accuracyMeters: _selectedLocation!.accuracyMeters,
        houseNo: _selectedLocation!.houseNo,
        street: _selectedLocation!.street,
        city: _selectedLocation!.city,
        directions: _selectedLocation!.directions,
        bookingType:
            _scheduleMode == ScheduleHelpers.modeToday ? 'asap' : 'scheduled',
        scheduleMode: schedRes.scheduleMode,
        scheduledDate: schedRes.scheduledDate,
        scheduledStartAt: finalStartAt,
        scheduledEndAt: finalEndAt,
        scheduledSlot: schedRes.scheduledSlot,
        flexibleWindowDays: schedRes.flexibleWindowDays,
        expiresAt: schedRes.expiresAt,
      );

      if (widget.isEditMode) {
        final currentPhotos = photosList;
        final currentVideo = videoItem;

        await JobRequestRepository().updateJobPost(
          requestId: widget.editJob!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          scheduleMode: schedRes.scheduleMode,
          scheduledDate: schedRes.scheduledDate,
          scheduledStartAt: finalStartAt,
          scheduledEndAt: finalEndAt,
          scheduledSlot: schedRes.scheduledSlot,
          flexibleWindowDays: schedRes.flexibleWindowDays,
          photos: currentPhotos,
          video: currentVideo,
          updateLocation: !_isLocationLocked && _selectedLocation != null,
          latitude: _selectedLocation?.latitude,
          longitude: _selectedLocation?.longitude,
          district: _selectedLocation?.label,
          address: _selectedLocation?.address,
          landmark: _selectedLocation?.effectiveNote,
          note: _selectedLocation?.effectiveNote,
          houseNo: _selectedLocation?.houseNo,
          street: _selectedLocation?.street,
          city: _selectedLocation?.city,
          directions: _selectedLocation?.directions,
          accuracyMeters: _selectedLocation?.accuracyMeters,
          hasQuotes: widget.editJob!.hasQuotes,
        );

        // delete removed media
        final remainingKeys = <String>{
          ...currentPhotos.map((p) => p.key),
          if (currentVideo != null) currentVideo.key,
        };
        for (final oldKey in _originalMediaKeys) {
          if (!remainingKeys.contains(oldKey)) {
            unawaited(ApiClient.instance
                .delete(
              uri: Uri.parse(
                  '${AppConfig.otpApiUrl}/media?key=${Uri.encodeComponent(oldKey)}&jobId=${widget.editJob!.id}'),
            )
                .catchError((e) {
              debugPrint('[PostJobRequest] delete media error: $e');
              return http.Response('', 500);
            }));
          }
        }

        unawaited(VideoService.instance.cleanCache());

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.editJobSuccess),
              backgroundColor: AppColors.primary,
            ),
          );
          Navigator.of(context).pop(true);
        }
        return;
      }

      final requestId = await JobRequestRepository().createJobRequest(request);

      // notify without blocking
      unawaited(NotificationService.instance
          .sendNotification(
        event: 'job_posted',
        docId: requestId,
      )
          .catchError((e) {
        debugPrint('[PostJobRequest] notify job_posted error: $e');
        return false;
      }));

      // clear temp video
      unawaited(VideoService.instance.cleanCache());

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
    } on MediaUploadException catch (e) {
      if (_submitGeneration != currentGen) return;
      debugPrint('[PostJobRequest] media upload failed: $e');
      unawaited(ErrorReporter.report(
        screen: 'post_job_request_screen',
        action: 'upload_media',
        error: e,
      ));
      if (mounted) {
        String friendlyMsg;
        switch (e.statusCode) {
          case 400:
            friendlyMsg = context.l10n.invalidRequest;
            break;
          case 401:
          case 403:
            friendlyMsg = context.l10n.loginOtpRequired;
            break;
          case 413:
            friendlyMsg = context.l10n.certUploadFileTooLargeError('Media');
            break;
          case 415:
            friendlyMsg = context.l10n.certUploadUnsupportedTypeError('Media');
            break;
          case 429:
            friendlyMsg = context.l10n.authErrTooManyRequests;
            break;
          default:
            friendlyMsg = context.l10n.mediaUploadFailedRetry;
            break;
        }
        final debugDetails =
            kDebugMode ? ErrorReporter.formatDebugDetails(e) : null;
        setState(() {
          _uploadFailed = true;
          _saveFailed = false;
          _isUploadingMedia = false;
          _uploadProgressText = friendlyMsg;
          _debugErrorDetails = debugDetails;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friendlyMsg),
                if (debugDetails != null)
                  Text(debugDetails,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } on FirebaseException catch (e) {
      if (_submitGeneration != currentGen) return;
      debugPrint(
          '[PostJobRequest] create job FirebaseException: [${e.code}] ${e.message}');
      unawaited(ErrorReporter.report(
        screen: 'post_job_request_screen',
        action: 'submit_job_request',
        error: e,
      ));
      if (mounted) {
        final friendlyMsg = jobPostErrorMessage(context, e);
        final debugDetails =
            kDebugMode ? ErrorReporter.formatDebugDetails(e) : null;
        setState(() {
          _uploadFailed = false;
          _saveFailed = true;
          _isUploadingMedia = false;
          _uploadProgressText = friendlyMsg;
          _debugErrorDetails = debugDetails;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friendlyMsg),
                if (debugDetails != null)
                  Text(debugDetails,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (_submitGeneration != currentGen) return;
      debugPrint('[PostJobRequest] create job error: $e');
      unawaited(ErrorReporter.report(
        screen: 'post_job_request_screen',
        action: 'submit_job_request',
        error: e,
      ));
      if (mounted) {
        final friendlyMsg = jobPostErrorMessage(context, e);
        final debugDetails =
            kDebugMode ? ErrorReporter.formatDebugDetails(e) : null;
        setState(() {
          _uploadFailed = false;
          _saveFailed = true;
          _isUploadingMedia = false;
          _uploadProgressText = friendlyMsg;
          _debugErrorDetails = debugDetails;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friendlyMsg),
                if (debugDetails != null)
                  Text(debugDetails,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted && _submitGeneration == currentGen) {
        setState(() {
          _submitting = false;
          _isUploadingMedia = false;
          if (!_uploadFailed && !_saveFailed) {
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
          widget.isEditMode
              ? context.l10n.editJobPost
              : (widget.isPrefillMode
                  ? context.l10n.postAgain
                  : context.l10n.postJobGetQuotes),
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
              if (_loadingInitialData) ...[
                const LinearProgressIndicator(
                  minHeight: 3,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 12),
              ],
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
              if (widget.isEditMode) ...[
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: context.themeSurfaceLow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.themeBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline_rounded,
                          size: 18, color: context.themeTextSecondary),
                      const SizedBox(width: 10),
                      Text(
                        _selectedCategory ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.themeInk,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.categoryCannotBeEdited,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.themeTextSecondary,
                  ),
                ),
              ] else
                StreamBuilder<List<CategoryRow>>(
                  stream: _categoriesStream,
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
                      initialValue:
                          dbCategories.any((c) => c.id == _selectedCategory)
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
                      onChanged: (v) {
                        setState(() => _selectedCategory = v);
                        _updateCoverage();
                      },
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

              if (_hasSkippedOldPhotos) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.warning, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.l10n.oldPhotosUnavailable,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

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
                              child: Image.memory(
                                entry.value.bytes,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  final removed = _photos.removeAt(entry.key);
                                  _uploadedPhotos.remove(removed);
                                }),
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

              // optional video section
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
              if (_hasVideoNotCopied) ...[
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.info.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: AppColors.info, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.l10n.videoNotCopiedNote,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.info,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            // duration and size
                            child: Text(
                              '${_processedVideo!.durationSec}s • ${_formatFileSize(_processedVideo!.compressedFile.lengthSync())}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _processedVideo = null;
                              _uploadedVideoItem = null;
                              _uploadedVideoThumb = null;
                              _uploadedVideoSource = null;
                            }),
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
                  ],
                )
              else if (kIsWeb)
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: context.themeSurfaceLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.themeBorder,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.themeBorder.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.videocam_off_outlined,
                            color: context.themeTextSecondary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          context.l10n.videoUploadMobileOnly,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.themeTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                          child: const Icon(Icons.videocam_outlined,
                              color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                context.l10n.addShortVideo,
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700),
                              ),
                              Text(
                                context.l10n.addShortVideoSubtitle,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: context.themeTextSecondary),
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
                context.l10n.whenDoYouNeedThis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: context.themeInk,
                ),
              ),
              const SizedBox(height: 8),

              // mode options
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt_rounded, size: 16),
                          const SizedBox(width: 4),
                          Text(context.l10n.scheduleModeToday),
                        ],
                      ),
                      selected: _scheduleMode == ScheduleHelpers.modeToday,
                      onSelected: ScheduleHelpers.canChooseToday()
                          ? (sel) {
                              if (sel) {
                                setState(() {
                                  _scheduleMode = ScheduleHelpers.modeToday;
                                  if (_scheduledSlot ==
                                      ScheduleHelpers.slotExact) {
                                    _scheduledSlot =
                                        ScheduleHelpers.slotAnytime;
                                  }
                                });
                              }
                            }
                          : null,
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _scheduleMode == ScheduleHelpers.modeToday
                            ? AppColors.primary
                            : (ScheduleHelpers.canChooseToday()
                                ? context.themeTextSecondary
                                : context.themeTextSecondary
                                    .withValues(alpha: 0.4)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 16),
                          const SizedBox(width: 4),
                          Text(context.l10n.scheduleModeSpecificDay),
                        ],
                      ),
                      selected: _scheduleMode == ScheduleHelpers.modeDate,
                      onSelected: (sel) {
                        if (sel) {
                          setState(
                              () => _scheduleMode = ScheduleHelpers.modeDate);
                        }
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _scheduleMode == ScheduleHelpers.modeDate
                            ? AppColors.primary
                            : context.themeTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.date_range_rounded, size: 16),
                          const SizedBox(width: 4),
                          Text(context.l10n.scheduleModeFlexible),
                        ],
                      ),
                      selected: _scheduleMode == ScheduleHelpers.modeFlexible,
                      onSelected: (sel) {
                        if (sel) {
                          setState(() {
                            _scheduleMode = ScheduleHelpers.modeFlexible;
                            _scheduledSlot = ScheduleHelpers.slotAnytime;
                          });
                        }
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _scheduleMode == ScheduleHelpers.modeFlexible
                            ? AppColors.primary
                            : context.themeTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              if (!ScheduleHelpers.canChooseToday() &&
                  _scheduleMode == ScheduleHelpers.modeToday) ...[
                const SizedBox(height: 8),
                Text(
                  context.l10n.todayDisabledPast20,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600),
                ),
              ],

              // today fields
              if (_scheduleMode == ScheduleHelpers.modeToday) ...[
                const SizedBox(height: 12),
                _buildScheduleSlotChips(isToday: true),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EmergencyDispatchScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emergency_outlined,
                            size: 16, color: AppColors.error),
                        const SizedBox(width: 6),
                        Text(
                          context.l10n.urgentHelpHint,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // specific date fields
              if (_scheduleMode == ScheduleHelpers.modeDate) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _pickScheduledDate(context),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: context.themeSurfaceLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.themeBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_note_rounded,
                            size: 20, color: AppColors.primary),
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
                        const Icon(Icons.arrow_drop_down,
                            color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildScheduleSlotChips(
                    isToday: ScheduleHelpers.isToday(_scheduledDate)),
                if (_scheduledSlot == ScheduleHelpers.slotExact) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.scheduleFrom,
                              style: const TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () => _pickScheduledTime(context, true),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: context.themeSurfaceLow,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: context.themeBorder),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _fromTime.format(context),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5),
                                    ),
                                    const Icon(Icons.access_time_rounded,
                                        size: 16, color: AppColors.primary),
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
                              style: const TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () => _pickScheduledTime(context, false),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: context.themeSurfaceLow,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: context.themeBorder),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _toTime.format(context),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5),
                                    ),
                                    const Icon(Icons.access_time_rounded,
                                        size: 16, color: AppColors.primary),
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
              ],

              // flexible fields
              if (_scheduleMode == ScheduleHelpers.modeFlexible) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(context.l10n.flexibleWithin3Days),
                      selected: _flexibleDays == 3,
                      onSelected: (sel) {
                        if (sel) setState(() => _flexibleDays = 3);
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _flexibleDays == 3
                            ? AppColors.primary
                            : context.themeTextSecondary,
                      ),
                    ),
                    ChoiceChip(
                      label: Text(context.l10n.flexibleWithinWeek),
                      selected: _flexibleDays == 7,
                      onSelected: (sel) {
                        if (sel) setState(() => _flexibleDays = 7);
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _flexibleDays == 7
                            ? AppColors.primary
                            : context.themeTextSecondary,
                      ),
                    ),
                    ChoiceChip(
                      label: Text(context.l10n.flexibleWithin2Weeks),
                      selected: _flexibleDays == 14,
                      onSelected: (sel) {
                        if (sel) setState(() => _flexibleDays = 14);
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _flexibleDays == 14
                            ? AppColors.primary
                            : context.themeTextSecondary,
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
                            : Colors.black
                                .withValues(alpha: context.isDark ? 0.2 : 0.03),
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
                                  ? (_selectedLocation!.label ??
                                      context.l10n.selectJobLocation)
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
                            if (_selectedLocation?.effectiveNote != null &&
                                _selectedLocation!
                                    .effectiveNote!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${context.l10n.providerNoteLabel}: ${_selectedLocation!.effectiveNote}',
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
                      if (_isLocationLocked)
                        Icon(Icons.lock_rounded,
                            color: context.themeTextSecondary, size: 20)
                      else ...[
                        Text(
                          _selectedLocation != null
                              ? context.l10n.change
                              : context.l10n.setPin,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: AppColors.primary, size: 18),
                      ],
                    ],
                  ),
                ),
              ),
              if (_isLocationLocked) ...[
                const SizedBox(height: 6),
                Text(
                  context.l10n.locationLockedHasQuotes,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.themeTextSecondary,
                  ),
                ),
              ],

              if (_uploadProgressText != null ||
                  _uploadFailed ||
                  _saveFailed) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: (_uploadFailed || _saveFailed)
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (_uploadFailed || _saveFailed)
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
                          ] else if (_uploadFailed || _saveFailed) ...[
                            const Icon(Icons.error_outline_rounded,
                                size: 18, color: AppColors.error),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _uploadProgressText ??
                                      context.l10n.uploadFailedAttempts,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: (_uploadFailed || _saveFailed)
                                        ? AppColors.error
                                        : AppColors.primary,
                                  ),
                                ),
                                if (kDebugMode &&
                                    _debugErrorDetails != null &&
                                    (_uploadFailed || _saveFailed)) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _debugErrorDetails!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ],
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
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                          ),
                        ),
                      ],
                      if (_submitting && _isUploadingMedia) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: _cancelMediaUpload,
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: Text(context.l10n.cancelUpload),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                            ),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_off_rounded,
                          color: AppColors.error, size: 18),
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
              if (_selectedLocation != null &&
                  _selectedCategory != null &&
                  _coverageProviderCount != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _coverageProviderCount == 0
                        ? AppColors.warning.withValues(alpha: 0.12)
                        : AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _coverageProviderCount == 0
                          ? AppColors.warning.withValues(alpha: 0.3)
                          : AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _coverageProviderCount == 0
                            ? Icons.info_outline_rounded
                            : Icons.check_circle_outline_rounded,
                        color: _coverageProviderCount == 0
                            ? AppColors.warning
                            : AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _coverageProviderCount == 0
                              ? context.l10n.coverageWarningZero
                              : context.l10n.coverageWarningCount(
                                  _coverageProviderCount!),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: context.themeTextPrimary,
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
                  label: widget.isEditMode
                      ? context.l10n.saveChanges
                      : context.l10n.postJobGetQuotes,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    );
  }

  Widget _buildScheduleSlotChips({required bool isToday}) {
    final now = DateTime.now();
    final morningOk = !isToday ||
        ScheduleHelpers.isSlotAvailableToday(ScheduleHelpers.slotMorning, now);
    final afternoonOk = !isToday ||
        ScheduleHelpers.isSlotAvailableToday(
            ScheduleHelpers.slotAfternoon, now);
    final eveningOk = !isToday ||
        ScheduleHelpers.isSlotAvailableToday(ScheduleHelpers.slotEvening, now);
    final anytimeOk = !isToday ||
        ScheduleHelpers.isSlotAvailableToday(ScheduleHelpers.slotAnytime, now);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text(context.l10n.slotAnytimeShort),
          selected: _scheduledSlot == ScheduleHelpers.slotAnytime,
          onSelected: anytimeOk
              ? (sel) {
                  if (sel) {
                    setState(
                        () => _scheduledSlot = ScheduleHelpers.slotAnytime);
                  }
                }
              : null,
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _scheduledSlot == ScheduleHelpers.slotAnytime
                ? AppColors.primary
                : (anytimeOk
                    ? context.themeTextSecondary
                    : context.themeTextSecondary.withValues(alpha: 0.35)),
          ),
        ),
        ChoiceChip(
          label: Text(context.l10n.slotMorningShort),
          selected: _scheduledSlot == ScheduleHelpers.slotMorning,
          onSelected: morningOk
              ? (sel) {
                  if (sel) {
                    setState(
                        () => _scheduledSlot = ScheduleHelpers.slotMorning);
                  }
                }
              : null,
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _scheduledSlot == ScheduleHelpers.slotMorning
                ? AppColors.primary
                : (morningOk
                    ? context.themeTextSecondary
                    : context.themeTextSecondary.withValues(alpha: 0.35)),
          ),
        ),
        ChoiceChip(
          label: Text(context.l10n.slotAfternoonShort),
          selected: _scheduledSlot == ScheduleHelpers.slotAfternoon,
          onSelected: afternoonOk
              ? (sel) {
                  if (sel) {
                    setState(
                        () => _scheduledSlot = ScheduleHelpers.slotAfternoon);
                  }
                }
              : null,
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _scheduledSlot == ScheduleHelpers.slotAfternoon
                ? AppColors.primary
                : (afternoonOk
                    ? context.themeTextSecondary
                    : context.themeTextSecondary.withValues(alpha: 0.35)),
          ),
        ),
        ChoiceChip(
          label: Text(context.l10n.slotEveningShort),
          selected: _scheduledSlot == ScheduleHelpers.slotEvening,
          onSelected: eveningOk
              ? (sel) {
                  if (sel) {
                    setState(
                        () => _scheduledSlot = ScheduleHelpers.slotEvening);
                  }
                }
              : null,
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _scheduledSlot == ScheduleHelpers.slotEvening
                ? AppColors.primary
                : (eveningOk
                    ? context.themeTextSecondary
                    : context.themeTextSecondary.withValues(alpha: 0.35)),
          ),
        ),
        if (_scheduleMode == ScheduleHelpers.modeDate)
          ChoiceChip(
            label: Text(context.l10n.slotExactTime),
            selected: _scheduledSlot == ScheduleHelpers.slotExact,
            onSelected: (sel) {
              if (sel) {
                setState(() => _scheduledSlot = ScheduleHelpers.slotExact);
              }
            },
            selectedColor: AppColors.primary.withValues(alpha: 0.15),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _scheduledSlot == ScheduleHelpers.slotExact
                  ? AppColors.primary
                  : context.themeTextSecondary,
            ),
          ),
      ],
    );
  }
}
