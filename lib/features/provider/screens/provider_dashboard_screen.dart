import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart' as pv;
import '../../../services/review_service.dart';
import '../../../theme/app_theme.dart';
import '../../../constants/job_status.dart';
import '../../../models/booking.dart';
import '../../../models/job_request.dart';
import '../../../models/quote.dart';
import '../../../repositories/booking_repository.dart';
import '../../../services/category_service.dart';
import '../../../repositories/job_request_repository.dart';
import '../../../repositories/technician_repository.dart';
import '../../../state/role_provider.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/role_switch_sheet.dart';
import '../../../utils/location_utils.dart';
import '../../../utils/map_launcher.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/app_localizations_helpers.dart';
import '../../../utils/permission_utils.dart';
import '../../../services/call_service.dart';
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
import '../widgets/provider_approval_gate.dart';
import '../../../shared/widgets/notification_bell_icon.dart';
import '../../../shared/widgets/reschedule_sheet.dart';
import '../../shared/widgets/job_media_gallery.dart';
import '../../support/widgets/report_problem_dialog.dart';
import '../../../models/technician.dart';
import '../../../services/provider_tracking_service.dart';
import '../../../services/live_location_service.dart';
import '../../../utils/provider_location_helper.dart';
import '../../../utils/schedule_helpers.dart';

class ProviderDashboardScreen extends StatefulWidget {
  final int initialNavIndex;
  final String? openJobRequestId;

  const ProviderDashboardScreen({
    super.key,
    this.initialNavIndex = 0,
    this.openJobRequestId,
  });

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  static bool _hasCheckedEnRouteResume = false;
  bool _online = true;
  late int _navIndex;
  bool _sortByClosest = true;
  double? _selectedRadiusKm;

  @override
  void initState() {
    super.initState();
    _navIndex = widget.initialNavIndex;
    _initProviderTracking();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        PermissionUtils.checkAndPromptInitialPermissions(context);
        if (widget.openJobRequestId != null &&
            widget.openJobRequestId!.isNotEmpty) {
          _handleInitialJobRequest(widget.openJobRequestId!);
        }
      }
    });
  }

  Future<void> _handleInitialJobRequest(String jobId) async {
    try {
      final job = await JobRequestRepository().getById(jobId);
      if (!mounted) return;
      if (job != null && job.status == 'open' && !job.isExpired) {
        _openSubmitQuoteSheet(job);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.bidStatusJobClosed),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProviderDashboard] _handleInitialJobRequest error: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.bidStatusJobClosed),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _initProviderTracking() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      final tech = await TechnicianRepository().getById(uid);
      if (mounted && tech != null) {
        setState(() {
          _online = tech.online;
          if (_selectedRadiusKm == null && tech.serviceRadiusKm > 0) {
            _selectedRadiusKm = tech.serviceRadiusKm;
          }
        });
        if (tech.online) {
          ProviderTrackingService.instance.startOnlineTracking(uid);
        }

        // resume live tracking for active en-route booking (once per app start, approved providers only)
        if (!_hasCheckedEnRouteResume && tech.isApproved) {
          _hasCheckedEnRouteResume = true;
          _checkAndResumeEnRouteBooking(uid);
        }
      }
    }
  }

  Future<void> _checkAndResumeEnRouteBooking(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection(FirestorePaths.bookings)
          .where('providerId', isEqualTo: uid)
          .where('status', isEqualTo: JobStatus.enRoute)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;
        final booking = Booking.fromMap(doc.id, doc.data());
        final customerId = booking.customerId;
        await LiveLocationService.instance.startTrackingForBooking(
          userId: uid,
          bookingId: booking.id,
          allowedViewers: customerId.isNotEmpty ? [customerId] : null,
        );
      }
    } catch (e) {
      debugPrint('[ProviderDashboard] Error resuming en-route tracking: $e');
    }
  }

  @override
  void dispose() {
    ProviderTrackingService.instance.stopOnlineTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navItems = [
      NavItem(Icons.radar, context.l10n.navJobsRadar),
      NavItem(Icons.assignment, context.l10n.navMyQuotes),
      NavItem(Icons.chat_bubble_outline_rounded, context.l10n.navMessages),
      NavItem(Icons.manage_accounts, context.l10n.navProfile),
    ];

    return ProviderApprovalGate(
      child: PopScope(
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
              const ConversationsInboxScreen(),
              const ProviderProfileScreen(),
            ],
          ),
          bottomNavigationBar: AppBottomNav(
            items: navItems,
            currentIndex: _navIndex,
            onTap: (i) => setState(() => _navIndex = i),
          ),
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
        ? context.l10n.categorySpecialist(CategoryService.instance
            .nameOf(user!.serviceCategory!, context: context))
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
                  onTap: () => setState(() => _navIndex = 3),
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
                const NotificationBellIcon(size: 40),
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
            if (roleProvider.isAuthorizedAdmin) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: context.themeAmberTint,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.adminInspectionMode,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: context.themeInk,
                            ),
                          ),
                          Text(
                            context.l10n.adminInspectionModeDesc,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.themeTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
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
                                if (!v) {
                                  await LiveLocationService.instance
                                      .stopTracking();
                                  ProviderTrackingService.instance
                                      .stopOnlineTracking();
                                }
                                await TechnicianRepository()
                                    .updateOnlineStatus(uid, v);
                                if (v) {
                                  ProviderTrackingService.instance
                                      .startOnlineTracking(uid);
                                }
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
                                if (!v) {
                                  await LiveLocationService.instance
                                      .stopTracking();
                                  ProviderTrackingService.instance
                                      .stopOnlineTracking();
                                }
                                await TechnicianRepository()
                                    .updateOnlineStatus(uid, v);
                                if (v) {
                                  ProviderTrackingService.instance
                                      .startOnlineTracking(uid);
                                }
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
                              ? ratingStr
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
              StreamBuilder<Technician?>(
                stream: TechnicianRepository().streamById(user?.id ?? ''),
                builder: (context, techSnap) {
                  final tech = techSnap.data;
                  final effectiveLoc = tech != null
                      ? getEffectiveProviderLocation(tech)
                      : EffectiveProviderLocation.none;

                  if (effectiveLoc.source == ProviderLocationSource.none) {
                    return _buildNoBaseLocationCard(context);
                  }

                  return StreamBuilder<List<JobRequest>>(
                    stream: JobRequestRepository()
                        .streamOpenRequestsForCategory(providerCategory),
                    builder: (context, snapshot) {
                      final rawRequests = snapshot.data ?? [];
                      var requests = rawRequests.where((req) {
                        if (req.status != JobRequestStatus.open &&
                            req.status != 'pending') {
                          return false;
                        }
                        return !req.isExpired;
                      }).toList();

                      if (_selectedRadiusKm != null) {
                        requests = requests.where((req) {
                          if (req.latitude == null || req.longitude == null) {
                            return false;
                          }
                          final usesBase = ScheduleHelpers.usesBaseLocation(
                            scheduleMode: req.scheduleMode,
                            scheduledDate: req.scheduledDate,
                            scheduledStartAt: req.scheduledStartAt,
                          );
                          final pLat = (usesBase && tech?.baseLat != null)
                              ? tech!.baseLat
                              : effectiveLoc.latitude;
                          final pLng = (usesBase && tech?.baseLng != null)
                              ? tech!.baseLng
                              : effectiveLoc.longitude;
                          if (pLat == null || pLng == null) return false;
                          final km = LocationUtils.calculateDistanceKm(
                            pLat,
                            pLng,
                            req.latitude!,
                            req.longitude!,
                          );
                          return km <= _selectedRadiusKm!;
                        }).toList();
                      }

                      if (_sortByClosest) {
                        requests.sort((a, b) {
                          final hasA =
                              a.latitude != null && a.longitude != null;
                          final hasB =
                              b.latitude != null && b.longitude != null;
                          if (!hasA && !hasB) return 0;
                          if (!hasA) return 1;
                          if (!hasB) return -1;
                          final usesBaseA = ScheduleHelpers.usesBaseLocation(
                            scheduleMode: a.scheduleMode,
                            scheduledDate: a.scheduledDate,
                            scheduledStartAt: a.scheduledStartAt,
                          );
                          final usesBaseB = ScheduleHelpers.usesBaseLocation(
                            scheduleMode: b.scheduleMode,
                            scheduledDate: b.scheduledDate,
                            scheduledStartAt: b.scheduledStartAt,
                          );
                          final pLatA = (usesBaseA && tech?.baseLat != null)
                              ? tech!.baseLat
                              : effectiveLoc.latitude;
                          final pLngA = (usesBaseA && tech?.baseLng != null)
                              ? tech!.baseLng
                              : effectiveLoc.longitude;
                          final pLatB = (usesBaseB && tech?.baseLat != null)
                              ? tech!.baseLat
                              : effectiveLoc.latitude;
                          final pLngB = (usesBaseB && tech?.baseLng != null)
                              ? tech!.baseLng
                              : effectiveLoc.longitude;
                          if (pLatA == null || pLngA == null) return 0;
                          if (pLatB == null || pLngB == null) return 0;
                          final distA = LocationUtils.calculateDistanceKm(
                            pLatA,
                            pLngA,
                            a.latitude!,
                            a.longitude!,
                          );
                          final distB = LocationUtils.calculateDistanceKm(
                            pLatB,
                            pLngB,
                            b.latitude!,
                            b.longitude!,
                          );
                          return distA.compareTo(distB);
                        });
                      } else {
                        requests.sort((a, b) {
                          final isTodayA = ScheduleHelpers.isTodayJob(
                            scheduleMode: a.scheduleMode,
                            scheduledDate: a.scheduledDate,
                            scheduledStartAt: a.scheduledStartAt,
                          );
                          final isTodayB = ScheduleHelpers.isTodayJob(
                            scheduleMode: b.scheduleMode,
                            scheduledDate: b.scheduledDate,
                            scheduledStartAt: b.scheduledStartAt,
                          );
                          if (isTodayA && !isTodayB) return -1;
                          if (!isTodayA && isTodayB) return 1;

                          final dateA = a.scheduledStartAt ??
                              a.scheduledDate ??
                              a.createdAt ??
                              DateTime(2100);
                          final dateB = b.scheduledStartAt ??
                              b.scheduledDate ??
                              b.createdAt ??
                              DateTime(2100);
                          final dateComp = dateA.compareTo(dateB);
                          if (dateComp != 0) return dateComp;

                          final hasA =
                              a.latitude != null && a.longitude != null;
                          final hasB =
                              b.latitude != null && b.longitude != null;
                          if (!hasA || !hasB) return 0;
                          final usesBaseA = ScheduleHelpers.usesBaseLocation(
                            scheduleMode: a.scheduleMode,
                            scheduledDate: a.scheduledDate,
                            scheduledStartAt: a.scheduledStartAt,
                          );
                          final usesBaseB = ScheduleHelpers.usesBaseLocation(
                            scheduleMode: b.scheduleMode,
                            scheduledDate: b.scheduledDate,
                            scheduledStartAt: b.scheduledStartAt,
                          );
                          final pLatA = (usesBaseA && tech?.baseLat != null)
                              ? tech!.baseLat
                              : effectiveLoc.latitude;
                          final pLngA = (usesBaseA && tech?.baseLng != null)
                              ? tech!.baseLng
                              : effectiveLoc.longitude;
                          final pLatB = (usesBaseB && tech?.baseLat != null)
                              ? tech!.baseLat
                              : effectiveLoc.latitude;
                          final pLngB = (usesBaseB && tech?.baseLng != null)
                              ? tech!.baseLng
                              : effectiveLoc.longitude;
                          if (pLatA == null ||
                              pLngA == null ||
                              pLatB == null ||
                              pLngB == null) {
                            return 0;
                          }
                          final distA = LocationUtils.calculateDistanceKm(
                            pLatA,
                            pLngA,
                            a.latitude!,
                            a.longitude!,
                          );
                          final distB = LocationUtils.calculateDistanceKm(
                            pLatB,
                            pLngB,
                            b.latitude!,
                            b.longitude!,
                          );
                          return distA.compareTo(distB);
                        });
                      }

                      final customRadius = tech?.serviceRadiusKm;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLocationBanner(context, tech, effectiveLoc),
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
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                InkWell(
                                  onTap: () => setState(
                                      () => _sortByClosest = !_sortByClosest),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _sortByClosest
                                          ? AppColors.primary
                                              .withValues(alpha: 0.12)
                                          : context.themeSurfaceLow,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _sortByClosest
                                            ? AppColors.primary
                                            : context.themeBorder,
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _sortByClosest
                                              ? Icons.near_me_rounded
                                              : Icons.schedule_rounded,
                                          size: 13,
                                          color: _sortByClosest
                                              ? AppColors.primary
                                              : context.themeTextSecondary,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          _sortByClosest
                                              ? context.l10n.closestFirst
                                              : context.l10n.newestFirst,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: _sortByClosest
                                                ? AppColors.primary
                                                : context.themeTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildRadiusFilterChip(
                                  label: context.l10n.allDistances,
                                  radius: null,
                                ),
                                if (customRadius != null &&
                                    customRadius > 0 &&
                                    customRadius != 5.0 &&
                                    customRadius != 10.0 &&
                                    customRadius != 25.0) ...[
                                  const SizedBox(width: 6),
                                  _buildRadiusFilterChip(
                                    label: '${customRadius.toInt()} km',
                                    radius: customRadius,
                                  ),
                                ],
                                const SizedBox(width: 6),
                                _buildRadiusFilterChip(
                                  label: context.l10n.within5Km,
                                  radius: 5.0,
                                ),
                                const SizedBox(width: 6),
                                _buildRadiusFilterChip(
                                  label: context.l10n.within10Km,
                                  radius: 10.0,
                                ),
                                const SizedBox(width: 6),
                                _buildRadiusFilterChip(
                                  label: context.l10n.within25Km,
                                  radius: 25.0,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
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
                                      size: 36,
                                      color: context.themeTextSecondary),
                                  const SizedBox(height: 8),
                                  Text(
                                    rawRequests.isNotEmpty &&
                                            _selectedRadiusKm != null
                                        ? context.l10n.noJobsInRadius
                                        : context.l10n.noOpenRequests,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: context.themeTextSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
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
                            StreamBuilder<List<Quote>>(
                              stream: JobRequestRepository()
                                  .streamProviderQuotes(user?.id ?? ''),
                              builder: (context, quotesSnap) {
                                final quotes =
                                    quotesSnap.data ?? const <Quote>[];
                                final quotesMap = <String, Quote>{
                                  for (final q in quotes) q.requestId: q,
                                };
                                return Column(
                                  children: requests.map((req) {
                                    final usesBase =
                                        ScheduleHelpers.usesBaseLocation(
                                      scheduleMode: req.scheduleMode,
                                      scheduledDate: req.scheduledDate,
                                      scheduledStartAt: req.scheduledStartAt,
                                    );
                                    final pLat =
                                        (usesBase && tech?.baseLat != null)
                                            ? tech!.baseLat
                                            : effectiveLoc.latitude;
                                    final pLng =
                                        (usesBase && tech?.baseLng != null)
                                            ? tech!.baseLng
                                            : effectiveLoc.longitude;
                                    return _JobRequestCard(
                                      request: req,
                                      providerLat: pLat,
                                      providerLng: pLng,
                                      myQuote: quotesMap[req.id],
                                      onSendQuote: () =>
                                          _openSubmitQuoteSheet(req),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                        ],
                      );
                    },
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
                                  border:
                                      Border.all(color: context.themeBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RescheduleProposalBanner(
                                      booking: b,
                                      currentUid: FirebaseAuth
                                              .instance.currentUser?.uid ??
                                          '',
                                      actorRole: 'provider',
                                    ),
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
                                            b.scheduledDate != null
                                                ? b.formattedScheduledSummary(
                                                    context)
                                                : b.time,
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
                                              CallService.instance.startCall(
                                                context: context,
                                                calleePhone: b.customerPhone,
                                                calleeName: b
                                                        .customerName.isNotEmpty
                                                    ? b.customerName
                                                    : context.l10n.roleCustomer,
                                                bookingId: b.id,
                                                calleeUid: b.customerId,
                                                calleeRole: 'customer',
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(context.l10n
                                                      .customerPhoneNotAvailable),
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
                                                        : context.l10n
                                                            .customerLocation,
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(context.l10n
                                                      .customerLocationNotAvailableCall),
                                                  backgroundColor:
                                                      AppColors.warning,
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
                                          icon: const Icon(
                                              Icons.near_me_rounded,
                                              size: 16,
                                              color: AppColors.primary),
                                        ),
                                        if (b.status == JobStatus.pending ||
                                            b.status ==
                                                JobStatus.confirmed) ...[
                                          const SizedBox(width: 6),
                                          IconButton(
                                            tooltip:
                                                context.l10n.rescheduleBooking,
                                            onPressed: () =>
                                                RescheduleSheet.show(
                                              context: context,
                                              booking: b,
                                              currentUid: FirebaseAuth.instance
                                                      .currentUser?.uid ??
                                                  '',
                                              actorRole: 'provider',
                                            ),
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
                                                Icons.calendar_month_outlined,
                                                size: 16,
                                                color: AppColors.primary),
                                          ),
                                        ],
                                        const SizedBox(width: 6),
                                        IconButton(
                                          tooltip:
                                              context.l10n.reportProblemTitle,
                                          onPressed: () =>
                                              ReportProblemDialog.show(
                                            context,
                                            bookingId: b.id,
                                            otherPartyId: b.customerId,
                                            otherPartyRole: 'customer',
                                            otherPartyName: b.customerName,
                                          ),
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
                                          icon: const Icon(Icons.flag_outlined,
                                              size: 16, color: AppColors.error),
                                        ),
                                      ],
                                    ),
                                    if (b.status == JobStatus.pending) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: PrimaryButton(
                                              label: context
                                                  .l10n.acceptDirectBooking,
                                              leadingIcon: Icons
                                                  .check_circle_outline_rounded,
                                              onPressed: () async {
                                                await BookingRepository()
                                                    .acceptBookingByProvider(
                                                  bookingId: b.id,
                                                  jobRequestId: b.jobRequestId,
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            tooltip: context.l10n.decline,
                                            style: IconButton.styleFrom(
                                              backgroundColor: AppColors.error
                                                  .withValues(alpha: 0.12),
                                              foregroundColor: AppColors.error,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12)),
                                              padding: const EdgeInsets.all(12),
                                            ),
                                            icon: const Icon(
                                                Icons.close_rounded,
                                                size: 20),
                                            onPressed: () async {
                                              await BookingRepository()
                                                  .declineBookingByProvider(
                                                bookingId: b.id,
                                                jobRequestId: b.jobRequestId,
                                              );
                                            },
                                          ),
                                        ],
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
            final pastQuotes = quotes
                .where((q) =>
                    q.status == 'not_selected' ||
                    q.status == 'withdrawn' ||
                    q.status == 'job_closed' ||
                    q.status == 'declined')
                .toList();

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
                if (quotes.isNotEmpty) ...[
                  Builder(
                    builder: (context) {
                      final pendingWithClash = pendingQuotes.where((pq) {
                        final pqStart = pq.proposedStartAt;
                        final pqEnd = pq.proposedEndAt;
                        if (pqStart == null || pqEnd == null) return false;
                        return acceptedQuotes.any((aq) {
                          final aqStart = aq.proposedStartAt;
                          final aqEnd = aq.proposedEndAt;
                          if (aqStart == null || aqEnd == null) return false;
                          return ScheduleHelpers.windowsOverlap(
                            start1: pqStart,
                            end1: pqEnd,
                            start2: aqStart,
                            end2: aqEnd,
                          );
                        });
                      }).toList();
                      if (pendingWithClash.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: AppColors.warning, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'You have ${pendingWithClash.length} other pending bid(s) overlapping an accepted job. Consider reviewing or withdrawing them.',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: context.themeTextPrimary),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
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
                  if (pastQuotes.isNotEmpty) ...[
                    _sectionHeader(
                        context,
                        context.l10n.myBidsPastTab.toUpperCase(),
                        context.themeTextSecondary,
                        pastQuotes.length),
                    ...pastQuotes.map((q) => _QuoteHistoryTile(quote: q)),
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

  Widget _buildRadiusFilterChip({
    required String label,
    required double? radius,
  }) {
    final isSelected = _selectedRadiusKm == radius;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedRadiusKm = radius;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : context.themeSurfaceLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : context.themeBorder,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : context.themeTextSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationBanner(
    BuildContext context,
    Technician? tech,
    EffectiveProviderLocation effectiveLoc,
  ) {
    final isCurrent = effectiveLoc.source == ProviderLocationSource.current;
    final areaName =
        (tech?.baseArea != null && tech!.baseArea!.trim().isNotEmpty)
            ? tech.baseArea!.trim()
            : extractBaseArea(address: tech?.baseAddress);

    final title = isCurrent
        ? context.l10n.showingJobsNearYouNow
        : (areaName != null && areaName.isNotEmpty)
            ? context.l10n.showingJobsNearBase(areaName)
            : context.l10n.showingJobsNearBaseNoArea;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrent
            ? (context.isDark
                ? const Color(0xFF133F26)
                : const Color(0xFFE8F5E9))
            : (context.isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent
              ? (context.isDark
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFA3D9B5))
              : (context.isDark
                  ? const Color(0xFF334155)
                  : const Color(0xFFCBD5E1)),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCurrent ? Icons.my_location_rounded : Icons.home_work_outlined,
            size: 18,
            color: isCurrent
                ? (context.isDark
                    ? const Color(0xFF81C784)
                    : const Color(0xFF2E7D32))
                : context.themeTextPrimary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: context.themeTextPrimary,
              ),
            ),
          ),
          IconButton(
            tooltip: context.l10n.refreshGps,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Icons.refresh_rounded,
              size: 18,
              color: context.themeTextSecondary,
            ),
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null && uid.isNotEmpty) {
                final pos = await LocationUtils.getCurrentPosition();
                if (pos != null) {
                  await TechnicianRepository().updateCurrentLocation(
                    uid,
                    latitude: pos.latitude,
                    longitude: pos.longitude,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoBaseLocationCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.location_off_outlined,
              size: 40, color: context.themeTextSecondary),
          const SizedBox(height: 12),
          Text(
            context.l10n.setBaseLocationPrompt,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.themeTextPrimary,
            ),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: context.l10n.setBaseLocationBtn,
            leadingIcon: Icons.pin_drop_outlined,
            onPressed: () => setState(() => _navIndex = 3),
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
  final Quote? myQuote;
  final VoidCallback onSendQuote;

  const _JobRequestCard({
    required this.request,
    this.providerLat,
    this.providerLng,
    this.myQuote,
    required this.onSendQuote,
  });

  @override
  Widget build(BuildContext context) {
    String? distanceText;
    double? rawKm;
    if (providerLat != null &&
        providerLng != null &&
        request.latitude != null &&
        request.longitude != null) {
      rawKm = LocationUtils.calculateDistanceKm(
        providerLat!,
        providerLng!,
        request.latitude!,
        request.longitude!,
      );
      distanceText = LocationUtils.formatDistanceL10n(context, rawKm);
    }

    final proximityColor = (rawKm == null)
        ? AppColors.primary
        : (rawKm < 5.0)
            ? const Color(0xFF22C55E)
            : (rawKm <= 15.0)
                ? const Color(0xFF3B82F6)
                : const Color(0xFFF59E0B);

    final proximityLabel = (rawKm != null)
        ? LocationUtils.getProximityLabel(context, rawKm)
        : null;

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
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
                      CategoryService.instance
                          .nameOf(request.category, context: context)
                          .toUpperCase(),
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
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
                decoration: BoxDecoration(
                  color: ScheduleHelpers.isTodayJob(
                    scheduleMode: request.scheduleMode,
                    scheduledDate: request.scheduledDate,
                    scheduledStartAt: request.scheduledStartAt,
                  )
                      ? const Color(0xFF22C55E).withValues(alpha: 0.12)
                      : context.themeSurfaceLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ScheduleHelpers.isTodayJob(
                      scheduleMode: request.scheduleMode,
                      scheduledDate: request.scheduledDate,
                      scheduledStartAt: request.scheduledStartAt,
                    )
                        ? const Color(0xFF22C55E).withValues(alpha: 0.3)
                        : context.themeBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      ScheduleHelpers.isTodayJob(
                        scheduleMode: request.scheduleMode,
                        scheduledDate: request.scheduledDate,
                        scheduledStartAt: request.scheduledStartAt,
                      )
                          ? Icons.flash_on_rounded
                          : Icons.calendar_today_rounded,
                      size: 11,
                      color: ScheduleHelpers.isTodayJob(
                        scheduleMode: request.scheduleMode,
                        scheduledDate: request.scheduledDate,
                        scheduledStartAt: request.scheduledStartAt,
                      )
                          ? const Color(0xFF16A34A)
                          : context.themeTextSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      request.scheduleLabel(context),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: ScheduleHelpers.isTodayJob(
                          scheduleMode: request.scheduleMode,
                          scheduledDate: request.scheduledDate,
                          scheduledStartAt: request.scheduledStartAt,
                        )
                            ? const Color(0xFF16A34A)
                            : context.themeTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (distanceText != null && proximityLabel != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: proximityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: proximityColor.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.near_me_rounded,
                        size: 11,
                        color: proximityColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$distanceText • $proximityLabel',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: proximityColor,
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
          const SizedBox(height: 12),
          // customer info and quotes
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 14,
                color: context.themeTextSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                request.customerName,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: context.themeTextSecondary,
                ),
              ),
              if (distanceText != null && request.quoteCount > 0) ...[
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.themeSurfaceLow,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: context.themeBorder),
                  ),
                  child: Text(
                    '${request.quoteCount} ${context.l10n.quotesTitle}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: context.themeTextSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          // location and route details
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.themeSurfaceLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.themeBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.address.isNotEmpty
                            ? request.address
                            : (LocationUtils.resolveDistrict(
                                    latitude: request.latitude,
                                    longitude: request.longitude) ??
                                context.l10n.locationNotSpecified),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (rawKm != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.directions_car_rounded,
                              size: 13,
                              color: context.themeTextSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              LocationUtils.formatEstimatedDriveTime(
                                  context, rawKm),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: context.themeTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (request.latitude != null && request.longitude != null) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      MapLauncher.openDirections(
                        latitude: request.latitude!,
                        longitude: request.longitude!,
                        destinationTitle: request.title.isNotEmpty
                            ? request.title
                            : request.address,
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.map_outlined,
                            size: 12,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.l10n.viewOnMap,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (myQuote != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    _quoteStatusColor(myQuote!.status).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _quoteStatusColor(myQuote!.status)
                      .withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.gavel_rounded,
                    size: 14,
                    color: _quoteStatusColor(myQuote!.status),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You bid LKR ${myQuote!.quotedPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _quoteStatusColor(myQuote!.status),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _quoteStatusColor(myQuote!.status),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _quoteStatusBadgeLabel(context, myQuote!.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (myQuote == null)
            PrimaryButton(
              label: context.l10n.sendPriceQuote,
              leadingIcon: Icons.send_rounded,
              onPressed: onSendQuote,
            )
          else if (myQuote!.status == 'pending')
            PrimaryButton(
              label: 'Update Quote',
              leadingIcon: Icons.edit_note_rounded,
              onPressed: onSendQuote,
            ),
        ],
      ),
    );
  }

  Color _quoteStatusColor(String status) {
    return switch (status) {
      'accepted' => const Color(0xFF22C55E),
      'declined' || 'not_selected' => const Color(0xFF64748B),
      'withdrawn' || 'job_closed' || 'cancelled' => const Color(0xFF94A3B8),
      _ => AppColors.primary,
    };
  }

  String _quoteStatusBadgeLabel(BuildContext context, String status) {
    return switch (status) {
      'accepted' => context.l10n.acceptedCaps,
      'declined' || 'not_selected' => context.l10n.declinedCaps,
      'withdrawn' => 'WITHDRAWN',
      'job_closed' || 'cancelled' => 'CLOSED',
      _ => context.l10n.pendingResponseCaps,
    };
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

  Future<void> _cancelQuote(BuildContext context) async {
    final reasons = [
      context.l10n.cancelReasonProviderUnavailable,
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
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.cancellationReasonPrompt,
                style: TextStyle(color: ctx.themeTextSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.confirmCancellation),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
        await JobRequestRepository().cancelAssignedJob(
          requestId: quote.requestId,
          reason: selectedReason,
          quoteId: quote.id,
          cancelledBy: currentUid,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.bookingCancelledSuccess),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } catch (e) {
        debugPrint('[ProviderDashboardScreen] Error: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.somethingWentWrong)),
          );
        }
      }
    }
  }

  Future<void> _withdrawBid(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.themeSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          context.l10n.withdrawBid,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: Text(
          context.l10n.withdrawBidConfirmPrompt,
          style: TextStyle(color: ctx.themeTextSecondary, fontSize: 13.5),
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
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.withdrawBid),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await JobRequestRepository().withdrawQuote(quote.requestId, quote.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.bidWithdrawnSuccess),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } catch (e) {
        debugPrint('[ProviderDashboard] withdrawQuote error: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.somethingWentWrong)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAccepted = quote.status == 'accepted';
    final isPending = quote.status == 'pending';
    final statusColor = switch (quote.status) {
      'accepted' => const Color(0xFF22C55E),
      'declined' || 'not_selected' => context.themeTextSecondary,
      'withdrawn' => AppColors.warning,
      'job_closed' => AppColors.error,
      _ => AppColors.primary,
    };
    final statusIcon = switch (quote.status) {
      'accepted' => Icons.check_circle_rounded,
      'declined' || 'not_selected' => Icons.cancel_outlined,
      'withdrawn' => Icons.remove_circle_outline,
      'job_closed' => Icons.close_rounded,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
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
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: context.l10n.chatWithCustomer,
                    leadingIcon: Icons.chat_bubble_outline_rounded,
                    onPressed: () => _openCustomerChat(context),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: context.l10n.cancelBookingOrQuote,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.error.withValues(alpha: 0.12),
                    foregroundColor: AppColors.error,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: const Icon(Icons.cancel_outlined, size: 20),
                  onPressed: () => _cancelQuote(context),
                ),
              ],
            ),
          ] else if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _withdrawBid(context),
                  icon: const Icon(Icons.remove_circle_outline, size: 16),
                  label: Text(context.l10n.withdrawBid),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                        color: AppColors.error.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
