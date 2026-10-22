import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart' as pv;
import '../../constants/firestore_paths.dart';
import '../../services/session_guard.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../../utils/l10n_extension.dart';
import '../../state/role_provider.dart';
import '../../models/admin_user.dart';
import '../../theme/app_theme.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_top_bar.dart';
import 'screens/dashboard_live_map_screen.dart';
import 'screens/nic_verification_workspace_screen.dart';
import 'screens/admin_user_management_screen.dart';
import 'screens/category_district_management_screen.dart';
import 'screens/admin_management_screen.dart';
import 'screens/job_ledger_screen.dart';
import 'screens/admin_complaints_screen.dart';
import 'screens/admin_profile_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final roleProvider = pv.Provider.of<RoleProvider>(context);

    return StreamBuilder<int>(
      stream: FirebaseFirestore.instance
          .collection(FirestorePaths.verificationQueue)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .withSessionGuard()
          .map((s) => s.docs.length),
      builder: (context, countSnapshot) {
        if (countSnapshot.hasError) {
          SessionGuard.handlePermissionDenied(countSnapshot.error);
        }
        final pendingCount = countSnapshot.data ?? 0;
        final verifyBadge = pendingCount > 0 ? '$pendingCount' : null;

        return StreamBuilder<int>(
          stream: FirebaseFirestore.instance
              .collection(FirestorePaths.complaints)
              .where('status', isEqualTo: 'pending')
              .snapshots()
              .withSessionGuard()
              .map((s) => s.docs.length),
          builder: (context, complaintCountSnap) {
            if (complaintCountSnap.hasError) {
              SessionGuard.handlePermissionDenied(complaintCountSnap.error);
            }
            final pendingComplaints = complaintCountSnap.data ?? 0;
            final complaintsBadge =
                pendingComplaints > 0 ? '$pendingComplaints' : null;

            final canHandleSupport = roleProvider.isSuperAdmin ||
                roleProvider.hasAdminPermission(AdminPermission.handleSupport);

            final navDefinitions = [
              (NavItem(Icons.grid_view_rounded, context.l10n.navOverview), 0),
              (
                NavItem(Icons.badge_outlined, context.l10n.navVerify,
                    badge: verifyBadge),
                1
              ),
              (
                NavItem(Icons.manage_accounts_outlined,
                    context.l10n.navUserManagement),
                2
              ),
              (NavItem(Icons.layers_outlined, context.l10n.navCoverage), 3),
              (NavItem(Icons.people_outline, context.l10n.navTeam), 4),
              (
                NavItem(Icons.format_list_bulleted, context.l10n.jobLedgerNav),
                5
              ),
              if (canHandleSupport)
                (
                  NavItem(Icons.warning_amber_rounded, context.l10n.navDisputes,
                      badge: complaintsBadge),
                  6
                ),
              (NavItem(Icons.tune, context.l10n.navSettings), 7),
            ];

            final adminNavItems = navDefinitions.map((d) => d.$1).toList();
            int currentBottomNavIndex =
                navDefinitions.indexWhere((d) => d.$2 == _navIndex);
            if (currentBottomNavIndex == -1) currentBottomNavIndex = 0;

            final screens = [
              const DashboardLiveMapScreen(),
              const NicVerificationWorkspaceScreen(),
              const AdminUserManagementScreen(),
              const CategoryDistrictManagementScreen(),
              const AdminManagementScreen(),
              const JobLedgerScreen(),
              const AdminComplaintsScreen(),
              AdminProfileScreen(
                onNavigateToVerifications: () => setState(() => _navIndex = 1),
                onNavigateToAdmins: () => setState(() => _navIndex = 4),
              ),
            ];

            bool canAccessTab(int i) {
              if (roleProvider.isSuperAdmin) return true;
              switch (i) {
                case 1:
                  return roleProvider
                      .hasAdminPermission(AdminPermission.verifyNic);
                case 3:
                  return roleProvider
                      .hasAdminPermission(AdminPermission.manageCategories);
                case 4:
                  return roleProvider.isSuperAdmin;
                case 5:
                  return roleProvider
                      .hasAdminPermission(AdminPermission.viewFinances);
                case 6:
                  return roleProvider
                      .hasAdminPermission(AdminPermission.handleSupport);
                default:
                  return true;
              }
            }

            void handleTabSelect(int i) {
              if (!canAccessTab(i)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(i == 4
                        ? context.l10n.shellSuperAdminOnly
                        : context.l10n.noPermissionForAction),
                    backgroundColor: AppColors.error,
                    duration: const Duration(seconds: 2),
                  ),
                );
                return;
              }
              setState(() => _navIndex = i);
            }

            final Widget shell = isMobile
                ? Scaffold(
                    body: SafeArea(
                      child: Column(
                        children: [
                          AdminTopBar(
                            onProfileTap: () => setState(() => _navIndex = 7),
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
                      items: adminNavItems,
                      currentIndex: currentBottomNavIndex,
                      compact: true,
                      onTap: (navItemIndex) {
                        final targetIndex = navDefinitions[navItemIndex].$2;
                        handleTabSelect(targetIndex);
                      },
                    ),
                  )
                : Scaffold(
                    body: Row(
                      children: [
                        AdminSidebar(
                          selectedIndex: _navIndex,
                          onSelect: handleTabSelect,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              AdminTopBar(
                                onProfileTap: () =>
                                    setState(() => _navIndex = 7),
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

            return PopScope(
              canPop: _navIndex == 0,
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop && _navIndex != 0) {
                  setState(() => _navIndex = 0);
                }
              },
              child: shell,
            );
          },
        );
      },
    );
  }
}
