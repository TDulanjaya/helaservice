import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/app_theme.dart';
import '../../../models/user_profile.dart';
import '../../../state/role_provider.dart';
import '../../../repositories/user_repository.dart';
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
  String _selectedRoleFilter = 'all'; // 'all', 'customer', 'provider', 'admin'
  String _selectedDistrictFilter = 'all'; // 'all' or specific district name
  String _selectedStatusFilter = 'all'; // 'all', 'active', 'suspended'

  @override
  void dispose() {
    _searchController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _showSuspendDialog(UserProfile user, {bool isSuper = false}) {
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
    if (user.role == AppRole.provider) {
      roleLabel = context.l10n.custServiceProviderLabel;
    } else if (user.role == AppRole.admin) {
      roleLabel = context.l10n.roleAdmin;
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
              content: SingleChildScrollView(
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
                          color: context.themeTextSecondary.withValues(alpha: 0.6),
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
                    final reason = _reasonController.text.trim();
                    if (reason.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.l10n.pleaseEnterSuspensionReason),
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
          content: Text(
            context.l10n.confirmUnbanDesc,
            style: TextStyle(
              fontSize: 13.5,
              color: context.themeTextSecondary,
              height: 1.4,
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
              : (context.isDark ? context.themeSurfaceLow : const Color(0xFFF1F3F5)),
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

  @override
  Widget build(BuildContext context) {
    final districts = LocationUtils.districtCoordinates.keys.toList();
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('superAdmins').snapshots(),
      builder: (context, superAdminSnap) {
        final superAdminUids = superAdminSnap.data?.docs.map((d) => d.id).toSet() ?? <String>{};

        bool checkIsSuperAdmin(UserProfile u) {
          return u.isSuperAdmin || superAdminUids.contains(u.id);
        }

        return StreamBuilder<List<UserProfile>>(
          stream: _userRepo.streamAllUsers(),
          builder: (context, snapshot) {
            final allUsers = snapshot.data ?? [];
            final totalCount = allUsers.length;
            final customerCount = allUsers.where((u) => u.role == AppRole.customer).length;
            final providerCount = allUsers.where((u) => u.role == AppRole.provider).length;
            final suspendedCount = allUsers.where((u) => u.isBanned).length;

            // apply filters
            final filteredUsers = allUsers.where((user) {
              // role filter
              if (_selectedRoleFilter == 'customer' && user.role != AppRole.customer) {
                return false;
              }
              if (_selectedRoleFilter == 'provider' && user.role != AppRole.provider) {
                return false;
              }
              if (_selectedRoleFilter == 'admin' &&
                  user.role != AppRole.admin &&
                  !checkIsSuperAdmin(user)) {
                return false;
              }

          // district filter
          if (_selectedDistrictFilter != 'all') {
            if (user.district == null ||
                user.district!.toLowerCase() != _selectedDistrictFilter.toLowerCase()) {
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
                if (isDesktop)
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
                    border: Border.all(color: context.themeBorder, width: 1.5),
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
                            color: context.themeTextSecondary.withValues(alpha: 0.6),
                            fontSize: 13.5,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: context.themeTextSecondary,
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
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
                            borderSide: BorderSide(color: context.themeBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: context.themeBorder),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(14)),
                            borderSide: BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // role filter section
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
                                  isSelected: _selectedRoleFilter == 'all',
                                  onTap: () =>
                                      setState(() => _selectedRoleFilter = 'all'),
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  context: context,
                                  label: context.l10n.filterCustomers,
                                  icon: Icons.person_outline_rounded,
                                  isSelected: _selectedRoleFilter == 'customer',
                                  onTap: () => setState(
                                      () => _selectedRoleFilter = 'customer'),
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  context: context,
                                  label: context.l10n.filterProviders,
                                  icon: Icons.handyman_outlined,
                                  isSelected: _selectedRoleFilter == 'provider',
                                  onTap: () => setState(
                                      () => _selectedRoleFilter = 'provider'),
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  context: context,
                                  label: context.l10n.filterAdmins,
                                  icon: Icons.shield_outlined,
                                  isSelected: _selectedRoleFilter == 'admin',
                                  onTap: () =>
                                      setState(() => _selectedRoleFilter = 'admin'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // status filter section
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
                                  isSelected: _selectedStatusFilter == 'all',
                                  onTap: () =>
                                      setState(() => _selectedStatusFilter = 'all'),
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  context: context,
                                  label: context.l10n.statusActive,
                                  icon: Icons.check_circle_outline_rounded,
                                  isSelected: _selectedStatusFilter == 'active',
                                  activeColor: const Color(0xFF2E7D32),
                                  onTap: () => setState(
                                      () => _selectedStatusFilter = 'active'),
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  context: context,
                                  label: context.l10n.statusSuspended,
                                  icon: Icons.block_flipped,
                                  isSelected: _selectedStatusFilter == 'suspended',
                                  activeColor: AppColors.error,
                                  onTap: () => setState(
                                      () => _selectedStatusFilter = 'suspended'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // district picker row
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isDesktop ? 340 : double.infinity,
                        ),
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
                          onSelected: (val) =>
                              setState(() => _selectedDistrictFilter = val),
                        ),
                      ),
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
                      final isSuper = checkIsSuperAdmin(user);
                      final isProvider = user.role == AppRole.provider;
                      final isAdmin = user.role == AppRole.admin || isSuper;

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
                            // top row with avatar, name, badges
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                UserAvatar(
                                  uid: user.id,
                                  displayName: user.displayName,
                                  email: user.email,
                                  radius: 24,
                                  backgroundColor: isSuper
                                      ? Colors.amber.withValues(alpha: 0.2)
                                      : (isProvider
                                          ? Colors.purple.withValues(alpha: 0.2)
                                          : (isAdmin
                                              ? Colors.indigo.withValues(alpha: 0.2)
                                              : Colors.blue.withValues(alpha: 0.2))),
                                  textColor: isSuper
                                      ? Colors.amber.shade800
                                      : (isProvider
                                          ? Colors.purple
                                          : (isAdmin
                                              ? Colors.indigo
                                              : Colors.blue)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      () {
                                        final roleBadge = Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSuper
                                                ? Colors.amber.withValues(alpha: 0.15)
                                                : (isProvider
                                                    ? Colors.purple
                                                        .withValues(alpha: 0.12)
                                                    : (isAdmin
                                                        ? Colors.indigo
                                                            .withValues(alpha: 0.12)
                                                        : Colors.blue
                                                            .withValues(alpha: 0.12))),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            isSuper
                                                ? context.l10n.roleSuperAdminBadge
                                                : (isProvider
                                                    ? context.l10n.custServiceProviderLabel
                                                    : (isAdmin
                                                        ? context.l10n.roleAdmin
                                                        : context.l10n.roleCustomer)),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: isSuper
                                                  ? Colors.amber.shade800
                                                  : (isProvider
                                                      ? Colors.purple
                                                      : (isAdmin
                                                          ? Colors.indigo
                                                          : Colors.blue)),
                                            ),
                                          ),
                                        );

                                        final statusBadge = Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isBanned
                                                ? AppColors.error
                                                    .withValues(alpha: 0.12)
                                                : AppColors.success
                                                    .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            isBanned
                                                ? context.l10n.statusSuspended
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
                                                  user.displayName.isNotEmpty
                                                      ? user.displayName
                                                      : user.email,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w800,
                                                    color: context.themeTextPrimary,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
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
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user.displayName.isNotEmpty
                                                    ? user.displayName
                                                    : user.email,
                                                style: TextStyle(
                                                  fontSize: 15.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: context.themeTextPrimary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
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
                                              mainAxisSize: MainAxisSize.min,
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
                                              mainAxisSize: MainAxisSize.min,
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
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.location_on_outlined,
                                                  size: 14,
                                                  color: context
                                                      .themeTextSecondary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  LocalizedData.getDistrict(
                                                      context, user.district!),
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    color: context
                                                        .themeTextSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          if (isProvider &&
                                              user.serviceCategory != null &&
                                              user.serviceCategory!.isNotEmpty)
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.handyman_outlined,
                                                  size: 14,
                                                  color: context
                                                      .themeTextSecondary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  LocalizedData.getCategory(
                                                      context,
                                                      user.serviceCategory!),
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
                                  color: AppColors.error.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.error.withValues(alpha: 0.25),
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
                                      foregroundColor: context.themeTextPrimary,
                                      side: BorderSide(
                                          color: context.themeBorder),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () =>
                                        MapLauncher.openPhoneCall(user.phone!),
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
                                      color: Colors.amber.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.amber.withValues(alpha: 0.35),
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
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.success,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () => _showUnbanDialog(user),
                                    icon: const Icon(
                                      Icons.lock_open_rounded,
                                      size: 15,
                                    ),
                                    label: Text(context.l10n.unbanAccount),
                                  )
                                else
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.error,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () =>
                                        _showSuspendDialog(user, isSuper: isSuper),
                                    icon: const Icon(
                                      Icons.block_flipped,
                                      size: 15,
                                    ),
                                    label: Text(context.l10n.suspendAccount),
                                  ),
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
