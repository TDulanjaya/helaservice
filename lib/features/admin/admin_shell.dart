import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_top_bar.dart';
import 'screens/dashboard_live_map_screen.dart';
import 'screens/nic_verification_workspace_screen.dart';
import 'screens/category_district_management_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _navIndex = 0;

  Widget _body() {
    switch (_navIndex) {
      case 1:
        return const NicVerificationWorkspaceScreen();
      case 2:
        return const CategoryDistrictManagementScreen();
      default:
        return const DashboardLiveMapScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          AdminSidebar(
            selectedIndex: _navIndex,
            onSelect: (i) => setState(() => _navIndex = i > 2 ? _navIndex : i),
          ),
          Expanded(
            child: Column(
              children: [
                const AdminTopBar(),
                Expanded(child: _body()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
