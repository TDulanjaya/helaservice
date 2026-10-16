import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/admin_user.dart';
import '../../../services/auth_service.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/admin_l10n_helpers.dart';
import '../../../utils/auth_error_l10n.dart';

class AddAdminDialog extends StatefulWidget {
  const AddAdminDialog({super.key});

  @override
  State<AddAdminDialog> createState() => _AddAdminDialogState();
}

class _AddAdminDialogState extends State<AddAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  AdminRole _selectedRole = AdminRole.opsAdmin;
  late Set<AdminPermission> _selectedPermissions;
  bool _isLoading = false;

  bool _isSuccess = false;
  String? _createdAdminName;
  String? _createdAdminEmail;

  @override
  void initState() {
    super.initState();
    _selectedPermissions = _getDefaultPermissionsForRole(_selectedRole);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Set<AdminPermission> _getDefaultPermissionsForRole(AdminRole role) {
    switch (role) {
      case AdminRole.superAdmin:
        return AdminPermission.values.toSet();
      case AdminRole.opsAdmin:
        return {
          AdminPermission.verifyNic,
          AdminPermission.manageCategories,
          AdminPermission.broadcastAlerts,
          AdminPermission.manageUsers,
          AdminPermission.handleSupport,
        };
      case AdminRole.supportAdmin:
        return {
          AdminPermission.verifyNic,
          AdminPermission.handleSupport,
        };
    }
  }

  void _onRoleChanged(AdminRole newRole) {
    setState(() {
      _selectedRole = newRole;
      _selectedPermissions = _getDefaultPermissionsForRole(newRole);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPermissions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.addAdminGrantOnePermission),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim().toLowerCase();
      final phone = _phoneController.text.trim().isNotEmpty
          ? _phoneController.text.trim()
          : null;

      final permissions = _selectedPermissions.toList();

      await AuthService().createAdminAccount(
        email: email,
        displayName: name,
        role: _selectedRole,
        permissions: permissions,
        phone: phone,
      );

      if (!mounted) return;
      setState(() {
        _createdAdminName = name;
        _createdAdminEmail = email;
        _isSuccess = true;
      });
    } catch (e) {
      if (!mounted) return;
      final errorMsg = authErrorMessage(context, e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.addAdminFailed(errorMsg)),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
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
          maxWidth: 580,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isSuccess ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.green,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.addAdminAccountCreated,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.themeTextPrimary,
                    ),
                  ),
                  Text(
                    '$_createdAdminName ($_createdAdminEmail)',
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
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.addAdminSuccessBody(
                      adminRoleLabel(context, _selectedRole)),
                  style: TextStyle(
                    fontSize: 12,
                    color: context.themeTextPrimary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Divider(height: 1, color: context.themeBorder),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(context.l10n.done,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.addAdminTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: context.themeTextPrimary,
                      ),
                    ),
                    Text(
                      context.l10n.addAdminSubtitle,
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
          const SizedBox(height: 18),
          Divider(height: 1, color: context.themeBorder),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.fullName,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: context.themeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(color: context.themeTextPrimary),
                    decoration: InputDecoration(
                      hintText: context.l10n.hintFullName,
                      hintStyle: TextStyle(color: context.themeTextSecondary),
                      prefixIcon: Icon(Icons.person_outline,
                          size: 20, color: context.themeTextSecondary),
                      filled: true,
                      fillColor: context.themeSurfaceLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: context.themeBorder,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return context.l10n.addAdminEnterFullName;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    context.l10n.addAdminWorkEmail,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: context.themeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: context.themeTextPrimary),
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: context.l10n.hintEmail,
                      hintStyle: TextStyle(color: context.themeTextSecondary),
                      prefixIcon: Icon(Icons.email_outlined,
                          size: 20, color: context.themeTextSecondary),
                      filled: true,
                      fillColor: context.themeSurfaceLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: context.themeBorder,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return context.l10n.addAdminEnterWorkEmail;
                      }
                      if (!v.contains('@') || !v.contains('.')) {
                        return context.l10n.enterValidEmail;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    context.l10n.addAdminMobileOptional,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: context.themeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _phoneController,
                    style: TextStyle(color: context.themeTextPrimary),
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: context.l10n.hintPhone,
                      hintStyle: TextStyle(color: context.themeTextSecondary),
                      prefixIcon: Icon(Icons.phone_outlined,
                          size: 20, color: context.themeTextSecondary),
                      filled: true,
                      fillColor: context.themeSurfaceLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: context.themeBorder,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.l10n.addAdminTier,
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
                        child: _RoleSelectCard(
                          role: AdminRole.opsAdmin,
                          isSelected: _selectedRole == AdminRole.opsAdmin,
                          onSelect: () => _onRoleChanged(AdminRole.opsAdmin),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _RoleSelectCard(
                          role: AdminRole.supportAdmin,
                          isSelected: _selectedRole == AdminRole.supportAdmin,
                          onSelect: () =>
                              _onRoleChanged(AdminRole.supportAdmin),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.l10n.addAdminOperationalPermissions,
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
                    final isChecked = _selectedPermissions.contains(permission);

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
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(
                  _isLoading
                      ? context.l10n.addAdminAdding
                      : context.l10n.addAdminGrantRole,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleSelectCard extends StatelessWidget {
  final AdminRole role;
  final bool isSelected;
  final VoidCallback onSelect;

  const _RoleSelectCard({
    required this.role,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    Color getRoleColor() {
      switch (role) {
        case AdminRole.superAdmin:
        case AdminRole.opsAdmin:
          return AppColors.primary;
        case AdminRole.supportAdmin:
          return const Color(0xFF4A6572);
      }
    }

    final color = getRoleColor();

    return InkWell(
      onTap: onSelect,
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
              role == AdminRole.opsAdmin
                  ? Icons.verified_user
                  : Icons.support_agent,
              size: 20,
              color: isSelected ? color : context.themeTextSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              adminRoleLabel(context, role),
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
