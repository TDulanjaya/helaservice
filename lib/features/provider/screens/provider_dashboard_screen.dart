import '../../../shared/widgets/role_switch_sheet.dart';
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../data/mock_data.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import 'job_alert_screen.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  bool _online = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jobs Radar'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999)),
                child: const Text('Online',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              const CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  child: Text('KP',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Row(children: [
                      Text('Kasun Perera',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(width: 4),
                      Icon(Icons.verified, size: 14, color: AppColors.primary),
                    ]),
                    Row(children: [
                      Icon(Icons.engineering,
                          size: 13, color: AppColors.onSurfaceVariant),
                      SizedBox(width: 3),
                      Text('Master Electrician (NVQ-4)',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.onSurfaceVariant)),
                    ]),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => showRoleSwitchSheet(context),
                icon: const Icon(Icons.sync, size: 14),
                label: const Text('Switch Role', style: TextStyle(fontSize: 11)),
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
                      Text(_online ? 'You are ONLINE' : 'You are OFFLINE',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17)),
                      Switch(
                        value: _online,
                        onChanged: (v) => setState(() => _online = v),
                        activeColor: Colors.white,
                        activeTrackColor: Colors.white38,
                      ),
                    ],
                  ),
                  const Text(
                      'Active Dispatch — Receiving instant requests in Colombo 03, 04, 07 & Dehiwala',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(children: const [
                    Icon(Icons.radar, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Instant Match priority: 98% · GPS calibrated',
                        style: TextStyle(color: Colors.white, fontSize: 11)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              _StatCard(icon: Icons.task_alt, value: '4 Jobs', sub: '+1 today'),
              const SizedBox(width: 10),
              _StatCard(icon: Icons.star, value: '4.9', sub: '128 reviews'),
              const SizedBox(width: 10),
              _StatCard(
                  icon: Icons.account_balance_wallet,
                  value: 'LKR 14.2k',
                  sub: 'Today'),
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16)),
              child: Row(children: const [
                Icon(Icons.local_fire_department,
                    color: AppColors.secondaryContainer),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                      'SURGE RADAR — High demand in Bambalapitiya & Kollupitiya right now',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Scheduled Bookings · 2 today',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('View All',
                    style: TextStyle(color: AppColors.primary, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 10),
            ...MockData.bookings.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                        color: AppColors.surfaceLowest,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10)
                        ]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  '${b.time}${b.relativeTime.isNotEmpty ? " (${b.relativeTime})" : ""}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.onSurfaceVariant)),
                              Text(b.estRate,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ]),
                        Text(b.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 6),
                        Row(children: [
                          CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.surfaceHigh,
                              child: Text(b.customerInitials,
                                  style: const TextStyle(fontSize: 10))),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b.customerName,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                                Text('${b.location} (${b.distance})',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.onSurfaceVariant)),
                              ],
                            ),
                          ),
                          IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.call,
                                  size: 18, color: AppColors.primary)),
                          IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.directions,
                                  size: 18, color: AppColors.primary)),
                        ]),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                const Icon(Icons.savings, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Withdrawable Balance',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.onSurfaceVariant)),
                      Text('LKR 9,500',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
                TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.bolt, size: 16),
                    label: const Text('Instant Cashout')),
              ]),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const JobAlertScreen())),
              child: const Text('Simulate: New Job Request'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        items: const [
          NavItem(Icons.radar, 'Jobs'),
          NavItem(Icons.payments, 'Earnings'),
          NavItem(Icons.calendar_today, 'Schedule'),
          NavItem(Icons.manage_accounts, 'Profile'),
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
            color: AppColors.surfaceLowest,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(sub,
              style: const TextStyle(
                  fontSize: 9, color: AppColors.onSurfaceVariant)),
        ]),
      ),
    );
  }
}
