import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import '../../theme/app_theme.dart';
import '../../state/role_provider.dart';
import '../../features/customer/screens/home_discovery_screen.dart';
import '../../features/provider/screens/provider_dashboard_screen.dart';
import '../../features/admin/admin_shell.dart';
import '../../utils/l10n_extension.dart';

void showRoleSwitchSheet(BuildContext context) {
  final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
  final isAuthorizedAdmin = roleProvider.isAuthorizedAdmin;
  final isApprovedProvider = roleProvider.isApprovedProvider;
  final isDesktop = MediaQuery.of(context).size.width >= 600;

  Widget buildContent(BuildContext popContext) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.switchRole,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.themeInk,
              ),
            ),
            if (isDesktop)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.of(popContext).pop(),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          isAuthorizedAdmin
              ? context.l10n.roleSwitchAdminOnlyDesc
              : context.l10n.roleSwitchDesc,
          style: TextStyle(
            fontSize: 13,
            color: context.themeTextSecondary,
          ),
        ),
        const SizedBox(height: 20),
        _RoleTile(
          icon: Icons.person_outline_rounded,
          title: context.l10n.roleCustomer,
          subtitle: context.l10n.roleCustomerSubtitle,
          selected: roleProvider.role == AppRole.customer,
          onTap: () => _switchTo(
            popContext,
            context,
            roleProvider,
            AppRole.customer,
          ),
        ),
        if (isAuthorizedAdmin || isApprovedProvider) ...[
          const SizedBox(height: 10),
          _RoleTile(
            icon: Icons.build_outlined,
            title: context.l10n.roleProvider,
            subtitle: context.l10n.roleProviderSubtitle,
            selected: roleProvider.role == AppRole.provider,
            onTap: () => _switchTo(
              popContext,
              context,
              roleProvider,
              AppRole.provider,
            ),
          ),
        ],
        if (isAuthorizedAdmin) ...[
          const SizedBox(height: 10),
          _RoleTile(
            icon: Icons.admin_panel_settings_outlined,
            title: context.l10n.roleAdmin,
            subtitle: context.l10n.roleSwitchAdminOnlyDesc,
            selected: roleProvider.role == AppRole.admin,
            onTap: () => _switchTo(
              popContext,
              context,
              roleProvider,
              AppRole.admin,
            ),
          ),
        ],
      ],
    );
  }

  if (isDesktop) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: context.themeSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: context.themeBorder, width: 1.5),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: buildContent(dialogContext),
            ),
          ),
        );
      },
    );
  } else {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.themeSurface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: buildContent(sheetContext),
          ),
        );
      },
    );
  }
}

void _switchTo(
  BuildContext sheetContext,
  BuildContext rootContext,
  RoleProvider roleProvider,
  AppRole role,
) {
  if (role == AppRole.admin && !roleProvider.isAuthorizedAdmin) {
    Navigator.of(sheetContext).pop();
    ScaffoldMessenger.of(rootContext).showSnackBar(
      SnackBar(content: Text(rootContext.l10n.unauthorizedAdminAccess)),
    );
    return;
  }

  if (role == AppRole.provider &&
      !roleProvider.isAuthorizedAdmin &&
      !roleProvider.isApprovedProvider) {
    Navigator.of(sheetContext).pop();
    ScaffoldMessenger.of(rootContext).showSnackBar(
      SnackBar(
        content: Text(rootContext.l10n.unauthorizedRoleSwitch),
        backgroundColor: AppColors.error,
      ),
    );
    return;
  }

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
    final activeBg = context.themeAmberTint;
    final inactiveBg = context.themeSoft;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? activeBg : inactiveBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : context.themeBorder,
              width: selected ? 1.6 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.18)
                      : context.themeSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: selected ? AppColors.primary : context.themeInk,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.themeInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.themeTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 22,
                )
              else
                Icon(
                  Icons.circle_outlined,
                  color: context.themeMuted.withValues(alpha: 0.5),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
