import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import '../../../theme/app_theme.dart';
import '../../../models/admin_user.dart';
import '../../../repositories/admin_repository.dart';
import '../../../state/role_provider.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/admin_l10n_helpers.dart';
import '../widgets/add_admin_dialog.dart';
import '../widgets/edit_admin_permissions_dialog.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/user_avatar.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  AdminRole? _roleFilter;
  AdminStatus? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddAdminDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AddAdminDialog(),
    );
  }

  void _openEditPermissionsDialog(BuildContext context, AdminUser admin) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditAdminPermissionsDialog(admin: admin),
    );
  }

  void _toggleAdminStatus(AdminUser admin, bool makeActive) async {
    if (admin.isSuperAdmin && !makeActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Super Admin accounts cannot be suspended.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    try {
      await AdminRepository().toggleAdminStatus(admin.id, makeActive);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.teamAdminNowStatus(
              admin.displayName,
              adminStatusLabel(context,
                  makeActive ? AdminStatus.active : AdminStatus.suspended),
            ),
          ),
          backgroundColor: makeActive ? AppColors.primary : AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.teamFailedUpdateStatus('$e')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }



  void _confirmRevoke(AdminUser admin) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Text(ctx.l10n.revokeAdminAccess),
          ],
        ),
        content: Text(
          ctx.l10n.revokeAccessConfirm(admin.displayName, admin.email),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AdminRepository().deleteAdmin(admin.id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    context.l10n.adminAccessRevoked(admin.displayName),
                  ),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(ctx.l10n.revokeAccess),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = pv.Provider.of<RoleProvider>(context);
    final isSuperAdmin = roleProvider.isSuperAdmin;
    final currentAdminId = roleProvider.currentAdminUser?.id;
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<AdminUser>>(
          stream: AdminRepository().getAdminsStream(),
          builder: (context, snapshot) {
            final allAdmins = snapshot.data ?? [];
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting &&
                    allAdmins.isEmpty;

            final totalCount = allAdmins.length;
            final superAdminCount =
                allAdmins.where((a) => a.isSuperAdmin).length;
            final activeOpsCount =
                allAdmins.where((a) => a.isActive && !a.isSuperAdmin).length;
            final pendingInviteCount =
                allAdmins.where((a) => a.isInvited).length;

            final filtered = allAdmins.where((admin) {
              if (_searchQuery.isNotEmpty) {
                final matchName = admin.displayName
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase());
                final matchEmail = admin.email
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase());
                if (!matchName && !matchEmail) return false;
              }
              if (_roleFilter != null && admin.role != _roleFilter) {
                return false;
              }
              if (_statusFilter != null && admin.status != _statusFilter) {
                return false;
              }
              return true;
            }).toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isMobile)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.shield_outlined,
                                      color: AppColors.primary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      context.l10n.adminTeamGovernanceTitle,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                        color: context.themeTextPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (isSuperAdmin) ...[
                                const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          _openAddAdminDialog(context),
                                      icon: const Icon(Icons.add_rounded, size: 18),
                                      label: Text(
                                        context.l10n.addNewAdminAction,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: AppColors.ink,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ],
                          )
                        else
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.shield_outlined,
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
                                      context.l10n.adminTeamGovernanceTitle,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                        color: context.themeTextPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSuperAdmin) ...[
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _openAddAdminDialog(context),
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: Text(context.l10n.addNewAdminAction,
                                      style: const TextStyle(fontWeight: FontWeight.w800)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.ink,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        if (!isSuperAdmin) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    size: 18, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    context.l10n.teamReadOnlyView,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final cardWidth = constraints.maxWidth > 700
                            ? (constraints.maxWidth - 36) / 4
                            : (constraints.maxWidth > 320
                                ? (constraints.maxWidth - 12) / 2
                                : constraints.maxWidth);

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: cardWidth,
                              child: _MetricCard(
                                title: context.l10n.totalAdminsCount,
                                value: '$totalCount',
                                subtitle: context.l10n.registeredPlatformAccounts,
                                icon: Icons.badge_outlined,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _MetricCard(
                                title: context.l10n.superAdminsCount,
                                value: '$superAdminCount',
                                subtitle: context.l10n.rootGovernanceLeads,
                                icon: Icons.shield,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _MetricCard(
                                title: context.l10n.activeOperatorsCount,
                                value: '$activeOpsCount',
                                subtitle: context.l10n.dispatchKycDuty,
                                icon: Icons.verified_user_outlined,
                                color: context.themeSuccess,
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: _MetricCard(
                                title: context.l10n.pendingInvitesCount,
                                value: '$pendingInviteCount',
                                subtitle: context.l10n.awaitingFirstSignIn,
                                icon: Icons.mark_email_unread_outlined,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (v) =>
                                    setState(() => _searchQuery = v.trim()),
                                style:
                                    TextStyle(color: context.themeTextPrimary),
                                decoration: InputDecoration(
                                  hintText: context.l10n.searchAdminPlaceholder,
                                  hintStyle: TextStyle(
                                      color: context.themeTextSecondary),
                                  prefixIcon: Icon(Icons.search,
                                      size: 20,
                                      color: context.themeTextSecondary),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(Icons.clear,
                                              size: 18,
                                              color:
                                                  context.themeTextSecondary),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = '');
                                          },
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: context.themeSurfaceLow,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: context.themeBorder,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: context.themeBorder,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Text(
                                context.l10n.roleFilterLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: context.themeTextSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: context.l10n.allRolesFilter,
                                isSelected: _roleFilter == null,
                                onSelected: () =>
                                    setState(() => _roleFilter = null),
                              ),
                              _FilterChip(
                                label: context.l10n.roleSuperAdminBadge,
                                isSelected: _roleFilter == AdminRole.superAdmin,
                                color: AppColors.primary,
                                onSelected: () => setState(
                                    () => _roleFilter = AdminRole.superAdmin),
                              ),
                              _FilterChip(
                                label: context.l10n.roleOpsAdminBadge,
                                isSelected: _roleFilter == AdminRole.opsAdmin,
                                color: AppColors.primary,
                                onSelected: () => setState(
                                    () => _roleFilter = AdminRole.opsAdmin),
                              ),
                              _FilterChip(
                                label: context.l10n.roleSupportAdminBadge,
                                isSelected:
                                    _roleFilter == AdminRole.supportAdmin,
                                color: const Color(0xFF4A6572),
                                onSelected: () => setState(
                                    () => _roleFilter = AdminRole.supportAdmin),
                              ),
                              const SizedBox(width: 14),
                              Container(
                                width: 1,
                                height: 20,
                                color: context.themeBorder,
                              ),
                              const SizedBox(width: 14),
                              Text(
                                context.l10n.teamStatusFilterLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: context.themeTextSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: context.l10n.teamAllStatuses,
                                isSelected: _statusFilter == null,
                                onSelected: () =>
                                    setState(() => _statusFilter = null),
                              ),
                              _FilterChip(
                                label: adminStatusLabel(context, AdminStatus.active),
                                isSelected: _statusFilter == AdminStatus.active,
                                color: const Color(0xFF2E7D32),
                                onSelected: () => setState(
                                    () => _statusFilter = AdminStatus.active),
                              ),
                              _FilterChip(
                                label: adminStatusLabel(context, AdminStatus.invited),
                                isSelected:
                                    _statusFilter == AdminStatus.invited,
                                color: AppColors.primary,
                                onSelected: () => setState(
                                    () => _statusFilter = AdminStatus.invited),
                              ),
                              _FilterChip(
                                label: adminStatusLabel(context, AdminStatus.suspended),
                                isSelected:
                                    _statusFilter == AdminStatus.suspended,
                                color: AppColors.error,
                                onSelected: () => setState(() =>
                                    _statusFilter = AdminStatus.suspended),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.group_off_outlined,
                            size: 54,
                            color: AppColors.outline.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.l10n.teamNoAdminsFound,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _searchQuery.isNotEmpty
                                ? context.l10n.teamNoAdminMatching(_searchQuery)
                                : context.l10n.teamTryChangingFilter,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: context.themeTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 4, 20, isMobile ? AppBottomNav.contentBottomPadding : 24),
                    sliver: isDesktop
                        ? SliverToBoxAdapter(
                            child: _AdminDesktopTable(
                              admins: filtered,
                              isSuperAdmin: isSuperAdmin,
                              currentAdminId: currentAdminId,
                              onEditPermissions: (admin) =>
                                  _openEditPermissionsDialog(context, admin),
                              onToggleStatus: _toggleAdminStatus,
                              onRevoke: _confirmRevoke,
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final admin = filtered[index];
                                return _AdminMobileCard(
                                  admin: admin,
                                  isSuperAdmin: isSuperAdmin,
                                  isSelf: admin.id == currentAdminId ||
                                      admin.email ==
                                          roleProvider.currentUser?.email,
                                  onEditPermissions: () =>
                                      _openEditPermissionsDialog(
                                          context, admin),
                                  onToggleStatus: (active) =>
                                      _toggleAdminStatus(admin, active),
                                  onRevoke: () => _confirmRevoke(admin),
                                );
                              },
                              childCount: filtered.length,
                            ),
                          ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.themeBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: context.themeTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: context.themeTextPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: context.themeTextSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selBg = context.isDark ? Colors.white : AppColors.ink;
    final selFg = context.isDark ? AppColors.ink : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? selBg : context.themeSurface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSelected ? selBg : context.themeBorder,
              width: 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? selFg : context.themeTextPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminDesktopTable extends StatelessWidget {
  final List<AdminUser> admins;
  final bool isSuperAdmin;
  final String? currentAdminId;
  final ValueChanged<AdminUser> onEditPermissions;
  final void Function(AdminUser admin, bool makeActive) onToggleStatus;
  final ValueChanged<AdminUser> onRevoke;

  const _AdminDesktopTable({
    required this.admins,
    required this.isSuperAdmin,
    required this.currentAdminId,
    required this.onEditPermissions,
    required this.onToggleStatus,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: DataTable(
          headingRowHeight: 46,
          dataRowMinHeight: 64,
          dataRowMaxHeight: 74,
          horizontalMargin: 20,
          columnSpacing: 24,
          headingRowColor: WidgetStateProperty.all(AppColors.surfaceLow),
          columns: [
            DataColumn(
              label: Text(context.l10n.teamColAdministrator,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.outline)),
            ),
            DataColumn(
              label: Text(context.l10n.teamColTierRole,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.outline)),
            ),
            DataColumn(
              label: Text(context.l10n.teamColGrantedPermissions,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.outline)),
            ),
            DataColumn(
              label: Text(context.l10n.teamColStatus,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.outline)),
            ),
            DataColumn(
              label: Text(context.l10n.teamColActions,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.outline)),
            ),
          ],
          rows: admins.map((admin) {
            final isSelf = admin.id == currentAdminId;

            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      UserAvatar(
                        uid: admin.id,
                        displayName: admin.displayName,
                        radius: 18,
                        backgroundColor: admin.roleBgColor,
                        textColor: admin.roleColor,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Text(
                                admin.displayName,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (isSelf) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    context.l10n.youBadge,
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            admin.email,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: context.themeTextSecondary,
                            ),
                          ),
                          if (admin.phone != null && admin.phone!.isNotEmpty)
                            Text(
                              admin.phone!,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: context.themeMuted,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: admin.roleBgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: admin.roleColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          admin.isSuperAdmin
                              ? Icons.shield
                              : Icons.verified_user,
                          size: 13,
                          color: admin.roleColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          admin.role == AdminRole.superAdmin
                              ? context.l10n.roleSuperAdminBadge
                              : (admin.role == AdminRole.opsAdmin
                                  ? context.l10n.roleOpsAdminBadge
                                  : context.l10n.roleSupportAdminBadge),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: admin.roleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: admin.isSuperAdmin
                        ? Text(
                            context.l10n.fullRootGovernanceBadge,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          )
                        : Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: admin.permissions.map((p) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLow,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppColors.outline
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  adminPermissionLabel(context, p),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ),
                DataCell(
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: admin.statusBgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      adminStatusLabel(context, admin.status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: admin.statusColor,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (admin.isSuperAdmin) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_outline,
                                  size: 12, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                context.l10n.teamManagedInFirebase,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (isSuperAdmin && !isSelf) ...[
                        Switch(
                          value: admin.isActive,
                          activeThumbColor: AppColors.primary,
                          onChanged: (active) => onToggleStatus(admin, active),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 18),
                          tooltip: context.l10n.teamManageAdmin,
                          onSelected: (val) {
                            switch (val) {
                              case 'edit':
                                onEditPermissions(admin);
                                break;
                              case 'revoke':
                                onRevoke(admin);
                                break;
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit_outlined, size: 16),
                                  const SizedBox(width: 8),
                                  Text(ctx.l10n.teamEditPermissions),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              value: 'revoke',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_outline,
                                      size: 16, color: AppColors.error),
                                  const SizedBox(width: 8),
                                  Text(ctx.l10n.revokeAccess,
                                      style: const TextStyle(
                                          color: AppColors.error)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          context.l10n.teamProtected,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.outline,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _AdminMobileCard extends StatelessWidget {
  final AdminUser admin;
  final bool isSuperAdmin;
  final bool isSelf;
  final VoidCallback onEditPermissions;
  final ValueChanged<bool> onToggleStatus;
  final VoidCallback onRevoke;

  const _AdminMobileCard({
    required this.admin,
    required this.isSuperAdmin,
    required this.isSelf,
    required this.onEditPermissions,
    required this.onToggleStatus,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    if (admin.isSuperAdmin) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.themeHeroSurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.themeHeroBorder, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(
                  uid: admin.id,
                  displayName: admin.displayName,
                  radius: 22,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  textColor: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              admin.displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelf) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                context.l10n.youBadge,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        admin.email,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      width: 1.0,
                    ),
                  ),
                  child: Text(
                    context.l10n.roleSuperAdminBadge.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.fullRootGovernanceBadge,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_outline,
                            size: 11, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          context.l10n.teamProtected,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.verified_outlined,
                    size: 13, color: Colors.white.withValues(alpha: 0.5)),
                const SizedBox(width: 6),
                Text(
                  context.l10n.teamManagedInFirebase,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.65),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final statusBg = admin.status == AdminStatus.active
        ? context.themeSuccessTint
        : (admin.status == AdminStatus.suspended
            ? context.themeDangerTint
            : context.themeAmberTint);
    final statusFg = admin.status == AdminStatus.active
        ? context.themeSuccess
        : (admin.status == AdminStatus.suspended
            ? context.themeDanger
            : context.themeAmberText);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.themeBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                uid: admin.id,
                displayName: admin.displayName,
                radius: 20,
                backgroundColor: admin.roleBgColor,
                textColor: admin.roleColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            admin.displayName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: context.themeTextPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelf) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.themeAmberTint,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              context.l10n.youBadge,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: context.themeAmberText,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      admin.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.themeTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  adminStatusLabel(context, admin.status),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: statusFg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: admin.roleBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  admin.role == AdminRole.superAdmin
                      ? context.l10n.roleSuperAdminBadge
                      : (admin.role == AdminRole.opsAdmin
                          ? context.l10n.roleOpsAdminBadge
                          : context.l10n.roleSupportAdminBadge),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: admin.roleColor,
                  ),
                ),
              ),
              if (admin.phone != null && admin.phone!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  admin.phone!,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.themeTextSecondary,
                  ),
                ),
              ],
            ],
          ),
          if (admin.permissions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: admin.permissions.map((p) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.themeSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    adminPermissionLabel(context, p),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: context.themeTextPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          if (isSuperAdmin && !isSelf && !admin.isSuperAdmin) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: context.themeBorder),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      context.l10n.teamActiveLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.themeTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Transform.scale(
                      scale: 0.85,
                      child: Switch.adaptive(
                        value: admin.isActive,
                        activeThumbColor: AppColors.primary,
                        onChanged: onToggleStatus,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_outlined,
                          size: 19, color: context.themeTextSecondary),
                      tooltip: context.l10n.teamEditPermissions,
                      onPressed: onEditPermissions,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 19, color: AppColors.error),
                      tooltip: context.l10n.revokeAccess,
                      onPressed: onRevoke,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
