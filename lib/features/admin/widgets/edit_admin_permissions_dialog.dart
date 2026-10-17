import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../theme/app_theme.dart';
import '../../../models/admin_user.dart';
import '../../../repositories/admin_repository.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/admin_l10n_helpers.dart';

class EditAdminPermissionsDialog extends StatefulWidget {
  final AdminUser admin;

  const EditAdminPermissionsDialog({super.key, required this.admin});

  @override
  State<EditAdminPermissionsDialog> createState() =>
      _EditAdminPermissionsDialogState();
}

class _EditAdminPermissionsDialogState
    extends State<EditAdminPermissionsDialog> {
  late AdminRole _selectedRole;
  late Set<AdminPermission> _selectedPermissions;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.admin.role == AdminRole.supportAdmin
        ? AdminRole.supportAdmin
        : AdminRole.opsAdmin;
    _selectedPermissions = widget.admin.permissions.toSet();
    if (_selectedPermissions.isEmpty) {
      _selectedPermissions = _getDefaultPermissionsForRole(_selectedRole);
    }
  }

  Set<AdminPermission> _getDefaultPermissionsForRole(AdminRole role) {
    if (role == AdminRole.superAdmin) {
      return AdminPermission.values.toSet();
    }
    if (role == AdminRole.supportAdmin) {
      return {
        AdminPermission.verifyNic,
        AdminPermission.handleSupport,
      };
    }
    return {
      AdminPermission.verifyNic,
      AdminPermission.manageCategories,
      AdminPermission.broadcastAlerts,
      AdminPermission.manageUsers,
      AdminPermission.handleSupport,
    };
  }

  void _onRoleChanged(AdminRole newRole) {
    setState(() {
      _selectedRole = newRole;
      if (_selectedPermissions.isEmpty) {
        _selectedPermissions = _getDefaultPermissionsForRole(newRole);
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedPermissions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.editPermSelectOne),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AdminRepository().updateAdminRoleAndPermissions(
        widget.admin.id,
        _selectedRole,
        _selectedPermissions.toList(),
      );

      if (!mounted) return;
      final successMsg =
          context.l10n.editPermUpdatedFor(widget.admin.displayName);
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            successMsg,
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[EditAdminPermissions] update permissions error: $e');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              context.l10n.editPermFailed(context.l10n.somethingWentWrong)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: context.themeSurface,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  UserAvatar(
                    uid: widget.admin.id,
                    displayName: widget.admin.displayName,
                    radius: 20,
                    backgroundColor: widget.admin.roleBgColor,
                    textColor: widget.admin.roleColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.admin.displayName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: context.themeTextPrimary,
                          ),
                        ),
                        Text(
                          widget.admin.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.themeTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close,
                        size: 20, color: context.themeTextSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: context.themeBorder),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.editPermChangeTier,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: context.themeTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _RoleCard(
                              label:
                                  adminRoleLabel(context, AdminRole.opsAdmin),
                              icon: Icons.verified_user,
                              color: AppColors.primary,
                              isSelected: _selectedRole == AdminRole.opsAdmin,
                              onTap: () => _onRoleChanged(AdminRole.opsAdmin),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _RoleCard(
                              label: adminRoleLabel(
                                  context, AdminRole.supportAdmin),
                              icon: Icons.support_agent,
                              color: const Color(0xFF4A6572),
                              isSelected:
                                  _selectedRole == AdminRole.supportAdmin,
                              onTap: () =>
                                  _onRoleChanged(AdminRole.supportAdmin),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        context.l10n.editPermAssigned,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: context.themeTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...AdminPermission.values
                          .where((p) => p != AdminPermission.manageAdmins)
                          .map((permission) {
                        final isChecked =
                            _selectedPermissions.contains(permission);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isChecked
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : context.themeSurfaceLow,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isChecked
                                  ? AppColors.primary.withValues(alpha: 0.3)
                                  : context.themeBorder,
                            ),
                          ),
                          child: CheckboxListTile(
                            value: isChecked,
                            dense: true,
                            activeColor: AppColors.primary,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 2),
                            title: Text(
                              adminPermissionLabel(context, permission),
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: context.themeTextPrimary,
                              ),
                            ),
                            subtitle: Text(
                              adminPermissionDescription(context, permission),
                              style: TextStyle(
                                fontSize: 11,
                                color: context.themeTextSecondary,
                              ),
                            ),
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedPermissions.add(permission);
                                } else {
                                  _selectedPermissions.remove(permission);
                                }
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Divider(height: 1, color: context.themeBorder),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _isLoading ? null : () => Navigator.of(context).pop(),
                    child: Text(context.l10n.cancel,
                        style: TextStyle(color: context.themeTextSecondary)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save, size: 18),
                    label: Text(
                      _isLoading
                          ? context.l10n.editPermUpdating
                          : context.l10n.editPermSave,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.12)
              : context.themeSurfaceLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : context.themeBorder,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? color : context.themeTextSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? color : context.themeTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
