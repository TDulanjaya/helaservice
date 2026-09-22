import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import '../../theme/app_theme.dart';
import '../../state/role_provider.dart';
import '../../features/customer/screens/home_discovery_screen.dart';
import '../../features/provider/screens/provider_dashboard_screen.dart';
import '../../features/admin/admin_shell.dart';

void showRoleSwitchSheet(BuildContext context) {
  final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Switch role',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                'Same account, different way of using HelaService',
                style: TextStyle(
                    fontSize: 12.5, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              _RoleTile(
                icon: Icons.person_outline,
                title: 'Customer',
                subtitle: 'Book and track home services',
                selected: roleProvider.role == AppRole.customer,
                onTap: () => _switchTo(
                    sheetContext, context, roleProvider, AppRole.customer),
              ),
              _RoleTile(
                icon: Icons.build_outlined,
                title: 'Service Provider',
                subtitle: 'Go online and take job requests',
                selected: roleProvider.role == AppRole.provider,
                onTap: () => _switchTo(
                    sheetContext, context, roleProvider, AppRole.provider),
              ),
              _RoleTile(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Admin',
                subtitle: 'Platform back-office tools',
                selected: roleProvider.role == AppRole.admin,
                onTap: () => _switchTo(
                    sheetContext, context, roleProvider, AppRole.admin),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _switchTo(BuildContext sheetContext, BuildContext rootContext,
    RoleProvider roleProvider, AppRole role) {
  roleProvider.setRole(role);
  Navigator.of(sheetContext).pop();

  Widget destination;
  switch (role) {
    case AppRole.customer:
      destination = const HomeDiscoveryScreen();
      break;
    case AppRole.provider:
      destination = const ProviderDashboardScreen();
      break;
    case AppRole.admin:
      destination = const AdminShell();
      break;
  }

  Navigator.of(rootContext).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => destination),
    (route) => false,
  );
}

class _RoleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _RoleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.outline.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color:
                    selected ? AppColors.primary : AppColors.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11.5, color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}
