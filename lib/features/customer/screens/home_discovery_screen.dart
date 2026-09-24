import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/technician.dart';
import '../../../models/category_item.dart';
import '../../../repositories/category_repository.dart';
import '../../../repositories/technician_repository.dart';
import '../../../shared/widgets/technician_card.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/role_switch_sheet.dart';
import '../widgets/customer_bookings_view.dart';
import 'provider_detail_screen.dart';
import 'customer_profile_screen.dart';
import 'live_tracking_screen.dart';

class HomeDiscoveryScreen extends StatefulWidget {
  const HomeDiscoveryScreen({super.key});

  @override
  State<HomeDiscoveryScreen> createState() => _HomeDiscoveryScreenState();
}

class _HomeDiscoveryScreenState extends State<HomeDiscoveryScreen> {
  final CategoryRepository _categoryRepo = CategoryRepository();
  final TechnicianRepository _technicianRepo = TechnicianRepository();

  int _selectedCategory = 0;
  int _navIndex = 0;

  static const _defaultTechnician = Technician(
    id: 'kasun',
    name: 'Kasun Perera',
    initials: 'KP',
    avatarColor: Color(0xFF00685F),
    title: 'Master Electrician & Senior Plumber',
    nicVerified: true,
    online: true,
    rating: 4.9,
    reviewCount: 142,
    etaLabel: 'Instant (8 min)',
    baseRateLkr: 1500,
    responseTimeLabel: 'Usually responds in 5 mins',
    jobsCount: 142,
    yearsExperience: '10+ Yrs',
    onTimePercent: '99.2%',
    hourlyRateLkr: 1200,
    emergencyRateLkr: 1800,
    about: '',
    languages: 'Sinhala & English',
    serviceArea: 'Colombo 01-15 & Gampaha',
    certification: 'NVQ-4 Certified',
    recentWork: [],
    reviews: [],
  );

  static const _navItems = [
    NavItem(Icons.explore, 'Explore'),
    NavItem(Icons.calendar_month, 'Bookings'),
    NavItem(Icons.near_me, 'Tracking'),
    NavItem(Icons.person, 'Profile'),
  ];

  Stream<List<CategoryItem>> get _categoryStream {
    try {
      return _categoryRepo.streamCategories();
    } catch (_) {
      return const Stream.empty();
    }
  }

  Stream<List<Technician>> get _technicianStream {
    try {
      return _technicianRepo.streamTechnicians();
    } catch (_) {
      return const Stream.empty();
    }
  }

  void _openTechnician(BuildContext context, Technician tech) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ProviderDetailScreen(technician: tech)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _navIndex,
        children: [
          _buildExploreView(context),
          CustomerBookingsView(
            onTrackPressed: () => setState(() => _navIndex = 2),
          ),
          const LiveTrackingScreen(
            technician: _defaultTechnician,
            showBottomNav: false,
          ),
          const CustomerProfileScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        items: _navItems,
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }

  Widget _buildExploreView(BuildContext context) {
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
          GestureDetector(
            onTap: () => setState(() => _navIndex = 3),
            child: const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.surfaceHigh,
                child: Icon(Icons.person,
                    size: 18, color: AppColors.onSurfaceVariant)),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Ayubowan, Sanduni! 👋',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('Find certified local artisans ready to help today.',
                          style: TextStyle(color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => showRoleSwitchSheet(context),
                  icon:
                      Icon(Icons.swap_horiz, color: AppColors.onSurfaceVariant),
                  tooltip: 'Switch role',
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLowest,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16)
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
                  decoration: const BoxDecoration(
                      color: AppColors.surfaceContainer,
                      shape: BoxShape.circle),
                  child: const Icon(Icons.tune,
                      size: 18, color: AppColors.primary),
                ),
              ]),
            ),
            const SizedBox(height: 22),
            StreamBuilder<List<CategoryItem>>(
              stream: _categoryStream,
              builder: (context, snapshot) {
                final categories = snapshot.data ?? [];
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Categories',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('View all (${categories.length})',
                            style: const TextStyle(
                                color: AppColors.primary, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 84,
                      child: categories.isEmpty
                          ? (snapshot.connectionState == ConnectionState.waiting
                              ? const Center(child: CircularProgressIndicator())
                              : const Center(
                                  child: Text('No categories available',
                                      style: TextStyle(
                                          color: AppColors.onSurfaceVariant,
                                          fontSize: 12))))
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: categories.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 14),
                              itemBuilder: (context, i) {
                                final cat = categories[i];
                                final selected = i == _selectedCategory;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedCategory = i),
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
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        )),
                                  ]),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
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
            const _MapRadarPreview(),
            const SizedBox(height: 22),
            const Text('Top Rated Technicians',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Text('Verified background checks & island-wide ratings',
                style:
                    TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
            const SizedBox(height: 12),
            StreamBuilder<List<Technician>>(
              stream: _technicianStream,
              builder: (context, snapshot) {
                final technicians = snapshot.data ?? [];
                if (technicians.isEmpty &&
                    snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (technicians.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text('No technicians available',
                          style: TextStyle(color: AppColors.onSurfaceVariant)),
                    ),
                  );
                }
                return Column(
                  children: technicians
                      .map((tech) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TechnicianCard(
                                technician: tech,
                                onTap: () => _openTechnician(context, tech)),
                          ))
                      .toList(),
                );
              },
            ),
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
                  decoration: const BoxDecoration(
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
  const _MapRadarPreview();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.15)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.04),
                    AppColors.primaryContainer.withValues(alpha: 0.1),
                  ],
                ),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.radar, color: AppColors.primary, size: 30),
              ),
              const SizedBox(height: 8),
              const Text(
                'Instant Dispatch Radar Active',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                'Average arrival time: 14 mins in Colombo 03',
                style:
                    TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
