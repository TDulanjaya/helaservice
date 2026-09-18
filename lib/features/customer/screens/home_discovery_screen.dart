import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../data/mock_data.dart';
import '../../../shared/widgets/technician_card.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import 'provider_detail_screen.dart';

class HomeDiscoveryScreen extends StatefulWidget {
  const HomeDiscoveryScreen({super.key});

  @override
  State<HomeDiscoveryScreen> createState() => _HomeDiscoveryScreenState();
}

class _HomeDiscoveryScreenState extends State<HomeDiscoveryScreen> {
  int _selectedCategory = 0;
  int _navIndex = 0;

  static const _navItems = [
    NavItem(Icons.explore, 'Explore'),
    NavItem(Icons.calendar_month, 'Bookings'),
    NavItem(Icons.near_me, 'Tracking'),
    NavItem(Icons.person, 'Profile'),
  ];

  void _openTechnician(context, tech) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ProviderDetailScreen(technician: tech)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.handyman, size: 16, color: Colors.white)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('HelaService',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                Text('Explore',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.onSurfaceVariant)),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: AppColors.surfaceLow,
                borderRadius: BorderRadius.circular(999)),
            child: const Row(children: [
              Icon(Icons.location_on, size: 16, color: AppColors.primary),
              SizedBox(width: 4),
              Text('Colombo 03',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Icon(Icons.expand_more, size: 16),
            ]),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.surfaceHigh,
              child: Icon(Icons.person,
                  size: 18, color: AppColors.onSurfaceVariant)),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Text('Ayubowan, Sanduni! 👋',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('Find certified local artisans ready to help today.',
                style: TextStyle(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLowest,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04), blurRadius: 16)
                ],
              ),
              child: Row(children: [
                const Icon(Icons.search, color: AppColors.outline),
                const SizedBox(width: 8),
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search plumbing, AC repair, electricians...',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      shape: BoxShape.circle),
                  child: const Icon(Icons.tune,
                      size: 18, color: AppColors.primary),
                ),
              ]),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Categories',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('View all (18)',
                    style: TextStyle(color: AppColors.primary, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: MockData.categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, i) {
                  final cat = MockData.categories[i];
                  final selected = i == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = i),
                    child: Column(children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                              : AppColors.surfaceHigh,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(cat.icon,
                            color: selected
                                ? Colors.white
                                : AppColors.onSurfaceVariant,
                            size: 26),
                      ),
                      const SizedBox(height: 6),
                      Text(cat.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: selected
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                          )),
                    ]),
                  );
                },
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: const [
                  _PulsingDot(),
                  SizedBox(width: 6),
                  Text('Artisans on Duty',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ]),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(999)),
                  child: const Text('4 Active Nearby',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _MapRadarPreview(),
            const SizedBox(height: 22),
            const Text('Top Rated Technicians',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Text('Verified background checks & island-wide ratings',
                style:
                    TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
            const SizedBox(height: 12),
            ...MockData.technicians.map((tech) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TechnicianCard(
                      technician: tech,
                      onTap: () => _openTechnician(context, tech)),
                )),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: AppColors.surfaceHighest, shape: BoxShape.circle),
                  child: const Icon(Icons.health_and_safety,
                      color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('HelaCare Guarantee',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                          'All booked visits include complimentary property damage coverage up to LKR 100,000.',
                          style: TextStyle(
                              color: AppColors.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        items: _navItems,
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

class _PulsingDot extends StatelessWidget {
  const _PulsingDot();
  @override
  Widget build(BuildContext context) => Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
          color: AppColors.primary, shape: BoxShape.circle));
}

class _MapRadarPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 170,
        color: AppColors.surfaceLow,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _RoadPainter()),
            ),
            Center(
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3)),
              ),
            ),
            Positioned(
                top: 20,
                left: 20,
                child: _PinBadge(icon: Icons.ac_unit, label: '8 mins away')),
            Positioned(
                bottom: 30,
                right: 24,
                child: _PinBadge(icon: Icons.bolt, label: '12 mins away')),
            Positioned(
              bottom: 10,
              left: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.explore, size: 14, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text('Expand Radar',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PinBadge({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _RoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.surfaceHighest
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(-10, size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.1, size.width * 0.6,
          size.height * 0.35)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.5, size.width + 10,
          size.height * 0.3);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
