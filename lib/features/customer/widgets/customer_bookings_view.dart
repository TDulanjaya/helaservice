import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../theme/app_theme.dart';
import '../../../models/technician.dart';
import '../../../models/booking.dart';
import '../../../repositories/technician_repository.dart';
import '../../../repositories/booking_repository.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/app_localizations_helpers.dart';
import '../screens/live_tracking_screen.dart';

class CustomerBookingsView extends StatelessWidget {
  final VoidCallback? onTrackPressed;

  const CustomerBookingsView({super.key, this.onTrackPressed});

  @override
  Widget build(BuildContext context) {
    final customerId =
        FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.myBookings,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Booking>>(
          stream: BookingRepository().streamBookingsForCustomer(customerId),
          builder: (context, snapshot) {
            final bookings = snapshot.data ?? [];
            final activeBookings = bookings
                .where((b) => b.status != 'completed' && b.status != 'cancelled')
                .toList();
            final pastBookings = bookings
                .where((b) => b.status == 'completed' || b.status == 'cancelled')
                .toList();

            if (bookings.isEmpty) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month_outlined,
                          size: 54, color: context.themeTextSecondary),
                      const SizedBox(height: 12),
                      Text(context.l10n.noBookingsRecorded,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(context.l10n.browseArtisansExplore,
                          style: TextStyle(
                              fontSize: 12, color: context.themeTextSecondary)),
                    ],
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (activeBookings.isNotEmpty) ...[
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.activeServiceVisit,
                        style: const TextStyle(
                          fontSize: 11,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...activeBookings.map((b) => Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.themeSurface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: context.isDark ? 0.2 : 0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: context.isDark
                                        ? const Color(0xFF1B382B)
                                        : const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    LocalizedData.getStatus(context, b.status),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: context.isDark
                                          ? const Color(0xFF81C784)
                                          : const Color(0xFF2E7D32),
                                    ),
                                  ),
                                ),
                                Text(
                                  b.relativeTime.isNotEmpty
                                      ? b.relativeTime
                                      : 'Today',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              b.title.isNotEmpty
                                   ? b.title
                                  : 'Service Diagnostic',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${context.l10n.roleProvider}: ${b.providerName.isNotEmpty ? b.providerName : (b.providerId.isNotEmpty ? b.providerId : "Technician")}',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: context.themeTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 16, color: context.themeTextSecondary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    b.location.isNotEmpty
                                        ? b.location
                                        : 'Colombo, Sri Lanka',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  b.estRate.isNotEmpty
                                      ? b.estRate
                                      : 'LKR 2,500',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: onTrackPressed ??
                                  () async {
                                    final Technician? tech =
                                        await TechnicianRepository()
                                            .getById(b.providerId);
                                    if (!context.mounted) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => LiveTrackingScreen(
                                          technician: tech,
                                          booking: b,
                                          showBottomNav: false,
                                        ),
                                      ),
                                    );
                                  },
                              icon: const Icon(Icons.navigation_outlined,
                                  size: 18),
                              label: Text(context.l10n.openLiveGpsTracking),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                minimumSize: const Size(double.infinity, 44),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
                if (pastBookings.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.pastCompletedServices,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  ...pastBookings.map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PastBookingCard(
                          title: b.title.isNotEmpty ? b.title : 'Service',
                          technician: b.providerName.isNotEmpty
                              ? b.providerName
                              : 'Technician',
                          date: b.time.isNotEmpty ? b.time : 'Completed',
                          amount:
                              b.estRate.isNotEmpty ? b.estRate : 'LKR 2,500',
                          status: LocalizedData.getStatus(context, b.status),
                          rating: b.status.toLowerCase() == 'completed'
                              ? (b.rating ?? 5)
                              : 0,
                        ),
                      )),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PastBookingCard extends StatelessWidget {
  final String title;
  final String technician;
  final String date;
  final String amount;
  final String status;
  final int rating;

  const _PastBookingCard({
    required this.title,
    required this.technician,
    required this.date,
    required this.amount,
    required this.status,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: TextStyle(
                  fontSize: 11.5,
                  color: context.themeTextSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.themeSurfaceContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'By $technician',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.themeTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (rating > 0) ...[
                      const SizedBox(width: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          rating,
                          (index) => const Icon(Icons.star,
                              size: 13, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
