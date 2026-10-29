import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../constants/app_config.dart';
import '../../../constants/firestore_paths.dart';
import '../../../constants/job_status.dart';
import '../../../models/booking.dart';
import '../../../models/job_request.dart';
import '../../../repositories/job_request_repository.dart';
import '../../../services/api_client.dart';
import '../../../services/error_reporter.dart';
import '../../../services/notification_service.dart';
import '../../../services/session_guard.dart';
import '../../../services/storage_service.dart';
import '../../../shared/widgets/job_schedule_picker.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/location_utils.dart';
import '../../../utils/schedule_helpers.dart';
import '../../../utils/ticket_error_l10n.dart';
import '../screens/job_quotes_screen.dart';
import '../screens/post_job_request_screen.dart';

// repost bottom sheet
class JobRepostSheet extends StatelessWidget {
  final JobRequest request;
  final Booking? booking;

  const JobRepostSheet({
    super.key,
    required this.request,
    this.booking,
  });

  static Future<void> show(
    BuildContext context, {
    required JobRequest request,
    Booking? booking,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JobRepostSheet(request: request, booking: booking),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final canToday = ScheduleHelpers.canChooseToday(now);
    final initialDate = canToday ? now : now.add(const Duration(days: 1));
    final initialMode = canToday
        ? (request.scheduleMode.isNotEmpty
            ? request.scheduleMode
            : ScheduleHelpers.modeToday)
        : ScheduleHelpers.modeDate;

    return JobSchedulePicker(
      title: context.l10n.repostJobTitle,
      initialDate: initialDate,
      initialMode: initialMode,
      initialSlot: request.scheduledSlot,
      note: _buildNote(context),
      actionsBuilder: (ctx, getSchedule, getScheduleError) =>
          _RepostSheetActions(
        request: request,
        booking: booking,
        getSchedule: getSchedule,
        getScheduleError: getScheduleError,
      ),
    );
  }

  Widget? _buildNote(BuildContext context) {
    final showPhotosRemoved = request.isPhotosRemoved;
    final showVideoNotCopied = request.video != null;

    if (!showPhotosRemoved && !showVideoNotCopied) return null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showPhotosRemoved) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        if (showPhotosRemoved && showVideoNotCopied) const SizedBox(height: 8),
        if (showVideoNotCopied) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: context.themeSoft,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.themeBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.videocam_off_outlined,
                    color: context.themeTextSecondary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.videoNotCopiedNote,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.themeTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// sheet action buttons
class _RepostSheetActions extends StatefulWidget {
  final JobRequest request;
  final Booking? booking;
  final JobScheduleResult? Function() getSchedule;
  final String? Function() getScheduleError;

  const _RepostSheetActions({
    required this.request,
    this.booking,
    required this.getSchedule,
    required this.getScheduleError,
  });

  @override
  State<_RepostSheetActions> createState() => _RepostSheetActionsState();
}

class _RepostSheetActionsState extends State<_RepostSheetActions> {
  bool _isSubmitting = false;
  double _progressFraction = 0.0;
  String? _progressText;
  String? _errorMessage;
  String? _debugErrorDetails;

  @override
  void initState() {
    super.initState();
    final initialError = widget.getScheduleError();
    if (initialError != null) {
      _errorMessage = initialError;
    }
  }

  @override
  void didUpdateWidget(covariant _RepostSheetActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    final error = widget.getScheduleError();
    if (error == null && _errorMessage != null && !_isSubmitting) {
      setState(() {
        _errorMessage = null;
        _debugErrorDetails = null;
      });
    } else if (error != null && _errorMessage != error && !_isSubmitting) {
      setState(() {
        _errorMessage = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (kDebugMode && _debugErrorDetails != null) ...[
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
        if (_isSubmitting) ...[
          if (_progressFraction > 0.0)
            LinearProgressIndicator(
              value: _progressFraction,
              backgroundColor: context.themeBorder,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            )
          else
            const LinearProgressIndicator(),
          if (_progressText != null) ...[
            const SizedBox(height: 8),
            Text(
              _progressText!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: context.themeTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 12),
        ],
        if (!_isSubmitting) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleRepostNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                context.l10n.repostNow,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _handleEditDetailsFirst,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                context.l10n.editDetailsFirst,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _handleEditDetailsFirst() {
    final sched = widget.getSchedule();
    if (sched == null) {
      final scheduleErr = widget.getScheduleError() ??
          'Schedule is invalid. Please select another date or time.';
      setState(() {
        _errorMessage = scheduleErr;
        _debugErrorDetails =
            kDebugMode ? 'Schedule validation returned null' : null;
      });
      return;
    }

    final prefill = widget.request.copyWith(
      scheduleMode: sched.scheduleMode,
      scheduledDate: sched.scheduledDate,
      scheduledSlot: sched.scheduledSlot,
      scheduledStartAt: sched.scheduledStartAt,
      scheduledEndAt: sched.scheduledEndAt,
      flexibleWindowDays: sched.flexibleWindowDays,
      expiresAt: sched.expiresAt,
    );

    Navigator.of(context).pop();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostJobRequestScreen(prefillJob: prefill),
      ),
    );
  }

  Future<void> _handleRepostNow() async {
    final sched = widget.getSchedule();
    if (sched == null) {
      final scheduleErr = widget.getScheduleError() ??
          context.l10n.timePassedChooseLater;
      setState(() {
        _errorMessage = scheduleErr;
        _debugErrorDetails = kDebugMode
            ? 'Schedule validation returned null (slot unavailable or past cutoff)'
            : null;
      });
      return;
    }

    final isToday = sched.scheduledDate != null &&
        ScheduleHelpers.isToday(sched.scheduledDate!);
    if (isToday &&
        sched.scheduledStartAt != null &&
        sched.scheduledEndAt != null) {
      // check if clamped schedule window has passed
      final clamped = ScheduleHelpers.clampWindowToNow(
        startAt: sched.scheduledStartAt!,
        endAt: sched.scheduledEndAt!,
      );
      if (clamped.hasPassed) {
        setState(() {
          _errorMessage = context.l10n.timePassedChooseLater;
        });
        return;
      }
    }

    // renew expired post
    final isExpiredWithMedia = widget.booking == null &&
        widget.request.status == JobRequestStatus.expired &&
        !widget.request.isPhotosRemoved;

    if (isExpiredWithMedia) {
      await _renewExpiredPost(sched);
      return;
    }

    // or create fresh post
    await _createNewPost(sched);
  }

  Future<void> _renewExpiredPost(JobScheduleResult sched) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _debugErrorDetails = null;
      _progressText = null;
    });

    try {
      final customerId = widget.request.customerId;
      final prefix =
          'https://helaservice.vercel.app/api/media?key=uploads/$customerId/';
      final keyPrefix = 'uploads/$customerId/';

      final validPhotos = widget.request.photos.where((p) {
        return p.url.startsWith(prefix) && p.key.startsWith(keyPrefix);
      }).toList();

      final hadOldPhotos = widget.request.photos.length > validPhotos.length;
      final hasInvalidVideo = widget.request.video != null &&
          (!widget.request.video!.url.startsWith(prefix) ||
              !widget.request.video!.key.startsWith(keyPrefix));

      await JobRequestRepository().renewJobPost(
        requestId: widget.request.id,
        scheduleMode: sched.scheduleMode,
        scheduledDate: sched.scheduledDate,
        scheduledStartAt: sched.scheduledStartAt,
        scheduledEndAt: sched.scheduledEndAt,
        scheduledSlot: sched.scheduledSlot,
        flexibleWindowDays: sched.flexibleWindowDays,
        expiresAt: sched.expiresAt,
        sanitizedPhotos: hadOldPhotos ? validPhotos : null,
        dropVideo: hasInvalidVideo,
      );

      if (mounted) {
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(hadOldPhotos
                ? '${context.l10n.renewPostSuccess} (${context.l10n.oldPhotosUnavailable})'
                : context.l10n.renewPostSuccess),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } on FirebaseException catch (e) {
      debugPrint(
          '[RepostSheet] renew FirebaseException: [${e.code}] ${e.message}');
      unawaited(ErrorReporter.report(
        screen: 'job_repost_sheet',
        action: 'renew_job_post',
        error: e,
      ));
      final sessionValid = await SessionGuard.handlePermissionDenied(e);
      if (!sessionValid) return;
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.code == 'permission-denied'
              ? context.l10n.loginOtpRequired
              : (e.message ?? context.l10n.somethingWentWrong);
          _debugErrorDetails =
              kDebugMode ? ErrorReporter.formatDebugDetails(e) : null;
        });
      }
    } catch (e) {
      debugPrint('[RepostSheet] renew error: $e');
      unawaited(ErrorReporter.report(
        screen: 'job_repost_sheet',
        action: 'renew_job_post',
        error: e,
      ));
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = context.l10n.somethingWentWrong;
          _debugErrorDetails =
              kDebugMode ? ErrorReporter.formatDebugDetails(e) : null;
        });
      }
    }
  }

  Future<void> _createNewPost(JobScheduleResult sched) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = context.l10n.loginOtpRequired;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _progressFraction = 0.0;
      _progressText = context.l10n.preparingMedia;
    });

    try {
      // load contact info if available
      Map<String, dynamic>? contact;
      if (widget.request.id.isNotEmpty) {
        try {
          contact = await JobRequestRepository()
              .getJobPrivateContact(widget.request.id);
        } catch (e) {
          debugPrint('[RepostSheet] contact fetch error: $e');
        }
      }

      // validate required fields
      final title = widget.request.title.trim();
      final category = widget.request.category.trim();
      final lat = (contact?['latitude'] as num?)?.toDouble() ??
          widget.request.latitude ??
          widget.booking?.customerLatitude;
      final lng = (contact?['longitude'] as num?)?.toDouble() ??
          widget.request.longitude ??
          widget.booking?.customerLongitude;
      final address = (contact?['address'] as String?) ??
          (widget.request.address.isNotEmpty
              ? widget.request.address
              : (widget.booking?.location ?? ''));

      if (title.isEmpty) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = context.l10n.invalidRequest;
        });
        return;
      }

      if (category.isEmpty) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = context.l10n.selectCategoryError;
        });
        return;
      }

      if (lat == null || lng == null) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = context.l10n.pleaseSelectServiceLocation;
        });
        return;
      }

      // verify coverage
      try {
        final snap = await FirebaseFirestore.instance
            .collection(FirestorePaths.technicians)
            .where('category', isEqualTo: category)
            .where('nicVerified', isEqualTo: true)
            .get();

        int coverageCount = 0;
        for (final doc in snap.docs) {
          final d = doc.data();
          if (d['isBanned'] == true) continue;
          final baseLat = (d['baseLatitude'] as num?)?.toDouble() ??
              (d['latitude'] as num?)?.toDouble();
          final baseLng = (d['baseLongitude'] as num?)?.toDouble() ??
              (d['longitude'] as num?)?.toDouble();
          if (baseLat == null || baseLng == null) continue;
          final radius = (d['serviceRadiusKm'] as num?)?.toDouble() ?? 25.0;
          final dist =
              LocationUtils.calculateDistanceKm(lat, lng, baseLat, baseLng);
          if (dist <= radius) coverageCount++;
        }
        debugPrint('[RepostSheet] coverage count: $coverageCount');
      } catch (e) {
        debugPrint('[RepostSheet] coverage check warning: $e');
      }

      // copy photos if media exists
      final List<JobMediaItem> newPhotosList = [];
      if (!widget.request.isPhotosRemoved && widget.request.photos.isNotEmpty) {
        for (int i = 0; i < widget.request.photos.length; i++) {
          if (!mounted) return;
          final p = widget.request.photos[i];
          if (p.key.isEmpty) continue;

          setState(() {
            _progressFraction = 0.0;
            _progressText = context.l10n
                .uploadingPhotoProgress(i + 1, widget.request.photos.length);
          });

          // fetch presigned url
          final mediaUri = Uri.parse(
              '${AppConfig.otpApiUrl}/media?key=${Uri.encodeComponent(p.key)}&mode=json');
          final res = await ApiClient.instance.get(uri: mediaUri);
          if (res.statusCode != 200) {
            throw MediaUploadException('Failed to download photo',
                statusCode: res.statusCode);
          }
          final data = jsonDecode(res.body);
          final presignedUrl = data['url'] as String?;
          if (presignedUrl == null) {
            throw const MediaUploadException('Invalid photo url');
          }

          final imgRes = await http
              .get(Uri.parse(presignedUrl))
              .timeout(const Duration(seconds: 15));
          if (imgRes.statusCode != 200) {
            throw MediaUploadException('Failed to download photo bytes',
                statusCode: imgRes.statusCode);
          }

          final rawBytes = imgRes.bodyBytes;
          final stripped =
              await StorageService.instance.stripExifAndCompressImage(rawBytes);

          // upload new photo
          final uploadRes = await StorageService.instance.uploadJobMedia(
            bytes: stripped,
            filename: 'photo_$i.jpg',
            contentType: 'image/jpeg',
            onProgress: (sent, total) {
              if (mounted) {
                setState(() {
                  _progressFraction = total > 0 ? (sent / total) : 0.0;
                  final sentMb = (sent / (1024 * 1024)).toStringAsFixed(1);
                  final totalMb = (total / (1024 * 1024)).toStringAsFixed(1);
                  _progressText = context.l10n.uploadPhotoBytesProgress(
                      i + 1, widget.request.photos.length, sentMb, totalMb);
                });
              }
            },
          );

          newPhotosList
              .add(JobMediaItem(url: uploadRes.url, key: uploadRes.key));
        }
      }

      if (!mounted) return;

      setState(() {
        _progressText = null;
      });

      final note = (contact?['note'] as String?) ??
          (contact?['landmark'] as String?) ??
          widget.request.note;

      final newJob = JobRequest(
        customerId: user.uid,
        customerName: user.displayName ??
            user.email?.split('@').first ??
            context.l10n.roleCustomer,
        customerPhone: user.phoneNumber ??
            (contact?['customerPhone'] as String?) ??
            widget.request.customerPhone,
        title: title,
        description: widget.request.description,
        category: category,
        photoUrls: newPhotosList.map((p) => p.url).toList(),
        photos: newPhotosList,
        video: null,
        latitude: lat,
        longitude: lng,
        district: widget.request.district ?? (contact?['label'] as String?),
        address: address,
        note: note,
        landmark: note,
        accuracyMeters: (contact?['accuracyMeters'] as num?)?.toDouble() ??
            widget.request.accuracyMeters,
        houseNo: contact?['houseNo'] as String? ?? widget.request.houseNo,
        street: contact?['street'] as String? ?? widget.request.street,
        city: contact?['city'] as String? ?? widget.request.city,
        directions:
            contact?['directions'] as String? ?? widget.request.directions,
        bookingType: sched.scheduleMode == ScheduleHelpers.modeToday
            ? 'asap'
            : 'scheduled',
        scheduleMode: sched.scheduleMode,
        scheduledDate: sched.scheduledDate,
        scheduledStartAt: sched.scheduledStartAt,
        scheduledEndAt: sched.scheduledEndAt,
        scheduledSlot: sched.scheduledSlot,
        flexibleWindowDays: sched.flexibleWindowDays,
        expiresAt: sched.expiresAt,
        status: JobRequestStatus.open,
        quoteCount: 0,
      );

      final newRequestId =
          await JobRequestRepository().createJobRequest(newJob);

      // send job_posted notification
      unawaited(NotificationService.instance
          .sendNotification(
        event: 'job_posted',
        docId: newRequestId,
      )
          .catchError((e) {
        debugPrint('[RepostSheet] notify job_posted error: $e');
        return false;
      }));

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);
        navigator.pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text(context.l10n.postAgainSuccess),
            backgroundColor: AppColors.primary,
          ),
        );
        navigator.push(
          MaterialPageRoute(
            builder: (_) => JobQuotesScreen(
              requestId: newRequestId,
              jobTitle: newJob.title,
            ),
          ),
        );
      }
    } on MediaUploadException catch (e) {
      debugPrint(
          '[RepostSheet] media upload failed: status=${e.statusCode} message=${e.message}');
      unawaited(ErrorReporter.report(
        screen: 'job_repost_sheet',
        action: 'create_new_post_upload',
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
        setState(() {
          _isSubmitting = false;
          _errorMessage = friendlyMsg;
          _debugErrorDetails =
              kDebugMode ? ErrorReporter.formatDebugDetails(e) : null;
        });
      }
    } on FirebaseException catch (e) {
      debugPrint(
          '[RepostSheet] post again FirebaseException: [${e.code}] ${e.message}');
      unawaited(ErrorReporter.report(
        screen: 'job_repost_sheet',
        action: 'create_new_post',
        error: e,
      ));
      final sessionValid = await SessionGuard.handlePermissionDenied(e);
      if (!sessionValid) return;
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.code == 'permission-denied'
              ? context.l10n.loginOtpRequired
              : (e.message ?? context.l10n.somethingWentWrong);
          _debugErrorDetails =
              kDebugMode ? ErrorReporter.formatDebugDetails(e) : null;
        });
      }
    } catch (e) {
      debugPrint('[RepostSheet] repost now error: $e');
      unawaited(ErrorReporter.report(
        screen: 'job_repost_sheet',
        action: 'create_new_post',
        error: e,
      ));
      if (mounted) {
        final friendlyMsg = jobPostErrorMessage(context, e);
        setState(() {
          _isSubmitting = false;
          _errorMessage = friendlyMsg;
          _debugErrorDetails =
              kDebugMode ? ErrorReporter.formatDebugDetails(e) : null;
        });
      }
    }
  }
}
