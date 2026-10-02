import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_theme.dart';
import '../../../models/technician.dart';
import '../../../repositories/technician_repository.dart';
import '../../../repositories/booking_repository.dart';
import '../../../shared/widgets/pill_badge.dart';
import '../../../shared/widgets/outline_button.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/icon_square_button.dart';
import 'package:latlong2/latlong.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/location_utils.dart';
import '../../../shared/widgets/app_map_view.dart';
import '../../../services/routing_service.dart';
import '../../../utils/map_launcher.dart';
import '../../../models/booking.dart';
import '../../../services/live_location_service.dart';
import 'direct_chat_screen.dart';
import 'rating_completion_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_discovery_screen.dart';
import '../../../shared/widgets/user_avatar.dart';

class LiveTrackingScreen extends StatelessWidget {
  final Technician? technician;
  final Booking? booking;
  final bool showBottomNav;

  const LiveTrackingScreen({
    super.key,
    this.technician,
    this.booking,
    this.showBottomNav = true,
  });

  @override
  Widget build(BuildContext context) {
    if (technician != null) {
      return _buildScaffold(context, technician!, booking);
    }

    if (booking != null) {
      return StreamBuilder<Technician?>(
        stream: TechnicianRepository().streamById(booking!.providerId),
        builder: (context, techSnap) {
          final tech = techSnap.data;
          if (tech == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return _buildScaffold(context, tech, booking);
        },
      );
    }

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) {
      return _buildEmptyState(context);
    }

    return StreamBuilder<List<Booking>>(
      stream: BookingRepository().streamBookingsForCustomer(currentUid),
      builder: (context, bSnapshot) {
        if (bSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final bookings = bSnapshot.data ?? [];
        final activeBooking = bookings
            .where((b) => b.status != 'completed' && b.status != 'cancelled')
            .firstOrNull;

        if (activeBooking == null) {
          return _buildEmptyState(context);
        }

        return StreamBuilder<Technician?>(
          stream: TechnicianRepository().streamById(activeBooking.providerId),
          builder: (context, techSnap) {
            final tech = techSnap.data;
            if (tech == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return _buildScaffold(context, tech, activeBooking);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.liveTracking)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, AppBottomNav.contentBottomPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.near_me_outlined,
                    size: 50, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.noActiveDispatch,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.noActiveDispatchSub,
                style: TextStyle(
                  color: context.themeTextSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: context.l10n.navExplore,
                leadingIcon: Icons.explore,
                expand: false,
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) =>
                          const HomeDiscoveryScreen(initialIndex: 0),
                    ),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: showBottomNav
          ? AppBottomNav(
              currentIndex: 2,
              onTap: (i) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => HomeDiscoveryScreen(initialIndex: i),
                  ),
                  (route) => false,
                );
              },
              items: [
                NavItem(Icons.explore, context.l10n.navExplore),
                NavItem(Icons.calendar_month, context.l10n.navBookings),
                NavItem(Icons.near_me, context.l10n.navTracking),
                NavItem(Icons.person, context.l10n.navProfile),
              ],
            )
          : null,
    );
  }

  Widget _buildScaffold(BuildContext context, Technician tech,
      [Booking? overrideBooking]) {
    final effectiveBooking = overrideBooking ?? booking;
    return StreamBuilder<Booking?>(
      stream: effectiveBooking != null && effectiveBooking.id.isNotEmpty
          ? BookingRepository().streamBooking(effectiveBooking.id)
          : Stream.value(effectiveBooking),
      initialData: effectiveBooking,
      builder: (context, bSnap) {
        final currentBooking = bSnap.data ?? effectiveBooking;

        return Scaffold(
          appBar: AppBar(
            leading: !showBottomNav
                ? Center(
                    child: IconSquareButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.maybePop(context),
                    ),
                  )
                : null,
            title: Text(context.l10n.liveTracking),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                    child: PillBadge(
                        label: tech.serviceArea.isNotEmpty
                            ? tech.serviceArea
                            : 'Colombo 03',
                        icon: Icons.location_on)),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, AppBottomNav.contentBottomPadding),
              children: [
                StreamBuilder<LatLng?>(
                    stream: LiveLocationService.instance
                        .streamUserLocation(tech.id),
                    builder: (context, locSnapshot) {
                      final liveTechPoint = locSnapshot.data;
                      final isLive = liveTechPoint != null;

                      final LatLng customerPoint;
                      if (currentBooking?.customerLatitude != null &&
                          currentBooking?.customerLongitude != null) {
                        customerPoint = LatLng(
                            currentBooking!.customerLatitude!,
                            currentBooking.customerLongitude!);
                      } else {
                        final baseCoord = LocationUtils.getDistrictCoordinates(
                            tech.serviceArea.isNotEmpty
                                ? tech.serviceArea
                                : 'Colombo');
                        customerPoint = LatLng(baseCoord.lat, baseCoord.lng);
                      }

                      final techPoint = liveTechPoint ??
                          LatLng(customerPoint.latitude - 0.008,
                              customerPoint.longitude - 0.012);
                      final midPoint = LatLng(
                        (customerPoint.latitude + techPoint.latitude) / 2,
                        (customerPoint.longitude + techPoint.longitude) / 2,
                      );

                      return FutureBuilder<RouteInfo>(
                        future: RoutingService().getDrivingRoute(
                          origin: techPoint,
                          destination: customerPoint,
                        ),
                        builder: (context, snapshot) {
                          final route = snapshot.data ??
                              RouteInfo.fallback(techPoint, customerPoint);

                          return Column(
                            children: [
                              Container(
                                height: 220,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: context.themeBorder),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Stack(
                                    children: [
                                      AppMapView(
                                        initialCenter: midPoint,
                                        initialZoom: 14.2,
                                        interactive: true,
                                        routePoints: route.points,
                                        markers: [
                                          AppMapMarker.provider(
                                            point: techPoint,
                                            label: tech.name.isNotEmpty
                                                ? tech.name
                                                : 'Artisan',
                                            enRoute: true,
                                          ),
                                          AppMapMarker.customer(
                                            point: customerPoint,
                                            label: 'Destination',
                                          ),
                                        ],
                                      ),
                                      Positioned(
                                        top: 12,
                                        left: 12,
                                        child: PillBadge(
                                          label: isLive
                                              ? 'Live GPS • On the way'
                                              : context.l10n.techOnTheWay,
                                          icon: isLive ? Icons.sensors : null,
                                          background: context.themeSurface,
                                          foreground: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              AppCard(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(children: [
                                      const Icon(Icons.timer,
                                          color: AppColors.primary, size: 22),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(context.l10n.estimatedArrival,
                                              style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: context
                                                      .themeTextSecondary)),
                                          Text(
                                              '${context.l10n.arrivingIn} ${route.formattedDuration}',
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w800)),
                                        ],
                                      ),
                                    ]),
                                    Row(children: [
                                      Icon(Icons.navigation,
                                          size: 16,
                                          color: context.themeTextSecondary),
                                      const SizedBox(width: 4),
                                      Text(route.formattedDistance,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700)),
                                    ]),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    }),
                if (currentBooking?.delayReason != null &&
                    currentBooking!.delayReason!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.error, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ETA Adjusted: +${currentBooking.delayMinutes ?? 10} Mins Delay',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.error),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Artisan reported: ${currentBooking.delayReason}',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    color: context.themeTextSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(children: [
                        UserAvatar(
                          uid: tech.id,
                          displayName: tech.name,
                          radius: 24,
                          backgroundColor: tech.avatarColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Icon(Icons.star,
                                    size: 14,
                                    color: AppColors.secondaryContainer),
                                Text(' ${tech.rating}  ',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12)),
                                Expanded(
                                    child: Text(tech.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis)),
                              ]),
                              Row(children: [
                                const Icon(Icons.verified,
                                    size: 12, color: AppColors.primary),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    '${tech.title} • ${tech.jobsCount} ${context.l10n.completedJobs}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: context.themeTextSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ]),
                              Row(children: [
                                Icon(Icons.motorcycle,
                                    size: 12,
                                    color: context.themeTextSecondary),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    tech.serviceArea.isNotEmpty
                                        ? tech.serviceArea
                                        : 'Western Province',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: context.themeTextSecondary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ]),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(
                            child: AppOutlineButton(
                                label: context.l10n.callTech,
                                icon: Icons.call,
                                onPressed: () {
                                  final phone = tech.phone;
                                  if (phone.isNotEmpty) {
                                    MapLauncher.openPhoneCall(phone);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Provider phone not available')),
                                    );
                                  }
                                })),
                        const SizedBox(width: 10),
                        Expanded(
                            child: AppOutlineButton(
                                label: context.l10n.chat,
                                icon: Icons.chat,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DirectChatScreen(
                                        otherPartyId: tech.id,
                                        otherPartyName: tech.name,
                                        otherPartyRole: tech.title,
                                        otherPartyPhone: tech.phone,
                                      ),
                                    ),
                                  );
                                })),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                AppCard(
                  padding: const EdgeInsets.all(14),
                  color: context.themeSurfaceLow,
                  child: Row(children: [
                    const Icon(Icons.payments, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.l10n.directPayCash,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                          Text(
                              'LKR ${tech.baseRateLkr} ${context.l10n.inspectionFeeNotice}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: context.themeTextSecondary)),
                        ],
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                      child: AppOutlineButton(
                          label: context.l10n.cancelRequest,
                          icon: Icons.cancel,
                          color: AppColors.error,
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: context.themeSurface,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                title: const Text('Cancel Request',
                                    style: TextStyle(fontWeight: FontWeight.w800)),
                                content: Text(
                                    'Are you sure you want to cancel this booking request?',
                                    style: TextStyle(
                                        color: context.themeTextSecondary)),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('No')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.error,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12))),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Yes, Cancel'),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true && context.mounted) {
                              if (currentBooking != null &&
                                  currentBooking.id.isNotEmpty) {
                                await BookingRepository().updateStatus(
                                    currentBooking.id, 'cancelled');
                              }
                              if (!context.mounted) return;
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Service request cancelled.')),
                              );
                            }
                          })),
                  const SizedBox(width: 10),
                  Expanded(
                      child: AppOutlineButton(
                          label: context.l10n.shareTrip,
                          icon: Icons.share_location,
                          onPressed: () {
                            final trackingLink =
                                'https://helaservice.lk/track/${currentBooking?.id ?? tech.id}';
                            Clipboard.setData(ClipboardData(
                                text:
                                    'Track my HelaService artisan live here: $trackingLink'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Live tracking link copied to clipboard!'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          })),
                ]),
                const SizedBox(height: 14),
                PrimaryButton(
                  label: context.l10n.jobFinishedRatePay,
                  leadingIcon: Icons.check_circle,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RatingCompletionScreen(
                        technician: tech,
                        bookingId: currentBooking?.id ?? '',
                        jobRequestId: currentBooking?.jobRequestId ?? '',
                        jobTitle: currentBooking?.title.isNotEmpty == true
                            ? currentBooking!.title
                            : tech.title,
                        totalPrice: currentBooking?.agreedPrice ??
                            tech.baseRateLkr.toDouble(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: showBottomNav
              ? AppBottomNav(
                  currentIndex: 2,
                  onTap: (i) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => HomeDiscoveryScreen(initialIndex: i),
                      ),
                      (route) => false,
                    );
                  },
                  items: [
                    NavItem(Icons.explore, context.l10n.navExplore),
                    NavItem(Icons.calendar_month, context.l10n.navBookings),
                    NavItem(Icons.near_me, context.l10n.navTracking),
                    NavItem(Icons.person, context.l10n.navProfile),
                  ],
                )
              : null,
        );
      },
    );
  }
}
