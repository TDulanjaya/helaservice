import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import '../../../theme/app_theme.dart';
import '../../../models/admin_models.dart';
import '../../../models/technician.dart';
import '../../../repositories/category_repository.dart';
import '../../../repositories/technician_repository.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/role_switch_sheet.dart';
import '../../../state/role_provider.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/app_localizations_helpers.dart';
import '../widgets/customer_bookings_view.dart';
import '../../../shared/screens/conversations_inbox_screen.dart';
import 'customer_profile_screen.dart';
import 'live_tracking_screen.dart';
import 'post_job_request_screen.dart';
import 'provider_detail_screen.dart';
import '../../../shared/widgets/user_avatar.dart';

class HomeDiscoveryScreen extends StatefulWidget {
  final int initialIndex;
  const HomeDiscoveryScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeDiscoveryScreen> createState() => _HomeDiscoveryScreenState();
}

class _HomeDiscoveryScreenState extends State<HomeDiscoveryScreen> {
  final CategoryRepository _categoryRepo = CategoryRepository();
  final TechnicianRepository _techRepo = TechnicianRepository();
  final TextEditingController _searchController = TextEditingController();

  int _selectedCategoryIndex = -1;
  String _selectedCategoryName = '';
  late int _navIndex;
  String _searchQuery = '';
  String _selectedDistrict = '';
  bool _onlineOnly = false;
  bool _emergencyOnly = false;
  double _minRating = 0.0;

  bool get _hasActiveFilters =>
      _onlineOnly || _emergencyOnly || _minRating > 0.0;

  @override
  void initState() {
    super.initState();
    _navIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<CategoryRow>> get _categoryStream {
    try {
      return _categoryRepo.streamCategoryRows();
    } catch (_) {
      return const Stream.empty();
    }
  }

  Stream<List<Technician>> get _technicianStream {
    try {
      return _techRepo
          .streamTechnicians()
          .map((list) => list.where((t) => !t.isBanned).toList());
    } catch (_) {
      return const Stream.empty();
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Artisans',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                _onlineOnly = false;
                                _emergencyOnly = false;
                                _minRating = 0.0;
                              });
                              setState(() {
                                _onlineOnly = false;
                                _emergencyOnly = false;
                                _minRating = 0.0;
                              });
                            },
                            child: const Text(
                              'Reset All',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Online & Ready to Bid',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'Show active artisans ready for instant booking',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: context.themeTextSecondary),
                            ),
                            value: _onlineOnly,
                            activeThumbColor: AppColors.primary,
                            onChanged: (val) {
                              setSheetState(() => _onlineOnly = val);
                              setState(() => _onlineOnly = val);
                            },
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Emergency Dispatch',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'Available for urgent 24/7 or emergency callouts',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: context.themeTextSecondary),
                            ),
                            value: _emergencyOnly,
                            activeThumbColor: AppColors.primary,
                            onChanged: (val) {
                              setSheetState(() => _emergencyOnly = val);
                              setState(() => _emergencyOnly = val);
                            },
                          ),
                          const Divider(height: 24),
                          const Text(
                            'Customer Rating',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('All Ratings'),
                                selected: _minRating == 0.0,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: _minRating == 0.0
                                      ? AppColors.onPrimary
                                      : context.themeTextPrimary,
                                  fontWeight: _minRating == 0.0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (_) {
                                  setSheetState(() => _minRating = 0.0);
                                  setState(() => _minRating = 0.0);
                                },
                              ),
                              ChoiceChip(
                                label: const Text('4.0+'),
                                selected: _minRating == 4.0,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: _minRating == 4.0
                                      ? AppColors.onPrimary
                                      : context.themeTextPrimary,
                                  fontWeight: _minRating == 4.0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (_) {
                                  setSheetState(() => _minRating = 4.0);
                                  setState(() => _minRating = 4.0);
                                },
                              ),
                              ChoiceChip(
                                label: const Text('4.5+'),
                                selected: _minRating == 4.5,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: _minRating == 4.5
                                      ? AppColors.onPrimary
                                      : context.themeTextPrimary,
                                  fontWeight: _minRating == 4.5
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (_) {
                                  setSheetState(() => _minRating = 4.5);
                                  setState(() => _minRating = 4.5);
                                },
                              ),
                              ChoiceChip(
                                label: const Text('Top Rated (4.8+)'),
                                selected: _minRating == 4.8,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: _minRating == 4.8
                                      ? AppColors.onPrimary
                                      : context.themeTextPrimary,
                                  fontWeight: _minRating == 4.8
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (_) {
                                  setSheetState(() => _minRating = 4.8);
                                  setState(() => _minRating = 4.8);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navItems = [
      NavItem(Icons.explore, context.l10n.navExplore),
      NavItem(Icons.calendar_month, context.l10n.navBookings),
      NavItem(Icons.near_me, context.l10n.navTracking),
      NavItem(Icons.person, context.l10n.navProfile),
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
            _buildExploreView(context),
            CustomerBookingsView(
              onTrackPressed: () => setState(() => _navIndex = 2),
            ),
            const LiveTrackingScreen(
              showBottomNav: false,
            ),
            const CustomerProfileScreen(),
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

  Widget _buildExploreView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.appTitle,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                Text(context.l10n.navExplore,
                    style: TextStyle(
                        fontSize: 11, color: context.themeTextSecondary)),
              ],
            ),
          ],
        ),
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
          GestureDetector(
            onTap: () => setState(() => _navIndex = 3),
            child: UserAvatar(
              uid: pv.Provider.of<RoleProvider>(context).currentUser?.id,
              displayName: pv.Provider.of<RoleProvider>(context).currentUser?.displayName ?? '',
              photoUrl: pv.Provider.of<RoleProvider>(context).currentUser?.photoUrl,
              radius: 16,
            ),
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
                    children: [
                      Text(
                        '${context.l10n.greetingAyubowan}, ${pv.Provider.of<RoleProvider>(context).currentUser?.displayName.split(' ').first ?? 'Friend'}!',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        context.l10n.findCertifiedArtisans,
                        style: TextStyle(color: context.themeTextSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => showRoleSwitchSheet(context),
                  icon:
                      Icon(Icons.swap_horiz, color: context.themeTextSecondary),
                  tooltip: context.l10n.switchRole,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Colors.black],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Need Quick Service?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Post your job in 60s & receive instant competitive bids from verified nearby artisans.',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 11.5),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PostJobRequestScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.add_task, size: 16),
                          label: const Text('Post Job & Get Quotes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.electric_bolt,
                        size: 36, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: context.themeSurface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: context.themeBorder),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black
                          .withValues(alpha: context.isDark ? 0.2 : 0.04),
                      blurRadius: 16)
                ],
              ),
              child: Row(children: [
                Icon(Icons.search, color: context.themeTextSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim().toLowerCase()),
                    style: TextStyle(color: context.themeTextPrimary),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: context.l10n.searchServiceHint,
                      hintStyle: TextStyle(color: context.themeTextSecondary),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                InkWell(
                  onTap: _showFilterSheet,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: _hasActiveFilters
                            ? AppColors.primary
                            : context.themeSurfaceContainer,
                        shape: BoxShape.circle),
                    child: Icon(Icons.tune,
                        size: 18,
                        color: _hasActiveFilters
                            ? AppColors.onPrimary
                            : AppColors.primary),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 22),
            StreamBuilder<List<CategoryRow>>(
              stream: _categoryStream,
              builder: (context, snapshot) {
                final categories = snapshot.data ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.l10n.categories,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        if (_selectedCategoryIndex != -1)
                          TextButton(
                            onPressed: () => setState(() {
                              _selectedCategoryIndex = -1;
                              _selectedCategoryName = '';
                            }),
                            child: const Text('Show All',
                                style: TextStyle(fontSize: 12)),
                          )
                        else
                          Text('${context.l10n.viewAll} (${categories.length})',
                              style: const TextStyle(
                                  color: AppColors.primary, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 108,
                      child: categories.isEmpty
                          ? (snapshot.connectionState == ConnectionState.waiting
                              ? const Center(child: CircularProgressIndicator())
                              : Center(
                                  child: Text(
                                      context.l10n.noCategoriesAvailable,
                                      style: TextStyle(
                                          color: context.themeTextSecondary,
                                          fontSize: 12))))
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: categories.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, i) {
                                final cat = categories[i];
                                final selected = i == _selectedCategoryIndex;
                                return SizedBox(
                                  width: 76,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (_selectedCategoryIndex == i) {
                                          _selectedCategoryIndex = -1;
                                          _selectedCategoryName = '';
                                        } else {
                                          _selectedCategoryIndex = i;
                                          _selectedCategoryName = cat.name;
                                        }
                                      });
                                    },
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 58,
                                          height: 58,
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? AppColors.primary
                                                : context.themeSurfaceContainer,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(cat.icon,
                                              color: selected
                                                  ? AppColors.onPrimary
                                                  : context.themeTextSecondary,
                                              size: 26),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          LocalizedData.getCategory(
                                              context, cat.name),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11,
                                            height: 1.2,
                                            color: selected
                                                ? AppColors.primary
                                                : context.themeTextSecondary,
                                            fontWeight: selected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedCategoryName.isNotEmpty
                      ? 'Top Artisans — $_selectedCategoryName'
                      : 'Verified Nearby Artisans',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Technician>>(
              stream: _technicianStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ));
                }

                var technicians = snapshot.data ?? [];

                if (_selectedCategoryName.isNotEmpty) {
                  final catLower = _selectedCategoryName.toLowerCase();
                  technicians = technicians.where((t) {
                    final titleLower = t.title.toLowerCase();
                    final aboutLower = t.about.toLowerCase();
                    return titleLower.contains(catLower) ||
                        aboutLower.contains(catLower);
                  }).toList();
                }

                if (_selectedDistrict.isNotEmpty) {
                  technicians = technicians.where((t) {
                    final area = t.serviceArea.toLowerCase();
                    return area.isEmpty ||
                        area.contains(_selectedDistrict.toLowerCase());
                  }).toList();
                }

                if (_searchQuery.isNotEmpty) {
                  technicians = technicians.where((t) {
                    return t.name.toLowerCase().contains(_searchQuery) ||
                        t.title.toLowerCase().contains(_searchQuery) ||
                        t.serviceArea.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                if (_onlineOnly) {
                  technicians = technicians.where((t) => t.online).toList();
                }
                if (_emergencyOnly) {
                  technicians =
                      technicians.where((t) => t.emergencyRateLkr > 0).toList();
                }
                if (_minRating > 0.0) {
                  technicians =
                      technicians.where((t) => t.rating >= _minRating).toList();
                }
                technicians.sort((a, b) => b.rating.compareTo(a.rating));

                if (technicians.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: context.themeSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.themeBorder),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.person_search,
                            size: 42, color: AppColors.outline),
                        const SizedBox(height: 10),
                        const Text(
                          'No artisans match your filters',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Try clearing your search query or adjusting your filters',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, color: context.themeTextSecondary),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _selectedCategoryIndex = -1;
                              _selectedCategoryName = '';
                              _selectedDistrict = '';
                              _onlineOnly = false;
                              _emergencyOnly = false;
                              _minRating = 0.0;
                            });
                          },
                          child: const Text('Reset All Filters'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: technicians.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final tech = technicians[index];
                    return _ArtisanCard(tech: tech);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtisanCard extends StatelessWidget {
  final Technician tech;
  const _ArtisanCard({required this.tech});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProviderDetailScreen(technician: tech),
        ),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.themeSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.themeBorder),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UserAvatar(
              uid: tech.id,
              displayName: tech.name,
              radius: 26,
              backgroundColor: tech.avatarColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tech.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (tech.nicVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified,
                            size: 14, color: AppColors.primary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tech.title,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.themeTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 14, color: AppColors.secondaryContainer),
                      const SizedBox(width: 3),
                      Text(
                        '${tech.rating.toStringAsFixed(1)} (${tech.reviewCount})',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.location_on,
                          size: 13, color: context.themeTextSecondary),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          tech.serviceArea.isNotEmpty
                              ? tech.serviceArea
                              : 'Colombo',
                          style: TextStyle(
                              fontSize: 11, color: context.themeTextSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'LKR ${tech.baseRateLkr}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Inspection',
                  style: TextStyle(
                      fontSize: 10, color: context.themeTextSecondary),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: tech.online
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : context.themeSurfaceContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    tech.online
                        ? context.l10n.statusOnline
                        : context.l10n.statusOffline,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: tech.online
                          ? AppColors.primary
                          : context.themeTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
