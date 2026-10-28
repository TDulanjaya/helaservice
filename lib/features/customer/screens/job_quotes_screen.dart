import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../theme/app_theme.dart';
import '../../../models/job_request.dart';
import '../../../models/quote.dart';
import '../../../models/booking.dart';
import '../../../constants/firestore_paths.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../repositories/job_request_repository.dart';
import '../../../models/technician.dart';
import '../../../services/category_service.dart';
import '../../../repositories/technician_repository.dart';
import '../../../utils/location_utils.dart';
import '../../../utils/exact_location_helper.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/app_localizations_helpers.dart';
import 'live_tracking_screen.dart';
import 'direct_chat_screen.dart';
import 'post_job_request_screen.dart';
import '../../../services/chat_service.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/icon_square_button.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/job_location_picker.dart';
import '../../../shared/widgets/job_schedule_picker.dart';
import '../../../services/call_service.dart';
import '../../shared/widgets/job_media_gallery.dart';
import '../../../utils/schedule_helpers.dart';

class JobQuotesScreen extends StatefulWidget {
  final String requestId;
  final String jobTitle;

  const JobQuotesScreen({
    super.key,
    required this.requestId,
    required this.jobTitle,
  });

  @override
  State<JobQuotesScreen> createState() => _JobQuotesScreenState();
}

class _JobQuotesScreenState extends State<JobQuotesScreen> {
  final JobRequestRepository _repo = JobRequestRepository();
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _jobStream;
  bool _hadPendingWrites = false;

  String get requestId => widget.requestId;
  String get jobTitle => widget.jobTitle;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    _jobStream = _repo.streamJobRequestSnapshot(widget.requestId);
  }

  void _retrySubscription() {
    setState(() {
      _initStream();
    });
  }

  Widget _buildPendingWritesBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.pendingJobPostBanner,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              context.l10n.jobLoadErrorTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _retrySubscription,
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(context.l10n.retryAction),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundOrFailedState(BuildContext context,
      {required bool isFailed}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFailed ? Icons.warning_amber_rounded : Icons.search_off_rounded,
              size: 48,
              color: isFailed ? AppColors.error : context.themeTextSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              isFailed
                  ? context.l10n.jobPostFailedTitle
                  : context.l10n.jobNotFoundTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: Text(context.l10n.backAction),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Center(
          child: IconSquareButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.maybePop(context),
          ),
        ),
        title: Text(
          jobTitle,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _jobStream,
          builder: (context, requestSnap) {
            if (requestSnap.hasError) {
              debugPrint(
                  '[JobQuotesScreen] stream error: ${requestSnap.error}');
              return _buildErrorState(context);
            }

            if (requestSnap.connectionState == ConnectionState.waiting &&
                !requestSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docSnap = requestSnap.data;
            if (docSnap == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final exists = docSnap.exists && docSnap.data() != null;
            final isFromCache = docSnap.metadata.isFromCache;
            final hasPendingWrites = docSnap.metadata.hasPendingWrites;

            if (exists && hasPendingWrites) {
              _hadPendingWrites = true;
            }

            // while not exists and from local cache, keep showing spinner
            if (!exists && isFromCache) {
              return const Center(child: CircularProgressIndicator());
            }

            // if not exists and from server: check if it failed after pending write or not found
            if (!exists) {
              return _buildNotFoundOrFailedState(context,
                  isFailed: _hadPendingWrites);
            }

            final request = JobRequest.fromMap(docSnap.id, docSnap.data()!);

            return Column(
              children: [
                if (hasPendingWrites) _buildPendingWritesBanner(context),
                _JobSummaryCard(request: request),
                const SizedBox(height: 4),
                Expanded(
                  child: StreamBuilder<List<Quote>>(
                    stream: _repo.streamQuotesForRequest(requestId),
                    builder: (context, quotesSnap) {
                      if (quotesSnap.connectionState ==
                              ConnectionState.waiting &&
                          !quotesSnap.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        );
                      }

                      final allQuotes = quotesSnap.data ?? [];
                      final quotes = allQuotes
                          .where((q) => q.status != 'withdrawn')
                          .toList();
                      final hasWithdrawn =
                          allQuotes.any((q) => q.status == 'withdrawn');

                      if (request.status == 'assigned') {
                        return _buildAssignedView(context, request, quotes);
                      }

                      if (request.status == 'cancelled') {
                        return _buildCancelledView(context, request);
                      }

                      if (quotes.isEmpty) {
                        return _buildWaitingView(context, request);
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: quotes.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                        '${quotes.length} ${context.l10n.quotesReceived}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          letterSpacing: 0.8,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (hasWithdrawn) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: context.themeSurfaceLow,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: context.themeBorder),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.info_outline_rounded,
                                              size: 16,
                                              color:
                                                  context.themeTextSecondary),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'A provider withdrew their quote.',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    context.themeTextSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }
                          final quote = quotes[index - 1];
                          return _QuoteCard(
                            quote: quote,
                            request: request,
                            onAccept: () =>
                                _acceptQuote(context, quote, request),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWaitingView(BuildContext context, JobRequest request) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // status pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
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
                    LocalizedData.getStatus(context, request.status),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // icon badge
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: const Icon(
                Icons.mark_email_unread_outlined,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.waitingForQuotes,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.waitingForQuotesDesc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: context.themeTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            // info tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.themeSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.themeBorder),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active_outlined,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.l10n.noQuotes,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.themeTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.verified_outlined,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.l10n.quotesAlert,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.themeTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final editBtn = OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostJobRequestScreen(editJob: request),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(context.l10n.editJobPost),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                );

                final deleteBtn = OutlinedButton.icon(
                  onPressed: () => request.canDelete
                      ? _deleteJob(context, request)
                      : _cancelJob(context, request),
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
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
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: Text(context.l10n.backToHome),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignedView(
      BuildContext context, JobRequest request, List<Quote> quotes) {
    final acceptedQuote = quotes.where((q) => q.status == 'accepted').toList();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              acceptedQuote.isNotEmpty
                  ? context.l10n.providerHired(acceptedQuote.first.providerName)
                  : context.l10n.providerHired(context.l10n.roleProvider),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            if (acceptedQuote.isNotEmpty)
              Text(
                '${acceptedQuote.first.providerName} • ${request.agreedPrice != null ? "LKR ${request.agreedPrice!.toStringAsFixed(0)}" : "LKR ${acceptedQuote.first.quotedPrice.toStringAsFixed(0)}"}',
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 13, color: context.themeTextSecondary),
              ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: context.l10n.openLiveGpsTracking,
              leadingIcon: Icons.navigation,
              expand: false,
              onPressed: () async {
                final providerId = request.selectedProviderId ??
                    (acceptedQuote.isNotEmpty
                        ? acceptedQuote.first.providerId
                        : '');
                final tech = await TechnicianRepository().getById(providerId);

                Booking? booking;
                try {
                  final bSnap = await FirebaseFirestore.instance
                      .collection(FirestorePaths.bookings)
                      .where('jobRequestId', isEqualTo: request.id)
                      .limit(1)
                      .get();
                  if (bSnap.docs.isNotEmpty) {
                    booking = Booking.fromMap(
                        bSnap.docs.first.id, bSnap.docs.first.data());
                  }
                } catch (_) {}

                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => LiveTrackingScreen(
                        technician: tech,
                        booking: booking,
                        showBottomNav: false,
                      ),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final pId = request.selectedProviderId ??
                    (acceptedQuote.isNotEmpty
                        ? acceptedQuote.first.providerId
                        : '');
                final pName = acceptedQuote.isNotEmpty
                    ? acceptedQuote.first.providerName
                    : context.l10n.roleProvider;
                final tech = await TechnicianRepository().getById(pId);
                final pPhone = tech?.phone;
                if (!context.mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DirectChatScreen(
                      otherPartyId: pId,
                      otherPartyName: pName,
                      otherPartyRole: 'provider',
                      otherPartyPhone: pPhone,
                      jobRequestId: request.id,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: Text(context.l10n.chatWithProvider),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _cancelJob(context, request),
              icon: const Icon(Icons.cancel_outlined,
                  size: 16, color: AppColors.error),
              label: Text(
                context.l10n.cancelBookingOrQuote,
                style: const TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: Text(context.l10n.backToHome),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelledView(BuildContext context, JobRequest request) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.highlight_off,
                  color: AppColors.error, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              LocalizedData.getStatus(context, 'cancelled'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 8),
            if (request.cancellationReason != null &&
                request.cancellationReason!.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: context.themeSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.themeBorder),
                ),
                child: Column(
                  children: [
                    Text(
                      '${context.l10n.cancellationReasonPrompt}:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.themeTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.cancellationReason!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              label: context.l10n.postAgain,
              leadingIcon: Icons.refresh_rounded,
              expand: false,
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostJobRequestScreen(prefillJob: request),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _deleteJob(context, request),
              icon: const Icon(Icons.delete_forever,
                  size: 18, color: AppColors.error),
              label: Text(context.l10n.deleteJob,
                  style: const TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: Text(context.l10n.backToHome),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelJob(BuildContext context, JobRequest request) async {
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
                        child: Text(r, style: const TextStyle(fontSize: 13))))
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
        await JobRequestRepository().cancelAssignedJob(
          requestId: request.id,
          cancelledByRole: 'customer',
          reason: selectedReason,
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
        debugPrint('[JobQuotesScreen] Cancel booking failed: $e');
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

  Future<void> _deleteJob(BuildContext context, JobRequest request) async {
    final isPermanent = request.canDelete;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.themeSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isPermanent
              ? context.l10n.deleteJobPost
              : context.l10n.removeFromHistory,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isPermanent
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
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              isPermanent ? context.l10n.deleteJobPost : context.l10n.removeFromHistory,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        if (isPermanent) {
          await JobRequestRepository()
              .deleteJobPost(request.id, previousStatus: request.status);
        } else {
          await JobRequestRepository().hideJobPostFromCustomer(request.id);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isPermanent
                    ? context.l10n.deleteJobPostSuccess
                    : context.l10n.removeFromHistorySuccess,
              ),
              backgroundColor: AppColors.primary,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        debugPrint('[JobQuotesScreen] Delete job error: $e');
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

  Future<void> _promptSetJobLocationAndAccept(
      BuildContext context, Quote quote, JobRequest request) async {
    final setLocation = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.themeSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.location_off_rounded,
                color: AppColors.warning, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.locationRequiredTitle,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
            ),
          ],
        ),
        content: Text(
          context.l10n.jobNoLocationRepost,
          style: TextStyle(fontSize: 13.5, color: ctx.themeTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.pin_drop_rounded, size: 16),
            label: Text(context.l10n.setServiceLocation),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );

    if (setLocation != true || !context.mounted) return;

    final picked = await JobLocationPicker.pickLocation(
      context,
      title: context.l10n.setServiceLocation,
    );

    if (picked != null && context.mounted) {
      try {
        await JobRequestRepository().updateJobLocation(
          requestId: request.id,
          latitude: picked.latitude,
          longitude: picked.longitude,
          address: picked.address,
          note: picked.effectiveNote,
          landmark: picked.effectiveNote,
        );

        final updatedRequest = request.copyWith(
          latitude: picked.latitude,
          longitude: picked.longitude,
          address: picked.address,
          note: picked.effectiveNote,
          landmark: picked.effectiveNote,
        );

        if (context.mounted) {
          await _acceptQuote(context, quote, updatedRequest);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[JobQuotes] update location error: $e');
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n
                  .failedToUpdateJobLocation(context.l10n.somethingWentWrong)),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  // pick a new time slot if previous slot passed
  Future<void> _promptUpdateScheduleAndAccept(
      BuildContext context, Quote quote, JobRequest request) async {
    final picked = await JobSchedulePicker.pickSchedule(
      context,
      initialDate: request.scheduledDate,
      initialSlot: request.scheduledSlot,
      title: context.l10n.chooseNewScheduleTitle,
    );

    if (picked != null && context.mounted) {
      try {
        await JobRequestRepository().updateJobSchedule(
          requestId: request.id,
          scheduledDate: picked.date,
          scheduledSlot: picked.slot,
          scheduleMode: picked.scheduleMode,
          scheduledStartAt: picked.scheduledStartAt,
          scheduledEndAt: picked.scheduledEndAt,
        );

        final updatedRequest = request.copyWith(
          scheduledDate: picked.date,
          scheduledSlot: picked.slot,
          scheduleMode: picked.scheduleMode,
          scheduledStartAt: picked.scheduledStartAt,
          scheduledEndAt: picked.scheduledEndAt,
        );

        if (context.mounted) {
          await _acceptQuote(context, quote, updatedRequest);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[JobQuotes] update schedule error: $e');
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

  Future<void> _acceptQuote(
      BuildContext context, Quote quote, JobRequest request) async {
    if (request.latitude == null || request.longitude == null) {
      await _promptSetJobLocationAndAccept(context, quote, request);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.l10n.acceptQuoteHire,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          '${quote.providerName}: LKR ${quote.quotedPrice.toStringAsFixed(0)}\n${context.l10n.etaLabel}: ${context.l10n.durationMins(quote.etaMinutes)}',
          style: TextStyle(color: context.themeTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(context.l10n.acceptHire,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!context.mounted) return;

    try {
      await JobRequestRepository().acceptQuote(
        requestId: requestId,
        quoteId: quote.id,
        providerId: quote.providerId,
        agreedPrice: quote.quotedPrice,
        request: request,
        quote: quote,
      );

      // open chat
      try {
        final tech = await TechnicianRepository().getById(quote.providerId);
        final chatRoomId = await ChatService.instance.getOrCreateChatRoom(
          userId1: request.customerId,
          userId2: quote.providerId,
          user1Name: request.customerName,
          user2Name: quote.providerName,
          user1Role: 'customer',
          user2Role: 'provider',
          user1Phone: request.customerPhone,
          user2Phone: tech?.phone ?? '',
          jobRequestId: requestId,
        );
        await ChatService.instance.sendMessage(
          chatRoomId: chatRoomId,
          senderId: request.customerId,
          senderName: request.customerName,
          text: quote.quotedPrice.toStringAsFixed(0),
          type: 'quote_accepted',
        );
      } catch (chatError) {
        debugPrint('Non-fatal chat room pre-creation note: $chatError');
      }

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: context.themeSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.check_circle,
                  color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.providerHired(quote.providerName),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
            ],
          ),
          content: Text(
            context.l10n.bookingConfirmedChatStarted(quote.providerName),
            style: TextStyle(fontSize: 13.5, color: context.themeTextSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(context.l10n.later),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final tech =
                    await TechnicianRepository().getById(quote.providerId);
                if (!context.mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DirectChatScreen(
                      otherPartyId: quote.providerId,
                      otherPartyName: quote.providerName,
                      otherPartyRole: 'provider',
                      otherPartyPhone: tech?.phone,
                      jobRequestId: requestId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 16),
              label: Text(context.l10n.openChat),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final tech =
                    await TechnicianRepository().getById(quote.providerId);
                if (!context.mounted) return;
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LiveTrackingScreen(
                      technician: tech,
                      showBottomNav: false,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.near_me_rounded, size: 16),
              label: Text(context.l10n.openLiveGpsTracking),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (e is ExactLocationUnavailableException ||
          e.toString().contains('ExactLocationUnavailableException')) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.couldNotLoadExactLocationRetry),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      if (e.toString().contains('JOB_LOCATION_MISSING')) {
        if (context.mounted) {
          await _promptSetJobLocationAndAccept(context, quote, request);
        }
        return;
      }
      if (e.toString().contains('QUOTE_OUTDATED')) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.quoteOutdatedDeclined),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }
      if (e.toString().contains('This quote is no longer available')) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.quoteNoLongerAvailable),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }
      if (e == 'SCHEDULE_PASSED' || e.toString().contains('SCHEDULE_PASSED')) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.scheduledTimePassedPrompt),
              backgroundColor: AppColors.warning,
            ),
          );
          await _promptUpdateScheduleAndAccept(context, quote, request);
        }
        return;
      }
      debugPrint('[JobQuotesScreen] Failed to accept quote: $e');
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

class _JobSummaryCard extends StatelessWidget {
  final JobRequest request;
  const _JobSummaryCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(16),
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
                      request.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CategoryService.instance
                          .nameOf(request.category, context: context),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.themeTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: request.status == 'open'
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.secondaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  request.status == 'open'
                      ? (request.quoteCount > 0
                          ? '${request.quoteCount} ${context.l10n.quotesTitle}'
                          : LocalizedData.getStatus(context, 'open'))
                      : LocalizedData.getStatus(context, request.status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: request.status == 'open'
                        ? AppColors.primary
                        : AppColors.secondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          if (request.photos.isNotEmpty ||
              request.video != null ||
              request.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            JobMediaGallery(
              photos: request.photos,
              video: request.video,
              legacyPhotoUrls: request.photoUrls,
            ),
          ],
        ],
      ),
    );
  }
}

class _QuoteCard extends StatefulWidget {
  final Quote quote;
  final JobRequest request;
  final VoidCallback onAccept;

  const _QuoteCard({
    required this.quote,
    required this.request,
    required this.onAccept,
  });

  @override
  State<_QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<_QuoteCard> {
  String? _fallbackLocation;
  Technician? _technician;

  @override
  void initState() {
    super.initState();
    _loadTechnician();
  }

  void _loadTechnician() async {
    final tech = await TechnicianRepository().getById(widget.quote.providerId);
    if (mounted && tech != null) {
      setState(() {
        _technician = tech;
        if (widget.quote.providerLocation.isEmpty &&
            tech.serviceArea.isNotEmpty) {
          _fallbackLocation = tech.serviceArea;
        }
      });
    }
  }

  void _callProvider() async {
    final phone = _technician?.phone ??
        (await TechnicianRepository().getById(widget.quote.providerId))
            ?.phone ??
        '';
    if (!mounted) return;
    if (phone.isNotEmpty) {
      CallService.instance.startCall(
        context: context,
        calleePhone: phone,
        calleeName: widget.quote.providerName,
        calleeUid: widget.quote.providerId,
        calleeRole: widget.quote.providerTrade.isNotEmpty
            ? widget.quote.providerTrade
            : 'provider',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.providerPhoneNotAvailable)),
      );
    }
  }

  void _chatProvider() async {
    final phone = _technician?.phone ??
        (await TechnicianRepository().getById(widget.quote.providerId))?.phone;
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DirectChatScreen(
          otherPartyId: widget.quote.providerId,
          otherPartyName: widget.quote.providerName,
          otherPartyRole: widget.quote.providerTrade.isNotEmpty
              ? widget.quote.providerTrade
              : 'provider',
          otherPartyPhone: phone,
          jobRequestId: widget.request.id,
        ),
      ),
    );
  }

  Widget _buildQuoteTypeBadge(String type) {
    Color color;
    String text;
    IconData icon;
    if (type == 'firm') {
      color = Colors.green;
      text = 'Firm Price';
      icon = Icons.verified_outlined;
    } else if (type == 'estimate') {
      color = Colors.blue;
      text = 'Estimate';
      icon = Icons.tune_rounded;
    } else {
      color = Colors.orange;
      text = 'Inspection First';
      icon = Icons.search_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quote = widget.quote;
    final request = widget.request;
    final isAccepted =
        request.status == 'assigned' && quote.status == 'accepted';

    String? distanceLabel;
    if (quote.travelKm > 0) {
      distanceLabel = LocationUtils.formatDistanceL10n(context, quote.travelKm);
    }

    final locationName = quote.providerLocation.isNotEmpty
        ? quote.providerLocation
        : (_fallbackLocation ?? '');

    String displayLocation = '';
    if (locationName.isNotEmpty && distanceLabel != null) {
      displayLocation = '$locationName · $distanceLabel';
    } else if (locationName.isNotEmpty) {
      displayLocation = locationName;
    } else if (distanceLabel != null) {
      displayLocation = distanceLabel;
    }

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      borderColor: isAccepted ? AppColors.primary : null,
      borderWidth: isAccepted ? 2.0 : 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                uid: quote.providerId,
                displayName: quote.providerName,
                radius: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            quote.providerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (quote.providerNicVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified,
                              size: 15, color: AppColors.primary),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 13, color: AppColors.secondaryContainer),
                        const SizedBox(width: 3),
                        Text(
                          '${quote.providerRating.toStringAsFixed(1)} (${quote.providerReviewCount})',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: context.themeTextSecondary,
                          ),
                        ),
                        if (displayLocation.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(
                            distanceLabel != null
                                ? Icons.near_me
                                : Icons.location_on_outlined,
                            size: 11,
                            color: context.themeTextSecondary,
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              displayLocation,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: context.themeTextSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildQuoteTypeBadge(quote.quoteType),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'LKR ${quote.quotedPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  if (quote.proposedStartAt != null) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.event_available_rounded,
                              size: 10, color: AppColors.primary),
                          const SizedBox(width: 3),
                          Text(
                            ScheduleHelpers.formatDate(quote.proposedStartAt!) +
                                (quote.proposedSlot != null
                                    ? ' (${ScheduleHelpers.slotLabel(quote.proposedSlot!, context)})'
                                    : ''),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Text(
                    '${context.l10n.etaLabel}: ${context.l10n.durationMins(quote.etaMinutes)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.themeTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Price Breakdown Card
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.themeSurfaceLow,
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: context.themeBorder.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                if (quote.quoteType == 'inspect') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(context.l10n.visitInspectionFee,
                          style: TextStyle(
                              fontSize: 11.5,
                              color: context.themeTextSecondary)),
                      Text('${'LKR'} ${quote.visitFeeLkr}',
                          style: const TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ] else ...[
                  if (quote.unitRateLkr != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${'Base'} (${quote.quantity?.toStringAsFixed(quote.quantity! % 1 == 0 ? 0 : 1) ?? 1} ${quote.priceUnit ?? 'job'} @ ${'LKR'} ${quote.unitRateLkr}):',
                          style: TextStyle(
                              fontSize: 11.5,
                              color: context.themeTextSecondary),
                        ),
                        Text(
                          '${'LKR'} ${((quote.quantity ?? 1.0) * (quote.unitRateLkr ?? 0)).round()}',
                          style: const TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  if (quote.materialsEstimateLkr != null &&
                      quote.materialsEstimateLkr! > 0) ...[
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.l10n.materialsEstimateColon,
                            style: TextStyle(
                                fontSize: 11.5,
                                color: context.themeTextSecondary)),
                        Text('${'LKR'} ${quote.materialsEstimateLkr}',
                            style: const TextStyle(
                                fontSize: 11.5, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ],
                if (quote.travelCostLkr > 0) ...[
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${context.l10n.travelTitle} (${quote.travelKm.toStringAsFixed(1)} km @ LKR ${quote.travelRateLkr}/km):',
                        style: TextStyle(
                            fontSize: 11.5, color: context.themeTextSecondary),
                      ),
                      Text('LKR ${quote.travelCostLkr}',
                          style: const TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${context.l10n.travelTitle}:',
                        style: TextStyle(
                            fontSize: 11.5, color: context.themeTextSecondary),
                      ),
                      Text(
                        context.l10n.travelIncluded,
                        style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (quote.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: context.themeSurfaceLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: context.themeBorder.withValues(alpha: 0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.format_quote,
                      size: 14, color: context.themeTextSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      quote.notes,
                      style: TextStyle(
                          fontSize: 12, color: context.themeTextSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (request.status == 'open') ...[
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final callBtn = OutlinedButton.icon(
                  onPressed: _callProvider,
                  icon: const Icon(Icons.call_rounded, size: 16),
                  label: Text(context.l10n.callTech),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );

                final chatBtn = OutlinedButton.icon(
                  onPressed: _chatProvider,
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: Text(context.l10n.chat),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                );

                final actionBtn = quote.isExpired
                    ? OutlinedButton(
                        onPressed: null,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          context.l10n.expiredPill,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      )
                    : PrimaryButton(
                        label: context.l10n.acceptHire,
                        leadingIcon: Icons.handshake_outlined,
                        onPressed: widget.onAccept,
                      );

                // stack buttons when narrow
                if (constraints.maxWidth < 420) {
                  return Column(
                    children: [
                      SizedBox(width: double.infinity, child: actionBtn),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: callBtn),
                          const SizedBox(width: 8),
                          Expanded(child: chatBtn),
                        ],
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    callBtn,
                    const SizedBox(width: 8),
                    chatBtn,
                    const SizedBox(width: 8),
                    Expanded(child: actionBtn),
                  ],
                );
              },
            ),
          ] else if (isAccepted) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _callProvider,
                    icon: const Icon(Icons.call_rounded, size: 16),
                    label: Text(context.l10n.callTech),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _chatProvider,
                    icon:
                        const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                    label: Text(context.l10n.chat),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
}
