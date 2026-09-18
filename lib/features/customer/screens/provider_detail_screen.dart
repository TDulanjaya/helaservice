import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../data/models/technician.dart';
import '../../../shared/widgets/pill_badge.dart';
import '../../../shared/widgets/outline_button.dart';
import '../../../shared/widgets/primary_button.dart';
import 'live_tracking_screen.dart';

class ProviderDetailScreen extends StatelessWidget {
  final Technician technician;
  const ProviderDetailScreen({super.key, required this.technician});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service Detail')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          Row(
            children: [
              CircleAvatar(
                  radius: 34,
                  backgroundColor: technician.avatarColor,
                  child: Text(technician.initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold))),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(technician.name,
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.bold)),
                    if (technician.nicVerified)
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: PillBadge(
                            label: 'NIC Verified ✓',
                            icon: Icons.verified,
                            background: AppColors.surfaceHigh,
                            foreground: AppColors.primary),
                      ),
                    const SizedBox(height: 4),
                    Text(technician.title,
                        style:
                            const TextStyle(color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.bolt,
                          size: 14, color: AppColors.secondaryContainer),
                      const SizedBox(width: 3),
                      Text(technician.responseTimeLabel,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.onSurfaceVariant)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatTile(
                  icon: Icons.star,
                  value: '${technician.rating}',
                  label: 'Rating'),
              _StatTile(
                  icon: Icons.task_alt,
                  value: '${technician.jobsCount}',
                  label: 'Jobs'),
              _StatTile(
                  icon: Icons.timer,
                  value: technician.yearsExperience,
                  label: 'Experience'),
              _StatTile(
                  icon: Icons.verified,
                  value: technician.onTimePercent,
                  label: 'On-Time'),
            ],
          ),
          const SizedBox(height: 20),
          _SectionCard(
            title: 'Transparent Pricing',
            child: Column(
              children: [
                _PriceRow(
                    'Base Inspection & Visit Fee',
                    'Covers doorstep diagnosis & transit costs',
                    'LKR ${technician.baseRateLkr}'),
                const Divider(),
                _PriceRow('Standard Hourly Labour', null,
                    'LKR ${technician.hourlyRateLkr} / hr'),
                const Divider(),
                _PriceRow('Emergency / After-hours Rate', null,
                    'LKR ${technician.emergencyRateLkr} / hr'),
                const SizedBox(height: 6),
                const Text(
                    '• Materials & replacement parts billed separately with store receipts.',
                    style: TextStyle(
                        color: AppColors.onSurfaceVariant, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'About the Technician',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(technician.about,
                    style: const TextStyle(
                        color: AppColors.onSurfaceVariant, height: 1.4)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  PillBadge(label: technician.languages, icon: Icons.translate),
                  PillBadge(
                      label: technician.serviceArea, icon: Icons.location_on),
                  PillBadge(
                      label: technician.certification,
                      icon: Icons.workspace_premium),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Work Completed (${technician.jobsCount})',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Text('View All',
                  style: TextStyle(color: AppColors.primary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: technician.recentWork.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final w = technician.recentWork[i];
                return Container(
                  width: 110,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(w.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12)),
                      Text(w.location,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                );
              },
            ),
          ),
          if (technician.reviews.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
                'Customer Reviews  •  ${technician.rating} / 5 (${technician.reviewCount} verified)',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ...technician.reviews.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primary,
                              child: Text(r.initials,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 11))),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.reviewerName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                                Text('${r.location} • ${r.timeAgo}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ]),
                        const SizedBox(height: 6),
                        Text(r.comment,
                            style:
                                const TextStyle(fontSize: 12.5, height: 1.35)),
                      ],
                    ),
                  ),
                )),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.background, boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2))
          ]),
          child: Row(children: [
            Expanded(
                child: AppOutlineButton(label: 'Message', icon: Icons.chat)),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: PrimaryButton(
                label: 'Request Service · From LKR ${technician.baseRateLkr}',
                trailingIcon: Icons.event_available,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) =>
                          LiveTrackingScreen(technician: technician)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatTile(
      {required this.icon, required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.onSurfaceVariant)),
      ]),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.surfaceLowest,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String? sub;
  final String price;
  const _PriceRow(this.label, this.sub, this.price);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                if (sub != null)
                  Text(sub!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
