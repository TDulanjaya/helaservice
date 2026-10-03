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
import '../../../shared/widgets/primary_button.dart';
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
        : context.l10n.roleProvider;
    final tradeLabel = user?.serviceCategory?.isNotEmpty == true
        ? context.l10n.categorySpecialist(user!.serviceCategory!)
        : context.l10n.certifiedArtisan;
    final providerCategory = user?.serviceCategory ?? '';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              16, 16, 16, AppBottomNav.contentBottomPadding),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _navIndex = 2),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: UserAvatar(
                      uid: user?.id,
                      displayName: displayName,
                      photoUrl: user?.photoUrl,
                      radius: 20,
                    ),
                  ),
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
                              displayName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded,
                              size: 15, color: AppColors.primary),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tradeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.themeTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ConversationsInboxScreen(),
                      ),
                    );
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: context.themeSurfaceLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: context.themeBorder),
                    ),
                  ),
                  icon: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: context.themeTextPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => showRoleSwitchSheet(context),
                  style: IconButton.styleFrom(
                    backgroundColor: context.themeSurfaceLow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: context.themeBorder),
                    ),
                  ),
                  icon: Icon(
                    Icons.swap_horiz_rounded,
                    size: 18,
                    color: context.themeTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_online)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: context.isDark
                        ? [const Color(0xFF0D2818), const Color(0xFF133F26)]
                        : [const Color(0xFFE8F5E9), const Color(0xFFD4EDDA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: context.isDark
                        ? const Color(0xFF1E5E3A)
                        : const Color(0xFFA3D9B5),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.statusOnline.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: context.isDark
                                    ? const Color(0xFF81C784)
                                    : const Color(0xFF2E7D32),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.l10n.youAreOnline,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: context.isDark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                        Transform.scale(
                          scale: 0.9,
                          child: Switch(
                            value: _online,
                            activeThumbColor: Colors.white,
                            activeTrackColor: const Color(0xFF22C55E),
                            onChanged: (v) async {
                              setState(() => _online = v);
                              final uid =
                                  FirebaseAuth.instance.currentUser?.uid;
                              if (uid != null && uid.isNotEmpty) {
                                await TechnicianRepository()
                                    .updateOnlineStatus(uid, v);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.activeDispatchSub,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.isDark
                            ? Colors.white70
                            : const Color(0xFF2D5A3F),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: context.isDark
                            ? Colors.black.withValues(alpha: 0.25)
                            : Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4ADE80),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.l10n.instantMatchActive,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: context.isDark
                                  ? Colors.white
                                  : const Color(0xFF1B5E20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: context.themeSurfaceLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.themeBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.statusOffline.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: context.themeTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.l10n.youAreOffline,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: context.themeTextPrimary,
                              ),
                            ),
                          ],
                        ),
                        Transform.scale(
                          scale: 0.9,
                          child: Switch(
                            value: _online,
                            onChanged: (v) async {
                              setState(() => _online = v);
                              final uid =
                                  FirebaseAuth.instance.currentUser?.uid;
                              if (uid != null && uid.isNotEmpty) {
                                await TechnicianRepository()
                                    .updateOnlineStatus(uid, v);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.activeDispatchSub,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.themeTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: context.themeSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.themeBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: context.themeTextSecondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.l10n.offlineSwitchOnDesc,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: context.themeTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                        : (completed > 0 ? '5.0' : context.l10n.newLabel);

                    return Row(
                      children: [
                        _StatCard(
                          icon: Icons.check_circle_outline_rounded,
                          value: '$completed',
                          sub: context.l10n.completedJobs,
                        ),
                        const SizedBox(width: 8),
                        _StatCard(
                          icon: Icons.star_rounded,
                          value: (reviews.isNotEmpty || completed > 0)
                              ? '$ratingStr ★'
                              : context.l10n.newLabel,
                          sub: context.l10n.rating,
                        ),
                        const SizedBox(width: 8),
                        _StatCard(
                          icon: Icons.timer_outlined,
                          value: onTimePercent,
                          sub: context.l10n.onTimeArrival,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            if (providerCategory.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.themeSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.themeBorder),
                ),
                child: Center(
                  child: Text(
                    context.l10n.customerRequestsAppearHere,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.themeTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              )
            else
              StreamBuilder<List<JobRequest>>(
                stream: JobRequestRepository()
                    .streamOpenRequestsForCategory(providerCategory),
                builder: (context, snapshot) {
                  final requests = snapshot.data ?? [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.l10n.openJobRequests,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          if (requests.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                context.l10n.nNew(requests.length),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (requests.isEmpty)
                        Container(
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
                              Text(
                                context.l10n.noOpenRequests,
                                style: TextStyle(
                                  color: context.themeTextSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.l10n.customerRequestsAppearHere,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: context.themeTextSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: requests
                              .map((req) => _JobRequestCard(
                                    request: req,
                                    providerLat: user?.latitude,
                                    providerLng: user?.longitude,
                                    onSendQuote: () =>
                                        _openSubmitQuoteSheet(req),
                                  ))
                              .toList(),
                        ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.scheduledBookings,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  context.l10n.viewAll,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
                                  border: Border.all(color: context.themeBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.14),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            b.time,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                b.location.isNotEmpty
                                                    ? b.location
                                                    : b.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 14.5,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${b.distance}${b.relativeTime.isNotEmpty ? " · ${b.relativeTime}" : ""}',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color: context
                                                      .themeTextSecondary,
                                                ),
                                              ),
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
                                                SnackBar(
                                                  content: Text(
                                                      context.l10n.customerPhoneNotAvailable),
                                                ),
                                              );
                                            }
                                          },
                                          style: IconButton.styleFrom(
                                            backgroundColor:
                                                context.themeSurfaceLow,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              side: BorderSide(
                                                  color: context.themeBorder),
                                            ),
                                            padding: const EdgeInsets.all(8),
                                          ),
                                          icon: const Icon(Icons.call_rounded,
                                              size: 16,
                                              color: AppColors.primary),
                                        ),
                                        const SizedBox(width: 6),
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
                                                        : context.l10n.customerLocation,
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
                                                        : context.l10n.customerLocation,
                                              );
                                            }
                                          },
                                          style: IconButton.styleFrom(
                                            backgroundColor:
                                                context.themeSurfaceLow,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              side: BorderSide(
                                                  color: context.themeBorder),
                                            ),
                                            padding: const EdgeInsets.all(8),
                                          ),
                                          icon: const Icon(
                                              Icons.near_me_rounded,
                                              size: 16,
                                              color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                    if (b.providerAcceptedAt == null &&
                                        b.status == 'pending') ...[
                                      const SizedBox(height: 12),
                                      PrimaryButton(
                                        label: context.l10n.acceptDirectBooking,
                                        leadingIcon:
                                            Icons.check_circle_outline_rounded,
                                        onPressed: () async {
                                          await BookingRepository()
                                              .acceptBookingByProvider(
                                            bookingId: b.id,
                                            jobRequestId: b.jobRequestId,
                                          );
                                        },
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
      body: SafeArea(
        child: StreamBuilder<List<Quote>>(
          stream: JobRequestRepository().streamProviderQuotes(uid),
          builder: (context, snapshot) {
            final quotes = snapshot.data ?? [];

            final pendingQuotes =
                quotes.where((q) => q.status == 'pending').toList();
            final acceptedQuotes =
                quotes.where((q) => q.status == 'accepted').toList();
            final declinedQuotes =
                quotes.where((q) => q.status == 'declined').toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                  16, 16, 16, AppBottomNav.contentBottomPadding),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.l10n.navMyQuotes,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ConversationsInboxScreen(),
                          ),
                        );
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: context.themeSurfaceLow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: context.themeBorder),
                        ),
                      ),
                      icon: Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                        color: context.themeTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (quotes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Center(
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
                                  fontSize: 12,
                                  color: context.themeTextSecondary)),
                        ],
                      ),
                    ),
                  )
                else ...[
                  if (acceptedQuotes.isNotEmpty) ...[
                    _sectionHeader(context, context.l10n.acceptedCaps,
                        const Color(0xFF22C55E), acceptedQuotes.length),
                    ...acceptedQuotes.map((q) => _QuoteHistoryTile(quote: q)),
                    const SizedBox(height: 16),
                  ],
                  if (pendingQuotes.isNotEmpty) ...[
                    _sectionHeader(context, context.l10n.pendingResponseCaps,
                        AppColors.primary, pendingQuotes.length),
                    ...pendingQuotes.map((q) => _QuoteHistoryTile(quote: q)),
                    const SizedBox(height: 16),
                  ],
                  if (declinedQuotes.isNotEmpty) ...[
                    _sectionHeader(context, context.l10n.declinedCaps,
                        context.themeTextSecondary, declinedQuotes.length),
                    ...declinedQuotes.map((q) => _QuoteHistoryTile(quote: q)),
                  ],
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
      distanceText = LocationUtils.formatDistanceL10n(context, km);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.themeBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.22 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      LocalizedData.getCategory(context, request.category).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (distanceText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.near_me_rounded,
                        size: 11,
                        color: Color(0xFF22C55E),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        distanceText,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF22C55E),
                        ),
                      ),
                    ],
                  ),
                )
              else if (request.quoteCount > 0)
                Text(
                  '${request.quoteCount} ${context.l10n.quotesTitle}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.themeTextSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            request.title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15.5,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            request.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: context.themeTextSecondary,
            ),
          ),
          if (request.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: request.photoUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final url = request.photoUrls[i];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: context.themeBorder),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _buildPhoto(url, 60, 60),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 14,
                color: context.themeTextSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  request.customerName,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: context.themeTextSecondary,
                  ),
                ),
              ),
              if (request.address.isNotEmpty) ...[
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: context.themeTextSecondary,
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    request.address,
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
          const SizedBox(height: 14),
          PrimaryButton(
            label: context.l10n.sendPriceQuote,
            leadingIcon: Icons.send_rounded,
            onPressed: onSendQuote,
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
        return Image.memory(
          Uint8List.fromList(bytes),
          width: width,
          height: height,
          fit: BoxFit.cover,
        );
      } catch (_) {
        return PhotoPlaceholder(width: width, height: height, iconSize: 16);
      }
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          PhotoPlaceholder(width: width, height: height, iconSize: 16),
    );
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
      'accepted' => const Color(0xFF22C55E),
      'declined' => AppColors.error,
      _ => AppColors.primary,
    };
    final statusIcon = switch (quote.status) {
      'accepted' => Icons.check_circle_rounded,
      'declined' => Icons.cancel_rounded,
      _ => Icons.hourglass_top_rounded,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAccepted
              ? const Color(0xFF22C55E).withValues(alpha: 0.4)
              : context.themeBorder,
          width: isAccepted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.18 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LKR ${quote.quotedPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${context.l10n.etaLabel}: ${quote.etaMinutes} ${context.l10n.minsUnit}${quote.notes.isNotEmpty ? " · ${quote.notes}" : ""}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: context.themeTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  LocalizedData.getStatus(context, quote.status).toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (isAccepted) ...[
            const SizedBox(height: 12),
            PrimaryButton(
              label: context.l10n.chatWithCustomer,
              leadingIcon: Icons.chat_bubble_outline_rounded,
              onPressed: () => _openCustomerChat(context),
            ),
          ],
        ],
      ),
    );
  }
}

