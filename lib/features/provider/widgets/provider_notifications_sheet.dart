import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart' as pv;

import '../../../constants/firestore_paths.dart';
import '../../../models/job_request.dart';
import '../../../models/quote.dart';
import '../../../repositories/job_request_repository.dart';
import '../../../services/category_service.dart';
import '../../../state/role_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/l10n_extension.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/screens/conversations_inbox_screen.dart';

class ProviderNotificationsSheet extends StatefulWidget {
  const ProviderNotificationsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProviderNotificationsSheet(),
    );
  }

  @override
  State<ProviderNotificationsSheet> createState() =>
      _ProviderNotificationsSheetState();
}

class _ProviderNotificationsSheetState
    extends State<ProviderNotificationsSheet> {
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _techStream;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _queueStream;
  Stream<List<Quote>>? _quotesStream;
  Stream<List<JobRequest>>? _jobsStream;
  String? _currentCategory;
  List<JobRequest> _lastJobs = const [];
  List<Quote> _lastQuotes = const [];
  String? _initializedUid;

  // setup notification streams for technician
  void _initStreams(String uid) {
    if (uid.isEmpty) {
      _techStream = null;
      _queueStream = null;
      _quotesStream = null;
      _jobsStream = null;
      _currentCategory = null;
      _initializedUid = null;
      return;
    }
    _initializedUid = uid;
    _techStream = FirebaseFirestore.instance
        .collection(FirestorePaths.technicians)
        .doc(uid)
        .snapshots()
        .distinct((prev, next) {
      final dPrev = prev.data();
      final dNext = next.data();
      if (dPrev == null && dNext == null) return true;
      if (dPrev == null || dNext == null) return false;
      return dPrev['nicVerified'] == dNext['nicVerified'] &&
          dPrev['isVerified'] == dNext['isVerified'] &&
          (dPrev['category'] as String?)?.trim() ==
              (dNext['category'] as String?)?.trim();
    }).asBroadcastStream();

    _queueStream = FirebaseFirestore.instance
        .collection(FirestorePaths.verificationQueue)
        .doc(uid)
        .snapshots()
        .distinct((prev, next) {
      return prev.data()?['status'] == next.data()?['status'];
    }).asBroadcastStream();

    _quotesStream = JobRequestRepository()
        .streamProviderQuotes(uid)
        .asBroadcastStream();
  }

  // update jobs stream when category changes
  void _updateJobsStream(String category) {
    final cat = category.trim();
    if (cat.isEmpty) {
      if (_currentCategory != null || _jobsStream != null) {
        _currentCategory = null;
        _jobsStream = null;
        _lastJobs = const [];
      }
      return;
    }
    if (_jobsStream == null || _currentCategory != cat) {
      _currentCategory = cat;
      _lastJobs = const [];
      _jobsStream = JobRequestRepository()
          .streamOpenRequestsForCategory(cat)
          .asBroadcastStream();
    }
  }

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isNotEmpty) {
      _initStreams(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = pv.Provider.of<RoleProvider>(context);
    final user = roleProvider.currentUser;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? (user?.id ?? '');
    if (_techStream == null || _initializedUid != uid) {
      _initStreams(uid);
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // drag handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.themeBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),

            // header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.notifications_active_outlined,
                            size: 20, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        context.l10n.proNotificationsTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.l10n.proMarkAllRead),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Text(
                      context.l10n.proMarkAllRead,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 16),

            // notification list
            Expanded(
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _techStream,
                builder: (context, techSnap) {
                  if (techSnap.connectionState == ConnectionState.waiting &&
                      !techSnap.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }
                  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: _queueStream,
                    builder: (context, queueSnap) {
                      final techData = techSnap.data?.data();
                      final queueData = queueSnap.data?.data();
                      final queueStatus = queueData?['status'] as String?;
                      final bool isRejected = queueStatus == 'rejected';
                      final bool isApproved =
                          techData?['nicVerified'] == true ||
                              techData?['isVerified'] == true ||
                              queueStatus == 'approved';

                      return StreamBuilder<List<Quote>>(
                        stream: _quotesStream,
                        initialData:
                            _lastQuotes.isNotEmpty ? _lastQuotes : null,
                        builder: (context, quotesSnap) {
                          if (quotesSnap.hasData && quotesSnap.data != null) {
                            _lastQuotes = quotesSnap.data!;
                          }
                          final quotes = quotesSnap.data ?? _lastQuotes;
                          final acceptedQuotes = quotes
                              .where((q) => q.status == 'accepted')
                              .toList();

                          final techCategory =
                              (techData?['category'] as String?)?.trim() ?? '';
                          _updateJobsStream(techCategory);

                          return StreamBuilder<List<JobRequest>>(
                            stream: _jobsStream,
                            initialData:
                                _lastJobs.isNotEmpty ? _lastJobs : null,
                            builder: (context, jobsSnap) {
                              if (jobsSnap.hasData && jobsSnap.data != null) {
                                _lastJobs = jobsSnap.data!;
                              }
                              final openJobs = jobsSnap.data ?? _lastJobs;

                              final items = <Widget>[];

                              // verification alert
                              if (isRejected) {
                                items.add(
                                  AppCard(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(14),
                                    borderColor:
                                        AppColors.error.withValues(alpha: 0.4),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.cancel_outlined,
                                          color: AppColors.error,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                context.l10n
                                                    .verificationNotApprovedTitle,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                  color: AppColors.error,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                context.l10n
                                                    .verificationNotApprovedBody,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: context
                                                      .themeTextSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              } else {
                                items.add(
                                  AppCard(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(14),
                                    borderColor: isApproved
                                        ? const Color(0xFF22C55E)
                                            .withValues(alpha: 0.4)
                                        : AppColors.primary
                                            .withValues(alpha: 0.4),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          isApproved
                                              ? Icons.verified_rounded
                                              : Icons.hourglass_top_rounded,
                                          color: isApproved
                                              ? const Color(0xFF22C55E)
                                              : AppColors.primary,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                isApproved
                                                    ? context
                                                        .l10n.accountVerified
                                                    : context.l10n
                                                        .verificationUnderReview,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                isApproved
                                                    ? context
                                                        .l10n.nicApprovedMessage
                                                    : context.l10n
                                                        .nicUnderReviewMessage,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: context
                                                      .themeTextSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              // accepted quotes
                              for (final q in acceptedQuotes.take(3)) {
                                items.add(
                                  AppCard(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(14),
                                    borderColor: const Color(0xFF22C55E)
                                        .withValues(alpha: 0.4),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF22C55E)
                                                .withValues(alpha: 0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                              Icons.check_circle_outline,
                                              color: Color(0xFF22C55E),
                                              size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                context.l10n.quoteAcceptedTitle,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13.5,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'LKR ${q.quotedPrice.toStringAsFixed(0)} • ${context.l10n.customerConfirmedBooking}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: context
                                                      .themeTextSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.chat_bubble_outline,
                                              size: 18),
                                          onPressed: () {
                                            Navigator.pop(context);
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const ConversationsInboxScreen(),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              // open job alerts
                              for (final job in openJobs.take(5)) {
                                items.add(
                                  AppCard(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.radar_rounded,
                                              color: AppColors.primary,
                                              size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                job.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13.5,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${CategoryService.instance.nameOf(job.category, context: context)} • ${job.address}',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: context
                                                      .themeTextSecondary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              if (items.isEmpty) {
                                return Center(
                                  child: Text(
                                    context.l10n.proNoNotifications,
                                    style: TextStyle(
                                      color: context.themeTextSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              }

                              return ListView(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 8, 20, 24),
                                children: items,
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
