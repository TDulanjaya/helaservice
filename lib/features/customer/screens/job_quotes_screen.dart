import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/job_request.dart';
import '../../../models/quote.dart';
import '../../../models/booking.dart';
import '../../../constants/firestore_paths.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../repositories/job_request_repository.dart';
import '../../../repositories/technician_repository.dart';
import '../../../utils/location_utils.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/app_localizations_helpers.dart';
import 'live_tracking_screen.dart';
import 'direct_chat_screen.dart';
import '../../../services/chat_service.dart';
import '../../../shared/widgets/photo_placeholder.dart';
import '../../../shared/widgets/user_avatar.dart';

class JobQuotesScreen extends StatelessWidget {
  final String requestId;
  final String jobTitle;

  const JobQuotesScreen({
    super.key,
    required this.requestId,
    required this.jobTitle,
  });

  @override
  Widget build(BuildContext context) {
    final repo = JobRequestRepository();
    return Scaffold(
      appBar: AppBar(
        title: Text(jobTitle,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: StreamBuilder<JobRequest?>(
          stream: repo.streamJobRequest(requestId),
          builder: (context, requestSnap) {
            final request = requestSnap.data;
            if (request == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              children: [
                _JobSummaryCard(request: request),
                const SizedBox(height: 4),
                Expanded(
                  child: StreamBuilder<List<Quote>>(
                    stream: repo.streamQuotesForRequest(requestId),
                    builder: (context, quotesSnap) {
                      final quotes = quotesSnap.data ?? [];

                      if (request.status == 'assigned') {
                        return _buildAssignedView(context, request, quotes);
                      }

                      if (quotes.isEmpty) {
                        return _buildWaitingView(context);
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: quotes.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
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
                            );
                          }
                          final quote = quotes[index - 1];
                          return _QuoteCard(
                            quote: quote,
                            request: request,
                            onAccept: () => _acceptQuote(context, quote, request),
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

  Widget _buildWaitingView(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_top,
                  color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.waitingForQuotes,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.waitingForQuotesDesc,
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 12.5, color: context.themeTextSecondary),
            ),
            const SizedBox(height: 20),
            const SizedBox(
              width: 24,
              height: 24,
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
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
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.providerHired,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            if (acceptedQuote.isNotEmpty)
              Text(
                '${acceptedQuote.first.providerName} • ${request.agreedPrice != null ? "LKR ${request.agreedPrice!.toStringAsFixed(0)}" : "LKR ${acceptedQuote.first.quotedPrice.toStringAsFixed(0)}"}',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: context.themeTextSecondary),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final providerId = request.selectedProviderId ??
                    (acceptedQuote.isNotEmpty ? acceptedQuote.first.providerId : '');
                final tech = await TechnicianRepository().getById(providerId);

                Booking? booking;
                try {
                  final bSnap = await FirebaseFirestore.instance
                      .collection(FirestorePaths.bookings)
                      .where('jobRequestId', isEqualTo: request.id)
                      .limit(1)
                      .get();
                  if (bSnap.docs.isNotEmpty) {
                    booking = Booking.fromMap(bSnap.docs.first.id, bSnap.docs.first.data());
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
              icon: const Icon(Icons.navigation, size: 16),
              label: const Text('Open Live Tracking'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
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

  Future<void> _acceptQuote(
      BuildContext context, Quote quote, JobRequest request) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.acceptQuoteHire),
        content: Text(
          '${quote.providerName} — LKR ${quote.quotedPrice.toStringAsFixed(0)}\nETA: ${quote.etaMinutes} mins.',
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
            ),
            child: Text(context.l10n.acceptHire),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await JobRequestRepository().acceptQuote(
        requestId: requestId,
        quoteId: quote.id,
        providerId: quote.providerId,
        agreedPrice: quote.quotedPrice,
        request: request,
        quote: quote,
      );

      // Opens chat with the technician.
      try {
        final chatRoomId = await ChatService.instance.getOrCreateChatRoom(
          userId1: request.customerId,
          userId2: quote.providerId,
          user1Name: request.customerName,
          user2Name: quote.providerName,
          user1Role: 'customer',
          user2Role: 'provider',
          user1Phone: request.customerPhone,
          user2Phone: quote.providerPhone,
          jobRequestId: requestId,
        );
        await ChatService.instance.sendMessage(
          chatRoomId: chatRoomId,
          senderId: request.customerId,
          senderName: request.customerName,
          text: 'Hello ${quote.providerName}, I have accepted your quote (LKR ${quote.quotedPrice.toStringAsFixed(0)}). Let\'s coordinate the job details!',
        );
      } catch (chatError) {
        debugPrint('Non-fatal chat room pre-creation note: $chatError');
      }

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${quote.providerName} Hired!',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
            ],
          ),
          content: Text(
            'Your service booking is confirmed. A direct conversation has been started with ${quote.providerName} to coordinate timing and location.',
            style: const TextStyle(fontSize: 13.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Later'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogCtx);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DirectChatScreen(
                      otherPartyId: quote.providerId,
                      otherPartyName: quote.providerName,
                      otherPartyRole: 'provider',
                      otherPartyPhone: quote.providerPhone,
                      jobRequestId: requestId,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 16),
              label: const Text('Open Chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept quote: $e'),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.18 : 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(LocalizedData.getCategory(context, request.category),
                        style: TextStyle(
                            fontSize: 11.5,
                            color: context.themeTextSecondary)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: request.status == 'open'
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.secondaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  request.status == 'open'
                      ? '${request.quoteCount} ${context.l10n.quotesTitle}'
                      : LocalizedData.getStatus(context, 'assigned'),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: request.status == 'open'
                        ? AppColors.primary
                        : AppColors.secondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          if (request.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: request.photoUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final url = request.photoUrls[i];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildPhoto(url, 60, 60),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhoto(String url, double width, double height) {
    if (url.startsWith('data:image')) {
      try {
        final base64Str = url.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(Uint8List.fromList(bytes),
            width: width, height: height, fit: BoxFit.cover);
      } catch (_) {
        return PhotoPlaceholder(width: width, height: height);
      }
    }
    return Image.network(url,
        width: width, height: height, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            PhotoPlaceholder(width: width, height: height));
  }
}

class _QuoteCard extends StatelessWidget {
  final Quote quote;
  final JobRequest request;
  final VoidCallback onAccept;

  const _QuoteCard({
    required this.quote,
    required this.request,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    String? distanceLabel;
    if (request.latitude != null &&
        request.longitude != null &&
        quote.providerLatitude != null &&
        quote.providerLongitude != null) {
      final km = LocationUtils.calculateDistanceKm(
        request.latitude!,
        request.longitude!,
        quote.providerLatitude!,
        quote.providerLongitude!,
      );
      distanceLabel = LocationUtils.formatDistance(km);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.18 : 0.04),
            blurRadius: 10,
          ),
        ],
      ),
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
                          child: Text(quote.providerName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (quote.providerNicVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified,
                              size: 14, color: AppColors.primary),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            size: 12, color: AppColors.secondaryContainer),
                        const SizedBox(width: 2),
                        Text(
                          '${quote.providerRating.toStringAsFixed(1)} (${quote.providerReviewCount})',
                          style: TextStyle(
                               fontSize: 11,
                              color: context.themeTextSecondary),
                        ),
                        if (distanceLabel != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.near_me,
                              size: 11, color: context.themeTextSecondary),
                          const SizedBox(width: 2),
                          Text(distanceLabel,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: context.themeTextSecondary)),
                        ],
                      ],
                    ),
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
                  Text(
                    'ETA: ${quote.etaMinutes} min',
                    style: TextStyle(
                        fontSize: 10.5, color: context.themeTextSecondary),
                  ),
                ],
              ),
            ],
          ),

          if (quote.notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.themeSurfaceLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.format_quote,
                      size: 14, color: context.themeTextSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(quote.notes,
                        style: TextStyle(
                            fontSize: 12,
                            color: context.themeTextSecondary)),
                  ),
                ],
              ),
            ),
          ],

          if (request.status == 'open') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAccept,
                icon: const Icon(Icons.handshake_outlined, size: 16),
                label: Text(context.l10n.acceptHire,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
