import '../../shared/widgets/job_media_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/booking.dart';
import '../../../models/booking_extra.dart';
import '../../../models/job_request.dart';
import '../../../models/technician.dart';
import '../../../repositories/booking_repository.dart';
import '../../../repositories/job_request_repository.dart';
import '../../../repositories/technician_repository.dart';
import '../../../services/category_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/l10n_extension.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../widgets/booking_timeline_sheet.dart';
import '../../../shared/widgets/pill_badge.dart';
import 'package:provider/provider.dart';
import '../../../state/role_provider.dart';
import '../../../models/admin_user.dart';

enum LedgerStatusFilter { all, completed, inProgress, cancelled }

class JobLedgerScreen extends StatefulWidget {
  const JobLedgerScreen({super.key});

  @override
  State<JobLedgerScreen> createState() => _JobLedgerScreenState();
}

class _JobLedgerScreenState extends State<JobLedgerScreen> {
  int _activeLedgerTab = 0; // zero for bookings or one for requests
  String _customerRequestStatus = 'all';
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

  String _getStatusLabel(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return context.l10n.filterCompleted;
      case 'in_progress':
        return context.l10n.filterInProgress;
      case 'cancelled':
        return context.l10n.filterCancelled;
      case 'en_route':
        return context.l10n.ledgerStatusEnRoute;
      case 'accepted':
        return context.l10n.statusAccepted;
      case 'pending':
        return context.l10n.statusPending;
      default:
        return status.isNotEmpty ? status : context.l10n.notRecorded;
    }
  }

  void _exportBookingsToCsv(
    BuildContext context,
    List<Booking> bookings,
    Map<String, String> techMap,
  ) {
    final buffer = StringBuffer();
    buffer.writeln(
        'Booking ID,Date,Title,Provider,Customer,Status,Agreed Price,Final Amount,Payment Method,Payment Status,Payment Note');
    for (final b in bookings) {
      final id = b.id;
      final date =
          b.createdAt != null ? b.createdAt!.toIso8601String() : b.time;
      final escapedTitle = b.title.replaceAll('"', '""');
      final title = '"$escapedTitle"';
      final provider =
          '"${(b.providerName.isNotEmpty ? b.providerName : techMap[b.providerId] ?? b.providerId).replaceAll('"', '""')}"';
      final customer = '"${b.customerName.replaceAll('"', '""')}"';
      final status = b.status;
      final agreed = (b.agreedPrice ?? 0).toStringAsFixed(0);
      final finalAmt = (b.finalAmount ?? b.agreedPrice ?? 0).toStringAsFixed(0);
      final method = b.paymentMethod ?? 'cash';
      String paymentStatus = 'Pending';
      if (b.status == 'completed') {
        if (b.customerConfirmedPaidAt != null) {
          paymentStatus = 'Confirmed';
        } else if (b.paymentDisputed == true) {
          paymentStatus = 'Disputed';
        } else {
          paymentStatus = 'Waiting Confirmation';
        }
      }
      final note = '"${(b.paymentNote ?? '').replaceAll('"', '""')}"';
      buffer.writeln(
          '$id,$date,$title,$provider,$customer,$status,$agreed,$finalAmt,$method,$paymentStatus,$note');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.csvExportSuccess),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = Provider.of<RoleProvider>(context);
    if (!roleProvider.hasAdminPermission(AdminPermission.viewFinances)) {
      return Scaffold(
        backgroundColor: context.themeSurface,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                context.l10n.noPermissionForAction,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

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

            final now = DateTime.now();
            final startOfToday = DateTime(now.year, now.month, now.day);
            final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
            final startOfMonth = DateTime(now.year, now.month, 1);

            double totalEarnings = 0;
            double todayEarnings = 0;
            double weekEarnings = 0;
            double monthEarnings = 0;

            for (final b in allBookings) {
              if (b.status.toLowerCase() == 'completed' &&
                  b.paymentDisputed != true) {
                final amount = b.finalAmount ?? b.agreedPrice ?? 0.0;
                totalEarnings += amount;
                final date = b.completedAt ?? b.createdAt;
                if (date != null) {
                  if (date.isAfter(startOfToday)) todayEarnings += amount;
                  if (date.isAfter(startOfWeek)) weekEarnings += amount;
                  if (date.isAfter(startOfMonth)) monthEarnings += amount;
                }
              }
            }

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.jobLedger,
                              style: TextStyle(
                                fontSize: isMobile ? 24 : 28,
                                fontWeight: FontWeight.w800,
                                color: context.themeTextPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.l10n.jobLedgerSubtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: context.themeTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _exportBookingsToCsv(
                          context,
                          filteredBookings,
                          techMap,
                        ),
                        icon:
                            const Icon(Icons.file_download_outlined, size: 16),
                        label: Text(context.l10n.exportCsv),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: context.themeSurfaceLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.themeBorder),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _activeLedgerTab = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _activeLedgerTab == 0
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Confirmed Bookings (${allBookings.length})',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: _activeLedgerTab == 0
                                        ? Colors.white
                                        : context.themeTextSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _activeLedgerTab = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _activeLedgerTab == 1
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Customer Requests',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: _activeLedgerTab == 1
                                        ? Colors.white
                                        : context.themeTextSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isMobile ? 18 : 22),
                  if (_activeLedgerTab == 0) ...[
                    _buildSummaryCards(
                      context: context,
                      isMobile: isMobile,
                      completedCount: completedCount,
                      inProgressCount: inProgressCount,
                      avgRating: avgRating,
                      ratedCount: ratedBookings.length,
                      totalEarnings: totalEarnings,
                      todayEarnings: todayEarnings,
                      weekEarnings: weekEarnings,
                      monthEarnings: monthEarnings,
                    ),
                    SizedBox(height: isMobile ? 18 : 22),
                    _buildFilterChips(context, isMobile),
                    const SizedBox(height: 18),
                    Text(
                      '${context.l10n.jobLedger.toUpperCase()} (${filteredBookings.length})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                        color: context.themeTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (bookingSnap.connectionState ==
                            ConnectionState.waiting &&
                        allBookings.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
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
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                  ] else ...[
                    _buildCustomerRequestsSection(context, isMobile),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryCards({
    required BuildContext context,
    required bool isMobile,
    required int completedCount,
    required int inProgressCount,
    required String avgRating,
    required int ratedCount,
    required double totalEarnings,
    required double todayEarnings,
    required double weekEarnings,
    required double monthEarnings,
  }) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.themeHeroSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.themeHeroBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.totalEarnings.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                  color: context.themeAmberText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'LKR ${totalEarnings.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildEarningPill(context.l10n.earningsToday,
                      'LKR ${todayEarnings.toStringAsFixed(0)}'),
                  const SizedBox(width: 8),
                  _buildEarningPill(context.l10n.earningsThisWeek,
                      'LKR ${weekEarnings.toStringAsFixed(0)}'),
                  const SizedBox(width: 8),
                  _buildEarningPill(context.l10n.earningsThisMonth,
                      'LKR ${monthEarnings.toStringAsFixed(0)}'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.themeSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.themeBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.totalCompletedJobs,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.themeTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$completedCount',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: context.themeTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.themeSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.themeBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.averageRating,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.themeTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          avgRating,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: context.themeTextPrimary,
                          ),
                        ),
                        if (avgRating != '—') ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.star_rounded,
                            size: 22,
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget _buildEarningPill(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 11.5,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, bool isMobile) {
    final filters = [
      (LedgerStatusFilter.all, context.l10n.filterAll),
      (LedgerStatusFilter.completed, context.l10n.filterCompleted),
      (LedgerStatusFilter.inProgress, context.l10n.filterInProgress),
      (LedgerStatusFilter.cancelled, context.l10n.filterCancelled),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final active = _selectedFilter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => setState(() => _selectedFilter = f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active
                      ? (context.isDark ? Colors.white : AppColors.ink)
                      : context.themeSurface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: active ? Colors.transparent : context.themeBorder,
                  ),
                ),
                child: Text(
                  f.$2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.bold : FontWeight.w600,
                    color: active
                        ? (context.isDark ? AppColors.ink : Colors.white)
                        : context.themeTextPrimary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
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
    final status = booking.status.toLowerCase();
    Color statusColor;
    Color statusBg;
    switch (status) {
      case 'completed':
        statusColor = AppColors.success;
        statusBg = context.themeSuccessTint;
        break;
      case 'in_progress':
      case 'en_route':
      case 'accepted':
        statusColor = context.themeAmberText;
        statusBg = context.themeAmberTint;
        break;
      case 'cancelled':
      case 'rejected':
        statusColor = AppColors.error;
        statusBg = context.themeDangerTint;
        break;
      default:
        statusColor = context.themeTextSecondary;
        statusBg = context.themeSoft;
    }
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

    final hasDelay =
        (booking.delayReason != null && booking.delayReason!.isNotEmpty) ||
            (booking.delayMinutes != null && booking.delayMinutes! > 0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.themeBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
                          : context.l10n.ledgerServiceBooking,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: context.themeTextPrimary,
                      ),
                    ),
                    if (dateTimeStr.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        dateTimeStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.themeTextSecondary,
                        ),
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
                  color: statusBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.wonBy,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.themeTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      providerDisplayName,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: context.themeTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.customerLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.themeTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customerDisplayName,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: context.themeTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.bidAmount,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: context.themeTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bidStr,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: context.themeTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (booking.status.toLowerCase() == 'completed') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.themeSurfaceLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.themeBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.payments_outlined,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        '${context.l10n.cashReceived}: LKR ${(booking.finalAmount ?? booking.agreedPrice ?? 0).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.themeTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (booking.customerConfirmedPaidAt != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 12, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                            context.l10n.paymentConfirmed,
                            style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success),
                          ),
                        ],
                      ),
                    )
                  else if (booking.paymentDisputed == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 12, color: AppColors.error),
                          const SizedBox(width: 4),
                          Text(
                            context.l10n.paymentDisputed,
                            style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.hourglass_empty_rounded,
                              size: 12, color: AppColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            context.l10n.paymentWaitingConfirmation,
                            style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          _buildPriceHistory(context, booking),
          if (booking.paymentNote != null &&
              booking.paymentNote!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${context.l10n.paymentNoteOptional}: ${booking.paymentNote}',
              style: TextStyle(
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                color: context.themeTextSecondary,
              ),
            ),
          ],
          if (booking.rating != null && booking.rating! > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                for (int s = 1; s <= 5; s++)
                  Icon(
                    s <= (booking.rating ?? 0).round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                const SizedBox(width: 6),
                Text(
                  '${booking.rating}/5',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: context.themeTextPrimary,
                  ),
                ),
              ],
            ),
          ],
          if (hasDelay) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.themeAmberTint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: context.themeAmberText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Builder(
                      builder: (ctx) {
                        final delayMins = booking.delayMinutes;
                        final delayPrefix = (delayMins != null && delayMins > 0)
                            ? '${context.l10n.ledgerDelayMinutes(delayMins.toString())} • '
                            : '';
                        return Text(
                          '${context.l10n.delayReported}: $delayPrefix${booking.delayReason ?? ""}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: context.themeAmberText,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (booking.arrivalMocked ||
              booking.arrivalOutsideZone ||
              booking.arrivalStatus == 'denied' ||
              booking.noShow) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (booking.arrivalMocked)
                  PillBadge(
                    label: context.l10n.arrivalMockedFlag,
                    icon: Icons.gps_off_rounded,
                    background: AppColors.error.withValues(alpha: 0.12),
                    foreground: AppColors.error,
                  ),
                if (booking.arrivalOutsideZone)
                  PillBadge(
                    label: context.l10n.arrivalOutsideZoneFlag,
                    icon: Icons.wrong_location_rounded,
                    background: AppColors.warning.withValues(alpha: 0.12),
                    foreground: AppColors.warning,
                  ),
                if (booking.arrivalStatus == 'denied')
                  PillBadge(
                    label: context.l10n.arrivalDeniedFlag,
                    icon: Icons.cancel_outlined,
                    background: AppColors.error.withValues(alpha: 0.12),
                    foreground: AppColors.error,
                  ),
                if (booking.noShow)
                  PillBadge(
                    label: context.l10n.noShowFlag,
                    icon: Icons.person_off_rounded,
                    background: AppColors.error.withValues(alpha: 0.12),
                    foreground: AppColors.error,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => BookingTimelineSheet.show(
                context,
                bookingId: booking.id,
                bookingTitle: booking.title,
              ),
              icon: const Icon(Icons.timeline_rounded, size: 16),
              label: Text(
                context.l10n.viewTimeline,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceHistory(BuildContext context, Booking booking) {
    String quoteLabel;
    switch (booking.quoteType) {
      case 'estimate':
        quoteLabel = context.l10n.quoteTypeEstimate;
        break;
      case 'inspect':
        quoteLabel = context.l10n.quoteTypeInspect;
        break;
      case 'firm':
      default:
        quoteLabel = context.l10n.quoteTypeFirm;
        break;
    }

    final initialQuote = booking.estimatedTotalLkr ??
        booking.agreedPrice?.round() ??
        booking.agreedPriceLkr;
    final finalCharged =
        booking.finalAmount ?? booking.agreedPrice ?? booking.agreedPriceLkr;
    final completionLabel = booking.completionType == 'visit_only'
        ? context.l10n.completionTypeVisitOnly
        : context.l10n.completionTypeNormal;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.themeSurfaceLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.priceHistoryAudit,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: context.themeTextPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: (booking.completionType == 'visit_only'
                          ? AppColors.warning
                          : AppColors.success)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  completionLabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: booking.completionType == 'visit_only'
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quote Type: $quoteLabel',
                style: TextStyle(
                    fontSize: 11.5, color: context.themeTextSecondary),
              ),
              Text(
                'Quoted: LKR $initialQuote',
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: context.themeTextPrimary),
              ),
            ],
          ),
          if (booking.proposedPrice != null ||
              (booking.priceStatus != null &&
                  booking.priceStatus != 'awaiting_confirmation')) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.ledgerPriceStatus(
                      booking.priceStatus ?? context.l10n.none),
                  style: TextStyle(
                      fontSize: 11.5, color: context.themeTextSecondary),
                ),
                if (booking.proposedPrice != null)
                  Text(
                    context.l10n.ledgerProposedLkr(
                        '${booking.proposedPrice!["totalLkr"] ?? ""}'),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: booking.priceStatus == 'approved'
                          ? AppColors.success
                          : (booking.priceStatus == 'rejected'
                              ? AppColors.error
                              : AppColors.warning),
                    ),
                  ),
              ],
            ),
          ],
          StreamBuilder<List<BookingExtra>>(
            stream: BookingRepository().streamExtras(booking.id),
            builder: (context, snap) {
              final extras = snap.data ?? [];
              if (extras.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  const Divider(height: 12),
                  Text(
                    'Extras (${extras.length}):',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: context.themeTextSecondary),
                  ),
                  const SizedBox(height: 4),
                  ...extras.map((ex) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '• ${ex.description} (${ex.status})',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: ex.status == 'approved'
                                      ? AppColors.success
                                      : (ex.status == 'rejected'
                                          ? AppColors.error
                                          : context.themeTextSecondary),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              'LKR ${ex.amountLkr}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: context.themeTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              );
            },
          ),
          const Divider(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.finalChargedAmount,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.themeTextPrimary),
              ),
              Text(
                'LKR ${finalCharged.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerRequestsSection(BuildContext context, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildReqFilterChip('all', 'All Posts'),
              const SizedBox(width: 8),
              _buildReqFilterChip('open', 'Open'),
              const SizedBox(width: 8),
              _buildReqFilterChip('assigned', 'Assigned'),
              const SizedBox(width: 8),
              _buildReqFilterChip('completed', 'Completed'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        StreamBuilder<List<JobRequest>>(
          stream: JobRequestRepository().streamAllCustomerRequests(
            statusFilter:
                _customerRequestStatus == 'all' ? null : _customerRequestStatus,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
              );
            }

            final requests = snapshot.data ?? [];
            if (requests.isEmpty) {
              return _buildEmptyState(
                context,
                'No customer job requests found.',
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ALL CUSTOMER POSTS (${requests.length})',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                    color: context.themeTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    return _buildCustomerRequestCard(context, req, isMobile);
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildReqFilterChip(String status, String label) {
    final isSelected = _customerRequestStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _customerRequestStatus = status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : context.themeSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : context.themeBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : context.themeTextSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerRequestCard(
      BuildContext context, JobRequest req, bool isMobile) {
    final status = req.status.toLowerCase();
    Color statusColor;
    Color statusBg;
    switch (status) {
      case 'open':
        statusColor = AppColors.success;
        statusBg = context.themeSuccessTint;
        break;
      case 'assigned':
        statusColor = context.themeAmberText;
        statusBg = context.themeAmberTint;
        break;
      case 'completed':
        statusColor = AppColors.info;
        statusBg = context.themeInfoTint;
        break;
      default:
        statusColor = context.themeTextSecondary;
        statusBg = context.themeSoft;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: context.themeSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  CategoryService.instance
                      .nameOf(req.category, context: context)
                      .toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  req.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            req.title.isNotEmpty ? req.title : context.l10n.serviceRequest,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          if (req.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              req.description,
              style: TextStyle(
                  fontSize: 13,
                  color: context.themeTextSecondary,
                  height: 1.35),
            ),
          ],
          const SizedBox(height: 12),
          // customer contact
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.themeSurfaceLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.themeBorder),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: const Icon(Icons.person,
                      size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.customerName.isNotEmpty
                            ? req.customerName
                            : context.l10n.ledgerCustomer,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      if (req.customerPhone.isNotEmpty)
                        Text(
                          req.customerPhone,
                          style: TextStyle(
                              fontSize: 11.5,
                              color: context.themeTextSecondary),
                        ),
                    ],
                  ),
                ),
                if (req.address.isNotEmpty)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14, color: context.themeTextSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            req.address,
                            style: TextStyle(
                                fontSize: 11.5,
                                color: context.themeTextSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // attached media
          if (req.photoUrls.isNotEmpty ||
              (req.videoUrl != null && req.videoUrl!.isNotEmpty)) ...[
            const SizedBox(height: 12),
            JobMediaGallery(
              photoUrls: req.photoUrls,
              videoUrl: req.videoUrl,
              height: 72,
            ),
          ],
          const SizedBox(height: 12),
          // quote count and date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: req.quoteCount > 0
                      ? context.themeAmberTint
                      : context.themeSurfaceLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      req.quoteCount > 0
                          ? Icons.local_offer
                          : Icons.hourglass_empty,
                      size: 14,
                      color: req.quoteCount > 0
                          ? context.themeAmberText
                          : context.themeTextSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${req.quoteCount} Quotes submitted',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: req.quoteCount > 0
                            ? context.themeAmberText
                            : context.themeTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (req.createdAt != null)
                Text(
                  '${req.createdAt!.year}-${req.createdAt!.month.toString().padLeft(2, '0')}-${req.createdAt!.day.toString().padLeft(2, '0')}',
                  style: TextStyle(
                      fontSize: 11.5, color: context.themeTextSecondary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
