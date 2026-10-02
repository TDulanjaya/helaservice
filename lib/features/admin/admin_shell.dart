import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart' as pv;
import '../../constants/firestore_paths.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../../utils/l10n_extension.dart';
import '../../state/role_provider.dart';
import '../../theme/app_theme.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_top_bar.dart';
import 'screens/dashboard_live_map_screen.dart';
import 'screens/nic_verification_workspace_screen.dart';
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
          .map((s) => s.docs.length),
      builder: (context, countSnapshot) {
        final pendingCount = countSnapshot.data ?? 0;
        final verifyBadge = pendingCount > 0 ? '$pendingCount' : null;

        return StreamBuilder<int>(
          stream: FirebaseFirestore.instance
              .collection(FirestorePaths.complaints)
              .where('status', isEqualTo: 'pending')
              .snapshots()
              .map((s) => s.docs.length),
          builder: (context, complaintCountSnap) {
            final pendingComplaints = complaintCountSnap.data ?? 0;
            final complaintsBadge =
                pendingComplaints > 0 ? '$pendingComplaints' : null;

            final adminNavItems = [
              NavItem(Icons.grid_view_rounded, context.l10n.navOverview),
              NavItem(Icons.badge_outlined, context.l10n.navVerify, badge: verifyBadge),
              NavItem(Icons.layers_outlined, context.l10n.navCoverage),
              NavItem(Icons.people_outline, context.l10n.navTeam),
              NavItem(Icons.format_list_bulleted, context.l10n.jobLedgerNav),
              NavItem(Icons.warning_amber_rounded, context.l10n.navDisputes,
                  badge: complaintsBadge),
              NavItem(Icons.tune, context.l10n.navSettings),
            ];

            final screens = [
              const DashboardLiveMapScreen(),
              const NicVerificationWorkspaceScreen(),
              const CategoryDistrictManagementScreen(),
              const AdminManagementScreen(),
              const JobLedgerScreen(),
              const AdminComplaintsScreen(),
              AdminProfileScreen(
                onNavigateToVerifications: () => setState(() => _navIndex = 1),
                onNavigateToAdmins: () => setState(() => _navIndex = 3),
              ),
            ];

            final Widget shell = isMobile
                ? Scaffold(
                    body: SafeArea(
                      child: Column(
                        children: [
                          AdminTopBar(
                            onProfileTap: () => setState(() => _navIndex = 6),
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
                      currentIndex: _navIndex,
                      compact: true,
                      onTap: (i) {
                        if (i == 3 && !roleProvider.isSuperAdmin) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Only Super Admins can access Administrator Management.'),
                              backgroundColor: AppColors.error,
                              duration: Duration(seconds: 2),
                            ),
                          );
                          return;
                        }
                        setState(() => _navIndex = i);
                      },
                    ),
                  )
                : Scaffold(
                    body: Row(
                      children: [
                        AdminSidebar(
                          selectedIndex: _navIndex,
                          onSelect: (i) => setState(() => _navIndex = i),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              AdminTopBar(
                                onProfileTap: () =>
                                    setState(() => _navIndex = 6),
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
