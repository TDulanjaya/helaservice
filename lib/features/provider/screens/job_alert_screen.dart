import 'dart:async';
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/outline_button.dart';
import 'en_route_navigation_screen.dart';

import '../../../models/booking.dart';
import '../../../repositories/booking_repository.dart';

class JobAlertScreen extends StatefulWidget {
  final Booking? booking;
  const JobAlertScreen({super.key, this.booking});

  @override
  State<JobAlertScreen> createState() => _JobAlertScreenState();
}

class _JobAlertScreenState extends State<JobAlertScreen> {
  int _secondsLeft = 38;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        if (mounted) Navigator.of(context).pop();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.onSurface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(children: [
                const Icon(Icons.handyman, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                const Text('EXPRESS DISPATCH ROUTE',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 11, letterSpacing: 1)),
                const Spacer(),
                const Icon(Icons.volume_up, color: Colors.white70, size: 14),
                Text(' Auto-passes in $_secondsLeft s',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 11)),
              ]),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: context.themeSurface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: context.themeBorder)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(children: [
                          Icon(Icons.bolt, color: AppColors.secondaryContainer),
                          SizedBox(width: 6),
                          Text('New Job Request',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ]),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: AppColors.errorContainer,
                              borderRadius: BorderRadius.circular(999)),
                          child: const Text('URGENT',
                              style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppColors.primary, width: 3)),
                      child: Text('$_secondsLeft\nsec',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 14),
                    Row(children: [
                      const Icon(Icons.handyman, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(widget.booking?.title ?? 'Service Request',
                              style: const TextStyle(fontWeight: FontWeight.w600))),
                    ]),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: context.themeSurfaceLow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.themeBorder)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Guaranteed Base Payout',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: context.themeTextSecondary)),
                              Text(widget.booking?.estRate.isNotEmpty == true ? widget.booking!.estRate : 'LKR 2,500',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17)),
                            ],
                          ),
                          Text('Direct Settlement\nCash at Service Site',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: context.themeTextSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      CircleAvatar(
                          radius: 16,
                          backgroundColor: context.themeSurfaceContainer,
                          child: Text(widget.booking?.customerInitials.isNotEmpty == true ? widget.booking!.customerInitials : 'CU',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(widget.booking?.customerName.isNotEmpty == true ? widget.booking!.customerName : 'Direct Customer',
                              style: const TextStyle(fontWeight: FontWeight.w600))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user, size: 12, color: AppColors.primary),
                            SizedBox(width: 3),
                            Text('Verified', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      Icon(Icons.navigation,
                          size: 14, color: context.themeTextSecondary),
                      const SizedBox(width: 4),
                      Text(widget.booking?.distance.isNotEmpty == true ? widget.booking!.distance : 'Nearby',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                    Row(children: [
                      Icon(Icons.location_on,
                          size: 14, color: context.themeTextSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(widget.booking?.location.isNotEmpty == true ? widget.booking!.location : 'Client Address',
                              style: const TextStyle(fontSize: 12))),
                    ]),
                    Row(children: [
                      Icon(Icons.two_wheeler,
                          size: 14, color: context.themeTextSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                          child: Text(
                              'Fastest direct route available',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: context.themeTextSecondary))),
                    ]),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: AppColors.errorContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(children: [
                            Icon(Icons.warning,
                                size: 14, color: AppColors.error),
                            SizedBox(width: 4),
                            Text('Service Note',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12))
                          ]),
                          const SizedBox(height: 4),
                          Text(
                              widget.booking?.title ?? 'Service Request',
                              style: const TextStyle(
                                  fontSize: 12, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Accept Job ($_secondsLeft s)',
                trailingIcon: Icons.check_circle,
                onPressed: () async {
                  _timer?.cancel();
                  if (widget.booking != null && widget.booking!.id.isNotEmpty) {
                    await BookingRepository().acceptBookingByProvider(
                      bookingId: widget.booking!.id,
                      jobRequestId: widget.booking!.jobRequestId,
                    );
                  }
                  if (!context.mounted) return;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (_) => EnRouteNavigationScreen(booking: widget.booking)),
                  );
                },
              ),
              const SizedBox(height: 10),
              AppOutlineButton(
                label: 'Pass to Next Available Artisan',
                icon: Icons.cancel,
                color: Colors.white,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 10),
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.security, size: 12, color: Colors.white54),
                SizedBox(width: 4),
                Text('Pull over safely before confirming arrival navigation',
                    style: TextStyle(color: Colors.white54, fontSize: 10)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
