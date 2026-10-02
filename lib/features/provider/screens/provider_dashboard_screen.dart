import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart' as pv;
import '../../../services/review_service.dart';
import '../../../theme/app_theme.dart';
import '../../../models/booking.dart';
import '../../../models/job_request.dart';
import '../../../models/quote.dart';
import '../../../repositories/booking_repository.dart';
import '../../../repositories/job_request_repository.dart';
import '../../../repositories/technician_repository.dart';
import '../../../state/role_provider.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/photo_placeholder.dart';
import '../../../shared/widgets/role_switch_sheet.dart';
import '../../../utils/location_utils.dart';
import '../../../utils/map_launcher.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/app_localizations_helpers.dart';
import '../../../shared/screens/conversations_inbox_screen.dart';
import '../../customer/screens/direct_chat_screen.dart';
import '../../../services/chat_service.dart';
import '../../../constants/firestore_paths.dart';
import '../../../shared/widgets/user_avatar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'en_route_navigation_screen.dart';
import 'provider_profile_screen.dart';
import 'submit_quote_sheet.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  bool _online = true;
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final navItems = [
      NavItem(Icons.radar, context.l10n.navJobsRadar),
      NavItem(Icons.assignment, context.l10n.navMyQuotes),
      NavItem(Icons.manage_accounts, context.l10n.navProfile),
    ];

    return PopScope(
      canPop: _navIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _navIndex != 0) {
          setState(() => _navIndex = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _navIndex,
          children: [
            _buildJobsRadarView(context),
            _buildMyQuotesView(context),
            const ProviderProfileScreen(),
          ],
        ),
        bottomNavigationBar: AppBottomNav(
          items: navItems,
          currentIndex: _navIndex,
          onTap: (i) => setState(() => _navIndex = i),
        ),
      ),
    );
  }

  Widget _buildJobsRadarView(BuildContext context) {
    final roleProvider = pv.Provider.of<RoleProvider>(context);
    final user = roleProvider.currentUser;
    final displayName = user?.displayName.isNotEmpty == true
        ? user!.displayName
        : 'Service Provider';
    final tradeLabel = user?.serviceCategory?.isNotEmpty == true
        ? '${LocalizedData.getCategory(context, user!.serviceCategory!)} Specialist'
        : 'Certified Artisan';
    final providerCategory = user?.serviceCategory ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.navJobsRadar),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            tooltip: 'Messages',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ConversationsInboxScreen(),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999)),
                child: Text(
                    _online
                        ? context.l10n.statusOnline
                        : context.l10n.statusOffline,
                    style: TextStyle(
                        color: _online ? AppColors.primary : AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, AppBottomNav.contentBottomPadding),
          children: [
            Row(children: [
              GestureDetector(
                onTap: () => setState(() => _navIndex = 2),
                child: UserAvatar(
                  uid: user?.id,
                  displayName: displayName,
                  photoUrl: user?.photoUrl,
                  radius: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(displayName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified,
                          size: 14, color: AppColors.primary),
                    ]),
                    Row(children: [
                      Icon(Icons.engineering,
                          size: 13, color: context.themeTextSecondary),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(tradeLabel,
                            style: TextStyle(
                                fontSize: 11,
                                color: context.themeTextSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => showRoleSwitchSheet(context),
                icon: const Icon(Icons.sync, size: 14),
                label: Text(context.l10n.switchRole,
                    style: const TextStyle(fontSize: 11)),
              ),
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          _online
                              ? context.l10n.youAreOnline
                              : context.l10n.youAreOffline,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17)),
                      Switch(
                        value: _online,
                        onChanged: (v) async {
                          setState(() => _online = v);
                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          if (uid != null && uid.isNotEmpty) {
                            await TechnicianRepository()
                                .updateOnlineStatus(uid, v);
                          }
                        },
                        activeThumbColor: Colors.white,
                        activeTrackColor: Colors.white38,
                      ),
                    ],
                  ),
                  Text(context.l10n.activeDispatchSub,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.radar, size: 14, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Instant Match active · ${_online ? 'Online & Available' : 'Offline'}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 14),
            StreamBuilder<List<Booking>>(
              stream: BookingRepository().streamBookingsForProvider(
                  FirebaseAuth.instance.currentUser?.uid ?? ''),
              builder: (context, snapshot) {
                final bookings = snapshot.data ?? [];
                final completed =
                    bookings.where((b) => b.status == 'completed').length;
                final delayedBookings = bookings
                    .where((b) => b.delayMinutes != null && b.delayMinutes! > 0)
                    .length;
                final onTimePercent = completed > 0
                    ? '${(((completed - delayedBookings).clamp(0, completed) / completed) * 100).round()}%'
                    : '100%';

                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: ReviewService.instance.streamProviderReviews(
                      FirebaseAuth.instance.currentUser?.uid ?? ''),
                  builder: (context, reviewSnap) {
                    final reviews = reviewSnap.data ?? [];
                    double avgRating = 5.0;
                    if (reviews.isNotEmpty) {
                      final total = reviews.fold<double>(
                        0,
                        (prev, r) =>
                            prev + ((r['rating'] as num?)?.toDouble() ?? 5.0),
                      );
                      avgRating = total / reviews.length;
                    }
                    final ratingStr = reviews.isNotEmpty
                        ? avgRating.toStringAsFixed(1)
                        : (completed > 0 ? '5.0' : 'New');

                    return Row(children: [
                      _StatCard(
                          icon: Icons.task_alt,
                          value: '$completed',
                          sub: context.l10n.completedJobs),
                      const SizedBox(width: 10),
                      _StatCard(
                          icon: Icons.star,
                          value: ratingStr,
                          sub: context.l10n.rating),
                      const SizedBox(width: 10),
                      _StatCard(
                          icon: Icons.schedule,
                          value: onTimePercent,
                          sub: context.l10n.onTimeArrival),
                    ]);
                  },
                );
              },
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.l10n.openJobRequests,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(context.l10n.fromCustomers,
                    style: const TextStyle(
                        color: AppColors.primary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            if (providerCategory.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.themeSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.themeBorder),
                ),
                child: Center(
                  child: Text(context.l10n.customerRequestsAppearHere,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: context.themeTextSecondary, fontSize: 13)),
                ),
              )
            else
              StreamBuilder<List<JobRequest>>(
                stream: JobRequestRepository()
                    .streamOpenRequestsForCategory(providerCategory),
                builder: (context, snapshot) {
                  final requests = snapshot.data ?? [];
                  if (requests.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.themeSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.themeBorder),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined,
                              size: 36, color: context.themeTextSecondary),
                          const SizedBox(height: 8),
                          Text(context.l10n.noOpenRequests,
                              style: TextStyle(
                                  color: context.themeTextSecondary,
                                  fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(context.l10n.customerRequestsAppearHere,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: context.themeTextSecondary,
                                  fontSize: 11)),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: requests
                        .map((req) => _JobRequestCard(
                              request: req,
                              providerLat: user?.latitude,
                              providerLng: user?.longitude,
                              onSendQuote: () => _openSubmitQuoteSheet(req),
                            ))
                        .toList(),
                  );
                },
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.l10n.scheduledBookings,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(context.l10n.viewAll,
                    style: const TextStyle(
                        color: AppColors.primary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<Booking>>(
              stream: BookingRepository().streamBookingsForProvider(
                  FirebaseAuth.instance.currentUser?.uid ?? ''),
              builder: (context, snapshot) {
                final bookings = snapshot.data ?? [];
                if (bookings.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.themeSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.themeBorder),
                    ),
                    child: Center(
                      child: Text(context.l10n.noActiveBookings,
                          style: TextStyle(
                              color: context.themeTextSecondary, fontSize: 13)),
                    ),
                  );
                }
                return Column(
                  children: bookings
                      .map((b) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: InkWell(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        EnRouteNavigationScreen(booking: b)),
                              ),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                    color: context.themeSurface,
                                    borderRadius: BorderRadius.circular(16),
                                    border:
                                        Border.all(color: context.themeBorder),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black.withValues(
                                              alpha:
                                                  context.isDark ? 0.2 : 0.04),
                                          blurRadius: 10)
                                    ]),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                              '${b.time}${b.relativeTime.isNotEmpty ? " (${b.relativeTime})" : ""}',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: context
                                                      .themeTextSecondary)),
                                          Text(b.estRate,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                        ]),
                                    Text(b.title,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                    const SizedBox(height: 6),
                                    Row(children: [
                                      UserAvatar(
                                        uid: b.customerId,
                                        displayName: b.customerName,
                                        radius: 14,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(b.customerName,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            Text(
                                                '${b.location} (${b.distance})',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: context
                                                        .themeTextSecondary)),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                          onPressed: () {
                                            if (b.customerPhone.isNotEmpty) {
                                              MapLauncher.openPhoneCall(
                                                  b.customerPhone);
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Customer phone not available')),
                                              );
                                            }
                                          },
                                          icon: const Icon(Icons.call,
                                              size: 18,
                                              color: AppColors.primary)),
                                      IconButton(
                                          onPressed: () {
                                            if (b.customerLatitude != null &&
                                                b.customerLongitude != null) {
                                              MapLauncher.openDirections(
                                                latitude: b.customerLatitude!,
                                                longitude: b.customerLongitude!,
                                                destinationTitle:
                                                    b.customerName.isNotEmpty
                                                        ? b.customerName
                                                        : 'Customer Location',
                                              );
                                            } else {
                                              final coords = LocationUtils
                                                  .getDistrictCoordinates(
                                                      b.location.isNotEmpty
                                                          ? b.location
                                                          : 'Colombo');
                                              MapLauncher.openDirections(
                                                latitude: coords.lat,
                                                longitude: coords.lng,
                                                destinationTitle:
                                                    b.location.isNotEmpty
                                                        ? b.location
                                                        : 'Customer Location',
                                              );
                                            }
                                          },
                                          icon: const Icon(Icons.directions,
                                              size: 18,
                                              color: AppColors.primary)),
                                    ]),
                                    if (b.providerAcceptedAt == null && b.status == 'pending') ...[
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10)),
                                          ),
                                          icon: const Icon(Icons.check_circle_outline, size: 16),
                                          label: const Text('Accept Direct Booking',
                                              style: TextStyle(
                                                  fontSize: 12, fontWeight: FontWeight.bold)),
                                          onPressed: () async {
                                            await BookingRepository().acceptBookingByProvider(
                                              bookingId: b.id,
                                              jobRequestId: b.jobRequestId,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _openSubmitQuoteSheet(JobRequest request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubmitQuoteSheet(jobRequest: request),
    );
  }

  Widget _buildMyQuotesView(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.navMyQuotes),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            tooltip: 'Messages',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ConversationsInboxScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<Quote>>(
          stream: JobRequestRepository().streamProviderQuotes(uid),
          builder: (context, snapshot) {
            final quotes = snapshot.data ?? [];

            if (quotes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assignment_outlined,
                        size: 48, color: context.themeTextSecondary),
                    const SizedBox(height: 12),
                    Text(context.l10n.noQuotesYet,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(context.l10n.browseRadarDesc,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12, color: context.themeTextSecondary)),
                  ],
                ),
              );
            }

            final pendingQuotes =
                quotes.where((q) => q.status == 'pending').toList();
            final acceptedQuotes =
                quotes.where((q) => q.status == 'accepted').toList();
            final declinedQuotes =
                quotes.where((q) => q.status == 'declined').toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, AppBottomNav.contentBottomPadding),
              children: [
                if (acceptedQuotes.isNotEmpty) ...[
                  _sectionHeader(context, context.l10n.acceptedCaps,
                      AppColors.primary, acceptedQuotes.length),
                  ...acceptedQuotes.map((q) => _QuoteHistoryTile(quote: q)),
                  const SizedBox(height: 16),
                ],
                if (pendingQuotes.isNotEmpty) ...[
                  _sectionHeader(context, context.l10n.pendingResponseCaps,
                      AppColors.secondaryContainer, pendingQuotes.length),
                  ...pendingQuotes.map((q) => _QuoteHistoryTile(quote: q)),
                  const SizedBox(height: 16),
                ],
                if (declinedQuotes.isNotEmpty) ...[
                  _sectionHeader(context, context.l10n.declinedCaps,
                      AppColors.error, declinedQuotes.length),
                  ...declinedQuotes.map((q) => _QuoteHistoryTile(quote: q)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sectionHeader(
      BuildContext context, String label, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$label ($count)',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String sub;
  const _StatCard({required this.icon, required this.value, required this.sub});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: context.themeSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.themeBorder),
            boxShadow: [
              BoxShadow(
                  color: Colors.black
                      .withValues(alpha: context.isDark ? 0.2 : 0.04),
                  blurRadius: 8)
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(sub,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  TextStyle(fontSize: 10, color: context.themeTextSecondary)),
        ]),
      ),
    );
  }
}

class _JobRequestCard extends StatelessWidget {
  final JobRequest request;
  final double? providerLat;
  final double? providerLng;
  final VoidCallback onSendQuote;

  const _JobRequestCard({
    required this.request,
    this.providerLat,
    this.providerLng,
    required this.onSendQuote,
  });

  @override
  Widget build(BuildContext context) {
    String? distanceText;
    if (providerLat != null &&
        providerLng != null &&
        request.latitude != null &&
        request.longitude != null) {
      final km = LocationUtils.calculateDistanceKm(
        providerLat!,
        providerLng!,
        request.latitude!,
        request.longitude!,
      );
      distanceText = LocationUtils.formatDistance(km);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                    LocalizedData.getCategory(context, request.category),
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ),
              const Spacer(),
              if (distanceText != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.near_me,
                          size: 11, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Text(
                        distanceText,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                )
              else if (request.quoteCount > 0)
                Text('${request.quoteCount} ${context.l10n.quotesTitle}',
                    style: TextStyle(
                        fontSize: 10.5, color: context.themeTextSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(request.title,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 4),
          Text(request.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  TextStyle(fontSize: 12, color: context.themeTextSecondary)),
          if (request.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: request.photoUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final url = request.photoUrls[i];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildPhoto(url, 56, 56),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.person_outline,
                  size: 13, color: context.themeTextSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(request.customerName,
                    style: TextStyle(
                        fontSize: 11.5, color: context.themeTextSecondary)),
              ),
              if (request.address.isNotEmpty) ...[
                Icon(Icons.location_on,
                    size: 13, color: context.themeTextSecondary),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(request.address,
                      style: TextStyle(
                          fontSize: 11, color: context.themeTextSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSendQuote,
              icon: const Icon(Icons.send, size: 16),
              label: Text(context.l10n.sendPriceQuote,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
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
        return PhotoPlaceholder(width: width, height: height, iconSize: 16);
      }
    }
    return Image.network(url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            PhotoPlaceholder(width: width, height: height, iconSize: 16));
  }
}

class _QuoteHistoryTile extends StatelessWidget {
  final Quote quote;
  const _QuoteHistoryTile({required this.quote});

  Future<void> _openCustomerChat(BuildContext context) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    try {
      final snap = await FirebaseFirestore.instance
          .collection(FirestorePaths.chatRooms)
          .where('jobRequestId', isEqualTo: quote.requestId)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final room =
            ChatRoomSummary.fromMap(snap.docs.first.id, snap.docs.first.data());
        final otherId = room.getOtherPartyId(currentUid);
        final otherName = room.getOtherPartyName(currentUid);
        final otherPhone = room.getOtherPartyPhone(currentUid);
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DirectChatScreen(
                otherPartyId: otherId,
                otherPartyName: otherName,
                otherPartyRole: 'customer',
                otherPartyPhone: otherPhone,
                jobRequestId: quote.requestId,
              ),
            ),
          );
          return;
        }
      }
    } catch (_) {}

    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const ConversationsInboxScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAccepted = quote.status == 'accepted';
    final statusColor = switch (quote.status) {
      'accepted' => AppColors.primary,
      'declined' => AppColors.error,
      _ => AppColors.secondaryContainer,
    };
    final statusIcon = switch (quote.status) {
      'accepted' => Icons.check_circle,
      'declined' => Icons.cancel,
      _ => Icons.hourglass_top,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAccepted
              ? AppColors.primary.withValues(alpha: 0.5)
              : context.themeBorder,
          width: isAccepted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(statusIcon, color: statusColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LKR ${quote.quotedPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('ETA: ${quote.etaMinutes} min',
                        style: TextStyle(
                            fontSize: 11, color: context.themeTextSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  LocalizedData.getStatus(context, quote.status),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: statusColor),
                ),
              ),
            ],
          ),
          if (isAccepted) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openCustomerChat(context),
                icon: const Icon(Icons.chat_bubble_outline, size: 15),
                label: const Text(
                  'Chat with Customer',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
