import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../constants/job_status.dart';
import '../../../models/booking.dart';
import '../../../repositories/booking_repository.dart';
import '../../../services/session_guard.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/l10n_extension.dart';
import '../../admin/widgets/booking_timeline_sheet.dart';
import 'en_route_navigation_screen.dart';

// provider booking history screen
class ProviderBookingHistoryScreen extends StatefulWidget {
  const ProviderBookingHistoryScreen({super.key});

  @override
  State<ProviderBookingHistoryScreen> createState() =>
      _ProviderBookingHistoryScreenState();
}

class _ProviderBookingHistoryScreenState
    extends State<ProviderBookingHistoryScreen> {
  // filter index for all upcoming completed and cancelled
  int _selectedFilter = 0;
  late final Stream<List<Booking>> _bookingsStream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _bookingsStream = BookingRepository().streamBookingsForProvider(uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBg,
      appBar: AppBar(
        title: Text(
          context.l10n.bookingHistory,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: StreamBuilder<List<Booking>>(
        stream: _bookingsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            SessionGuard.handlePermissionDenied(snapshot.error);
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 40,
                      color: context.themeDanger,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.somethingWentWrong,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.themeTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final allBookings = snapshot.data ?? [];
          final filteredBookings = _filterBookings(allBookings);

          return Column(
            children: [
              _buildFilterChips(context),
              Expanded(
                child: filteredBookings.isEmpty
                    ? _buildEmptyState(context, allBookings.isEmpty)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: filteredBookings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final booking = filteredBookings[index];
                          return _ProviderBookingHistoryCard(booking: booking);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // filter bookings based on selected status chip
  List<Booking> _filterBookings(List<Booking> list) {
    switch (_selectedFilter) {
      case 1:
        return list.where((b) => JobStatus.isUpcoming(b.status)).toList()
          ..sort(Booking.compareUpcoming);
      case 2:
        return list.where((b) => b.status == JobStatus.completed).toList();
      case 3:
        return list
            .where((b) =>
                b.status == JobStatus.cancelled ||
                b.status == JobStatus.declined ||
                b.status == JobStatus.expired)
            .toList();
      case 0:
      default:
        return list;
    }
  }

  Widget _buildFilterChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildChip(0, context.l10n.allBookings),
          const SizedBox(width: 8),
          _buildChip(1, context.l10n.activeBookings),
          const SizedBox(width: 8),
          _buildChip(2, context.l10n.statusCompleted),
          const SizedBox(width: 8),
          _buildChip(3, context.l10n.statusCancelled),
        ],
      ),
    );
  }

  Widget _buildChip(int index, String label) {
    final isSelected = _selectedFilter == index;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          color: isSelected ? Colors.white : context.themeTextSecondary,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: context.themeSurface,
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : context.themeBorder,
        ),
      ),
      onSelected: (_) => setState(() => _selectedFilter = index),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isTotalEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isTotalEmpty
                  ? context.l10n.noBookingsRecorded
                  : context.l10n.noBookingsMatchingFilter,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: context.themeTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// booking card with status pill and details
class _ProviderBookingHistoryCard extends StatelessWidget {
  final Booking booking;

  const _ProviderBookingHistoryCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final b = booking;
    final isUpcoming = JobStatus.isUpcoming(b.status);

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: InkWell(
        onTap: isUpcoming
            ? () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EnRouteNavigationScreen(booking: b),
                  ),
                )
            : () => BookingTimelineSheet.show(
                  context,
                  bookingId: b.id,
                  bookingTitle: b.title,
                ),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _formatBookingTime(context, b),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: context.themeTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                StatusPill.fromStatus(b.status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              b.title.isNotEmpty ? b.title : context.l10n.serviceDiagnostic,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 15,
                  color: context.themeTextSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    b.customerName.isNotEmpty
                        ? b.customerName
                        : context.l10n.roleCustomer,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: context.themeTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (b.estRate.isNotEmpty) ...[
                  Text(
                    b.estRate,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
            if (b.location.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: context.themeTextSecondary,
                  ),
                  const SizedBox(width: 4),
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
            if (b.cancellationReason != null &&
                b.cancellationReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.themeDangerTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 14, color: context.themeDanger),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        b.cancellationReason!,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: context.themeDanger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => BookingTimelineSheet.show(
                    context,
                    bookingId: b.id,
                    bookingTitle: b.title,
                  ),
                  icon: const Icon(Icons.timeline_rounded, size: 14),
                  label: Text(
                    context.l10n.viewTimeline,
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                if (isUpcoming) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EnRouteNavigationScreen(booking: b),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                    label: Text(
                      context.l10n.openBookingTimeline(b.id),
                      style: const TextStyle(fontSize: 11.5),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatBookingTime(BuildContext context, Booking booking) {
    if (booking.scheduledDate != null) {
      return booking.formattedScheduledSummary(context);
    }
    if (booking.time.isNotEmpty) return booking.time;
    final date = booking.completedAt ?? booking.createdAt;
    if (date != null) {
      final locale = Localizations.localeOf(context).languageCode;
      return DateFormat('d MMM yyyy, h:mm a', locale).format(date);
    }
    return '';
  }
}
