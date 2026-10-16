import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../models/user_profile.dart';
import '../../../models/admin_user.dart';
import '../../../state/role_provider.dart';
import '../../../repositories/user_repository.dart';
import '../../../services/category_service.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/searchable_select_picker.dart';
import '../../../utils/location_utils.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/app_localizations_helpers.dart';
import '../../../utils/map_launcher.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final _userRepo = UserRepository();
  final _searchController = TextEditingController();
  final _reasonController = TextEditingController();

  String _searchQuery = '';
  String _selectedRoleFilter = 'all'; // all or customer or provider or admin
  String _selectedDistrictFilter = 'all'; // all or specific district name
  String _selectedStatusFilter = 'all'; // all or active or suspended

  @override
  void dispose() {
    _searchController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _showSuspendDialog(UserProfile user, {bool isSuper = false}) {
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    if (!roleProvider.hasAdminPermission(AdminPermission.manageUsers)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.noPermissionForAction),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (isSuper || user.isSuperAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.superAdminCannotBeSuspended),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    _reasonController.clear();
    final String roleLabel;
    if (user.adminRole == AdminRole.superAdmin ||
        isSuper ||
        user.isSuperAdmin) {
      roleLabel = context.l10n.roleSuperAdminBadge;
    } else if (user.adminRole == AdminRole.opsAdmin) {
      roleLabel = context.l10n.roleOpsAdminBadge;
    } else if (user.adminRole == AdminRole.supportAdmin) {
      roleLabel = context.l10n.roleSupportAdminBadge;
    } else if (user.role == AppRole.admin) {
      roleLabel = context.l10n.roleAdmin;
    } else if (user.role == AppRole.provider) {
      roleLabel = context.l10n.custServiceProviderLabel;
    } else {
      roleLabel = context.l10n.roleCustomer;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: context.themeSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: BorderSide(color: context.themeBorder, width: 1.5),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.block_flipped,
                      color: AppColors.error,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${context.l10n.suspendAccount} ($roleLabel)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: context.themeTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(dialogCtx).size.height * 0.7,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.suspendUserConfirmDesc,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.themeTextSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.l10n.enterBanReason,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: context.themeTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _reasonController,
                        maxLines: 3,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: context.themeTextPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: context.l10n.banReasonHint,
                          hintStyle: TextStyle(
                            fontSize: 12.5,
                            color: context.themeTextSecondary
                                .withValues(alpha: 0.6),
                          ),
                          filled: true,
                          fillColor: context.isDark
                              ? context.themeSurfaceLow
                              : const Color(0xFFF7F8FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: context.themeBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: context.themeBorder),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide:
                                BorderSide(color: AppColors.error, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          context.l10n.presetAbusiveComm,
                          context.l10n.presetFraudActivity,
                          context.l10n.presetFailedDispute,
                          context.l10n.presetPolicyViolation,
                        ].map((preset) {
                          return InkWell(
                            onTap: () {
                              setDialogState(() {
                                _reasonController.text = preset;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: context.isDark
                                    ? context.themeSurfaceLow
                                    : const Color(0xFFF1F3F5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: context.themeBorder),
                              ),
                              child: Text(
                                preset,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.themeTextSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(
                    context.l10n.cancel,
                    style: TextStyle(color: context.themeTextSecondary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final roleProvider =
                        Provider.of<RoleProvider>(context, listen: false);
                    if (!roleProvider
                        .hasAdminPermission(AdminPermission.manageUsers)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.l10n.noPermissionForAction),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }
                    final reason = _reasonController.text.trim();
                    if (reason.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text(context.l10n.pleaseEnterSuspensionReason),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }

                    final messenger = ScaffoldMessenger.of(context);
                    final snackMsg = context.l10n.userSuspendedSnack;

                    Navigator.of(dialogCtx).pop();

                    await _userRepo.toggleUserBanStatus(
                      userId: user.id,
                      isBanned: true,
                      reason: reason,
                    );

                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(snackMsg),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  },
                  child: Text(context.l10n.suspendAccount),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showUnbanDialog(UserProfile user) {
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);
    if (!roleProvider.hasAdminPermission(AdminPermission.manageUsers)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.noPermissionForAction),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: context.themeSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: context.themeBorder, width: 1.5),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.unbanAccount,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.themeTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(dialogCtx).size.height * 0.7,
            ),
            child: SingleChildScrollView(
              child: Text(
                context.l10n.confirmUnbanDesc,
                style: TextStyle(
                  fontSize: 13.5,
                  color: context.themeTextSecondary,
                  height: 1.4,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                context.l10n.cancel,
                style: TextStyle(color: context.themeTextSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final roleProvider =
                    Provider.of<RoleProvider>(context, listen: false);
                if (!roleProvider
                    .hasAdminPermission(AdminPermission.manageUsers)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.noPermissionForAction),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }
                final messenger = ScaffoldMessenger.of(context);
                final snackMsg = context.l10n.userRestoredSnack;

                Navigator.of(dialogCtx).pop();

                await _userRepo.toggleUserBanStatus(
                  userId: user.id,
                  isBanned: false,
                );

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(snackMsg),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: Text(context.l10n.unbanAccount),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.themeSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.themeBorder, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.themeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: context.themeTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
    Color? activeColor,
  }) {
    final effectiveActiveColor = activeColor ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? effectiveActiveColor
              : (context.isDark
                  ? context.themeSurfaceLow
                  : const Color(0xFFF1F3F5)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? effectiveActiveColor : context.themeBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : context.themeTextSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : context.themeTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleFilterDisplayLabel(BuildContext context, String roleKey) {
    switch (roleKey) {
      case 'customer':
        return context.l10n.filterCustomers;
      case 'provider':
        return context.l10n.filterProviders;
      case 'admin':
        return context.l10n.roleAllAdmins;
      case 'super_admin':
        return context.l10n.roleSuperAdminBadge;
      case 'ops_admin':
        return context.l10n.roleOpsAdminBadge;
      case 'support_admin':
        return context.l10n.roleSupportAdminBadge;
      case 'all':
      default:
        return context.l10n.allRoles;
    }
  }

  String _getStatusFilterDisplayLabel(BuildContext context, String statusKey) {
    switch (statusKey) {
      case 'active':
        return context.l10n.statusActive;
      case 'suspended':
        return context.l10n.statusSuspended;
      case 'all':
      default:
        return context.l10n.allStatuses;
    }
  }

  Widget _buildCompactFilterDropdown({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String selectedLabel,
    required bool isFiltered,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isFiltered
              ? AppColors.primary.withValues(alpha: 0.12)
              : (context.isDark
                  ? context.themeSurfaceLow
                  : const Color(0xFFF1F3F5)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isFiltered ? AppColors.primary : context.themeBorder,
            width: isFiltered ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color:
                  isFiltered ? AppColors.primary : context.themeTextSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isFiltered
                          ? AppColors.primary
                          : context.themeTextSecondary,
                    ),
                  ),
                  Text(
                    selectedLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isFiltered
                          ? AppColors.primary
                          : context.themeTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color:
                  isFiltered ? AppColors.primary : context.themeTextSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showRoleFilterBottomSheet({
    required BuildContext context,
    required int totalCount,
    required int customerCount,
    required int providerCount,
    required int adminCount,
    required int superAdminCount,
    required int opsAdminCount,
    required int supportAdminCount,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.themeSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bCtx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(bCtx).size.height * 0.75,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.themeBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.filterByRole,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: context.themeTextPrimary,
                        ),
                      ),
                      if (_selectedRoleFilter != 'all')
                        TextButton(
                          onPressed: () {
                            setState(() => _selectedRoleFilter = 'all');
                            Navigator.pop(bCtx);
                          },
                          child: Text(
                            context.l10n.clearFilters,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFilterOptionTile(
                    bCtx,
                    title: context.l10n.allRoles,
                    count: totalCount,
                    icon: Icons.grid_view_rounded,
                    isSelected: _selectedRoleFilter == 'all',
                    onTap: () {
                      setState(() => _selectedRoleFilter = 'all');
                      Navigator.pop(bCtx);
                    },
                  ),
                  _buildFilterOptionTile(
                    bCtx,
                    title: context.l10n.filterCustomers,
                    count: customerCount,
                    icon: Icons.person_outline_rounded,
                    isSelected: _selectedRoleFilter == 'customer',
                    color: Colors.blue,
                    onTap: () {
                      setState(() => _selectedRoleFilter = 'customer');
                      Navigator.pop(bCtx);
                    },
                  ),
                  _buildFilterOptionTile(
                    bCtx,
                    title: context.l10n.filterProviders,
                    count: providerCount,
                    icon: Icons.handyman_outlined,
                    isSelected: _selectedRoleFilter == 'provider',
                    color: Colors.purple,
                    onTap: () {
                      setState(() => _selectedRoleFilter = 'provider');
                      Navigator.pop(bCtx);
                    },
                  ),
                  const Divider(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      context.l10n.roleAllAdmins.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: context.themeTextSecondary,
                      ),
                    ),
                  ),
                  _buildFilterOptionTile(
                    bCtx,
                    title: context.l10n.roleAllAdmins,
                    count: adminCount,
                    icon: Icons.shield_outlined,
                    isSelected: _selectedRoleFilter == 'admin',
                    color: Colors.indigo,
                    onTap: () {
                      setState(() => _selectedRoleFilter = 'admin');
                      Navigator.pop(bCtx);
                    },
                  ),
                  _buildFilterOptionTile(
                    bCtx,
                    title: context.l10n.roleSuperAdminBadge,
                    count: superAdminCount,
                    icon: Icons.shield_rounded,
                    isSelected: _selectedRoleFilter == 'super_admin',
                    color: Colors.amber.shade800,
                    onTap: () {
                      setState(() => _selectedRoleFilter = 'super_admin');
                      Navigator.pop(bCtx);
                    },
                  ),
                  _buildFilterOptionTile(
                    bCtx,
                    title: context.l10n.roleOpsAdminBadge,
                    count: opsAdminCount,
                    icon: Icons.settings_suggest_rounded,
                    isSelected: _selectedRoleFilter == 'ops_admin',
                    color: Colors.indigo,
                    onTap: () {
                      setState(() => _selectedRoleFilter = 'ops_admin');
                      Navigator.pop(bCtx);
                    },
                  ),
                  _buildFilterOptionTile(
                    bCtx,
                    title: context.l10n.roleSupportAdminBadge,
                    count: supportAdminCount,
                    icon: Icons.support_agent_rounded,
                    isSelected: _selectedRoleFilter == 'support_admin',
                    color: const Color(0xFF0D9488),
                    onTap: () {
                      setState(() => _selectedRoleFilter = 'support_admin');
                      Navigator.pop(bCtx);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showStatusFilterBottomSheet({
    required BuildContext context,
    required int totalCount,
    required int activeCount,
    required int suspendedCount,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.themeSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bCtx) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(bCtx).size.height * 0.65,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.themeBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.filterByStatus,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: context.themeTextPrimary,
                        ),
                      ),
                      if (_selectedStatusFilter != 'all')
                        TextButton(
                          onPressed: () {
                            setState(() => _selectedStatusFilter = 'all');
                            Navigator.pop(bCtx);
                          },
                          child: Text(
                            context.l10n.clearFilters,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFilterOptionTile(
                    bCtx,
                    title: context.l10n.allStatuses,
                    count: totalCount,
                    icon: Icons.tune_rounded,
                    isSelected: _selectedStatusFilter == 'all',
                    onTap: () {
                      setState(() => _selectedStatusFilter = 'all');
                      Navigator.pop(bCtx);
                    },
                  ),
                  _buildFilterOptionTile(
                    bCtx,
                    title: context.l10n.statusActive,
                    count: activeCount,
                    icon: Icons.check_circle_outline_rounded,
                    isSelected: _selectedStatusFilter == 'active',
                    color: const Color(0xFF2E7D32),
                    onTap: () {
                      setState(() => _selectedStatusFilter = 'active');
                      Navigator.pop(bCtx);
                    },
                  ),
                  _buildFilterOptionTile(
                    bCtx,
                    title: context.l10n.statusSuspended,
                    count: suspendedCount,
                    icon: Icons.block_flipped,
                    isSelected: _selectedStatusFilter == 'suspended',
                    color: AppColors.error,
                    onTap: () {
                      setState(() => _selectedStatusFilter = 'suspended');
                      Navigator.pop(bCtx);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterOptionTile(
    BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
    required bool isSelected,
    Color? color,
    required VoidCallback onTap,
  }) {
    final effectiveColor = color ?? AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected
              ? effectiveColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? effectiveColor.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? effectiveColor : context.themeTextSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? effectiveColor : context.themeTextPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? effectiveColor
                    : (context.isDark
                        ? context.themeSurfaceLow
                        : const Color(0xFFECEFF1)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : context.themeTextSecondary,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_rounded, size: 18, color: effectiveColor),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterTags(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (_selectedRoleFilter != 'all')
          Chip(
            avatar: const Icon(Icons.badge_outlined, size: 14),
            label:
                Text(_getRoleFilterDisplayLabel(context, _selectedRoleFilter)),
            deleteIcon: const Icon(Icons.close_rounded, size: 14),
            onDeleted: () => setState(() => _selectedRoleFilter = 'all'),
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
        if (_selectedStatusFilter != 'all')
          Chip(
            avatar: const Icon(Icons.toggle_on_outlined, size: 14),
            label: Text(
                _getStatusFilterDisplayLabel(context, _selectedStatusFilter)),
            deleteIcon: const Icon(Icons.close_rounded, size: 14),
            onDeleted: () => setState(() => _selectedStatusFilter = 'all'),
            backgroundColor: _selectedStatusFilter == 'suspended'
                ? AppColors.error.withValues(alpha: 0.1)
                : const Color(0xFF2E7D32).withValues(alpha: 0.1),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _selectedStatusFilter == 'suspended'
                  ? AppColors.error
                  : const Color(0xFF2E7D32),
            ),
            side: BorderSide(
              color: _selectedStatusFilter == 'suspended'
                  ? AppColors.error.withValues(alpha: 0.2)
                  : const Color(0xFF2E7D32).withValues(alpha: 0.2),
            ),
          ),
        if (_selectedDistrictFilter != 'all')
          Chip(
            avatar: const Icon(Icons.location_on_outlined, size: 14),
            label: Text(
                LocalizedData.getDistrict(context, _selectedDistrictFilter)),
            deleteIcon: const Icon(Icons.close_rounded, size: 14),
            onDeleted: () => setState(() => _selectedDistrictFilter = 'all'),
            backgroundColor: context.themeSurfaceLow,
            labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.themeTextPrimary),
            side: BorderSide(color: context.themeBorder),
          ),
        TextButton(
          onPressed: () => setState(() {
            _selectedRoleFilter = 'all';
            _selectedStatusFilter = 'all';
            _selectedDistrictFilter = 'all';
          }),
          child: Text(
            context.l10n.clearFilters,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final districts = LocationUtils.districtCoordinates.keys.toList();
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isWide = screenWidth >= 600;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('superAdmins').snapshots(),
      builder: (context, superAdminSnap) {
        final superAdminUids =
            superAdminSnap.data?.docs.map((d) => d.id).toSet() ?? <String>{};

        bool checkIsSuperAdmin(UserProfile u) {
          return u.isSuperAdmin || superAdminUids.contains(u.id);
        }

        return StreamBuilder<List<UserProfile>>(
          stream: _userRepo.streamAllUnifiedUsers(),
          builder: (context, snapshot) {
            final allUsers = snapshot.data ?? [];
            final totalCount = allUsers.length;
            final customerCount =
                allUsers.where((u) => u.role == AppRole.customer).length;
            final providerCount =
                allUsers.where((u) => u.role == AppRole.provider).length;
            final suspendedCount = allUsers.where((u) => u.isBanned).length;
            final activeCount = allUsers.where((u) => !u.isBanned).length;
            final adminCount = allUsers
                .where((u) => u.role == AppRole.admin || checkIsSuperAdmin(u))
                .length;
            final superAdminCount = allUsers
                .where((u) =>
                    checkIsSuperAdmin(u) || u.adminRole == AdminRole.superAdmin)
                .length;
            final opsAdminCount =
                allUsers.where((u) => u.adminRole == AdminRole.opsAdmin).length;
            final supportAdminCount = allUsers
                .where((u) => u.adminRole == AdminRole.supportAdmin)
                .length;

            // apply filters
            final filteredUsers = allUsers.where((user) {
              final isSuper = checkIsSuperAdmin(user) ||
                  user.adminRole == AdminRole.superAdmin;
              final isOps = user.adminRole == AdminRole.opsAdmin;
              final isSupport = user.adminRole == AdminRole.supportAdmin;
              final isAdmin = user.role == AppRole.admin || isSuper;

              // role filter
              if (_selectedRoleFilter == 'customer' &&
                  user.role != AppRole.customer) {
                return false;
              }
              if (_selectedRoleFilter == 'provider' &&
                  user.role != AppRole.provider) {
                return false;
              }
              if (_selectedRoleFilter == 'admin' && !isAdmin) {
                return false;
              }
              if (_selectedRoleFilter == 'super_admin' && !isSuper) {
                return false;
              }
              if (_selectedRoleFilter == 'ops_admin' && !isOps) {
                return false;
              }
              if (_selectedRoleFilter == 'support_admin' && !isSupport) {
                return false;
              }

              // district filter
              if (_selectedDistrictFilter != 'all') {
                if (user.district == null ||
                    user.district!.toLowerCase() !=
                        _selectedDistrictFilter.toLowerCase()) {
                  return false;
                }
              }

              // status filter
              if (_selectedStatusFilter == 'active' && user.isBanned) {
                return false;
              }
              if (_selectedStatusFilter == 'suspended' && !user.isBanned) {
                return false;
              }

              // search query
              if (_searchQuery.isNotEmpty) {
                final q = _searchQuery.toLowerCase();
                final nameMatch = user.displayName.toLowerCase().contains(q);
                final emailMatch = user.email.toLowerCase().contains(q);
                final phoneMatch = (user.phone ?? '').toLowerCase().contains(q);
                final nicMatch = (user.nic ?? '').toLowerCase().contains(q);
                if (!nameMatch && !emailMatch && !phoneMatch && !nicMatch) {
                  return false;
                }
              }

              return true;
            }).toList();

            return Scaffold(
              backgroundColor: context.themeBg,
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // header row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.manage_accounts_outlined,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.navUserManagement,
                                style: TextStyle(
                                  fontSize: isDesktop ? 22 : 19,
                                  fontWeight: FontWeight.w800,
                                  color: context.themeTextPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                context.l10n.navUserManagementSubtitle,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: context.themeTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // stat cards
                    if (isWide)
                      Row(
                        children: [
                          _buildStatCard(
                            context,
                            label: context.l10n.totalUsers,
                            value: '$totalCount',
                            icon: Icons.people_alt_outlined,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            context,
                            label: context.l10n.activeCustomers,
                            value: '$customerCount',
                            icon: Icons.person_outline_rounded,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            context,
                            label: context.l10n.activeProviders,
                            value: '$providerCount',
                            icon: Icons.build_outlined,
                            color: Colors.purple,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            context,
                            label: context.l10n.suspendedAccounts,
                            value: '$suspendedCount',
                            icon: Icons.block_flipped,
                            color: AppColors.error,
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          Row(
                            children: [
                              _buildStatCard(
                                context,
                                label: context.l10n.totalUsers,
                                value: '$totalCount',
                                icon: Icons.people_alt_outlined,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 10),
                              _buildStatCard(
                                context,
                                label: context.l10n.activeCustomers,
                                value: '$customerCount',
                                icon: Icons.person_outline_rounded,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _buildStatCard(
                                context,
                                label: context.l10n.activeProviders,
                                value: '$providerCount',
                                icon: Icons.build_outlined,
                                color: Colors.purple,
                              ),
                              const SizedBox(width: 10),
                              _buildStatCard(
                                context,
                                label: context.l10n.suspendedAccounts,
                                value: '$suspendedCount',
                                icon: Icons.block_flipped,
                                color: AppColors.error,
                              ),
                            ],
                          ),
                        ],
                      ),

                    const SizedBox(height: 20),

                    // controls container
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: context.themeSurface,
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: context.themeBorder, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // search bar
                          TextField(
                            controller: _searchController,
                            onChanged: (val) =>
                                setState(() => _searchQuery = val.trim()),
                            style: TextStyle(
                              color: context.themeTextPrimary,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: context.l10n.searchUsersHint,
                              hintStyle: TextStyle(
                                color: context.themeTextSecondary
                                    .withValues(alpha: 0.6),
                                fontSize: 13.5,
                              ),
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: context.themeTextSecondary,
                                size: 20,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded,
                                          size: 18),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: context.isDark
                                  ? context.themeSurfaceLow
                                  : const Color(0xFFF7F8FA),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    BorderSide(color: context.themeBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide:
                                    BorderSide(color: context.themeBorder),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(14)),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (!isDesktop) ...[
                            // role and status filters
                            Row(
                              children: [
                                Expanded(
                                  child: _buildCompactFilterDropdown(
                                    context: context,
                                    icon: Icons.badge_outlined,
                                    title: context.l10n.filterByRole,
                                    selectedLabel: _getRoleFilterDisplayLabel(
                                        context, _selectedRoleFilter),
                                    isFiltered: _selectedRoleFilter != 'all',
                                    onTap: () => _showRoleFilterBottomSheet(
                                      context: context,
                                      totalCount: totalCount,
                                      customerCount: customerCount,
                                      providerCount: providerCount,
                                      adminCount: adminCount,
                                      superAdminCount: superAdminCount,
                                      opsAdminCount: opsAdminCount,
                                      supportAdminCount: supportAdminCount,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildCompactFilterDropdown(
                                    context: context,
                                    icon: Icons.toggle_on_outlined,
                                    title: context.l10n.filterByStatus,
                                    selectedLabel: _getStatusFilterDisplayLabel(
                                        context, _selectedStatusFilter),
                                    isFiltered: _selectedStatusFilter != 'all',
                                    onTap: () => _showStatusFilterBottomSheet(
                                      context: context,
                                      totalCount: totalCount,
                                      activeCount: activeCount,
                                      suspendedCount: suspendedCount,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                  maxWidth: double.infinity),
                              child: SearchableSelectPicker<String>(
                                label: '',
                                selectedValue: _selectedDistrictFilter,
                                prefixIcon: Icons.map_outlined,
                                isDarkField: context.isDark,
                                modalTitle: context.l10n.filterByDistrictTitle,
                                searchHint: context.l10n.searchDistrictHintText,
                                items: [
                                  SearchableSelectItem<String>(
                                    value: 'all',
                                    label: context.l10n.allDistricts,
                                    icon: Icons.public_rounded,
                                  ),
                                  ...districts.map((d) {
                                    final localized =
                                        LocalizedData.getDistrict(context, d);
                                    final sin =
                                        LocalizedData.districts[d]?['si'] ?? '';
                                    final tam =
                                        LocalizedData.districts[d]?['ta'] ?? '';
                                    return SearchableSelectItem<String>(
                                      value: d,
                                      label: localized,
                                      subtitle: localized != d ? d : null,
                                      icon: Icons.location_on_outlined,
                                      searchTerms: [d, sin, tam],
                                    );
                                  }),
                                ],
                                onSelected: (val) => setState(
                                    () => _selectedDistrictFilter = val),
                              ),
                            ),
                          ] else ...[
                            // desktop chip layout
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.badge_outlined,
                                      size: 14,
                                      color: context.themeTextSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      context.l10n.filterByRole,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: context.themeTextSecondary,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    children: [
                                      _buildFilterChip(
                                        context: context,
                                        label: context.l10n.allRoles,
                                        icon: Icons.grid_view_rounded,
                                        isSelected:
                                            _selectedRoleFilter == 'all',
                                        onTap: () => setState(
                                            () => _selectedRoleFilter = 'all'),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildFilterChip(
                                        context: context,
                                        label: context.l10n.filterCustomers,
                                        icon: Icons.person_outline_rounded,
                                        isSelected:
                                            _selectedRoleFilter == 'customer',
                                        onTap: () => setState(() =>
                                            _selectedRoleFilter = 'customer'),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildFilterChip(
                                        context: context,
                                        label: context.l10n.filterProviders,
                                        icon: Icons.handyman_outlined,
                                        isSelected:
                                            _selectedRoleFilter == 'provider',
                                        onTap: () => setState(() =>
                                            _selectedRoleFilter = 'provider'),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildFilterChip(
                                        context: context,
                                        label: context.l10n.roleAllAdmins,
                                        icon: Icons.shield_outlined,
                                        isSelected:
                                            _selectedRoleFilter == 'admin',
                                        onTap: () => setState(() =>
                                            _selectedRoleFilter = 'admin'),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildFilterChip(
                                        context: context,
                                        label: context.l10n.roleSuperAdminBadge,
                                        icon: Icons.shield_rounded,
                                        isSelected: _selectedRoleFilter ==
                                            'super_admin',
                                        activeColor: Colors.amber.shade800,
                                        onTap: () => setState(() =>
                                            _selectedRoleFilter =
                                                'super_admin'),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildFilterChip(
                                        context: context,
                                        label: context.l10n.roleOpsAdminBadge,
                                        icon: Icons.settings_suggest_rounded,
                                        isSelected:
                                            _selectedRoleFilter == 'ops_admin',
                                        activeColor: Colors.indigo,
                                        onTap: () => setState(() =>
                                            _selectedRoleFilter = 'ops_admin'),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildFilterChip(
                                        context: context,
                                        label:
                                            context.l10n.roleSupportAdminBadge,
                                        icon: Icons.support_agent_rounded,
                                        isSelected: _selectedRoleFilter ==
                                            'support_admin',
                                        activeColor: const Color(0xFF0D9488),
                                        onTap: () => setState(() =>
                                            _selectedRoleFilter =
                                                'support_admin'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.toggle_on_outlined,
                                      size: 14,
                                      color: context.themeTextSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      context.l10n.filterByStatus,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: context.themeTextSecondary,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    children: [
                                      _buildFilterChip(
                                        context: context,
                                        label: context.l10n.filterAll,
                                        icon: Icons.tune_rounded,
                                        isSelected:
                                            _selectedStatusFilter == 'all',
                                        onTap: () => setState(() =>
                                            _selectedStatusFilter = 'all'),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildFilterChip(
                                        context: context,
                                        label: context.l10n.statusActive,
                                        icon:
                                            Icons.check_circle_outline_rounded,
                                        isSelected:
                                            _selectedStatusFilter == 'active',
                                        activeColor: const Color(0xFF2E7D32),
                                        onTap: () => setState(() =>
                                            _selectedStatusFilter = 'active'),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildFilterChip(
                                        context: context,
                                        label: context.l10n.statusSuspended,
                                        icon: Icons.block_flipped,
                                        isSelected: _selectedStatusFilter ==
                                            'suspended',
                                        activeColor: AppColors.error,
                                        onTap: () => setState(() =>
                                            _selectedStatusFilter =
                                                'suspended'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 340),
                              child: SearchableSelectPicker<String>(
                                label: '',
                                selectedValue: _selectedDistrictFilter,
                                prefixIcon: Icons.map_outlined,
                                isDarkField: context.isDark,
                                modalTitle: context.l10n.filterByDistrictTitle,
                                searchHint: context.l10n.searchDistrictHintText,
                                items: [
                                  SearchableSelectItem<String>(
                                    value: 'all',
                                    label: context.l10n.allDistricts,
                                    icon: Icons.public_rounded,
                                  ),
                                  ...districts.map((d) {
                                    final localized =
                                        LocalizedData.getDistrict(context, d);
                                    final sin =
                                        LocalizedData.districts[d]?['si'] ?? '';
                                    final tam =
                                        LocalizedData.districts[d]?['ta'] ?? '';
                                    return SearchableSelectItem<String>(
                                      value: d,
                                      label: localized,
                                      subtitle: localized != d ? d : null,
                                      icon: Icons.location_on_outlined,
                                      searchTerms: [d, sin, tam],
                                    );
                                  }),
                                ],
                                onSelected: (val) => setState(
                                    () => _selectedDistrictFilter = val),
                              ),
                            ),
                          ],

                          if (_selectedRoleFilter != 'all' ||
                              _selectedStatusFilter != 'all' ||
                              _selectedDistrictFilter != 'all') ...[
                            const SizedBox(height: 12),
                            _buildActiveFilterTags(context),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // users list
                    if (filteredUsers.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(40),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search_outlined,
                              size: 48,
                              color: context.themeTextSecondary
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              context.l10n.noUsersFound,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: context.themeTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredUsers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (ctx, idx) {
                          final user = filteredUsers[idx];
                          final isBanned = user.isBanned;
                          final isSuper = checkIsSuperAdmin(user) ||
                              user.adminRole == AdminRole.superAdmin;
                          final isOpsAdmin =
                              user.adminRole == AdminRole.opsAdmin;
                          final isSupportAdmin =
                              user.adminRole == AdminRole.supportAdmin;
                          final isOtherAdmin = user.role == AppRole.admin &&
                              !isSuper &&
                              !isOpsAdmin &&
                              !isSupportAdmin;
                          final isProvider = user.role == AppRole.provider;
                          final isAdmin = isSuper ||
                              isOpsAdmin ||
                              isSupportAdmin ||
                              isOtherAdmin;

                          Color roleColor;
                          Color roleBgColor;
                          String roleLabel;
                          IconData roleIcon;

                          if (isSuper) {
                            roleColor = Colors.amber.shade800;
                            roleBgColor = Colors.amber.withValues(alpha: 0.15);
                            roleLabel = context.l10n.roleSuperAdminBadge;
                            roleIcon = Icons.shield_rounded;
                          } else if (isOpsAdmin) {
                            roleColor = Colors.indigo;
                            roleBgColor = Colors.indigo.withValues(alpha: 0.12);
                            roleLabel = context.l10n.roleOpsAdminBadge;
                            roleIcon = Icons.settings_suggest_rounded;
                          } else if (isSupportAdmin) {
                            roleColor = const Color(0xFF0D9488);
                            roleBgColor =
                                const Color(0xFF0D9488).withValues(alpha: 0.12);
                            roleLabel = context.l10n.roleSupportAdminBadge;
                            roleIcon = Icons.support_agent_rounded;
                          } else if (isAdmin) {
                            roleColor = Colors.indigo;
                            roleBgColor = Colors.indigo.withValues(alpha: 0.12);
                            roleLabel = context.l10n.roleAdmin;
                            roleIcon = Icons.shield_outlined;
                          } else if (isProvider) {
                            roleColor = Colors.purple;
                            roleBgColor = Colors.purple.withValues(alpha: 0.12);
                            roleLabel = context.l10n.custServiceProviderLabel;
                            roleIcon = Icons.handyman_outlined;
                          } else {
                            roleColor = Colors.blue;
                            roleBgColor = Colors.blue.withValues(alpha: 0.12);
                            roleLabel = context.l10n.roleCustomer;
                            roleIcon = Icons.person_outline_rounded;
                          }

                          return Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: context.themeSurface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isBanned
                                    ? AppColors.error.withValues(alpha: 0.4)
                                    : context.themeBorder,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                      alpha: context.isDark ? 0.2 : 0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // user details row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    UserAvatar(
                                      uid: user.id,
                                      displayName: user.displayName,
                                      email: user.email,
                                      radius: 24,
                                      backgroundColor: roleBgColor,
                                      textColor: roleColor,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          () {
                                            final roleBadge = Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: roleBgColor,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(roleIcon,
                                                      size: 12,
                                                      color: roleColor),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    roleLabel,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: roleColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );

                                            final statusBadge = Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isBanned
                                                    ? AppColors.error
                                                        .withValues(alpha: 0.12)
                                                    : AppColors.success
                                                        .withValues(
                                                            alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                isBanned
                                                    ? context
                                                        .l10n.statusSuspended
                                                    : context.l10n.statusActive,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: isBanned
                                                      ? AppColors.error
                                                      : AppColors.success,
                                                ),
                                              ),
                                            );

                                            if (isDesktop) {
                                              return Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      user.displayName
                                                              .isNotEmpty
                                                          ? user.displayName
                                                          : user.email,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: context
                                                            .themeTextPrimary,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  roleBadge,
                                                  const SizedBox(width: 8),
                                                  statusBadge,
                                                ],
                                              );
                                            } else {
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    user.displayName.isNotEmpty
                                                        ? user.displayName
                                                        : user.email,
                                                    style: TextStyle(
                                                      fontSize: 15.5,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: context
                                                          .themeTextPrimary,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Wrap(
                                                    spacing: 6,
                                                    runSpacing: 4,
                                                    children: [
                                                      roleBadge,
                                                      statusBadge,
                                                    ],
                                                  ),
                                                ],
                                              );
                                            }
                                          }(),
                                          const SizedBox(height: 6),
                                          // contact details
                                          Wrap(
                                            spacing: 12,
                                            runSpacing: 4,
                                            children: [
                                              if (user.email.isNotEmpty)
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.email_outlined,
                                                      size: 14,
                                                      color: context
                                                          .themeTextSecondary,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      user.email,
                                                      style: TextStyle(
                                                        fontSize: 12.5,
                                                        color: context
                                                            .themeTextSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              if (user.phone != null &&
                                                  user.phone!.isNotEmpty)
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.phone_outlined,
                                                      size: 14,
                                                      color: context
                                                          .themeTextSecondary,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      user.phone!,
                                                      style: TextStyle(
                                                        fontSize: 12.5,
                                                        color: context
                                                            .themeTextSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              if (user.district != null &&
                                                  user.district!.isNotEmpty)
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .location_on_outlined,
                                                      size: 14,
                                                      color: context
                                                          .themeTextSecondary,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      LocalizedData.getDistrict(
                                                          context,
                                                          user.district!),
                                                      style: TextStyle(
                                                        fontSize: 12.5,
                                                        color: context
                                                            .themeTextSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              if (isProvider &&
                                                  user.serviceCategory !=
                                                      null &&
                                                  user.serviceCategory!
                                                      .isNotEmpty)
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.handyman_outlined,
                                                      size: 14,
                                                      color: context
                                                          .themeTextSecondary,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      CategoryService.instance
                                                          .nameOf(
                                                              user.serviceCategory!,
                                                              context: context),
                                                      style: TextStyle(
                                                        fontSize: 12.5,
                                                        color: context
                                                            .themeTextSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (isProvider)
                                  _ProviderArrivalStatsWidget(
                                      providerId: user.id),

                                // ban reason banner
                                if (isBanned) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.error
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: AppColors.error
                                            .withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          size: 16,
                                          color: AppColors.error,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${context.l10n.reasonLabel}: ${user.banReason?.isNotEmpty == true ? user.banReason : context.l10n.suspendedByAdmin}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 14),
                                Divider(
                                  color: context.themeBorder,
                                  thickness: 1,
                                  height: 1,
                                ),
                                const SizedBox(height: 12),

                                // action bar
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (user.phone != null &&
                                        user.phone!.trim().isNotEmpty) ...[
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              context.themeTextPrimary,
                                          side: BorderSide(
                                              color: context.themeBorder),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: () =>
                                            MapLauncher.openPhoneCall(
                                                user.phone!),
                                        icon: const Icon(Icons.phone_outlined,
                                            size: 15),
                                        label: Text(context.l10n.call),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    if (isSuper)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: Colors.amber
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: Colors.amber
                                                .withValues(alpha: 0.35),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.shield_rounded,
                                                size: 15,
                                                color: Colors.amber.shade800),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${context.l10n.teamProtected} (${context.l10n.roleSuperAdminBadge})',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.amber.shade800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else if (isBanned)
                                      () {
                                        final roleProvider =
                                            Provider.of<RoleProvider>(context,
                                                listen: false);
                                        final canManageUsers =
                                            roleProvider.hasAdminPermission(
                                                AdminPermission.manageUsers);
                                        return ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: canManageUsers
                                                ? AppColors.success
                                                : (context.isDark
                                                    ? Colors.white12
                                                    : Colors.grey.shade300),
                                            foregroundColor: canManageUsers
                                                ? Colors.white
                                                : (context.isDark
                                                    ? Colors.white38
                                                    : Colors.grey.shade600),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: () {
                                            if (!canManageUsers) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(context.l10n
                                                      .noPermissionForAction),
                                                  backgroundColor:
                                                      AppColors.error,
                                                ),
                                              );
                                              return;
                                            }
                                            _showUnbanDialog(user);
                                          },
                                          icon: Icon(
                                            canManageUsers
                                                ? Icons.lock_open_rounded
                                                : Icons.lock_outline,
                                            size: 15,
                                          ),
                                          label:
                                              Text(context.l10n.unbanAccount),
                                        );
                                      }()
                                    else
                                      () {
                                        final roleProvider =
                                            Provider.of<RoleProvider>(context,
                                                listen: false);
                                        final canManageUsers =
                                            roleProvider.hasAdminPermission(
                                                AdminPermission.manageUsers);
                                        return ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: canManageUsers
                                                ? AppColors.error
                                                : (context.isDark
                                                    ? Colors.white12
                                                    : Colors.grey.shade300),
                                            foregroundColor: canManageUsers
                                                ? Colors.white
                                                : (context.isDark
                                                    ? Colors.white38
                                                    : Colors.grey.shade600),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: () {
                                            if (!canManageUsers) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(context.l10n
                                                      .noPermissionForAction),
                                                  backgroundColor:
                                                      AppColors.error,
                                                ),
                                              );
                                              return;
                                            }
                                            _showSuspendDialog(user,
                                                isSuper: isSuper);
                                          },
                                          icon: Icon(
                                            canManageUsers
                                                ? Icons.block_flipped
                                                : Icons.lock_outline,
                                            size: 15,
                                          ),
                                          label:
                                              Text(context.l10n.suspendAccount),
                                        );
                                      }(),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// 90-day provider arrival & reliability counts
class _ProviderArrivalStatsWidget extends StatefulWidget {
  final String providerId;

  const _ProviderArrivalStatsWidget({required this.providerId});

  @override
  State<_ProviderArrivalStatsWidget> createState() =>
      _ProviderArrivalStatsWidgetState();
}

class _ProviderArrivalStatsWidgetState
    extends State<_ProviderArrivalStatsWidget> {
  late Future<
          ({int noShows, int arrivalDenials, int mockedGps, int outsideZone})>
      _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchStats();
  }

  @override
  void didUpdateWidget(covariant _ProviderArrivalStatsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.providerId != widget.providerId) {
      _statsFuture = _fetchStats();
    }
  }

  Future<({int noShows, int arrivalDenials, int mockedGps, int outsideZone})>
      _fetchStats() async {
    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: 90)),
    );
    final bookingsCol = FirebaseFirestore.instance.collection('bookings');

    final results = await Future.wait([
      bookingsCol
          .where('providerId', isEqualTo: widget.providerId)
          .where('noShow', isEqualTo: true)
          .where('createdAt', isGreaterThanOrEqualTo: cutoff)
          .count()
          .get(),
      bookingsCol
          .where('providerId', isEqualTo: widget.providerId)
          .where('arrivalStatus', isEqualTo: 'denied')
          .where('createdAt', isGreaterThanOrEqualTo: cutoff)
          .count()
          .get(),
      bookingsCol
          .where('providerId', isEqualTo: widget.providerId)
          .where('arrivalMocked', isEqualTo: true)
          .where('createdAt', isGreaterThanOrEqualTo: cutoff)
          .count()
          .get(),
      bookingsCol
          .where('providerId', isEqualTo: widget.providerId)
          .where('arrivalOutsideZone', isEqualTo: true)
          .where('createdAt', isGreaterThanOrEqualTo: cutoff)
          .count()
          .get(),
    ]);

    return (
      noShows: results[0].count ?? 0,
      arrivalDenials: results[1].count ?? 0,
      mockedGps: results[2].count ?? 0,
      outsideZone: results[3].count ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<
        ({int noShows, int arrivalDenials, int mockedGps, int outsideZone})>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;

        Widget buildBadge({
          required String label,
          required int count,
          required IconData icon,
          required Color activeColor,
        }) {
          final isFlagged = count > 0;
          final color = isFlagged ? activeColor : context.themeTextSecondary;
          final bg = isFlagged
              ? activeColor.withValues(alpha: 0.12)
              : (context.isDark
                  ? context.themeSurfaceLow
                  : const Color(0xFFF1F3F5));

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isFlagged
                    ? activeColor.withValues(alpha: 0.35)
                    : context.themeBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 5),
                Text(
                  '$label: $count',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isFlagged ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.isDark
                ? context.themeSurfaceLow.withValues(alpha: 0.5)
                : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.themeBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history_toggle_off_rounded,
                    size: 15,
                    color: context.themeTextSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.providerReliability90Days,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.themeTextPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  buildBadge(
                    label: context.l10n.providerNoShowsCount,
                    count: data.noShows,
                    icon: Icons.person_off_rounded,
                    activeColor: AppColors.error,
                  ),
                  buildBadge(
                    label: context.l10n.providerArrivalDenialsCount,
                    count: data.arrivalDenials,
                    icon: Icons.cancel_outlined,
                    activeColor: AppColors.error,
                  ),
                  buildBadge(
                    label: context.l10n.providerMockedGpsCount,
                    count: data.mockedGps,
                    icon: Icons.gps_off_rounded,
                    activeColor: AppColors.error,
                  ),
                  buildBadge(
                    label: context.l10n.providerOutsideZoneCount,
                    count: data.outsideZone,
                    icon: Icons.wrong_location_rounded,
                    activeColor: AppColors.warning,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
