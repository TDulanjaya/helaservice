import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../constants/firestore_paths.dart';
import '../../../models/admin_models.dart';
import '../../../models/technician.dart';
import '../../../models/job_request.dart';
import '../../../repositories/technician_repository.dart';
import '../../../repositories/job_request_repository.dart';
import '../../../services/category_service.dart';
import '../../../theme/app_theme.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../shared/widgets/app_map_view.dart';
import '../../../shared/widgets/full_screen_map_page.dart';
import '../widgets/admin_stat_card.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/hero_card.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/location_utils.dart';
import '../../../utils/app_localizations_helpers.dart';

class DashboardLiveMapScreen extends StatelessWidget {
  const DashboardLiveMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

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
            context.l10n.islandOperationsTitle,
            style: TextStyle(
              fontSize: isMobile ? 26 : 28,
              fontWeight: FontWeight.w800,
              color: context.themeTextPrimary,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: isMobile ? 16 : 20),
          _LiveDashboardStats(isMobile: isMobile),
          SizedBox(height: isMobile ? 16 : 24),
          _LiveTrafficHeatmapCard(isMobile: isMobile),
          SizedBox(height: isMobile ? 16 : 24),
          if (isMobile) ...[
            Text(
              context.l10n.activeArtisanFleetLive,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: context.themeTextPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Technician>>(
              stream: TechnicianRepository().streamTechnicians(),
              builder: (context, snapshot) {
                final technicians = snapshot.data ?? [];
                final roster = technicians
                    .map((t) => _technicianToRosterRow(context, t))
                    .toList();

                if (roster.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    alignment: Alignment.center,
                    child: Text(
                      context.l10n.noActiveArtisansFleet,
                      style: TextStyle(
                        color: context.themeTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                  );
                }

                return Column(
                  children: roster.map((r) => _MobileRosterCard(r: r)).toList(),
                );
              },
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.themeSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.themeBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.activeArtisanFleetLive,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.themeTextPrimary)),
                  const SizedBox(height: 14),
                  StreamBuilder<List<Technician>>(
                    stream: TechnicianRepository().streamTechnicians(),
                    builder: (context, snapshot) {
                      final technicians = snapshot.data ?? [];
                      final roster = technicians
                          .map((t) => _technicianToRosterRow(context, t))
                          .toList();

                      if (roster.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(context.l10n.noActiveArtisansFleet,
                                style: const TextStyle(
                                    color: AppColors.outline, fontSize: 12)),
                          ),
                        );
                      }

                      return Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2.2),
                          1: FlexColumnWidth(1.6),
                          2: FlexColumnWidth(1.4),
                          3: FlexColumnWidth(1.4),
                          4: FlexColumnWidth(1.4),
                          5: FlexColumnWidth(1.2),
                        },
                        children: [
                          TableRow(children: [
                            _TableHeaderCell(context.l10n.liveMapColArtisan),
                            _TableHeaderCell(
                                context.l10n.liveMapColAssignedZone),
                            _TableHeaderCell(context.l10n.ocrStatus),
                            _TableHeaderCell(context.l10n.liveMapColPayout),
                            _TableHeaderCell(context.l10n.rating),
                            _TableHeaderCell(
                                context.l10n.liveMapColQuickDispatch),
                          ]),
                          ...roster.map((r) => TableRow(children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: Row(children: [
                                    Icon(r.tradeIcon,
                                        size: 16, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(r.name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12.5)),
                                        Text(r.nic,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: AppColors.outline)),
                                      ],
                                    ),
                                  ]),
                                ),
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    child: Text(r.zone,
                                        style: const TextStyle(fontSize: 12))),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                        color: r.statusColor
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(999)),
                                    child: Text(r.status,
                                        style: TextStyle(
                                            fontSize: 10.5,
                                            color: r.statusColor,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ),
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    child: Text(
                                        context.l10n
                                            .liveMapPayoutToday(r.payoutToday),
                                        style: const TextStyle(fontSize: 12))),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star,
                                          size: 13,
                                          color: AppColors.secondaryContainer),
                                      const SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                            '${r.rating} (${r.reviews})',
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                const TextStyle(fontSize: 11)),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: TextButton(
                                      onPressed: () =>
                                          _showDispatchDialog(context, r),
                                      child: Text(
                                          _actionLabelText(
                                              context, r.actionLabel),
                                          style:
                                              const TextStyle(fontSize: 11))),
                                ),
                              ])),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// dispatch button label
String _actionLabelText(BuildContext context, String action) {
  return action == 'Dispatch'
      ? context.l10n.liveMapActionDispatch
      : context.l10n.liveMapActionReassign;
}

ArtisanRosterRow _technicianToRosterRow(BuildContext context, Technician t) {
  final l10n = context.l10n;
  IconData getTradeIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('electr')) return Icons.bolt;
    if (lower.contains('plumb')) return Icons.plumbing;
    if (lower.contains('ac') ||
        lower.contains('cool') ||
        lower.contains('hvac')) {
      return Icons.ac_unit;
    }
    if (lower.contains('carpent')) return Icons.carpenter;
    return Icons.engineering;
  }

  final statusStr = t.online
      ? l10n.liveMapStatusAvailableIdle
      : (t.nicVerified
          ? l10n.liveMapStatusActiveVerified
          : l10n.pendingVerificationStatus);
  final statusCol = t.online
      ? AppColors.primary
      : (t.nicVerified ? AppColors.secondaryContainer : AppColors.outline);

  return ArtisanRosterRow(
    name: t.name,
    nic: t.nicVerified ? l10n.liveMapNicVerified : l10n.liveMapNicPending,
    trade: t.title,
    tradeIcon: getTradeIcon(t.title),
    zone:
        t.serviceArea.isNotEmpty ? t.serviceArea : l10n.liveMapZoneColomboMetro,
    status: statusStr,
    statusColor: statusCol,
    // base rate in ui
    payoutToday: 'LKR ${t.baseRateLkr}',
    rating: t.rating ?? 0.0,
    reviews: t.reviewCount,
    actionLabel: t.online ? l10n.dispatchTitle : l10n.reassignTitle,
  );
}

void _showDispatchDialog(BuildContext context, ArtisanRosterRow r) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Icon(r.tradeIcon, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.liveMapDispatchDialogTitle(
                  _actionLabelText(context, r.actionLabel), r.name),
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.tradeAndZone(r.trade, r.zone),
                style:
                    TextStyle(fontSize: 12, color: context.themeTextSecondary)),
            const SizedBox(height: 14),
            Text(
              context.l10n.selectOpenJobRequest,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<JobRequest>>(
              stream: JobRequestRepository().streamOpenRequests(),
              builder: (context, snapshot) {
                final requests = snapshot.data ?? [];
                if (requests.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        context.l10n.noOpenCustomerRequests,
                        style: TextStyle(
                            fontSize: 12, color: context.themeTextSecondary),
                      ),
                    ),
                  );
                }
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: requests.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final req = requests[idx];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(req.title,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${req.address.isNotEmpty ? req.address : CategoryService.instance.nameOf(req.category, context: context)} • ${context.l10n.liveMapQuotesReceived(req.quoteCount)}',
                            style: const TextStyle(fontSize: 11)),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final addr = req.address.isNotEmpty
                                ? req.address
                                : CategoryService.instance
                                    .nameOf(req.category, context: context);
                            await FirebaseFirestore.instance
                                .collection(FirestorePaths.dispatchEvents)
                                .add({
                              'title': 'MANUAL_DISPATCH_ASSIGNED',
                              'detail': context.l10n.manualDispatchAssignedDesc(
                                  r.name, req.title, addr),
                              'tagLabel': 'DISPATCHED',
                              'timeAgo': '',
                              'iconKey': 'bolt',
                              'colorValue': 0xFFD6900F,
                              'timestamp': FieldValue.serverTimestamp(),
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.l10n
                                      .dispatchedArtisanToJob(
                                          r.name, '"${req.title}"')),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            }
                          },
                          child: Text(context.l10n.assignAction,
                              style: const TextStyle(fontSize: 11)),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(context.l10n.close),
        ),
      ],
    ),
  );
}

class _MobileRosterCard extends StatelessWidget {
  final ArtisanRosterRow r;
  const _MobileRosterCard({required this.r});

  @override
  Widget build(BuildContext context) {
    final isDispatch = r.actionLabel.toLowerCase().contains('dispatch');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.themeBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                displayName: r.name,
                radius: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: context.themeTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${r.nic} • ${r.zone}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: context.themeTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: r.statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  r.status,
                  style: TextStyle(
                    fontSize: 11,
                    color: r.statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${context.l10n.liveMapColPayout} ',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: context.themeTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: r.payoutToday,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: context.themeTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    context.l10n.liveMapTodayParen,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: context.themeTextSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 18),
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${r.rating}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: context.themeTextPrimary,
                        ),
                      ),
                      Text(
                        '(${r.reviews})',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: context.themeTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              if (isDispatch)
                ElevatedButton(
                  onPressed: () => _showDispatchDialog(context, r),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        context.isDark ? Colors.white : AppColors.ink,
                    foregroundColor:
                        context.isDark ? AppColors.ink : Colors.white,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    minimumSize: const Size(80, 38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _actionLabelText(context, r.actionLabel),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              else
                OutlinedButton(
                  onPressed: () => _showDispatchDialog(context, r),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.themeBorder, width: 1.2),
                    foregroundColor: context.themeTextPrimary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: const Size(80, 38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _actionLabelText(context, r.actionLabel),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: context.themeTextPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String label;
  const _TableHeaderCell(this.label);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label,
          style: TextStyle(
              fontSize: 10.5,
              color: context.themeTextSecondary,
              fontWeight: FontWeight.w700)),
    );
  }
}

class _LiveDashboardStats extends StatelessWidget {
  final bool isMobile;
  const _LiveDashboardStats({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(FirestorePaths.technicians)
          .snapshots(),
      builder: (context, techSnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection(FirestorePaths.bookings)
              .snapshots(),
          builder: (context, bookingSnap) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection(FirestorePaths.verificationQueue)
                  .snapshots(),
              builder: (context, queueSnap) {
                final techs = techSnap.data?.docs ?? [];
                final bookings = bookingSnap.data?.docs ?? [];
                final queue = queueSnap.data?.docs ?? [];

                final onlineCount =
                    techs.where((t) => t.data()['online'] == true).length;
                final verifiedCount =
                    techs.where((t) => t.data()['nicVerified'] == true).length;
                final totalTechs = techs.length;

                final totalBookings = bookings.length;
                final completedBookings = bookings
                    .where((b) => b.data()['status'] == 'completed')
                    .length;
                final activeBookings = bookings
                    .where((b) =>
                        b.data()['status'] == 'in_progress' ||
                        b.data()['status'] == 'pending')
                    .length;

                final pendingQueue = queue
                    .where(
                        (q) => (q.data()['status'] ?? 'pending') == 'pending')
                    .length;

                final heroCard = HeroCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.engineering,
                              size: 20,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              context.l10n.activeProvidersTitle.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: context.isDark
                                    ? context.themeAmberText
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  context.l10n.liveMapLiveCount(onlineCount),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '$totalTechs',
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.8,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.l10n.onlineFleetSummary(
                          '$onlineCount',
                          '$verifiedCount',
                        ),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                );

                final bookingsCard = AdminStatCard(
                  icon: Icons.receipt_long,
                  label: context.l10n.totalBookingsTitle,
                  value: '$totalBookings',
                  trailingBadge: activeBookings > 0
                      ? context.l10n.liveMapActiveCount(activeBookings)
                      : null,
                  subtitle: context.l10n.completedInProgressSummary(
                    '$completedBookings',
                    '$activeBookings',
                  ),
                );

                final nicCard = AdminStatCard(
                  icon: Icons.badge_outlined,
                  label: context.l10n.nicScreeningTitle,
                  value: '$pendingQueue',
                  trailingBadge: pendingQueue > 0
                      ? context.l10n.liveMapActionRequired
                      : context.l10n.clearStatusBadge,
                  subtitle: context.l10n.verificationDossiersLogged(
                    '${queue.length}',
                  ),
                );

                if (isMobile) {
                  return Column(
                    children: [
                      heroCard,
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: bookingsCard),
                          const SizedBox(width: 12),
                          Expanded(child: nicCard),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(flex: 3, child: heroCard),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: bookingsCard),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: nicCard),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _LiveTrafficHeatmapCard extends StatefulWidget {
  final bool isMobile;
  const _LiveTrafficHeatmapCard({required this.isMobile});

  @override
  State<_LiveTrafficHeatmapCard> createState() =>
      _LiveTrafficHeatmapCardState();
}

class _LiveTrafficHeatmapCardState extends State<_LiveTrafficHeatmapCard> {
  late final ValueNotifier<bool> _showAllDistrictsNotifier;
  late final ValueNotifier<List<AppMapMarker>> _markersNotifier;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _techniciansSub;
  QuerySnapshot<Map<String, dynamic>>? _latestSnapshot;
  int _unknownCount = 0;
  ModalRoute? _fullScreenRoute;

  @override
  void initState() {
    super.initState();
    _showAllDistrictsNotifier = ValueNotifier<bool>(false);
    _markersNotifier = ValueNotifier<List<AppMapMarker>>([]);

    _showAllDistrictsNotifier.addListener(_onFilterChanged);

    _techniciansSub = FirebaseFirestore.instance
        .collection(FirestorePaths.technicians)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      _latestSnapshot = snapshot;
      _updateMarkers();
    });
  }

  void _onFilterChanged() {
    if (!mounted) return;
    _updateMarkers();
  }

  void _updateMarkers() {
    if (!mounted) return;
    final docs = _latestSnapshot?.docs ?? [];
    final Map<String, int> counts = {
      for (final d in LocationUtils.districtCoordinates.keys) d: 0,
    };
    int unknown = 0;

    for (final d in docs) {
      final data = d.data();
      final lat = (data['currentLat'] ??
          data['baseLat'] ??
          data['latitude'] ??
          data['lat']) as num?;
      final lng = (data['currentLng'] ??
          data['baseLng'] ??
          data['longitude'] ??
          data['lng']) as num?;
      final districtStr = data['district'] as String?;
      final serviceAreaStr = data['serviceArea'] as String?;

      final matched = LocationUtils.resolveDistrict(
        latitude: lat?.toDouble(),
        longitude: lng?.toDouble(),
        district: districtStr,
        serviceArea: serviceAreaStr,
      );

      if (matched != null && counts.containsKey(matched)) {
        counts[matched] = counts[matched]! + 1;
      } else {
        unknown++;
      }
    }

    final showAll = _showAllDistrictsNotifier.value;
    final markers = <AppMapMarker>[];
    for (final entry in LocationUtils.districtCoordinates.entries) {
      final districtName = entry.key;
      final coords = entry.value;
      final count = counts[districtName] ?? 0;
      final localizedName = LocalizedData.getDistrict(context, districtName);

      if (count > 0) {
        markers.add(
          AppMapMarker.hub(
            point: LatLng(coords.lat, coords.lng),
            label: localizedName,
            count: count,
            isLarge: count >= 5,
          ),
        );
      } else if (showAll) {
        markers.add(
          AppMapMarker.hub(
            point: LatLng(coords.lat, coords.lng),
            label: localizedName,
            count: 0,
          ),
        );
      }
    }

    _unknownCount = unknown;
    _markersNotifier.value = markers;
    setState(() {});
  }

  void _openFullScreen() {
    final route = MaterialPageRoute<void>(
      builder: (ctx) => FullScreenMapPage(
        initialCenter: const LatLng(7.85, 80.725),
        initialZoom: widget.isMobile ? 6.5 : 7.2,
        initialCameraFit: CameraFit.bounds(
          bounds: LatLngBounds(
            const LatLng(5.85, 79.5),
            const LatLng(9.85, 81.95),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 20,
          ),
        ),
        markersNotifier: _markersNotifier,
        headerAction: ValueListenableBuilder<bool>(
          valueListenable: _showAllDistrictsNotifier,
          builder: (context, showAll, _) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: context.themeSurface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.themeBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: context.isDark ? 0.35 : 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.liveMapShowAllDistricts,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.themeTextPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch.adaptive(
                      value: showAll,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) {
                        _showAllDistrictsNotifier.value = val;
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    _fullScreenRoute = route;
    Navigator.of(context).push(route).then((_) {
      _fullScreenRoute = null;
    });
  }

  @override
  void dispose() {
    if (_fullScreenRoute != null && _fullScreenRoute!.isActive) {
      _fullScreenRoute!.navigator?.removeRoute(_fullScreenRoute!);
      _fullScreenRoute = null;
    }
    _techniciansSub?.cancel();
    _showAllDistrictsNotifier.removeListener(_onFilterChanged);
    _showAllDistrictsNotifier.dispose();
    _markersNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.themeBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.04),
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
                  context.l10n.allSriLankaLiveTraffic,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: context.themeTextPrimary,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.liveMapShowAllDistricts,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: context.themeTextSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Transform.scale(
                    scale: 0.8,
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _showAllDistrictsNotifier,
                      builder: (context, showAll, _) {
                        return Switch.adaptive(
                          value: showAll,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) =>
                              _showAllDistrictsNotifier.value = val,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: widget.isMobile ? 360 : 440,
            child: ValueListenableBuilder<List<AppMapMarker>>(
              valueListenable: _markersNotifier,
              builder: (context, markers, _) {
                return AppMapView(
                  initialCenter: const LatLng(7.85, 80.725),
                  initialZoom: widget.isMobile ? 6.5 : 7.2,
                  initialCameraFit: CameraFit.bounds(
                    bounds: LatLngBounds(
                      const LatLng(5.85, 79.5),
                      const LatLng(9.85, 81.95),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                  ),
                  interactive: true,
                  markers: markers,
                  onExpand: _openFullScreen,
                );
              },
            ),
          ),
          if (_unknownCount > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: context.themeTextSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  _unknownCount > 1
                      ? context.l10n.liveMapUnmappedProviderMany(_unknownCount)
                      : context.l10n.liveMapUnmappedProviderOne(_unknownCount),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: context.themeTextSecondary,
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
