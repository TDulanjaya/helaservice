import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../data/admin_mock_data.dart';
import '../../../data/models/admin_models.dart';
import '../widgets/admin_stat_card.dart';

class DashboardLiveMapScreen extends StatelessWidget {
  const DashboardLiveMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: const [
                Text('Island Operations & Live Dispatch', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                _LiveBadge(),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Real-time telematics, auto-dispatch logs, and LankaQR clearing across Western, Central, & Southern Provinces.',
              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(999)),
                  child: const Text('Synced 12s ago', style: TextStyle(fontSize: 11, color: AppColors.outline)),
                ),
                OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.download, size: 14), label: const Text('Export CSV')),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.tune, size: 14),
                  label: const Text('Dispatch Matrix'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: const [
                          Text('Island Operations & Live Dispatch', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          _LiveBadge(),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Real-time telematics, auto-dispatch logs, and LankaQR clearing across Western, Central, & Southern Provinces.',
                        style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Text('Synced 12s ago', style: TextStyle(fontSize: 11, color: AppColors.outline)),
                const SizedBox(width: 12),
                OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.download, size: 14), label: const Text('Export CSV')),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.tune, size: 14),
                  label: const Text('Dispatch Matrix'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                ),
              ],
            ),
          ],
          SizedBox(height: isMobile ? 16 : 20),

          if (isMobile)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: const [
                AdminStatCard(icon: Icons.engineering, label: 'Active Providers', value: '342', trailingBadge: '+12%', subtitle: '218 Col • 74 Kdy • 50 Gle'),
                AdminStatCard(icon: Icons.receipt_long, label: 'Total Bookings', value: '1,248', subtitle: 'LKR 2.45M Gross GMV • 94% On-time'),
                AdminStatCard(icon: Icons.assignment_late, label: 'NIC Screening', value: '7', subtitle: 'Pending • Avg 18 mins • SLA 99.1%'),
                AdminStatCard(icon: Icons.qr_code_2, label: 'LankaQR Settlements', value: 'LKR 1.84M', trailingBadge: '99.4%', subtitle: 'Direct Clear • BOC & COMB Healthy'),
              ],
            )
          else
            const Row(children: [
              Expanded(child: AdminStatCard(icon: Icons.engineering, label: 'Active Providers', value: '342', trailingBadge: '+12%', subtitle: '218 Col • 74 Kdy • 50 Gle')),
              SizedBox(width: 12),
              Expanded(child: AdminStatCard(icon: Icons.receipt_long, label: 'Total Bookings', value: '1,248', subtitle: 'LKR 2.45M Gross GMV • 94% On-time')),
              SizedBox(width: 12),
              Expanded(child: AdminStatCard(icon: Icons.assignment_late, label: 'NIC Screening', value: '7', subtitle: 'Pending • Avg 18 mins • SLA 99.1%')),
              SizedBox(width: 12),
              Expanded(child: AdminStatCard(icon: Icons.qr_code_2, label: 'LankaQR Settlements', value: 'LKR 1.84M', trailingBadge: '99.4%', subtitle: 'Direct Clear • BOC & COMB Healthy')),
            ]),
          SizedBox(height: isMobile ? 16 : 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.surfaceLowest, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: const [
                  Expanded(
                    child: Text(
                      'All Sri Lanka — Live Traffic',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('Heatmap', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                ]),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: isMobile ? 180 : 220,
                    color: AppColors.surfaceLow,
                    child: Stack(children: [
                      Positioned(top: 20, left: 40, child: _MapHub(count: 74, label: 'Kandy Hub')),
                      Positioned(bottom: 30, left: 100, child: _MapHub(count: 50, label: 'Galle Fort Zone')),
                      Positioned(top: 90, right: 60, child: _MapHub(count: 218, label: 'Colombo Metro 01-15', big: true)),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.secondaryContainer.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
                          child: const Text('High Surge 1.4x', style: TextStyle(fontSize: 10, color: AppColors.onSecondaryContainer, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('218 Verified Artisans online. 48 En Route, 142 On Active Job, 28 Available for Instant Booking.',
                    style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 10),
                Wrap(spacing: 14, runSpacing: 6, children: const [
                  _LegendDot(color: AppColors.primary, label: 'On Job (142)'),
                  _LegendDot(color: AppColors.secondaryContainer, label: 'En Route (48)'),
                  _LegendDot(color: AppColors.outline, label: 'Idle / Available (28)'),
                ]),
                const SizedBox(height: 14),
                isMobile
                    ? const Wrap(spacing: 18, runSpacing: 10, children: [
                        _MiniStat(label: 'Colombo Avg Dispatch', value: '11.8 min'),
                        _MiniStat(label: 'Kandy Valley ETA', value: '17.2 min'),
                        _MiniStat(label: 'Galle Coast ETA', value: '14.0 min'),
                        _MiniStat(label: 'Auto-Dispatch Rate', value: '96.4%'),
                      ])
                    : const Row(children: [
                        _MiniStat(label: 'Colombo Avg Dispatch', value: '11.8 min'),
                        _MiniStat(label: 'Kandy Valley ETA', value: '17.2 min'),
                        _MiniStat(label: 'Galle Coast ETA', value: '14.0 min'),
                        _MiniStat(label: 'Auto-Dispatch Rate', value: '96.4%'),
                      ]),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 16 : 24),

          if (isMobile) ...[
            const _DispatchStreamCard(),
            const SizedBox(height: 16),
            const _DistrictCapacityCard(),
          ] else
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _DispatchStreamCard()),
                SizedBox(width: 16),
                Expanded(child: _DistrictCapacityCard()),
              ],
            ),
          SizedBox(height: isMobile ? 16 : 24),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.surfaceLowest, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Active Artisan Field Fleet — Live Top Roster', style: TextStyle(fontWeight: FontWeight.bold)),
                const Text('Continuous GPS breadcrumb pings & job statuses', style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                const SizedBox(height: 12),
                if (isMobile)
                  Column(children: AdminMockData.roster.map((r) => _MobileRosterCard(r: r)).toList())
                else
                  Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2.2),
                      1: FlexColumnWidth(1.6),
                      2: FlexColumnWidth(1.4),
                      3: FlexColumnWidth(1.4),
                      4: FlexColumnWidth(1.4),
                      5: FlexColumnWidth(1.2),
                    },
                    children: [
                      const TableRow(children: [
                        _TableHeaderCell('Artisan'),
                        _TableHeaderCell('Assigned Zone'),
                        _TableHeaderCell('Status'),
                        _TableHeaderCell('LankaQR Payout'),
                        _TableHeaderCell('Rating'),
                        _TableHeaderCell('Quick Dispatch'),
                      ]),
                      ...AdminMockData.roster.map((r) => TableRow(children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(children: [
                                Icon(r.tradeIcon, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                                    Text(r.nic, style: const TextStyle(fontSize: 10, color: AppColors.outline)),
                                  ],
                                ),
                              ]),
                            ),
                            Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(r.zone, style: const TextStyle(fontSize: 12))),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: r.statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                                child: Text(r.status, style: TextStyle(fontSize: 10.5, color: r.statusColor, fontWeight: FontWeight.w700)),
                              ),
                            ),
                            Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(r.payoutToday, style: const TextStyle(fontSize: 12))),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, size: 13, color: AppColors.secondaryContainer),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text('${r.rating} (${r.reviews})',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 11)),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: TextButton(onPressed: () {}, child: Text(r.actionLabel, style: const TextStyle(fontSize: 11))),
                            ),
                          ])),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DispatchStreamCard extends StatelessWidget {
  const _DispatchStreamCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surfaceLowest, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.rss_feed, size: 16, color: AppColors.primary),
            SizedBox(width: 6),
            Text('Live Dispatch Stream', style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          ...AdminMockData.dispatchStream.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(radius: 14, backgroundColor: e.iconColor.withValues(alpha: 0.12), child: Icon(e.icon, size: 14, color: e.iconColor)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(child: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5))),
                            Text(e.timeAgo, style: const TextStyle(fontSize: 10, color: AppColors.outline)),
                          ]),
                          Text(e.detail, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
                          Text(e.tagLabel, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          const Align(alignment: Alignment.centerLeft, child: Text('View All Incident Logs', style: TextStyle(fontSize: 11, color: AppColors.primary))),
        ],
      ),
    );
  }
}

class _DistrictCapacityCard extends StatelessWidget {
  const _DistrictCapacityCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.surfaceLowest, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('District Capacity — Real-time Load', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...AdminMockData.districtLoad.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                      Text('${(d.percent * 100).round()}% (${d.loadLabel})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(value: d.percent, minHeight: 6, backgroundColor: AppColors.surfaceHigh, color: AppColors.primary),
                    ),
                    const SizedBox(height: 2),
                    Text(d.detail, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              )),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(12)),
            child: Row(children: const [
              Icon(Icons.info, size: 14, color: AppColors.primary),
              SizedBox(width: 6),
              Expanded(child: Text('Surge incentives active in Colombo 01-08 to recruit 25 additional electrical artisans.', style: TextStyle(fontSize: 10.5))),
            ]),
          ),
        ],
      ),
    );
  }
}

class _MobileRosterCard extends StatelessWidget {
  final ArtisanRosterRow r;
  const _MobileRosterCard({required this.r});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(r.tradeIcon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  Text(r.nic, style: const TextStyle(fontSize: 10, color: AppColors.outline)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: r.statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
              child: Text(r.status, style: TextStyle(fontSize: 10, color: r.statusColor, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(r.zone, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(child: Text(r.payoutToday, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600))),
            const Icon(Icons.star, size: 13, color: AppColors.secondaryContainer),
            const SizedBox(width: 3),
            Text('${r.rating} (${r.reviews})', style: const TextStyle(fontSize: 11)),
            const SizedBox(width: 10),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: Text(r.actionLabel, style: const TextStyle(fontSize: 11)),
            ),
          ]),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(999)),
      child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _MapHub extends StatelessWidget {
  final int count;
  final String label;
  final bool big;
  const _MapHub({required this.count, required this.label, this.big = false});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: big ? 40 : 28,
        height: big ? 40 : 28,
        decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
        alignment: Alignment.center,
        child: Text('$count', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: big ? 13 : 10)),
      ),
      Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
    ]);
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 11)),
    ]);
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
      ]),
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
      child: Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.outline, fontWeight: FontWeight.w700)),
    );
  }
}
