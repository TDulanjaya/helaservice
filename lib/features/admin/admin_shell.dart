import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_top_bar.dart';
import 'screens/dashboard_live_map_screen.dart';
import 'screens/nic_verification_workspace_screen.dart';
import 'screens/category_district_management_screen.dart';
import 'screens/admin_profile_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _navIndex = 0;

  static const _adminNavItems = [
    NavItem(Icons.speed, 'Overview'),
    NavItem(Icons.badge, 'Verify', badge: '7'),
    NavItem(Icons.map, 'Coverage'),
    NavItem(Icons.admin_panel_settings, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    final screens = [
      const DashboardLiveMapScreen(),
      const NicVerificationWorkspaceScreen(),
      const CategoryDistrictManagementScreen(),
      AdminProfileScreen(
        onNavigateToVerifications: () => setState(() => _navIndex = 1),
      ),
    ];

    if (isMobile) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              AdminTopBar(
                onProfileTap: () => setState(() => _navIndex = 3),
              ),
              Expanded(
                child: IndexedStack(
                  index: _navIndex,
                  children: screens,
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: AppBottomNav(
          items: _adminNavItems,
          currentIndex: _navIndex,
          onTap: (i) => setState(() => _navIndex = i),
        ),
      );
    }

    // Tablet & Desktop Layout with Sidebar + TopBar
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          AdminSidebar(
            selectedIndex: _navIndex == 3 ? 6 : _navIndex,
            onSelect: (i) {
              if (i == 6) {
                // Platform Settings
                setState(() => _navIndex = 3);
              } else if (i <= 2) {
                setState(() => _navIndex = i);
              }
            },
          ),
          Expanded(
            child: Column(
              children: [
                AdminTopBar(
                  onProfileTap: () => setState(() => _navIndex = 3),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _navIndex,
                    children: screens,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
