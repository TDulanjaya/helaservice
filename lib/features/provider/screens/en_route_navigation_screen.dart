import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../theme/app_theme.dart';
import '../../../constants/job_status.dart';
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

class EnRouteNavigationScreen extends StatefulWidget {
  final Booking? booking;
  const EnRouteNavigationScreen({super.key, this.booking});

  @override
  State<EnRouteNavigationScreen> createState() =>
      _EnRouteNavigationScreenState();
}

class _EnRouteNavigationScreenState extends State<EnRouteNavigationScreen> {
  LatLng? _currentGpsPosition;
  String _providerId = '';
  bool _isArrived = false;

  @override
  void initState() {
    super.initState();
    _isArrived = widget.booking?.status == JobStatus.inProgress;
    if (widget.booking != null &&
        widget.booking!.id.isNotEmpty &&
        widget.booking!.status == JobStatus.confirmed) {
      BookingRepository().startNavigation(widget.booking!.id);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLiveTracking();
    });
  }

  Future<void> _initLiveTracking() async {
    final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
    _providerId =
        roleProvider.currentUser?.id ?? widget.booking?.providerId ?? '';

    if (_providerId.isNotEmpty) {
      final customerId = widget.booking?.customerId;
      await LiveLocationService.instance.startTracking(
        _providerId,
        allowedViewers:
            customerId != null && customerId.isNotEmpty ? [customerId] : null,
      );
    }

    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high),
        );
        if (mounted) {
          setState(() {
            _currentGpsPosition = LatLng(pos.latitude, pos.longitude);
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_providerId.isNotEmpty) {
      LiveLocationService.instance.stopTracking();
    }
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
                      onSelected: () =>
                          _handleDelaySelected(
                              'Heavy Traffic', context.l10n.heavyTraffic),
                    ),
                    const SizedBox(height: 8),
                    _DelayChip(
                      Icons.water_drop_outlined,
                      context.l10n.monsoonRain,
                      onSelected: () =>
                          _handleDelaySelected(
                              'Monsoon Rain', context.l10n.monsoonRain),
                    ),
                    const SizedBox(height: 8),
                    _DelayChip(
                      Icons.alt_route_rounded,
                      context.l10n.roadDetour,
                      onSelected: () =>
                          _handleDelaySelected(
                              'Road Detour / Blocked', context.l10n.roadDetour),
                    ),
                    const SizedBox(height: 8),
                    _DelayChip(
                      Icons.local_gas_station_rounded,
                      context.l10n.refuelingStop,
                      onSelected: () =>
                          _handleDelaySelected(
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

  Future<void> _promptCompletionPin(BuildContext context) async {
    final b = widget.booking;
    if (b == null || b.id.isEmpty) return;

    final initialAmount = b.agreedPrice != null && b.agreedPrice! > 0
        ? b.agreedPrice!.toStringAsFixed(0)
        : '';
    final pinController = TextEditingController();
    final amountController = TextEditingController(text: initialAmount);
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
              const Icon(Icons.verified_outlined, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                context.l10n.verifyAndFinish,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.payProviderDirectlyTip,
                  style: TextStyle(
                    fontSize: 13,
                    color: ctx.themeTextSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  context.l10n.pinCode,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                          errorMessage = 'Please enter 6 digits';
                        });
                        return;
                      }

                      final enteredAmount = double.tryParse(
                            amountController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
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

                      final result = await BookingRepository()
                          .verifyAndCompleteJob(
                        bookingId: b.id,
                        enteredPin: pin,
                        jobRequestId: b.jobRequestId,
                        finalAmount: enteredAmount > 0 ? enteredAmount : null,
                        paymentNote: noteController.text.trim(),
                      );

                      if (result.success) {
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.l10n.jobCompletedSuccessfully),
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

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final hasCustomerLocation = booking?.customerLatitude != null &&
        booking?.customerLongitude != null;

    final LatLng customerPoint = hasCustomerLocation
        ? LatLng(booking!.customerLatitude!, booking.customerLongitude!)
        : (_currentGpsPosition ?? const LatLng(6.9271, 79.8612));

    final techPoint = _currentGpsPosition ??
        (hasCustomerLocation
            ? LatLng(customerPoint.latitude - 0.009,
                customerPoint.longitude - 0.013)
            : const LatLng(6.9271, 79.8612));

    final midPoint = hasCustomerLocation
        ? LatLng(
            (customerPoint.latitude + techPoint.latitude) / 2,
            (customerPoint.longitude + techPoint.longitude) / 2,
          )
        : techPoint;

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
                          ? context.l10n.customerLocationNamed(booking.customerName)
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
                            'Customer location not available',
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
                      'Exact GPS coordinates were not provided for this job. Contact the customer below to coordinate arrival.',
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
                                    otherPartyName:
                                        booking?.customerName ?? 'Customer',
                                    otherPartyRole: 'customer',
                                    otherPartyPhone: booking?.customerPhone,
                                    jobRequestId: booking?.jobRequestId,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline,
                                size: 16),
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
            FutureBuilder<RouteInfo>(
              future: hasCustomerLocation
                  ? RoutingService().getDrivingRoute(
                      origin: techPoint,
                      destination: customerPoint,
                    )
                  : Future.value(RouteInfo.empty()),
              builder: (context, snapshot) {
                final route = snapshot.data ??
                    RouteInfo.fallback(techPoint, customerPoint);

                return _ProviderEnRouteMapCard(
                  techPoint: techPoint,
                  customerPoint: customerPoint,
                  midPoint: midPoint,
                  customerLabel:
                      booking != null && booking.customerName.isNotEmpty
                          ? booking.customerName
                          : context.l10n.roleCustomer,
                  route: route,
                  booking: booking,
                  hasCustomerLocation: hasCustomerLocation,
                );
              },
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
                                        : 'Customer',
                                otherPartyRole: 'Customer',
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
                              calleeName: booking?.customerName ?? 'Customer',
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
            SlideToConfirm(
              label: _isArrived
                  ? context.l10n.arrivedAtLocation
                  : context.l10n.slideToConfirmArrival,
              onConfirmed: () async {
                setState(() => _isArrived = true);
                LiveLocationService.instance.stopTracking();
                if (booking != null && booking.id.isNotEmpty) {
                  await BookingRepository().confirmArrival(
                    bookingId: booking.id,
                    jobRequestId: booking.jobRequestId,
                  );
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.arrivalConfirmedNotified),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _isArrived
                    ? context.l10n.arrivalRecordedReady
                    : context.l10n.customerWillBeNotified,
                style: TextStyle(
                  fontSize: 11.5,
                  color: context.themeTextSecondary,
                ),
              ),
            ),
            if (_isArrived) ...[
              const SizedBox(height: 14),
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
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                onPressed: () {
                  if (booking != null) {
                    JobPhotosSheet.show(context, booking: booking, isProvider: true);
                  }
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
                label: const Text(
                  'Complete Job (Enter Customer PIN)',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                onPressed: () => _promptCompletionPin(context),
              ),
            ],
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
  final LatLng techPoint;
  final LatLng customerPoint;
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
  ModalRoute? _fullScreenRoute;

  @override
  void initState() {
    super.initState();
    _markersNotifier = ValueNotifier<List<AppMapMarker>>(_buildMarkers());
    _routePointsNotifier = ValueNotifier<List<LatLng>?>(
        widget.hasCustomerLocation ? widget.route.points : null);
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
    if (oldWidget.route.points != widget.route.points ||
        oldWidget.hasCustomerLocation != widget.hasCustomerLocation) {
      _routePointsNotifier.value =
          widget.hasCustomerLocation ? widget.route.points : null;
    }
  }

  List<AppMapMarker> _buildMarkers() {
    return [
      AppMapMarker.provider(
        point: widget.techPoint,
        label: mounted ? context.l10n.youEnRoute : 'You (En Route)',
        enRoute: true,
      ),
      if (widget.hasCustomerLocation)
        AppMapMarker.customer(
          point: widget.customerPoint,
          label: widget.customerLabel,
        ),
    ];
  }

  void _openFullScreen() {
    final route = MaterialPageRoute<void>(
      builder: (ctx) => FullScreenMapPage(
        initialCenter: widget.hasCustomerLocation
            ? widget.midPoint
            : widget.techPoint,
        initialZoom: 14.0,
        markersNotifier: _markersNotifier,
        routePointsNotifier: _routePointsNotifier,
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final customerPoint = widget.customerPoint;
    final route = widget.route;

    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ValueListenableBuilder<List<AppMapMarker>>(
              valueListenable: _markersNotifier,
              builder: (context, markers, _) {
                return AppMapView(
                  initialCenter: widget.hasCustomerLocation
                      ? widget.midPoint
                      : widget.techPoint,
                  initialZoom: 14.0,
                  interactive: true,
                  routePoints:
                      widget.hasCustomerLocation ? route.points : null,
                  markers: markers,
                  onExpand: _openFullScreen,
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
                          context.l10n.inDistance(route.formattedDistance),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: context.themeTextSecondary,
                          ),
                        ),
                        Text(
                          context.l10n.navigatingTo(booking?.customerName.isNotEmpty == true ? booking!.customerName : context.l10n.roleCustomer),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
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
          Positioned(
            bottom: 12,
            left: 12,
            child: OutlinedButton.icon(
              onPressed: () {
                MapLauncher.openDirections(
                  latitude: customerPoint.latitude,
                  longitude: customerPoint.longitude,
                  destinationTitle:
                      booking != null && booking.customerName.isNotEmpty
                          ? context.l10n.customerLocationNamed(booking.customerName)
                          : context.l10n.customerLocation,
                );
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
