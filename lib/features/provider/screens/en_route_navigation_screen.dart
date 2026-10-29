import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart' as pv;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/app_theme.dart';
import '../../../constants/job_status.dart';
import '../../../constants/firestore_paths.dart';
import '../../../models/booking.dart';
import '../../../utils/map_launcher.dart';
import '../../../shared/widgets/app_map_view.dart';
import '../../../shared/widgets/full_screen_map_page.dart';
import '../../../services/routing_service.dart';
import '../../../services/live_location_service.dart';
import '../../../state/role_provider.dart';
import '../../../repositories/booking_repository.dart';
import '../../customer/screens/direct_chat_screen.dart';
import '../../../shared/widgets/slide_to_confirm.dart';
import '../../../shared/widgets/outline_button.dart';
import '../../../shared/widgets/job_photos_sheet.dart';
import '../../../utils/l10n_extension.dart';
import '../../../services/call_service.dart';
import '../widgets/provider_price_extras_card.dart';
import '../../shared/widgets/job_media_gallery.dart';
import '../../../models/job_request.dart';
import '../../../repositories/job_request_repository.dart';
import '../../../utils/location_utils.dart';
import '../../../utils/exact_location_helper.dart';
import '../../shared/widgets/booking_cancellation_sheet.dart';

class EnRouteNavigationScreen extends StatefulWidget {
  final Booking? booking;
  const EnRouteNavigationScreen({super.key, this.booking});

  @override
  State<EnRouteNavigationScreen> createState() =>
      _EnRouteNavigationScreenState();
}

class _EnRouteNavigationScreenState extends State<EnRouteNavigationScreen> {
  LatLng? _currentGpsPosition;
  Position? _lastGpsPosition;
  DateTime? _lastGpsTimestamp;
  String _providerId = '';
  StreamSubscription<Position>? _positionSub;
  bool _gpsFailed = false;

  RouteInfo? _currentRoute;
  LatLng? _lastRouteOrigin;
  DateTime? _lastRouteFetchedAt;
  bool _isFetchingRoute = false;

  Future<JobRequest?>? _jobRequestFuture;
  String? _loadedJobRequestId;

  void _ensureJobRequestLoaded(String? jobRequestId) {
    if (jobRequestId == null || jobRequestId.isEmpty) return;
    if (_jobRequestFuture != null && _loadedJobRequestId == jobRequestId) {
      return;
    }
    _loadedJobRequestId = jobRequestId;
    _jobRequestFuture = JobRequestRepository().getById(jobRequestId);
  }

  @override
  void initState() {
    super.initState();
    _ensureJobRequestLoaded(widget.booking?.jobRequestId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLiveTracking();
    });
  }

  // start live location tracking and listen to position updates
  Future<void> _initLiveTracking() async {
    if (!mounted) return;
    setState(() {
      _gpsFailed = false;
    });

    final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
    _providerId =
        roleProvider.currentUser?.id ?? widget.booking?.providerId ?? '';

    // update marker and route on each gps fix
    _positionSub ??= LiveLocationService.instance.positionStream.listen((pos) {
      if (!mounted) return;
      final newPos = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _currentGpsPosition = newPos;
        _lastGpsPosition = pos;
        _lastGpsTimestamp = DateTime.now();
        _gpsFailed = false;
      });
      _refreshRouteIfNeeded();
    });

    // apply last known position immediately
    final existingPos = LiveLocationService.instance.lastKnownPosition;
    if (existingPos != null) {
      _currentGpsPosition = LatLng(existingPos.latitude, existingPos.longitude);
      _lastGpsPosition = existingPos;
      _lastGpsTimestamp = DateTime.now();
      _refreshRouteIfNeeded();
    }

    final bookingId = widget.booking?.id;
    bool trackingStarted = false;

    if (bookingId != null && bookingId.isNotEmpty && _providerId.isNotEmpty) {
      String? freshStatus;
      String? customerId = widget.booking?.customerId;

      // 1. read the booking fresh from Firestore
      try {
        final doc = await FirebaseFirestore.instance
            .collection(FirestorePaths.bookings)
            .doc(bookingId)
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          freshStatus = data['status'] as String?;
          final freshCust = data['customerId'] as String?;
          if (freshCust != null && freshCust.isNotEmpty) {
            customerId = freshCust;
          }
        }
      } catch (e) {
        debugPrint('[EnRouteNavigation] Error fetching fresh booking: $e');
      }

      freshStatus ??= widget.booking?.status;

      // only start tracking when booking is confirmed or on the way
      if (freshStatus == JobStatus.confirmed) {
        try {
          await BookingRepository().startNavigation(bookingId);
          freshStatus = JobStatus.enRoute;
        } catch (e) {
          debugPrint('[EnRouteNavigation] Error starting navigation: $e');
        }
      }

      if (freshStatus == JobStatus.enRoute) {
        // Then call startTrackingForBooking
        if (mounted) {
          final notifTitle = context.l10n.locationSharingNotificationTitle;
          final notifText = context.l10n.locationSharingNotificationText;
          trackingStarted =
              await LiveLocationService.instance.startTrackingForBooking(
            userId: _providerId,
            bookingId: bookingId,
            allowedViewers: customerId != null && customerId.isNotEmpty
                ? [customerId]
                : null,
            notificationTitle: notifTitle,
            notificationText: notifText,
          );
        }
      }
    }

    // fallback to single position if tracking failed
    if (!trackingStarted && _currentGpsPosition == null) {
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high),
        ).timeout(const Duration(seconds: 15));
        if (mounted) {
          setState(() {
            _currentGpsPosition = LatLng(pos.latitude, pos.longitude);
            _lastGpsPosition = pos;
            _lastGpsTimestamp = DateTime.now();
            _gpsFailed = false;
          });
          _refreshRouteIfNeeded();
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _gpsFailed = true;
          });
        }
      }
    } else if (trackingStarted && _currentGpsPosition == null) {
      // one-shot fix while waiting for stream
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high),
        ).timeout(const Duration(seconds: 15));
        if (mounted && _currentGpsPosition == null) {
          setState(() {
            _currentGpsPosition = LatLng(pos.latitude, pos.longitude);
            _lastGpsPosition = pos;
            _lastGpsTimestamp = DateTime.now();
            _gpsFailed = false;
          });
          _refreshRouteIfNeeded();
        }
      } catch (_) {
        if (mounted && _currentGpsPosition == null) {
          setState(() {
            _gpsFailed = true;
          });
        }
      }
    }
  }

  LatLng? _getCustomerPoint([Booking? booking]) {
    final b = booking ?? widget.booking;
    return ExactLocationHelper.resolveCustomerPoint(
      latitude: b?.customerLatitude,
      longitude: b?.customerLongitude,
    );
  }

  // fetch or refresh driving route
  Future<void> _refreshRouteIfNeeded([Booking? booking]) async {
    final customerPoint = _getCustomerPoint(booking);
    if (customerPoint == null ||
        _currentGpsPosition == null ||
        _isFetchingRoute) {
      return;
    }

    final isEstimated = _currentRoute?.isEstimated ?? false;
    final shouldRefresh = ExactLocationHelper.shouldRefreshRoute(
      currentPos: _currentGpsPosition,
      lastRoutePos: _lastRouteOrigin,
      lastFetchedAt: _lastRouteFetchedAt,
      now: DateTime.now(),
      isEstimated: isEstimated,
    );

    if (!shouldRefresh) return;

    _isFetchingRoute = true;
    final origin = _currentGpsPosition!;
    try {
      final route = await RoutingService().getDrivingRoute(
        origin: origin,
        destination: customerPoint,
      );

      if (!mounted) return;
      if (kDebugMode) {
        debugPrint(
            '[EnRouteNavigation] Route fetched: ${route.points.length} points, isEstimated: ${route.isEstimated}, distance: ${route.formattedDistance}, duration: ${route.formattedDuration}');
      }
      setState(() {
        _currentRoute = route;
        _lastRouteOrigin = origin;
        _lastRouteFetchedAt = DateTime.now();
        _isFetchingRoute = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint('[EnRouteNavigation] Error fetching driving route: $e');
      }
      setState(() {
        _isFetchingRoute = false;
        _currentRoute ??= RouteInfo.fallback(origin, customerPoint);
        _lastRouteOrigin = origin;
        _lastRouteFetchedAt = DateTime.now();
      });
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _positionSub = null;
    // do not stop tracking here; tracking is bound to the booking lifecycle
    // and will auto-stop when no longer en route, or explicitly on arrival/completion/cancellation
    super.dispose();
  }

  void _showDelayReasons(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.themeSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: context.themeBorder),
            left: BorderSide(color: context.themeBorder),
            right: BorderSide(color: context.themeBorder),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.themeBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.reportEnRouteDelay,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: context.themeSurfaceLow,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(6),
                      ),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: context.themeTextSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  context.l10n.selectDelayReason,
                  style: TextStyle(
                    color: context.themeTextSecondary,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    _DelayChip(
                      Icons.traffic_rounded,
                      context.l10n.heavyTraffic,
                      onSelected: () => _handleDelaySelected(
                          'Heavy Traffic', context.l10n.heavyTraffic),
                    ),
                    const SizedBox(height: 8),
                    _DelayChip(
                      Icons.water_drop_outlined,
                      context.l10n.monsoonRain,
                      onSelected: () => _handleDelaySelected(
                          'Monsoon Rain', context.l10n.monsoonRain),
                    ),
                    const SizedBox(height: 8),
                    _DelayChip(
                      Icons.alt_route_rounded,
                      context.l10n.roadDetour,
                      onSelected: () => _handleDelaySelected(
                          'Road Detour / Blocked', context.l10n.roadDetour),
                    ),
                    const SizedBox(height: 8),
                    _DelayChip(
                      Icons.local_gas_station_rounded,
                      context.l10n.refuelingStop,
                      onSelected: () => _handleDelaySelected(
                          'Refueling Stop', context.l10n.refuelingStop),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDelaySelected(String reason, String label) async {
    Navigator.pop(context);
    if (widget.booking != null && widget.booking!.id.isNotEmpty) {
      await BookingRepository().reportDelay(
        widget.booking!.id,
        reason: reason,
        delayMinutes: 10,
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.delayReportedNotice(label)),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  Future<void> _promptCompletionPin(BuildContext context,
      {String? defaultCompletionType}) async {
    final b = widget.booking;
    if (b == null || b.id.isEmpty) return;

    final isRejected = b.priceStatus == 'rejected';
    String completionType =
        defaultCompletionType ?? (isRejected ? 'visit_only' : 'normal');
    final normalAmount = b.approvedTotalLkr != null && b.approvedTotalLkr! > 0
        ? b.approvedTotalLkr!.toStringAsFixed(0)
        : (b.agreedPrice != null && b.agreedPrice! > 0
            ? b.agreedPrice!.toStringAsFixed(0)
            : '');
    final visitDue = (b.visitFeeLkr ?? 0) + (b.travelCostLkr ?? 0);
    final visitOnlyAmount = visitDue > 0
        ? visitDue.toString()
        : (b.agreedPrice != null && b.agreedPrice! > 0
            ? b.agreedPrice!.toStringAsFixed(0)
            : '1500');

    final pinController = TextEditingController();
    final amountController = TextEditingController(
        text: isRejected ? visitOnlyAmount : normalAmount);
    final noteController = TextEditingController();
    bool isSubmitting = false;
    String? errorMessage;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: ctx.themeSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.verified_outlined,
                  color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                context.l10n.verifyAndFinish,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Text(context.l10n.completionTypeNormal,
                            style: const TextStyle(fontSize: 12)),
                        selected: completionType == 'normal',
                        onSelected: isRejected
                            ? null
                            : (sel) {
                                if (sel) {
                                  setDialogState(() {
                                    completionType = 'normal';
                                    amountController.text = normalAmount;
                                  });
                                }
                              },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: Text(context.l10n.completionTypeVisitOnly,
                            style: const TextStyle(fontSize: 12)),
                        selected: completionType == 'visit_only',
                        onSelected: (sel) {
                          if (sel) {
                            setDialogState(() {
                              completionType = 'visit_only';
                              amountController.text = visitOnlyAmount;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  completionType == 'visit_only'
                      ? context.l10n.visitFeeOnlyDescription
                      : context.l10n.payProviderDirectlyTip,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: ctx.themeTextSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  context.l10n.pinCode,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••••',
                    filled: true,
                    fillColor: ctx.themeSurfaceLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: ctx.themeBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  context.l10n.cashReceived,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    prefixText: 'LKR ',
                    filled: true,
                    fillColor: ctx.themeSurfaceLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: ctx.themeBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  context.l10n.paymentNoteOptional,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: noteController,
                  decoration: InputDecoration(
                    hintText: context.l10n.paymentNoteHint,
                    filled: true,
                    fillColor: ctx.themeSurfaceLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: ctx.themeBorder),
                    ),
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: Text(context.l10n.cancel),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final pin = pinController.text.trim();
                      if (pin.length != 6 && pin.length != 4) {
                        setDialogState(() {
                          errorMessage = context.l10n.pleaseEnterSixDigits;
                        });
                        return;
                      }

                      final enteredAmount = double.tryParse(
                            amountController.text
                                .replaceAll(RegExp(r'[^0-9.]'), ''),
                          ) ??
                          (b.agreedPrice ?? 0);

                      if (b.agreedPrice != null &&
                          b.agreedPrice! > 0 &&
                          enteredAmount > b.agreedPrice! * 5) {
                        setDialogState(() {
                          errorMessage = context.l10n.finalAmountExceedsLimit;
                        });
                        return;
                      }

                      setDialogState(() {
                        isSubmitting = true;
                        errorMessage = null;
                      });

                      final result =
                          await BookingRepository().verifyAndCompleteJob(
                        bookingId: b.id,
                        enteredPin: pin,
                        jobRequestId: b.jobRequestId,
                        finalAmount: enteredAmount > 0 ? enteredAmount : null,
                        paymentNote: noteController.text.trim(),
                        completionType: completionType,
                      );

                      if (result.success) {
                        unawaited(LiveLocationService.instance.stopTracking());
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text(context.l10n.jobCompletedSuccessfully),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      } else {
                        setDialogState(() {
                          isSubmitting = false;
                          errorMessage = result.errorMessage ??
                              'Incorrect PIN. Please re-check with customer.';
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(context.l10n.verifyAndFinish),
            ),
          ],
        ),
      ),
    );
  }

  void _callCustomer(BuildContext context, Booking booking) {
    if (booking.customerPhone.isNotEmpty) {
      CallService.instance.startCall(
        context: context,
        calleePhone: booking.customerPhone,
        calleeName: booking.customerName,
        bookingId: booking.id,
        calleeUid: booking.customerId,
        calleeRole: 'customer',
      );
    }
  }

  Future<void> _showOutsideZoneConfirmDialog(
    BuildContext context,
    Booking booking,
    int distanceM,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.imHereGpsWrong),
        content: Text(
          context.l10n.gpsOutsideZoneAlert(distanceM.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.l10n.proceedAnyway),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _handleClaimArrival(booking, outsideZone: true);
    }
  }

  Future<void> _handleClaimArrival(Booking booking,
      {bool outsideZone = false}) async {
    try {
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (_) {}

      final decision = ArrivalZoneUtils.evaluateArrivalClaim(
        currentPosition: pos,
        cachedPosition: _lastGpsPosition,
        cachedTimestamp: _lastGpsTimestamp,
        customerLat: booking.customerLatitude,
        customerLng: booking.customerLongitude,
        forceOutsideZone: outsideZone,
      );

      if (!decision.hasRealGps && !outsideZone) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.locationPermissionRequired),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      await BookingRepository().claimArrival(
        bookingId: booking.id,
        latitude: decision.latitude ?? 0.0,
        longitude: decision.longitude ?? 0.0,
        accuracyM: decision.accuracyM ?? 0,
        distanceM: decision.distanceM ?? -1,
        outsideZone: decision.outsideZone,
        isMocked: decision.isMocked,
        currentClaimCount: booking.arrivalClaimCount,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.claimSuccessNotified),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[EnRouteNavigation] _handleArrivalClaim error: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.somethingWentWrong),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleAutoStart(Booking booking) async {
    try {
      await BookingRepository().autoStartArrival(
        bookingId: booking.id,
        jobRequestId: booking.jobRequestId,
      );
      unawaited(LiveLocationService.instance.stopTracking());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.arrivalConfirmedNotified),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[EnRouteNavigation] _handleAutoStart error: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.somethingWentWrong),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildArrivalSection(BuildContext context, Booking booking) {
    final isInProgress = booking.status == JobStatus.inProgress ||
        booking.status == JobStatus.completed;

    if (isInProgress) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.success, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.arrivalRecordedReady,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ProviderPriceExtrasCard(
            bookingId: booking.id,
            onCompleteVisitOnly: () => _promptCompletionPin(
              context,
              defaultCompletionType: 'visit_only',
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              foregroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.photo_library_outlined, size: 20),
            label: Text(
              context.l10n.jobPhotos,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
            onPressed: () {
              JobPhotosSheet.show(context, booking: booking, isProvider: true);
            },
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.check_circle_outline, size: 20),
            label: Text(
              context.l10n.completeJobEnterPin,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            onPressed: () => _promptCompletionPin(context),
          ),
        ],
      );
    }

    if (booking.arrivalStatus == 'claimed') {
      final claimedAt = booking.arrivalClaimedAt;
      final elapsedMinutes = claimedAt != null
          ? DateTime.now().difference(claimedAt).inMinutes
          : 0;
      final canAutoStart = (booking.arrivalOutsideZone == false) &&
          (booking.arrivalMocked == false) &&
          elapsedMinutes >= 10;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.themeSurfaceLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.themeBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.hourglass_top_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.waitingCustomerConfirmation,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (booking.arrivalOutsideZone == true ||
                booking.arrivalMocked == true) ...[
              Text(
                context.l10n.callCustomerToConfirm,
                style:
                    TextStyle(fontSize: 12, color: context.themeTextSecondary),
              ),
              const SizedBox(height: 10),
              if (booking.customerPhone.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => _callCustomer(context, booking),
                  icon: const Icon(Icons.call, size: 16),
                  label: Text(context.l10n.callCustomer),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
            ] else if (canAutoStart) ...[
              Text(
                context.l10n.customerDidNotAnswer,
                style:
                    TextStyle(fontSize: 12, color: context.themeTextSecondary),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => _handleAutoStart(booking),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(context.l10n.startJobVerifiedGps),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
            ] else ...[
              Text(
                context.l10n.customerWillBeNotified,
                style: TextStyle(
                    fontSize: 11.5, color: context.themeTextSecondary),
              ),
            ],
          ],
        ),
      );
    }

    if (booking.arrivalStatus == 'denied') {
      final claimCount = booking.arrivalClaimCount;
      final canReclaim = claimCount < 3;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.error, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.arrivalDeniedFlag,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.arrivalDeniedProviderNotice,
              style:
                  TextStyle(fontSize: 12.5, color: context.themeTextSecondary),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final hasPhone = booking.customerPhone.isNotEmpty;
                final callBtn = hasPhone
                    ? OutlinedButton.icon(
                        onPressed: () => _callCustomer(context, booking),
                        icon: const Icon(Icons.call, size: 16),
                        label: Text(context.l10n.callCustomer),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      )
                    : null;

                final reclaimWidget = canReclaim
                    ? ElevatedButton.icon(
                        onPressed: () => _handleClaimArrival(booking),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(context.l10n.claimAgainArrival),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      )
                    : Text(
                        context.l10n.maxClaimsReached,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.error),
                      );

                if (!hasPhone) {
                  return SizedBox(
                    width: double.infinity,
                    child: reclaimWidget,
                  );
                }

                // stack buttons when narrow
                if (constraints.maxWidth < 360) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: double.infinity, child: callBtn),
                      const SizedBox(height: 8),
                      SizedBox(width: double.infinity, child: reclaimWidget),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: callBtn!),
                    const SizedBox(width: 8),
                    Expanded(child: reclaimWidget),
                  ],
                );
              },
            ),
          ],
        ),
      );
    }

    // Default en_route: check zone
    int distanceM = 999999;
    int accuracyM = 15;
    if (_currentGpsPosition != null &&
        booking.customerLatitude != null &&
        booking.customerLongitude != null) {
      distanceM = Geolocator.distanceBetween(
        _currentGpsPosition!.latitude,
        _currentGpsPosition!.longitude,
        booking.customerLatitude!,
        booking.customerLongitude!,
      ).round();
    }

    final insideZone = ArrivalZoneUtils.isInsideZone(distanceM, accuracyM);

    if (insideZone) {
      return Column(
        children: [
          SlideToConfirm(
            label: context.l10n.slideToClaimArrival,
            onConfirmed: () => _handleClaimArrival(booking, outsideZone: false),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              context.l10n.customerWillBeNotified,
              style:
                  TextStyle(fontSize: 11.5, color: context.themeTextSecondary),
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.themeSurfaceLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.themeBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.navigation_outlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    distanceM < 999999
                        ? context.l10n.youAreMetersAway(distanceM.toString())
                        : context.l10n.customerLocation,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.wrong_location_outlined, size: 20),
            label: Text(
              context.l10n.imHereGpsWrong,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
            onPressed: () =>
                _showOutsideZoneConfirmDialog(context, booking, distanceM),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.booking != null && widget.booking!.id.isNotEmpty) {
      return StreamBuilder<Booking?>(
        stream: BookingRepository().streamBooking(widget.booking!.id),
        initialData: widget.booking,
        builder: (context, snapshot) {
          final booking = snapshot.data ?? widget.booking;
          return _buildContent(context, booking);
        },
      );
    }
    return _buildContent(context, widget.booking);
  }

  Widget _buildContent(BuildContext context, Booking? booking) {
    final customerPoint = _getCustomerPoint(booking);
    final hasCustomerLocation = customerPoint != null;

    final techPoint = ExactLocationHelper.resolveTechPoint(_currentGpsPosition);

    final LatLng midPoint = (customerPoint != null && techPoint != null)
        ? LatLng(
            (customerPoint.latitude + techPoint.latitude) / 2,
            (customerPoint.longitude + techPoint.longitude) / 2,
          )
        : (customerPoint ?? techPoint ?? const LatLng(6.9271, 79.8612));

    if (_currentRoute == null &&
        _currentGpsPosition != null &&
        customerPoint != null &&
        !_isFetchingRoute) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshRouteIfNeeded(booking);
      });
    }

    if (booking?.jobRequestId != null && booking!.jobRequestId!.isNotEmpty) {
      _ensureJobRequestLoaded(booking.jobRequestId);
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          context.l10n.enRouteNavigation,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          if (booking != null)
            IconButton(
              tooltip: context.l10n.cancelBookingOrQuote,
              icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
              onPressed: () async {
                final cancelled = await BookingCancellationSheet.show(
                  context,
                  booking: booking,
                  isCustomer: false,
                );
                if (cancelled == true && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: context.themeSurfaceLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.themeBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      booking != null && booking.customerName.isNotEmpty
                          ? context.l10n
                              .customerLocationNamed(booking.customerName)
                          : context.l10n.customerLocation,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!hasCustomerLocation)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.4),
                      width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_off_rounded,
                            color: AppColors.warning, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.l10n.customerLocationMissingCallCustomer,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              color: context.themeTextPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.customerLocationNotAvailableDesc,
                      style: TextStyle(
                          fontSize: 12.5, color: context.themeTextSecondary),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (booking != null && booking.customerPhone.isNotEmpty)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final b = booking;
                                CallService.instance.startCall(
                                  context: context,
                                  calleePhone: b.customerPhone,
                                  calleeName: b.customerName,
                                  bookingId: b.id,
                                  calleeUid: b.customerId,
                                  calleeRole: 'customer',
                                );
                              },
                              icon: const Icon(Icons.call, size: 16),
                              label: Text(context.l10n.callCustomer),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        if (booking?.customerPhone.isNotEmpty == true)
                          const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => DirectChatScreen(
                                    otherPartyId: booking?.customerId ?? '',
                                    otherPartyName: booking?.customerName ??
                                        context.l10n.roleCustomer,
                                    otherPartyRole: 'customer',
                                    otherPartyPhone: booking?.customerPhone,
                                    jobRequestId: booking?.jobRequestId,
                                  ),
                                ),
                              );
                            },
                            icon:
                                const Icon(Icons.chat_bubble_outline, size: 16),
                            label: Text(context.l10n.chat),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (techPoint == null)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: context.themeSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.themeBorder),
                ),
                child: Row(
                  children: [
                    if (_gpsFailed)
                      const Icon(Icons.location_off_rounded,
                          color: AppColors.warning, size: 22)
                    else
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.l10n.gettingYourLocation,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.themeTextPrimary,
                        ),
                      ),
                    ),
                    if (_gpsFailed)
                      TextButton.icon(
                        onPressed: _initLiveTracking,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(context.l10n.tryAgain),
                      ),
                  ],
                ),
              ),
            _ProviderEnRouteMapCard(
              techPoint: techPoint,
              customerPoint: customerPoint,
              midPoint: midPoint,
              customerLabel: booking != null && booking.customerName.isNotEmpty
                  ? booking.customerName
                  : context.l10n.roleCustomer,
              route: _currentRoute ??
                  (techPoint != null && customerPoint != null
                      ? RouteInfo.fallback(techPoint, customerPoint)
                      : RouteInfo.empty()),
              booking: booking,
              hasCustomerLocation: hasCustomerLocation,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.themeSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.themeBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: context.isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.12),
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppColors.primary,
                          size: 22,
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
                                  booking?.customerName.isNotEmpty == true
                                      ? booking!.customerName
                                      : context.l10n.customerLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 13,
                                  color: context.themeTextSecondary,
                                ),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    booking?.location.isNotEmpty == true
                                        ? booking!.location
                                        : context.l10n.provLocationNotSet,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: context.themeTextSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (booking?.scheduledDate != null) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    size: 13,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      booking!
                                          .formattedScheduledSummary(context),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: context.l10n.chatWithCustomer,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DirectChatScreen(
                                otherPartyId: booking?.customerId ?? '',
                                otherPartyName:
                                    booking?.customerName.isNotEmpty == true
                                        ? booking!.customerName
                                        : context.l10n.roleCustomer,
                                otherPartyRole: 'customer',
                                otherPartyPhone: booking?.customerPhone ?? '',
                                jobRequestId: booking?.jobRequestId,
                              ),
                            ),
                          );
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: context.themeSurfaceLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: context.themeBorder),
                          ),
                          padding: const EdgeInsets.all(8),
                        ),
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        tooltip: context.l10n.callCustomerPhone,
                        onPressed: () {
                          final phone = booking?.customerPhone ?? '';
                          if (phone.isNotEmpty) {
                            CallService.instance.startCall(
                              context: context,
                              calleePhone: phone,
                              calleeName: booking?.customerName ??
                                  context.l10n.roleCustomer,
                              bookingId: booking?.id,
                              calleeUid: booking?.customerId,
                              calleeRole: 'customer',
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    context.l10n.customerPhoneNotAvailable),
                              ),
                            );
                          }
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: context.themeSurfaceLow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: context.themeBorder),
                          ),
                          padding: const EdgeInsets.all(8),
                        ),
                        icon: const Icon(
                          Icons.phone_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(
                      height: 1,
                      color: context.themeBorder,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.key_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.entryInstructionsLabel.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 9.5,
                                letterSpacing: 0.6,
                                color: context.themeTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              booking?.entryInstructions?.isNotEmpty == true
                                  ? booking!.entryInstructions!
                                  : context.l10n.noSpecialEntryInstructions,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (booking?.jobRequestId != null &&
                      booking!.jobRequestId!.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        height: 1,
                        color: context.themeBorder,
                      ),
                    ),
                    FutureBuilder<JobRequest?>(
                      future: _jobRequestFuture,
                      builder: (ctx, snap) {
                        final jr = snap.data;
                        if (jr == null ||
                            (jr.photoUrls.isEmpty &&
                                (jr.videoUrl == null ||
                                    jr.videoUrl!.isEmpty))) {
                          return const SizedBox.shrink();
                        }
                        return JobMediaGallery(
                          photoUrls: jr.photoUrls,
                          videoUrl: jr.videoUrl,
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.themeSurfaceLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.themeBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.payments_rounded,
                      color: Color(0xFF22C55E),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.l10n.directPayCash,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    booking?.agreedPrice != null
                        ? 'LKR ${booking!.agreedPrice!.toStringAsFixed(0)}'
                        : (booking?.estRate.isNotEmpty == true
                            ? booking!.estRate
                            : context.l10n.provDirectPay),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (booking != null) _buildArrivalSection(context, booking),
            const SizedBox(height: 16),
            AppOutlineButton(
              label: context.l10n.reportTrafficDelay,
              icon: Icons.warning_amber_rounded,
              color: AppColors.error,
              onPressed: () => _showDelayReasons(context),
            ),
            const SizedBox(height: 10),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _currentGpsPosition != null
                          ? const Color(0xFF22C55E)
                          : context.themeTextSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _currentGpsPosition != null
                        ? context.l10n.gpsActiveDevice
                        : context.l10n.gpsActivePrecision,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.themeTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DelayChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onSelected;
  const _DelayChip(this.icon, this.label, {required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelected,
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: context.themeTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderEnRouteMapCard extends StatefulWidget {
  final LatLng? techPoint;
  final LatLng? customerPoint;
  final LatLng midPoint;
  final String customerLabel;
  final RouteInfo route;
  final Booking? booking;
  final bool hasCustomerLocation;

  const _ProviderEnRouteMapCard({
    required this.techPoint,
    required this.customerPoint,
    required this.midPoint,
    required this.customerLabel,
    required this.route,
    required this.booking,
    this.hasCustomerLocation = true,
  });

  @override
  State<_ProviderEnRouteMapCard> createState() =>
      _ProviderEnRouteMapCardState();
}

class _ProviderEnRouteMapCardState extends State<_ProviderEnRouteMapCard> {
  late final ValueNotifier<List<AppMapMarker>> _markersNotifier;
  late final ValueNotifier<List<LatLng>?> _routePointsNotifier;
  late final ValueNotifier<bool> _isRouteEstimatedNotifier;
  ModalRoute? _fullScreenRoute;

  @override
  void initState() {
    super.initState();
    _markersNotifier = ValueNotifier<List<AppMapMarker>>(_buildMarkers());
    _routePointsNotifier = ValueNotifier<List<LatLng>?>(
        widget.hasCustomerLocation && widget.techPoint != null
            ? widget.route.points
            : null);
    _isRouteEstimatedNotifier = ValueNotifier<bool>(widget.route.isEstimated);
  }

  @override
  void didUpdateWidget(covariant _ProviderEnRouteMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.techPoint != widget.techPoint ||
        oldWidget.customerPoint != widget.customerPoint ||
        oldWidget.customerLabel != widget.customerLabel ||
        oldWidget.hasCustomerLocation != widget.hasCustomerLocation) {
      _markersNotifier.value = _buildMarkers();
    }
    if (oldWidget.route != widget.route ||
        oldWidget.route.points != widget.route.points ||
        oldWidget.techPoint != widget.techPoint ||
        oldWidget.hasCustomerLocation != widget.hasCustomerLocation) {
      _routePointsNotifier.value =
          widget.hasCustomerLocation && widget.techPoint != null
              ? widget.route.points
              : null;
      _isRouteEstimatedNotifier.value = widget.route.isEstimated;
    }
  }

  List<AppMapMarker> _buildMarkers() {
    return [
      if (widget.techPoint != null)
        AppMapMarker.provider(
          point: widget.techPoint!,
          label: mounted ? context.l10n.youEnRoute : '',
          enRoute: true,
        ),
      if (widget.hasCustomerLocation && widget.customerPoint != null)
        AppMapMarker.customer(
          point: widget.customerPoint!,
          label: widget.customerLabel,
        ),
    ];
  }

  void _openFullScreen() {
    final center = widget.hasCustomerLocation && widget.customerPoint != null
        ? (widget.techPoint != null ? widget.midPoint : widget.customerPoint!)
        : (widget.techPoint ?? const LatLng(6.9271, 79.8612));
    final route = MaterialPageRoute<void>(
      builder: (ctx) => FullScreenMapPage(
        initialCenter: center,
        initialZoom: 14.0,
        markersNotifier: _markersNotifier,
        routePointsNotifier: _routePointsNotifier,
        isRouteDashedNotifier: _isRouteEstimatedNotifier,
      ),
    );
    _fullScreenRoute = route;
    Navigator.of(context).push(route).then((_) {
      _fullScreenRoute = null;
    });
  }

  @override
  void dispose() {
    if (_fullScreenRoute != null && _fullScreenRoute!.isActive) {
      _fullScreenRoute!.navigator?.removeRoute(_fullScreenRoute!);
      _fullScreenRoute = null;
    }
    _markersNotifier.dispose();
    _routePointsNotifier.dispose();
    _isRouteEstimatedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final customerPoint = widget.customerPoint;
    final techPoint = widget.techPoint;
    final route = widget.route;

    final initialCenter = (widget.hasCustomerLocation && customerPoint != null)
        ? (techPoint != null ? widget.midPoint : customerPoint)
        : (techPoint ?? const LatLng(6.9271, 79.8612));

    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ValueListenableBuilder<List<AppMapMarker>>(
              valueListenable: _markersNotifier,
              builder: (context, markers, _) {
                return ValueListenableBuilder<List<LatLng>?>(
                  valueListenable: _routePointsNotifier,
                  builder: (context, routePoints, _) {
                    return ValueListenableBuilder<bool>(
                      valueListenable: _isRouteEstimatedNotifier,
                      builder: (context, isEstimated, _) {
                        return AppMapView(
                          initialCenter: initialCenter,
                          initialZoom: 14.0,
                          interactive: true,
                          routePoints: (widget.hasCustomerLocation && techPoint != null)
                              ? routePoints
                              : null,
                          isRouteDashed: isEstimated,
                          markers: markers,
                          onExpand: _openFullScreen,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 54,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.themeSurface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.themeBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: context.isDark ? 0.35 : 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.turn_left_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          techPoint == null
                              ? context.l10n.gettingYourLocation
                              : context.l10n
                                  .inDistance(route.formattedDistance),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: context.themeTextSecondary,
                          ),
                        ),
                        Text(
                          context.l10n.navigatingTo(
                              booking?.customerName.isNotEmpty == true
                                  ? booking!.customerName
                                  : context.l10n.roleCustomer),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (techPoint != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          route.formattedDuration,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          route.formattedDistance,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: context.themeTextSecondary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (customerPoint != null)
            Positioned(
              bottom: 12,
              left: 12,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final ok = await MapLauncher.openDirections(
                    latitude: customerPoint.latitude,
                    longitude: customerPoint.longitude,
                    destinationTitle:
                        booking != null && booking.customerName.isNotEmpty
                            ? context.l10n
                                .customerLocationNamed(booking.customerName)
                            : context.l10n.customerLocation,
                  );
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.couldNotOpenMaps),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                icon: const Icon(
                  Icons.navigation_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                label: Text(
                  context.l10n.googleMapsOrWaze,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: context.themeTextPrimary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: context.themeSurface.withValues(alpha: 0.94),
                  side: BorderSide(color: context.themeBorder),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
