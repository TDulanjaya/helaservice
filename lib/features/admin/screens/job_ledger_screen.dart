import 'package:flutter/material.dart';
import '../../../models/booking.dart';
import '../../../models/technician.dart';
import '../../../repositories/booking_repository.dart';
import '../../../repositories/technician_repository.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/l10n_extension.dart';
import '../widgets/admin_stat_card.dart';
import '../../../shared/widgets/app_bottom_nav.dart';

enum LedgerStatusFilter { all, completed, inProgress, cancelled }

class JobLedgerScreen extends StatefulWidget {
  const JobLedgerScreen({super.key});

  @override
  State<JobLedgerScreen> createState() => _JobLedgerScreenState();
}

class _JobLedgerScreenState extends State<JobLedgerScreen> {
  LedgerStatusFilter _selectedFilter = LedgerStatusFilter.all;

  bool _matchesFilter(Booking booking) {
    final status = booking.status.toLowerCase();
    switch (_selectedFilter) {
      case LedgerStatusFilter.all:
        return true;
      case LedgerStatusFilter.completed:
        return status == 'completed';
      case LedgerStatusFilter.inProgress:
        return status == 'in_progress' ||
            status == 'en_route' ||
            status == 'accepted' ||
            status == 'pending';
      case LedgerStatusFilter.cancelled:
        return status == 'cancelled' || status == 'rejected';
    }
  }

  String _formatDateTime(Booking booking) {
    if (booking.createdAt != null) {
      final dt = booking.createdAt!.toLocal();
      final y = dt.year.toString();
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final hr = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      final formattedDate = '$y-$m-$d $hr:$min';
      if (booking.time.isNotEmpty) {
        return '$formattedDate (${booking.time})';
      }
      return formattedDate;
    }
    if (booking.time.isNotEmpty) return booking.time;
    if (booking.relativeTime.isNotEmpty) return booking.relativeTime;
    return '';
  }

  String _formatBidAmount(BuildContext context, Booking booking) {
    if (booking.agreedPrice != null && booking.agreedPrice! > 0) {
      return 'LKR ${booking.agreedPrice!.toStringAsFixed(0)}';
    }
    if (booking.estRate.trim().isNotEmpty) {
      return booking.estRate.trim();
    }
    return context.l10n.notRecorded;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.primary;
      case 'in_progress':
      case 'en_route':
      case 'accepted':
        return AppColors.secondaryContainer;
      case 'cancelled':
      case 'rejected':
        return AppColors.error;
      case 'pending':
      default:
        return AppColors.secondary;
    }
  }

  String _getStatusLabel(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return context.l10n.filterCompleted;
      case 'in_progress':
        return context.l10n.filterInProgress;
      case 'cancelled':
        return context.l10n.filterCancelled;
      case 'en_route':
        return 'En Route';
      case 'accepted':
        return 'Accepted';
      case 'pending':
      default:
        return status.isNotEmpty ? status : context.l10n.notRecorded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return StreamBuilder<List<Technician>>(
      stream: TechnicianRepository().streamTechnicians(),
      builder: (context, techSnap) {
        final technicians = techSnap.data ?? [];
        final Map<String, String> techMap = {
          for (final t in technicians) t.id: t.name,
        };

        return StreamBuilder<List<Booking>>(
          stream: BookingRepository().streamAllBookings(),
          builder: (context, bookingSnap) {
            final allBookings = bookingSnap.data ?? [];
            final filteredBookings = allBookings.where(_matchesFilter).toList();

            final completedCount = allBookings
                .where((b) => b.status.toLowerCase() == 'completed')
                .length;
            final inProgressCount = allBookings
                .where((b) =>
                    b.status.toLowerCase() == 'in_progress' ||
                    b.status.toLowerCase() == 'en_route' ||
                    b.status.toLowerCase() == 'accepted' ||
                    b.status.toLowerCase() == 'pending')
                .length;

            final ratedBookings = allBookings
                .where((b) => b.rating != null && b.rating! > 0)
                .toList();
            final avgRating = ratedBookings.isNotEmpty
                ? (ratedBookings.fold<double>(
                            0.0, (sum, b) => sum + (b.rating ?? 0)) /
                        ratedBookings.length)
                    .toStringAsFixed(1)
                : '—';

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : 24,
                isMobile ? 16 : 24,
                isMobile ? 16 : 24,
                isMobile ? AppBottomNav.contentBottomPadding : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.jobLedger,
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: context.themeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.l10n.jobLedgerSubtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.themeTextSecondary,
                    ),
                  ),
                  SizedBox(height: isMobile ? 16 : 20),
                  _buildSummaryCards(
                    isMobile: isMobile,
                    completedCount: completedCount,
                    inProgressCount: inProgressCount,
                    avgRating: avgRating,
                    ratedCount: ratedBookings.length,
                  ),
                  SizedBox(height: isMobile ? 16 : 24),
                  _buildFilterChips(context, isMobile),
                  const SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(isMobile ? 14 : 18),
                    decoration: BoxDecoration(
                      color: context.themeSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: context.themeBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: context.isDark ? 0.2 : 0.04),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${context.l10n.jobLedger} (${filteredBookings.length})',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: context.themeTextPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (bookingSnap.connectionState ==
                                ConnectionState.waiting &&
                            allBookings.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary),
                            ),
                          )
                        else if (allBookings.isEmpty)
                          _buildEmptyState(
                            context,
                            context.l10n.noBookingsFound,
                          )
                        else if (filteredBookings.isEmpty)
                          _buildEmptyState(
                            context,
                            context.l10n.noBookingsMatchingFilter,
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredBookings.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final booking = filteredBookings[index];
                              return _buildBookingCard(
                                context,
                                booking,
                                techMap,
                                isMobile,
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryCards({
    required bool isMobile,
    required int completedCount,
    required int inProgressCount,
    required String avgRating,
    required int ratedCount,
  }) {
    final cards = [
      AdminStatCard(
        icon: Icons.check_circle_outline,
        label: context.l10n.totalCompletedJobs,
        value: '$completedCount',
        subtitle: '$completedCount jobs resolved across island',
      ),
      AdminStatCard(
        icon: Icons.pending_actions,
        label: context.l10n.totalInProgressJobs,
        value: '$inProgressCount',
        trailingBadge: inProgressCount > 0 ? 'Active' : null,
        subtitle: '$inProgressCount dispatches active in field',
      ),
      AdminStatCard(
        icon: Icons.star_rate_rounded,
        label: context.l10n.averageRating,
        value: avgRating == '—' ? avgRating : avgRating,
        subtitle: ratedCount > 0
            ? 'Based on $ratedCount verified reviews'
            : 'Awaiting customer feedback',
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            cards[i],
          ],
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }

  Widget _buildFilterChips(BuildContext context, bool isMobile) {
    final filters = [
      (LedgerStatusFilter.all, context.l10n.filterAll),
      (LedgerStatusFilter.completed, context.l10n.filterCompleted),
      (LedgerStatusFilter.inProgress, context.l10n.filterInProgress),
      (LedgerStatusFilter.cancelled, context.l10n.filterCancelled),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters.map((f) {
        final active = _selectedFilter == f.$1;
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _selectedFilter = f.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : context.themeSurfaceContainer,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? AppColors.primary : context.themeBorder,
              ),
            ),
            child: Text(
              f.$2,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.bold : FontWeight.w600,
                color: active ? Colors.white : context.themeTextPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: context.themeSurfaceLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long,
                size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.themeTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(
    BuildContext context,
    Booking booking,
    Map<String, String> techMap,
    bool isMobile,
  ) {
    final statusColor = _getStatusColor(booking.status);
    final statusLabel = _getStatusLabel(context, booking.status);
    final dateTimeStr = _formatDateTime(booking);
    final bidStr = _formatBidAmount(context, booking);

    String providerDisplayName = booking.providerName;
    if (providerDisplayName.isEmpty &&
        techMap.containsKey(booking.providerId)) {
      providerDisplayName = techMap[booking.providerId]!;
    }
    if (providerDisplayName.isEmpty) {
      providerDisplayName = booking.providerId.isNotEmpty
          ? booking.providerId
          : context.l10n.notRecorded;
    }

    final customerDisplayName = booking.customerName.isNotEmpty
        ? booking.customerName
        : context.l10n.notRecorded;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.themeSurfaceLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.title.isNotEmpty
                          ? booking.title
                          : 'Service Booking',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: context.themeTextPrimary,
                      ),
                    ),
                    if (dateTimeStr.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.schedule,
                              size: 12, color: context.themeTextSecondary),
                          const SizedBox(width: 4),
                          Text(
                            dateTimeStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.themeTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: context.themeBorder),
          const SizedBox(height: 12),
          if (isMobile) ...[
            _buildDetailRow(
              context: context,
              icon: Icons.handyman_outlined,
              label: context.l10n.wonBy,
              value: providerDisplayName,
              extra: booking.providerPhone.isNotEmpty
                  ? booking.providerPhone
                  : null,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              context: context,
              icon: Icons.person_outline,
              label: context.l10n.customerLabel,
              value: customerDisplayName,
              extra: booking.customerPhone.isNotEmpty
                  ? booking.customerPhone
                  : null,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              context: context,
              icon: Icons.payments_outlined,
              label: context.l10n.bidAmount,
              value: bidStr,
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildDetailRow(
                    context: context,
                    icon: Icons.handyman_outlined,
                    label: context.l10n.wonBy,
                    value: providerDisplayName,
                    extra: booking.providerPhone.isNotEmpty
                        ? booking.providerPhone
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDetailRow(
                    context: context,
                    icon: Icons.person_outline,
                    label: context.l10n.customerLabel,
                    value: customerDisplayName,
                    extra: booking.customerPhone.isNotEmpty
                        ? booking.customerPhone
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDetailRow(
                    context: context,
                    icon: Icons.payments_outlined,
                    label: context.l10n.bidAmount,
                    value: bidStr,
                  ),
                ),
              ],
            ),
          ],
          if ((booking.delayReason != null &&
                  booking.delayReason!.isNotEmpty) ||
              (booking.delayMinutes != null && booking.delayMinutes! > 0) ||
              (booking.rating != null && booking.rating! > 0)) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: context.themeSurfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if ((booking.delayReason != null &&
                          booking.delayReason!.isNotEmpty) ||
                      (booking.delayMinutes != null &&
                          booking.delayMinutes! > 0)) ...[
                    const Icon(Icons.info_outline,
                        size: 14, color: AppColors.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${context.l10n.delayReported}: ${booking.delayMinutes != null ? "${booking.delayMinutes}m delay • " : ""}${booking.delayReason ?? ""}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  if (booking.rating != null && booking.rating! > 0) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${booking.rating}/5',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: context.themeTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    String? extra,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: context.themeTextSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: context.themeTextPrimary,
                ),
              ),
              if (extra != null && extra.isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(
                  extra,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: context.themeTextSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
