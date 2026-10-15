import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import '../../../theme/app_theme.dart';
import '../../../models/admin_models.dart';
import '../../../models/technician.dart';
import '../../../repositories/category_repository.dart';
import '../../../repositories/technician_repository.dart';
import '../../../services/category_service.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/role_switch_sheet.dart';
import '../../../state/role_provider.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/permission_utils.dart';
import '../widgets/customer_bookings_view.dart';
import '../../../shared/screens/conversations_inbox_screen.dart';
import 'customer_profile_screen.dart';
import 'post_job_request_screen.dart';
import 'provider_detail_screen.dart';
import 'emergency_dispatch_screen.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/icon_square_button.dart';
import '../../../shared/widgets/hero_card.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../../shared/widgets/notification_bell_icon.dart';
import '../../../utils/provider_pricing_helper.dart';

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
  String _selectedCategoryId = '';
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
    _navIndex = widget.initialIndex > 2 ? 2 : widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        PermissionUtils.checkAndPromptInitialPermissions(context);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<CategoryRow>> get _categoryStream {
    try {
      return _categoryRepo.streamLiveCategories();
    } catch (_) {
      return const Stream.empty();
    }
  }

  Stream<List<Technician>> get _technicianStream {
    try {
      return _techRepo.streamApprovedTechnicians();
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: context.themeBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.filterArtisans,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: context.themeInk),
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
                            child: Text(
                              context.l10n.resetAllFilters,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          IconSquareButton.small(
                            icon: Icons.close_rounded,
                            onTap: () => Navigator.pop(ctx),
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
                            title: Text(
                              context.l10n.onlineReadyToBid,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              context.l10n.onlineReadyToBidSub,
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
                            title: Text(
                              context.l10n.emergencyDispatch,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              context.l10n.emergencyHelpSubtitle,
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
                          Text(
                            context.l10n.customerRating,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: Text(context.l10n.allRatings),
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
                                label: const Text('4.8+'),
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
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        context.l10n.applyFilters,
                        style: const TextStyle(
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
            const CustomerBookingsView(),
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
    final roleProvider = pv.Provider.of<RoleProvider>(context);
    final canSwitchRole =
        roleProvider.isAuthorizedAdmin || roleProvider.isApprovedProvider;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.themeBg,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.themeBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 34,
                  height: 34,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.appTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: context.themeInk,
                  ),
                ),
                Text(
                  context.l10n.navExplore,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: context.themeMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          const NotificationBellIcon(size: 40),
          const SizedBox(width: 8),
          IconSquareButton(
            icon: Icons.chat_bubble_outline_rounded,
            size: 40,
            iconSize: 20,
            radius: 12,
            tooltip: context.l10n.messages,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ConversationsInboxScreen(),
                ),
              );
            },
          ),
          if (canSwitchRole) ...[
            const SizedBox(width: 8),
            IconSquareButton(
              icon: Icons.swap_vert_rounded,
              size: 40,
              iconSize: 22,
              radius: 12,
              tooltip: context.l10n.switchRole,
              onTap: () => showRoleSwitchSheet(context),
            ),
          ],
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              16, 12, 16, AppBottomNav.contentBottomPadding),
          children: [
            Builder(
              builder: (ctx) {
                final user = pv.Provider.of<RoleProvider>(ctx).currentUser;
                final rawName = user?.displayName.trim() ?? '';
                final cleanName = (rawName.isNotEmpty && !rawName.contains('@'))
                    ? rawName.split(' ').first
                    : context.l10n.roleCustomer;
                return Text(
                  '${context.l10n.greetingAyubowan}, $cleanName!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: context.themeInk,
                    letterSpacing: -0.3,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.findCertifiedArtisans,
              style: TextStyle(
                fontSize: 13,
                color: context.themeTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: context.themeSurface,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: context.themeBorder, width: 1.5),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(
                          () => _searchQuery = val.trim().toLowerCase()),
                      style: TextStyle(color: context.themeInk, fontSize: 14),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: context.themeMuted,
                          size: 20,
                        ),
                        hintText: context.l10n.searchServiceHint,
                        hintStyle: TextStyle(
                          color: context.themeMuted,
                          fontSize: 14,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 16),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                color: context.themeMuted,
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.tune_rounded,
                          size: 22,
                          color: AppColors.onPrimary,
                        ),
                        if (_hasActiveFilters)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            HeroCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.needQuickService,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.postJobBannerDesc,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PostJobRequestScreen(),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.l10n.postJobAndGetQuotes,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7F1D1D), Color(0xFF991B1B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.urgentHelpBannerTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.urgentHelpBannerDesc,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EmergencyDispatchScreen(),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF991B1B),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      context.l10n.urgentHelpBannerAction,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
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
                            child: Text(context.l10n.filterAll,
                                style: const TextStyle(fontSize: 12)),
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
                                          _selectedCategoryId = '';
                                          _selectedCategoryName = '';
                                        } else {
                                          _selectedCategoryIndex = i;
                                          _selectedCategoryId = cat.id;
                                          _selectedCategoryName =
                                              CategoryService.instance
                                                  .nameOf(cat.id,
                                                      context: context);
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
                                          CategoryService.instance
                                              .nameOf(cat.id, context: context),
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
                      ? '${context.l10n.topArtisans} — $_selectedCategoryName'
                      : context.l10n.nearbyArtisans,
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

                if (_selectedCategoryId.isNotEmpty) {
                  technicians = technicians.where((t) {
                    return t.category == _selectedCategoryId;
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
                      technicians.where((t) => (t.rating ?? 0.0) >= _minRating).toList();
                }
                technicians.sort((a, b) => (b.rating ?? 0.0).compareTo(a.rating ?? 0.0));

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
                        Text(
                          context.l10n.noArtisansMatchFilters,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.tryClearingSearchOrFilters,
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
                          child: Text(context.l10n.resetAllFilters),
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
    return AppCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProviderDetailScreen(technician: tech),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            uid: tech.id,
            displayName: tech.name,
            radius: 24,
            backgroundColor: tech.avatarColor,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        tech.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: context.themeInk,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (tech.nicVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: AppColors.success,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  tech.title,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.themeTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (tech.isNewProvider) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          context.l10n.newProviderBadge,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ] else ...[
                      const Icon(
                        Icons.star_rounded,
                        size: 15,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${tech.rating!.toStringAsFixed(1)} (${tech.reviewCount})',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: context.themeInk,
                        ),
                      ),
                    ],
                    const SizedBox(width: 10),
                    Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: context.themeMuted,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        tech.serviceArea.isNotEmpty
                            ? tech.serviceArea
                            : context.l10n.custFallbackColombo,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: context.themeTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusPill(
                      type: tech.isAvailableNow
                          ? StatusPillType.online
                          : (tech.online ? StatusPillType.pending : StatusPillType.offline),
                      label: tech.isAvailableNow
                          ? context.l10n.availableNow
                          : (tech.online ? context.l10n.outsideWorkingHours : context.l10n.statusOffline),
                      showDot: true,
                    ),
                    if (!tech.hasPricingMode(ProviderPricingHelper.modeTravel))
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          context.l10n.travelIncluded,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            color: context.themeMuted,
            size: 22,
          ),
        ],
      ),
    );
  }
}
