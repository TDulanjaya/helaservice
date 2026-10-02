import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../theme/app_theme.dart';
import '../../../models/technician.dart';
import '../../../models/booking.dart';
import '../../../repositories/technician_repository.dart';
import '../../../repositories/booking_repository.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/app_localizations_helpers.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/icon_square_button.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/screens/conversations_inbox_screen.dart';
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: IconSquareButton(
                icon: Icons.chat_bubble_outline,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ConversationsInboxScreen()),
                  );
                },
              ),
            ),
          ),
        ],
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
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.calendar_month_outlined,
                            size: 44, color: AppColors.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(context.l10n.noBookingsRecorded,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(context.l10n.browseArtisansExplore,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 13, color: context.themeTextSecondary)),
                    ],
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, AppBottomNav.contentBottomPadding),
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
                  ...activeBookings.map((b) => AppCard(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        borderColor: AppColors.primary,
                        borderWidth: 1.5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: b.status == 'in_progress' || b.status == 'dispatched'
                                        ? AppColors.primary.withValues(alpha: 0.15)
                                        : (context.isDark ? const Color(0xFF1B382B) : const Color(0xFFE8F5E9)),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    LocalizedData.getStatus(context, b.status),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: b.status == 'in_progress' || b.status == 'dispatched'
                                          ? AppColors.primary
                                          : (context.isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32)),
                                    ),
                                  ),
                                ),
                                Text(
                                  b.relativeTime.isNotEmpty
                                      ? b.relativeTime
                                      : context.l10n.today,
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
                                  : context.l10n.serviceDiagnostic,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                UserAvatar(
                                  uid: b.providerId,
                                  displayName: b.providerName,
                                  radius: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        b.providerName.isNotEmpty
                                            ? b.providerName
                                            : (b.providerId.isNotEmpty ? b.providerId : context.l10n.technician),
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        context.l10n.roleProvider,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: context.themeTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (b.estRate.isNotEmpty)
                                  Text(
                                    b.estRate,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primary,
                                    ),
                                  ),
                              ],
                            ),
                            if (b.location.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined,
                                      size: 16, color: context.themeTextSecondary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      b.location,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.themeTextSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            PrimaryButton(
                              label: context.l10n.openLiveGpsTracking,
                              leadingIcon: Icons.navigation_outlined,
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
                            ),
                          ],
                        ),
                      )),
                ],
                if (pastBookings.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    context.l10n.pastCompletedServices,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  ...pastBookings.map((b) => _PastBookingCard(
                        title: b.title.isNotEmpty ? b.title : context.l10n.serviceDiagnostic,
                        technician: b.providerName.isNotEmpty
                            ? b.providerName
                            : context.l10n.technician,
                        date: b.time.isNotEmpty ? b.time : LocalizedData.getStatus(context, 'completed'),
                        amount:
                            b.estRate.isNotEmpty ? b.estRate : 'LKR 2,500',
                        status: LocalizedData.getStatus(context, b.status),
                        rating: b.status.toLowerCase() == 'completed'
                            ? (b.rating ?? 5)
                            : 0,
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
    return AppCard(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.themeSurfaceContainer,
                  borderRadius: BorderRadius.circular(999),
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
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        context.l10n.byTechnician(technician),
                        style: TextStyle(
                          fontSize: 12,
                          color: context.themeTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (rating > 0) ...[
                      const SizedBox(width: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          rating,
                          (index) => const Icon(Icons.star,
                              size: 13, color: AppColors.secondaryContainer),
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
                  fontSize: 13.5,
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
