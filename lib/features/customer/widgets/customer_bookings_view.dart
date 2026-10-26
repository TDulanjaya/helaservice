import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart' as pv;
import '../../../theme/app_theme.dart';
import '../../../constants/job_status.dart';
import '../../../shared/widgets/status_pill.dart';
import 'job_repost_sheet.dart';
import '../../../models/technician.dart';
import '../../../models/booking.dart';
import '../../../models/job_request.dart';
import '../../../models/quote.dart';
import '../../../repositories/technician_repository.dart';
import '../../../repositories/booking_repository.dart';
import '../../../services/category_service.dart';
import '../../../repositories/job_request_repository.dart';
import '../../../services/session_guard.dart';
import '../../../services/error_reporter.dart';
import '../../../state/role_provider.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/app_localizations_helpers.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/icon_square_button.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/screens/conversations_inbox_screen.dart';
import '../screens/live_tracking_screen.dart';
import '../screens/job_quotes_screen.dart';
import '../screens/post_job_request_screen.dart';
import '../screens/direct_chat_screen.dart';
import '../screens/rating_completion_screen.dart';
import 'customer_payment_card.dart';
import 'price_extras_banner.dart';
import '../../admin/widgets/booking_timeline_sheet.dart';
import '../../../services/call_service.dart';
import '../../../shared/widgets/reschedule_sheet.dart';
import '../../../shared/widgets/job_photos_sheet.dart';
import '../../shared/widgets/job_media_gallery.dart';
import '../../support/widgets/report_problem_dialog.dart';

class CustomerBookingsView extends StatefulWidget {
  final VoidCallback? onTrackPressed;

  const CustomerBookingsView({super.key, this.onTrackPressed});

  @override
  State<CustomerBookingsView> createState() => _CustomerBookingsViewState();
}

class _CustomerBookingsViewState extends State<CustomerBookingsView> {
  int _activeTab = 0; // zero for bookings or one for jobs or two for history

  @override
  Widget build(BuildContext context) {
    final roleProvider = pv.Provider.of<RoleProvider>(context);
    final customerId = roleProvider.currentUser?.id.isNotEmpty == true
        ? roleProvider.currentUser!.id
        : (FirebaseAuth.instance.currentUser?.uid ?? '');

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
                      builder: (_) => const ConversationsInboxScreen(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: context.themeSurfaceLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.themeBorder),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildTabButton(0, context.l10n.myBookings),
                    _buildTabButton(1, context.l10n.myJobPosts),
                    _buildTabButton(2, context.l10n.historyTab),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _buildCurrentTabContent(context, customerId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : context.themeTextSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent(BuildContext context, String customerId) {
    if (customerId.isEmpty) {
      return Center(
        child: Text(
          context.l10n.signInToViewBookings,
          style: TextStyle(color: context.themeTextSecondary),
        ),
      );
    }

    switch (_activeTab) {
      case 0:
        return _buildBookingsStream(context, customerId);
      case 1:
        return _buildJobRequestsStream(context, customerId);
      case 2:
      default:
        return _buildHistoryStream(context, customerId);
    }
  }

  Widget _buildBookingsStream(BuildContext context, String customerId) {
    return StreamBuilder<List<Booking>>(
      stream: BookingRepository().streamBookingsForCustomer(customerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          SessionGuard.handlePermissionDenied(snapshot.error);
          return Center(
            child: Text(
              'Error loading bookings: ${snapshot.error}',
              style: TextStyle(color: context.themeTextSecondary),
            ),
          );
        }

        final bookings = snapshot.data ?? [];
        final activeBookings =
            bookings.where((b) => !JobStatus.isTerminal(b.status)).toList();

        if (activeBookings.isEmpty) {
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
                    child: const Icon(
                      Icons.calendar_month_outlined,
                      size: 44,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.noBookingsRecorded,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.browseArtisansExplore,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.themeTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(
              16, 8, 16, AppBottomNav.contentBottomPadding),
          children: [
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
            ...activeBookings.map((b) => _buildActiveBookingCard(context, b)),
          ],
        );
      },
    );
  }

  Widget _buildActiveBookingCard(BuildContext context, Booking b) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      borderColor: AppColors.primary,
      borderWidth: 1.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RescheduleProposalBanner(
            booking: b,
            currentUid: currentUid,
            actorRole: 'customer',
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              StatusPill.fromStatus(b.status),
              Text(
                b.relativeTime.isNotEmpty ? b.relativeTime : context.l10n.today,
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
            b.title.isNotEmpty ? b.title : context.l10n.serviceDiagnostic,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          if (b.entryInstructions != null &&
              b.entryInstructions!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              b.entryInstructions!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: context.themeTextSecondary,
              ),
            ),
          ],
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
                          : (b.providerId.isNotEmpty
                              ? b.providerId
                              : context.l10n.technician),
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
            const SizedBox(height: 10),
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
          StreamBuilder<String?>(
            stream: BookingRepository().streamBookingPin(b.id),
            builder: (context, pinSnap) {
              final pin = pinSnap.data;
              if (pin == null || pin.isEmpty) {
                return const SizedBox.shrink();
              }
              return Container(
                margin: const EdgeInsets.only(top: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.key_rounded,
                        color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${context.l10n.pinCode}: ',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                pin,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            context.l10n.givePinHint,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.themeTextSecondary,
                            ),
                          ),
                          if ((b.pinAttempts ?? 0) >= 5) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  await BookingRepository()
                                      .resetPinAttempts(b.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            context.l10n.pinAttemptsResetZero),
                                        backgroundColor: AppColors.success,
                                      ),
                                    );
                                  }
                                },
                                icon:
                                    const Icon(Icons.refresh_rounded, size: 16),
                                label: Text(
                                  context.l10n.resetPinAttempts,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (b.arrivalStatus == 'claimed') _buildArrivalClaimCard(context, b),
          PriceProposalBanner(booking: b),
          ExtrasCustomerBanner(booking: b),
          if (b.jobRequestId != null && b.jobRequestId!.isNotEmpty)
            _BookingMediaGallery(jobRequestId: b.jobRequestId!),
          if (b.status == JobStatus.inProgress ||
              b.beforePhotos.isNotEmpty ||
              b.afterPhotos.isNotEmpty) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => JobPhotosSheet.show(
                context,
                booking: b,
                isProvider: false,
              ),
              icon: const Icon(Icons.photo_library_outlined, size: 16),
              label: Text(
                '${context.l10n.jobPhotos} (${b.beforePhotos.length + b.afterPhotos.length})',
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          PrimaryButton(
            label: context.l10n.openLiveGpsTracking,
            leadingIcon: Icons.navigation_outlined,
            onPressed: widget.onTrackPressed ??
                () async {
                  final Technician? tech =
                      await TechnicianRepository().getById(b.providerId);
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
          const SizedBox(height: 10),
          Row(
            children: [
              if (b.providerPhone.isNotEmpty) ...[
                IconSquareButton(
                  icon: Icons.call,
                  size: 42,
                  iconSize: 18,
                  radius: 12,
                  tooltip: context.l10n.call,
                  onTap: () => CallService.instance.startCall(
                    context: context,
                    calleePhone: b.providerPhone,
                    calleeName: b.providerName,
                    bookingId: b.id,
                    calleeUid: b.providerId,
                    calleeRole: 'provider',
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DirectChatScreen(
                          otherPartyId: b.providerId,
                          otherPartyName: b.providerName.isNotEmpty
                              ? b.providerName
                              : context.l10n.roleProvider,
                          otherPartyRole: 'provider',
                          bookingId: b.id,
                          jobRequestId: b.jobRequestId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: Text(
                    context.l10n.chat,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12.5),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (b.status == JobStatus.pending ||
                  b.status == JobStatus.confirmed) ...[
                const SizedBox(width: 8),
                IconSquareButton(
                  icon: Icons.calendar_month_outlined,
                  size: 42,
                  iconSize: 18,
                  radius: 12,
                  tooltip: context.l10n.rescheduleBooking,
                  onTap: () => RescheduleSheet.show(
                    context: context,
                    booking: b,
                    currentUid: currentUid,
                    actorRole: 'customer',
                  ),
                ),
              ],
              if (JobStatus.canCancel(b.status)) ...[
                const SizedBox(width: 8),
                IconSquareButton(
                  icon: Icons.close_rounded,
                  size: 42,
                  iconSize: 18,
                  radius: 12,
                  color: AppColors.error,
                  tooltip: context.l10n.cancel,
                  onTap: () => _cancelBooking(context, b),
                ),
              ],
              const SizedBox(width: 8),
              IconSquareButton(
                icon: Icons.flag_outlined,
                size: 42,
                iconSize: 18,
                radius: 12,
                color: AppColors.error,
                tooltip: context.l10n.reportProblemTitle,
                onTap: () => ReportProblemDialog.show(
                  context,
                  bookingId: b.id,
                  otherPartyId: b.providerId,
                  otherPartyRole: 'provider',
                  otherPartyName: b.providerName,
                ),
              ),
            ],
          ),
          if (b.isEligibleForNoShow) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size.fromHeight(38),
              ),
              label: Text(
                context.l10n.providerDidNotCome,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
              icon: const Icon(Icons.person_off_outlined, size: 16),
              onPressed: () => _promptReportNoShow(context, b),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildArrivalClaimCard(BuildContext context, Booking booking) {
    final displayName = booking.providerName.isNotEmpty
        ? booking.providerName
        : context.l10n.roleProvider;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_on_rounded,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.providerSaysArrived(displayName),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ],
          ),
          if (booking.arrivalDistanceM != null &&
              (booking.arrivalOutsideZone ||
                  booking.arrivalDistanceM! > 200)) ...[
            const SizedBox(height: 6),
            Text(
              context.l10n
                  .providerGpsShowsAway(booking.arrivalDistanceM.toString()),
              style:
                  TextStyle(fontSize: 11.5, color: context.themeTextSecondary),
            ),
          ],
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final yesBtn = ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size.fromHeight(38),
                ),
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: Text(
                  context.l10n.yesTheyAreHere,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
                onPressed: () async {
                  try {
                    await BookingRepository().confirmCustomerArrival(
                      bookingId: booking.id,
                      jobRequestId: booking.jobRequestId,
                    );
                  } catch (e) {
                    if (kDebugMode) {
                      debugPrint(
                          '[CustomerBookings] confirm arrival error: $e');
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(context.l10n.somethingWentWrong),
                            backgroundColor: AppColors.error),
                      );
                    }
                  }
                },
              );

              final noBtn = OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size.fromHeight(38),
                ),
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: Text(
                  context.l10n.noNotHere,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
                onPressed: () async {
                  try {
                    await BookingRepository().denyCustomerArrival(
                      bookingId: booking.id,
                      currentDeniedCount: booking.arrivalDeniedCount,
                    );
                  } catch (e) {
                    if (kDebugMode) {
                      debugPrint('[CustomerBookings] deny arrival error: $e');
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(context.l10n.somethingWentWrong),
                            backgroundColor: AppColors.error),
                      );
                    }
                  }
                },
              );

              // stack buttons when narrow
              if (constraints.maxWidth < 360) {
                return Column(
                  children: [
                    SizedBox(width: double.infinity, child: yesBtn),
                    const SizedBox(height: 8),
                    SizedBox(width: double.infinity, child: noBtn),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: yesBtn),
                  const SizedBox(width: 8),
                  Expanded(child: noBtn),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _promptReportNoShow(
      BuildContext context, Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          context.l10n.confirmNoShowTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          context.l10n.confirmNoShowMessage,
          style: TextStyle(color: context.themeTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.providerDidNotCome),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await BookingRepository().reportNoShow(
          bookingId: booking.id,
          jobRequestId: booking.jobRequestId,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.noShowReportedSuccess),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[CustomerBookings] report no-show error: $e');
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.somethingWentWrong),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Widget _buildJobRequestsStream(BuildContext context, String customerId) {
    return StreamBuilder<List<JobRequest>>(
      stream: JobRequestRepository().streamCustomerRequests(customerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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
                  const Icon(Icons.error_outline,
                      size: 40, color: AppColors.error),
                  const SizedBox(height: 12),
                  Text(
                    'Could not load job posts: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.themeTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final allRequests = snapshot.data ?? [];
        // show open and bidding jobs
        final openRequests =
            allRequests.where((r) => r.status == 'open').toList();

        if (openRequests.isEmpty) {
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
                    child: const Icon(
                      Icons.assignment_outlined,
                      size: 44,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.noJobPostsYet,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.noJobPostsDesc,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.themeTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: context.l10n.postJobAndGetQuotes,
                    leadingIcon: Icons.add,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PostJobRequestScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(
              16, 4, 16, AppBottomNav.contentBottomPadding),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.yourPostedJobs(openRequests.length),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PostJobRequestScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: Text(
                    context.l10n.postNewJob,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...openRequests.map((r) => _CustomerJobRequestCard(request: r)),
          ],
        );
      },
    );
  }

  Widget _buildHistoryStream(BuildContext context, String customerId) {
    return StreamBuilder<List<Booking>>(
      stream: BookingRepository().streamBookingsForCustomer(customerId),
      builder: (context, bookingSnap) {
        return StreamBuilder<List<JobRequest>>(
          stream: JobRequestRepository().streamCustomerRequests(customerId),
          builder: (context, jobSnap) {
            if (bookingSnap.connectionState == ConnectionState.waiting &&
                jobSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (bookingSnap.hasError) {
              SessionGuard.handlePermissionDenied(bookingSnap.error);
            }
            if (jobSnap.hasError) {
              SessionGuard.handlePermissionDenied(jobSnap.error);
            }

            final bookings = bookingSnap.data ?? [];
            final historyBookings =
                bookings.where((b) => JobStatus.isTerminal(b.status)).toList();

            final allRequests = jobSnap.data ?? [];
            final closedJobs = allRequests
                .where((r) =>
                    !r.becameBooking &&
                    !r.hiddenByCustomer &&
                    ((r.status == 'expired' || r.status == 'cancelled') ||
                        (r.status == 'deleted' &&
                            r.deletedAt != null &&
                            DateTime.now().difference(r.deletedAt!).inDays <
                                1)))
                .toList();

            final List<_HistoryItem> items = [
              ...historyBookings.map((b) => _HistoryItem.booking(b)),
              ...closedJobs.map((r) => _HistoryItem.jobRequest(r)),
            ];

            items.sort((a, b) => b.timestamp.compareTo(a.timestamp));

            if (items.isEmpty) {
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
                        child: const Icon(
                          Icons.history_rounded,
                          size: 44,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.l10n.noServiceHistoryYet,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.l10n.noServiceHistorySubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.themeTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                  16, 8, 16, AppBottomNav.contentBottomPadding),
              children: [
                Text(
                  context.l10n.historyTab,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                ...items.map((item) {
                  if (item.isBooking) {
                    return HistoryBookingCard(
                      booking: item.booking!,
                      onTap: () =>
                          _showJobHistoryDetailModal(context, item.booking!),
                    );
                  } else {
                    return HistoryJobRequestCard(request: item.jobRequest!);
                  }
                }),
              ],
            );
          },
        );
      },
    );
  }

  void _showJobHistoryDetailModal(BuildContext context, Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _JobHistoryDetailModal(booking: booking),
    );
  }

  Future<void> _cancelBooking(BuildContext context, Booking booking) async {
    if (!JobStatus.canCancel(booking.status)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.cannotCancelInProgressBooking),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final reasons = [
      context.l10n.cancelReasonCustomerRequest,
      context.l10n.cancelReasonScheduleConflict,
      context.l10n.cancelReasonPriceDispute,
      context.l10n.cancelReasonOther,
    ];
    String selectedReason = reasons.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: ctx.themeSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            context.l10n.cancelBookingOrQuote,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.cancelBookingPrompt,
                style: TextStyle(fontSize: 13, color: ctx.themeTextSecondary),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedReason,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.l10n.cancellationReasonPrompt,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: reasons
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r, style: const TextStyle(fontSize: 13)),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedReason = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(context.l10n.confirmCancellation),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await BookingRepository().cancelBooking(
          bookingId: booking.id,
          reason: selectedReason,
          cancelledBy: 'customer',
          jobRequestId: booking.jobRequestId,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.bookingCancelledSuccess),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } catch (e) {
        debugPrint('[CustomerBookingsView] Error: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(context.l10n.somethingWentWrong),
                backgroundColor: AppColors.error),
          );
        }
      }
    }
  }
}

class HistoryBookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;

  const HistoryBookingCard({
    super.key,
    required this.booking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _formatBookingDate(context, booking),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: context.themeTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                StatusPill.fromStatus(booking.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              booking.title.isNotEmpty
                  ? booking.title
                  : context.l10n.serviceDiagnostic,
              style:
                  const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
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
                          booking.providerName.isNotEmpty
                              ? context.l10n.byTechnician(booking.providerName)
                              : context.l10n.technician,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.themeTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (booking.rating != null && booking.rating! > 0) ...[
                        const SizedBox(width: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            booking.rating!,
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
                  booking.estRate.isNotEmpty ? booking.estRate : 'LKR --',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: context.themeMuted,
                ),
              ],
            ),
            if (booking.status == JobStatus.cancelled ||
                booking.status == JobStatus.declined) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    JobRequest? prefillJob;
                    if (booking.jobRequestId != null &&
                        booking.jobRequestId!.isNotEmpty) {
                      prefillJob = await JobRequestRepository()
                          .getById(booking.jobRequestId!);
                    }
                    if (prefillJob == null && context.mounted) {
                      prefillJob = JobRequest(
                        id: '',
                        customerId: booking.customerId,
                        customerName: booking.customerName,
                        title: booking.title,
                        description: '',
                        category: '',
                        latitude: booking.customerLatitude,
                        longitude: booking.customerLongitude,
                        address: booking.location,
                      );
                    }
                    if (context.mounted && prefillJob != null) {
                      JobRepostSheet.show(
                        context,
                        request: prefillJob,
                        booking: booking,
                      );
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(context.l10n.repost),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatBookingDate(BuildContext context, Booking booking) {
    final date = booking.completedAt ?? booking.createdAt;
    if (date != null) {
      final locale = Localizations.localeOf(context).languageCode;
      final formatted = DateFormat('d MMM yyyy', locale).format(date);
      if (booking.status == JobStatus.cancelled) {
        return context.l10n.cancelledOn(formatted);
      } else if (booking.status == JobStatus.completed) {
        return context.l10n.completedOn(formatted);
      }
    }
    return booking.relativeTime.isNotEmpty
        ? booking.relativeTime
        : (booking.time.isNotEmpty ? booking.time : context.l10n.pastService);
  }
}

class _JobHistoryDetailModal extends StatelessWidget {
  final Booking booking;

  const _JobHistoryDetailModal({required this.booking});

  @override
  Widget build(BuildContext context) {
    final isCompleted = booking.status == JobStatus.completed;

    return Container(
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.themeBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking.title.isNotEmpty
                          ? booking.title
                          : context.l10n.serviceDiagnostic,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  StatusPill.fromStatus(booking.status),
                ],
              ),
              const SizedBox(height: 14),
              AppCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _buildDetailRow(
                      context,
                      icon: Icons.calendar_today_outlined,
                      label: context.l10n.serviceDate,
                      value: booking.relativeTime.isNotEmpty
                          ? booking.relativeTime
                          : (booking.time.isNotEmpty
                              ? booking.time
                              : context.l10n.statusCompleted),
                    ),
                    const Divider(height: 16),
                    _buildDetailRow(
                      context,
                      icon: Icons.location_on_outlined,
                      label: context.l10n.location,
                      value: booking.location.isNotEmpty
                          ? booking.location
                          : context.l10n.notSpecified,
                    ),
                    const Divider(height: 16),
                    _buildDetailRow(
                      context,
                      icon: Icons.payments_outlined,
                      label: context.l10n.agreedPrice,
                      value: booking.estRate.isNotEmpty
                          ? booking.estRate
                          : context.l10n.statusCompleted,
                    ),
                    if (isCompleted) ...[
                      const Divider(height: 16),
                      _buildDetailRow(
                        context,
                        icon: Icons.verified_user_outlined,
                        label: context.l10n.serviceVerification,
                        value: context.l10n.pinVerified,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => BookingTimelineSheet.show(
                  context,
                  bookingId: booking.id,
                  bookingTitle: booking.title,
                ),
                icon: const Icon(Icons.timeline_rounded, size: 16),
                label: Text(context.l10n.viewTimeline),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => ReportProblemDialog.show(
                  context,
                  bookingId: booking.id,
                  otherPartyId: booking.providerId,
                  otherPartyRole: 'provider',
                  otherPartyName: booking.providerName,
                ),
                icon: const Icon(Icons.flag_outlined,
                    size: 16, color: AppColors.error),
                label: Text(
                  context.l10n.reportProblemTitle,
                  style: const TextStyle(color: AppColors.error),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                  side:
                      BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (isCompleted) ...[
                CustomerPaymentCard(
                  booking: booking,
                  onUpdated: () => Navigator.pop(context),
                ),
              ],
              if (booking.beforePhotos.isNotEmpty ||
                  booking.afterPhotos.isNotEmpty) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => JobPhotosSheet.show(
                    context,
                    booking: booking,
                    isProvider: false,
                  ),
                  icon: const Icon(Icons.photo_library_rounded, size: 16),
                  label: Text(
                    '${context.l10n.jobPhotos} (${booking.beforePhotos.length + booking.afterPhotos.length})',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
              if (booking.jobRequestId != null &&
                  booking.jobRequestId!.isNotEmpty)
                FutureBuilder<JobRequest?>(
                  future: JobRequestRepository().getById(booking.jobRequestId!),
                  builder: (ctx, snap) {
                    final jr = snap.data;
                    if (jr == null ||
                        (jr.photoUrls.isEmpty &&
                            (jr.videoUrl == null || jr.videoUrl!.isEmpty))) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: JobMediaGallery(
                        photoUrls: jr.photoUrls,
                        videoUrl: jr.videoUrl,
                      ),
                    );
                  },
                ),
              const SizedBox(height: 16),
              Text(
                context.l10n.providerDetailsTitle,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              AppCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    UserAvatar(
                      uid: booking.providerId,
                      displayName: booking.providerName,
                      radius: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.providerName.isNotEmpty
                                ? booking.providerName
                                : context.l10n.technician,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            context.l10n.roleProvider,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.themeTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (booking.providerPhone.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: IconSquareButton.small(
                          icon: Icons.call,
                          tooltip: context.l10n.call,
                          onTap: () => CallService.instance.startCall(
                            context: context,
                            calleePhone: booking.providerPhone,
                            calleeName: booking.providerName,
                            bookingId: booking.id,
                            calleeUid: booking.providerId,
                            calleeRole: 'provider',
                          ),
                        ),
                      ),
                    IconSquareButton.small(
                      icon: Icons.chat_bubble_outline,
                      tooltip: context.l10n.chat,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DirectChatScreen(
                              otherPartyId: booking.providerId,
                              otherPartyName: booking.providerName,
                              otherPartyRole: 'provider',
                              bookingId: booking.id,
                              jobRequestId: booking.jobRequestId,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (isCompleted) ...[
                if (booking.rating != null && booking.rating! > 0) ...[
                  Text(
                    context.l10n.yourRatingReview,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        ...List.generate(
                          booking.rating!,
                          (i) => const Icon(Icons.star_rounded,
                              size: 18, color: AppColors.secondaryContainer),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${booking.rating}.0 / 5.0',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  PrimaryButton(
                    label: context.l10n.rateServiceProvider,
                    leadingIcon: Icons.star_rounded,
                    onPressed: () async {
                      Navigator.pop(context);
                      final tech = await TechnicianRepository()
                          .getById(booking.providerId);
                      if (tech == null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(context.l10n.somethingWentWrong),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                        return;
                      }
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RatingCompletionScreen(
                              technician: tech,
                              bookingId: booking.id,
                              jobRequestId: booking.jobRequestId ?? '',
                              jobTitle: booking.title,
                              totalPrice: booking.agreedPrice,
                              completionType: booking.completionType,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.themeTextSecondary),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.themeTextSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CustomerJobRequestCard extends StatelessWidget {
  final JobRequest request;

  const _CustomerJobRequestCard({required this.request});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  String _getStatusLabel(BuildContext context, String status) {
    return LocalizedData.getStatus(context, status);
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(request.status);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (request.isExpired ? AppColors.error : statusColor)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: request.isExpired
                                ? AppColors.error
                                : statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          request.isExpired
                              ? context.l10n.expiredPill
                              : _getStatusLabel(context, request.status),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: request.isExpired
                                ? AppColors.error
                                : statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (request.bookingType == 'scheduled') ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_month_outlined,
                              size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            request.scheduledSlot ??
                                context.l10n.statusScheduled,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.themeSurfaceLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  CategoryService.instance
                      .nameOf(request.category, context: context),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.themeTextSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            request.title,
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
          ),
          if (request.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              request.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                color: context.themeTextSecondary,
                height: 1.3,
              ),
            ),
          ],
          if (request.photoUrls.isNotEmpty ||
              (request.videoUrl != null && request.videoUrl!.isNotEmpty)) ...[
            const SizedBox(height: 10),
            JobMediaGallery(
              photoUrls: request.photoUrls,
              videoUrl: request.videoUrl,
              height: 56,
              showHeader: false,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 14, color: context.themeTextSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  request.address.isNotEmpty
                      ? request.address
                      : context.l10n.locationNotSpecified,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: context.themeTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<Quote>>(
            stream: JobRequestRepository().streamQuotesForRequest(request.id),
            builder: (ctx, quoteSnap) {
              final quotes = quoteSnap.data ?? [];
              final quotesCount = quotes.length;

              return Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JobQuotesScreen(
                              requestId: request.id,
                              jobTitle: request.title,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      icon: Icon(
                        quotesCount > 0
                            ? Icons.mark_chat_unread_outlined
                            : Icons.remove_red_eye_outlined,
                        size: 17,
                      ),
                      label: Text(
                        quotesCount > 0
                            ? context.l10n.reviewQuotesCount(quotesCount)
                            : context.l10n.waitingForQuotes,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final editBtn = OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PostJobRequestScreen(editJob: request),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: Text(context.l10n.editJobPost),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );

                      final deleteBtn = OutlinedButton.icon(
                        onPressed: () => request.canDelete
                            ? _deleteJobPost(context)
                            : _cancelJob(context),
                        icon: Icon(
                          request.canDelete
                              ? Icons.delete_outline
                              : Icons.cancel_outlined,
                          size: 16,
                          color: AppColors.error,
                        ),
                        label: Text(
                          request.canDelete
                              ? context.l10n.deleteJobPost
                              : context.l10n.cancelJobTitle,
                          style: const TextStyle(color: AppColors.error),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );

                      // stack buttons when narrow
                      if (constraints.maxWidth < 360) {
                        return Column(
                          children: [
                            SizedBox(width: double.infinity, child: editBtn),
                            const SizedBox(height: 8),
                            SizedBox(width: double.infinity, child: deleteBtn),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: editBtn),
                          const SizedBox(width: 8),
                          Expanded(child: deleteBtn),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deleteJobPost(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.themeSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.l10n.deleteJobPost,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          context.l10n.deleteJobPostConfirm,
          style: TextStyle(color: ctx.themeTextSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(context.l10n.deleteJobPost),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final prevStatus = request.status;
        await JobRequestRepository()
            .deleteJobPost(request.id, previousStatus: prevStatus);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.deleteJobPostSuccess),
              backgroundColor: AppColors.primary,
              action: SnackBarAction(
                label: context.l10n.undo,
                textColor: Colors.white,
                onPressed: () async {
                  try {
                    await JobRequestRepository()
                        .undoDeleteJobPost(request.id, prevStatus);
                  } catch (e) {
                    debugPrint('[CustomerBookingsView] Undo delete error: $e');
                    unawaited(
                      ErrorReporter.report(
                        screen: 'customer_bookings',
                        action: 'undo',
                        error: e,
                      ),
                    );
                    if (context.mounted) {
                      final debugDetails = ErrorReporter.formatDebugDetails(e);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.l10n.somethingWentWrong),
                              if (kDebugMode && debugDetails.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  debugDetails,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('[CustomerBookingsView] Delete job error: $e');
        unawaited(
          ErrorReporter.report(
            screen: 'customer_bookings',
            action: 'delete',
            error: e,
          ),
        );
        if (context.mounted) {
          final debugDetails = ErrorReporter.formatDebugDetails(e);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.somethingWentWrong),
                  if (kDebugMode && debugDetails.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      debugDetails,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _cancelJob(BuildContext context) async {
    String selectedReason = context.l10n.cancelReasonNoLongerNeeded;
    final reasons = [
      context.l10n.cancelReasonFoundSomeone,
      context.l10n.cancelReasonNoLongerNeeded,
      context.l10n.cancelReasonTooExpensive,
      context.l10n.cancelReasonOther,
    ];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: ctx.themeSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(context.l10n.cancelJobTitle,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.cancelJobConfirmPrompt,
                style: TextStyle(color: ctx.themeTextSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedReason,
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: reasons
                    .map((r) => DropdownMenuItem(
                        value: r,
                        child: Text(r, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedReason = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(context.l10n.confirmCancellation),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid ?? 'customer';
        await JobRequestRepository().cancelJobRequest(
          requestId: request.id,
          reason: selectedReason,
          cancelledBy: uid,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.bookingCancelledSuccess),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } catch (e) {
        debugPrint('[CustomerBookingsView] Cancel job failed: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(context.l10n.somethingWentWrong),
                backgroundColor: AppColors.error),
          );
        }
      }
    }
  }
}

class _HistoryItem {
  final Booking? booking;
  final JobRequest? jobRequest;
  final DateTime timestamp;

  _HistoryItem.booking(Booking b)
      : booking = b,
        jobRequest = null,
        timestamp = b.completedAt ??
            b.scheduledDate ??
            b.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);

  _HistoryItem.jobRequest(JobRequest r)
      : booking = null,
        jobRequest = r,
        timestamp = r.cancelledAt ??
            r.expiresAt ??
            r.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);

  bool get isBooking => booking != null;
}

class HistoryJobRequestCard extends StatelessWidget {
  final JobRequest request;

  const HistoryJobRequestCard({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatStatusDate(context, request);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusPill.fromStatus(request.status),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  request.category,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (dateLabel.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dateLabel,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: context.themeTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else ...[
                const Spacer(),
              ],
              const SizedBox(width: 8),
              Text(
                context.l10n.quoteCountBids(request.quoteCount),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: context.themeTextSecondary,
                ),
              ),
            ],
          ),
          if (request.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              request.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: context.themeTextSecondary,
              ),
            ),
          ],
          if (request.isPhotosRemoved) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.photo_outlined,
                    size: 14, color: context.themeTextSecondary),
                const SizedBox(width: 4),
                Text(
                  context.l10n.photosRemoved,
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: context.themeTextSecondary,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          if (request.status == 'deleted') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleUndo(context),
                icon: const Icon(Icons.undo_rounded, size: 16),
                label: Text(context.l10n.undo),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        JobRepostSheet.show(context, request: request),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(context.l10n.repost),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: context.l10n.removeFromHistory,
                  icon: Semantics(
                    label: context.l10n.removeFromHistory,
                    child: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.error,
                    ),
                  ),
                  onPressed: () => _handleRemove(context),
                  style: IconButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatStatusDate(BuildContext context, JobRequest request) {
    final date = request.cancelledAt ??
        request.expiresAt ??
        request.completedAt ??
        request.createdAt;
    if (date == null) return '';
    final locale = Localizations.localeOf(context).languageCode;
    final formatted = DateFormat('d MMM yyyy', locale).format(date);
    if (request.status == JobRequestStatus.expired) {
      return context.l10n.expiredOn(formatted);
    } else if (request.status == JobRequestStatus.cancelled) {
      return context.l10n.cancelledOn(formatted);
    } else if (request.status == JobRequestStatus.completed) {
      return context.l10n.completedOn(formatted);
    } else {
      return context.l10n.postedOn(formatted);
    }
  }

  Future<void> _handleUndo(BuildContext context) async {
    final now = DateTime.now();
    final fallbackStatus =
        (request.expiresAt != null && request.expiresAt!.isAfter(now))
            ? 'open'
            : 'expired';
    final targetStatus =
        (request.previousStatus != null && request.previousStatus!.isNotEmpty)
            ? request.previousStatus!
            : fallbackStatus;

    try {
      await JobRequestRepository().undoDeleteJobPost(
        request.id,
        targetStatus,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.undoDeletePostSuccess),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('[HistoryJobRequestCard] Undo error: $e');
      unawaited(
        ErrorReporter.report(
          screen: 'history',
          action: 'undo',
          error: e,
        ),
      );
      if (context.mounted) {
        final debugDetails = ErrorReporter.formatDebugDetails(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.somethingWentWrong),
                if (kDebugMode && debugDetails.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    debugDetails,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ],
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleRemove(BuildContext context) async {
    final isPermanentDelete = request.canDelete;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.themeSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isPermanentDelete
              ? context.l10n.deleteJobPost
              : context.l10n.removeFromHistory,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isPermanentDelete
              ? context.l10n.deleteJobPostConfirm
              : context.l10n.removeFromHistoryConfirm,
          style: TextStyle(color: ctx.themeTextSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isPermanentDelete
                  ? context.l10n.deleteJobPost
                  : context.l10n.removeFromHistory,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        if (isPermanentDelete) {
          final prevStatus = request.status;
          await JobRequestRepository()
              .deleteJobPost(request.id, previousStatus: prevStatus);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.deleteJobPostSuccess),
                backgroundColor: AppColors.primary,
                action: SnackBarAction(
                  label: context.l10n.undo,
                  textColor: Colors.white,
                  onPressed: () async {
                    try {
                      await JobRequestRepository()
                          .undoDeleteJobPost(request.id, prevStatus);
                    } catch (e) {
                      debugPrint('[HistoryJobRequestCard] Undo error: $e');
                      unawaited(
                        ErrorReporter.report(
                          screen: 'history',
                          action: 'undo',
                          error: e,
                        ),
                      );
                      if (context.mounted) {
                        final debugDetails =
                            ErrorReporter.formatDebugDetails(e);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(context.l10n.somethingWentWrong),
                                if (kDebugMode && debugDetails.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    debugDetails,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            );
          }
        } else {
          await JobRequestRepository().hideJobPostFromCustomer(request.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.removeFromHistorySuccess),
                backgroundColor: AppColors.primary,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('[HistoryJobRequestCard] remove error: $e');
        unawaited(
          ErrorReporter.report(
            screen: 'history',
            action: isPermanentDelete ? 'delete' : 'remove',
            error: e,
          ),
        );
        if (context.mounted) {
          final debugDetails = ErrorReporter.formatDebugDetails(e);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.somethingWentWrong),
                  if (kDebugMode && debugDetails.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      debugDetails,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

// load media gallery once
class _BookingMediaGallery extends StatefulWidget {
  final String jobRequestId;

  const _BookingMediaGallery({required this.jobRequestId});

  @override
  State<_BookingMediaGallery> createState() => _BookingMediaGalleryState();
}

class _BookingMediaGalleryState extends State<_BookingMediaGallery> {
  late final Future<JobRequest?> _future =
      JobRequestRepository().getById(widget.jobRequestId);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<JobRequest?>(
      future: _future,
      builder: (ctx, snap) {
        final jr = snap.data;
        if (jr == null ||
            (jr.photoUrls.isEmpty &&
                (jr.videoUrl == null || jr.videoUrl!.isEmpty))) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: JobMediaGallery(
            photoUrls: jr.photoUrls,
            videoUrl: jr.videoUrl,
          ),
        );
      },
    );
  }
}
