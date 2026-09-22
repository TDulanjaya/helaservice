import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../data/mock_data.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/role_switch_sheet.dart';
import 'job_alert_screen.dart';
import 'nic_verification_screen.dart';
import 'provider_profile_screen.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  bool _online = true;
  int _navIndex = 0;

  static const _navItems = [
    NavItem(Icons.radar, 'Jobs'),
    NavItem(Icons.payments, 'Earnings'),
    NavItem(Icons.verified_user, 'Verification'),
    NavItem(Icons.manage_accounts, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _navIndex,
        children: [
          _buildJobsRadarView(context),
          _buildEarningsScheduleView(context),
          const NicVerificationScreen(showBottomNav: false),
          const ProviderProfileScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        items: _navItems,
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }

  Widget _buildJobsRadarView(BuildContext context) {
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
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999)),
                child: Text(_online ? 'Online' : 'Offline',
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
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              GestureDetector(
                onTap: () => setState(() => _navIndex = 3),
                child: const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary,
                    child: Text('KP',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold))),
              ),
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
                        activeThumbColor: Colors.white,
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
            Row(children: const [
              _StatCard(icon: Icons.task_alt, value: '4 Jobs', sub: '+1 today'),
              SizedBox(width: 10),
              _StatCard(icon: Icons.star, value: '4.9', sub: '128 reviews'),
              SizedBox(width: 10),
              _StatCard(
                  icon: Icons.account_balance_wallet,
                  value: 'LKR 14.2k',
                  sub: 'Today'),
            ]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.secondaryContainer.withValues(alpha: 0.12),
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
                              color: Colors.black.withValues(alpha: 0.04),
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
                    onPressed: () => setState(() => _navIndex = 1),
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
    );
  }

  Widget _buildEarningsScheduleView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Earnings & Settlements'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Net Earnings (This Week)',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                  const SizedBox(height: 6),
                  const Text('LKR 38,400.00',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('11 Jobs Completed',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                      Text('Avg LKR 3,490 / job',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Recent Direct Settlements',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            const _EarningsItemTile(
              title: 'Main Breaker Panel Replacement',
              customer: 'Dr. Ruwan W. (Flower Rd)',
              date: 'Today, 11:30 AM',
              amount: '+ LKR 4,500',
              payoutStatus: 'Settled via LankaQR',
            ),
            const SizedBox(height: 8),
            const _EarningsItemTile(
              title: 'Kitchen Pipe Leak Repair',
              customer: 'Kamala S. (Nugegoda)',
              date: 'Yesterday, 4:15 PM',
              amount: '+ LKR 2,800',
              payoutStatus: 'Settled via LankaQR',
            ),
            const SizedBox(height: 8),
            const _EarningsItemTile(
              title: 'Inverter AC Diagnostic',
              customer: 'Ayesha S. (Colombo 03)',
              date: '20 Sep 2026, 2:00 PM',
              amount: '+ LKR 3,200',
              payoutStatus: 'Settled via LankaQR',
            ),

          ],
        ),
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
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(sub,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

class _EarningsItemTile extends StatelessWidget {
  final String title;
  final String customer;
  final String date;
  final String amount;
  final String payoutStatus;

  const _EarningsItemTile({
    required this.title,
    required this.customer,
    required this.date,
    required this.amount,
    required this.payoutStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_downward,
                color: Color(0xFF2E7D32), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text('$customer • $date',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: Color(0xFF2E7D32))),
              const SizedBox(height: 2),
              Text(payoutStatus,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.outline)),
            ],
          ),
        ],
      ),
    );
  }
}
