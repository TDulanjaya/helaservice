import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../theme/app_theme.dart';
import '../../../models/booking.dart';
import '../../../utils/location_utils.dart';
import '../../../utils/map_launcher.dart';
import '../../../shared/widgets/app_map_view.dart';
import '../../../services/routing_service.dart';
import '../../../services/live_location_service.dart';
import '../../../state/role_provider.dart';
import '../../../repositories/booking_repository.dart';
import '../../customer/screens/direct_chat_screen.dart';
import '../../../shared/widgets/slide_to_confirm.dart';
import '../../../shared/widgets/outline_button.dart';
import '../../../utils/l10n_extension.dart';

class EnRouteNavigationScreen extends StatefulWidget {
  final Booking? booking;
  const EnRouteNavigationScreen({super.key, this.booking});

  @override
  State<EnRouteNavigationScreen> createState() => _EnRouteNavigationScreenState();
}

class _EnRouteNavigationScreenState extends State<EnRouteNavigationScreen> {
  LatLng? _currentGpsPosition;
  String _providerId = '';
  bool _isArrived = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLiveTracking();
    });
  }

  Future<void> _initLiveTracking() async {
    final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
    _providerId = roleProvider.currentUser?.id ?? widget.booking?.providerId ?? '';

    if (_providerId.isNotEmpty) {
      final customerId = widget.booking?.customerId;
      await LiveLocationService.instance.startTracking(
        _providerId,
        allowedViewers: customerId != null && customerId.isNotEmpty ? [customerId] : null,
      );
    }

    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
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
      backgroundColor: context.themeSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                    child: Text(context.l10n.reportEnRouteDelay,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16))),
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close)),
              ]),
              Text(
                  context.l10n.selectDelayReason,
                  style:
                      TextStyle(color: context.themeTextSecondary, fontSize: 12)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _DelayChip(Icons.traffic, context.l10n.heavyTraffic, onSelected: () => _handleDelaySelected(context.l10n.heavyTraffic)),
                _DelayChip(Icons.water_drop_outlined, context.l10n.monsoonRain, onSelected: () => _handleDelaySelected(context.l10n.monsoonRain)),
                _DelayChip(Icons.alt_route, context.l10n.roadDetour, onSelected: () => _handleDelaySelected(context.l10n.roadDetour)),
                _DelayChip(Icons.local_gas_station, context.l10n.refuelingStop, onSelected: () => _handleDelaySelected(context.l10n.refuelingStop)),
              ]),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleDelaySelected(String reason) async {
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
          content: Text('Reported delay: $reason (+10 min ETA adjustment broadcasted)'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    final LatLng customerPoint;
    if (booking?.customerLatitude != null && booking?.customerLongitude != null) {
      customerPoint = LatLng(booking!.customerLatitude!, booking.customerLongitude!);
    } else {
      final destLocation = LocationUtils.getDistrictCoordinates(
          booking?.location.isNotEmpty == true ? booking!.location : 'Colombo');
      customerPoint = LatLng(destLocation.lat, destLocation.lng);
    }

    final techPoint = _currentGpsPosition ??
        LatLng(customerPoint.latitude - 0.009, customerPoint.longitude - 0.013);
    final midPoint = LatLng(
      (customerPoint.latitude + techPoint.latitude) / 2,
      (customerPoint.longitude + techPoint.longitude) / 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.enRouteNavigation),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(999)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.home, size: 13, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(booking != null && booking.customerName.isNotEmpty
                      ? "${booking.customerName}'s Location"
                      : "Customer Location",
                      style:
                          const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FutureBuilder<RouteInfo>(
              future: RoutingService().getDrivingRoute(
                origin: techPoint,
                destination: customerPoint,
              ),
              builder: (context, snapshot) {
                final route = snapshot.data ??
                    RouteInfo.fallback(techPoint, customerPoint);

                return SizedBox(
                  height: 250,
                  child: Stack(
                    children: [
                      AppMapView(
                        initialCenter: midPoint,
                        initialZoom: 14.0,
                        interactive: true,
                        routePoints: route.points,
                        markers: [
                          AppMapMarker.provider(
                            point: techPoint,
                            label: 'You (En Route)',
                            enRoute: true,
                          ),
                          AppMapMarker.customer(
                            point: customerPoint,
                            label: booking != null && booking.customerName.isNotEmpty
                                ? booking.customerName
                                : 'Customer',
                          ),
                        ],
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                              color:
                                  context.themeSurface.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.themeBorder),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(
                                        alpha: context.isDark ? 0.3 : 0.08),
                                    blurRadius: 8)
                              ]),
                          child: Row(children: [
                            const Icon(Icons.turn_left,
                                color: AppColors.primary, size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('In ${route.formattedDistance}',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: context.themeTextSecondary)),
                                  Text('Navigating to ${booking?.customerName.isNotEmpty == true ? booking!.customerName : 'Customer'}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(route.formattedDistance,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700)),
                                Text(route.formattedDuration,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: context.themeTextSecondary)),
                              ],
                            ),
                          ]),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            MapLauncher.openDirections(
                              latitude: customerPoint.latitude,
                              longitude: customerPoint.longitude,
                              destinationTitle: booking != null && booking.customerName.isNotEmpty
                                  ? "${booking.customerName}'s Location"
                                  : 'Customer Location',
                            );
                          },
                          icon: const Icon(Icons.navigation, size: 14),
                          label: Text(context.l10n.googleMapsOrWaze,
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                              backgroundColor: context.themeSurface,
                              side: BorderSide(color: context.themeBorder),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999))),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: context.themeSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.themeBorder),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.04), blurRadius: 10)
                  ]),
              child: Column(
                children: [
                  Row(children: [
                    CircleAvatar(
                        radius: 20,
                        backgroundColor: context.themeSurfaceContainer,
                        child: Icon(Icons.person,
                            color: context.themeTextSecondary)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(booking?.customerName.isNotEmpty == true ? booking!.customerName : 'Customer',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified,
                                size: 13, color: AppColors.primary)
                          ]),
                          Row(children: [
                            Icon(Icons.location_on,
                                size: 12, color: context.themeTextSecondary),
                            const SizedBox(width: 3),
                            Text(booking?.location.isNotEmpty == true ? booking!.location : 'Western Province',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: context.themeTextSecondary))
                          ]),
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
                                otherPartyName: booking?.customerName.isNotEmpty == true
                                    ? booking!.customerName
                                    : 'Customer',
                                otherPartyRole: 'Customer',
                                otherPartyPhone: booking?.customerPhone ?? '',
                                jobRequestId: booking?.jobRequestId,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat, color: AppColors.primary)),
                    IconButton(
                        tooltip: context.l10n.callCustomerPhone,
                        onPressed: () {
                          final phone = booking?.customerPhone ?? '';
                          if (phone.isNotEmpty) {
                            MapLauncher.openPhoneCall(phone);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.l10n.customerPhoneNotAvailable)),
                            );
                          }
                        },
                        icon:
                            const Icon(Icons.phone, color: AppColors.primary)),
                  ]),
                  const Divider(height: 20),
                  Row(children: [
                    const Icon(Icons.vpn_key,
                        size: 16, color: AppColors.secondaryContainer),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text.rich(TextSpan(children: [
                        TextSpan(
                            text: context.l10n.entryInstructionsLabel,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                        TextSpan(
                            text:
                                booking?.entryInstructions?.isNotEmpty == true
                                    ? booking!.entryInstructions!
                                    : context.l10n.noSpecialEntryInstructions,
                            style: const TextStyle(fontSize: 12)),
                      ])),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: context.themeSurfaceLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.themeBorder)),
              child: Row(children: [
                const Icon(Icons.payments, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.directPayCash,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12)),
                    ],
                  ),
                ),
                Text(
                  booking?.agreedPrice != null
                      ? 'LKR ${booking!.agreedPrice!.toStringAsFixed(0)}'
                      : (booking?.estRate.isNotEmpty == true ? booking!.estRate : 'Direct Pay'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ]),
            ),
            const SizedBox(height: 18),
            SlideToConfirm(
              label: _isArrived ? context.l10n.arrivedAtLocation : context.l10n.slideToConfirmArrival,
              onConfirmed: () async {
                setState(() => _isArrived = true);
                LiveLocationService.instance.stopTracking();
                if (booking != null && booking.id.isNotEmpty) {
                  await BookingRepository().updateStatus(booking.id, 'in_progress');
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
            const SizedBox(height: 6),
            Center(
              child: Text(
                _isArrived
                    ? context.l10n.arrivalRecordedReady
                    : context.l10n.customerWillBeNotified,
                style: TextStyle(
                    fontSize: 11, color: context.themeTextSecondary),
              ),
            ),
            const SizedBox(height: 14),
            AppOutlineButton(
              label: context.l10n.reportTrafficDelay,
              icon: Icons.warning,
              color: AppColors.error,
              onPressed: () => _showDelayReasons(context),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _currentGpsPosition != null
                    ? context.l10n.gpsActiveDevice
                    : context.l10n.gpsActivePrecision,
                style: TextStyle(fontSize: 11, color: context.themeTextSecondary),
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
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppColors.primary),
      label: Text(label, style: TextStyle(color: context.themeTextPrimary)),
      onPressed: onSelected,
      backgroundColor: context.themeSurfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}
