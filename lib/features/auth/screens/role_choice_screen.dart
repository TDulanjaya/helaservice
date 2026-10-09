import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import '../../../theme/app_theme.dart';
import '../../../state/role_provider.dart';
import '../../../models/user_profile.dart';
import '../../../services/auth_service.dart';
import '../../../utils/l10n_extension.dart';
import 'complete_profile_screen.dart';

class RoleChoiceScreen extends StatefulWidget {
  final UserProfile? user;

  const RoleChoiceScreen({super.key, this.user});

  @override
  State<RoleChoiceScreen> createState() => _RoleChoiceScreenState();
}

class _RoleChoiceScreenState extends State<RoleChoiceScreen> {
  bool _isProcessing = false;
  AppRole? _selectedRole;

  Future<void> _selectRole(AppRole role) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _selectedRole = role;
    });

    try {
      final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
      final current = widget.user ?? roleProvider.currentUser;
      final fbUser = AuthService().currentFirebaseUser;
      final uid = current?.id.isNotEmpty == true ? current!.id : (fbUser?.uid ?? '');

      final roleString = role == AppRole.provider ? 'provider' : 'customer';

      if (uid.isNotEmpty) {
        await AuthService().updateUserField(uid, {
          'role': roleString,
        });
      }

      UserProfile updatedProfile;
      if (current != null) {
        updatedProfile = current.copyWith(role: role);
      } else if (fbUser != null) {
        updatedProfile = UserProfile.fromFirebaseUser(fbUser, role: role);
      } else {
        updatedProfile = UserProfile(id: uid, role: role);
      }

      roleProvider.setUser(updatedProfile);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CompleteProfileScreen(initialProfile: updatedProfile),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.failedToSetRole(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _selectedRole = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // brand header
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.handyman_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.chooseRoleTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: context.themeInk,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.chooseRoleSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: context.themeTextSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 32),

              // role options
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildRoleCard(
                      context: context,
                      role: AppRole.customer,
                      icon: Icons.search_rounded,
                      accentColor: AppColors.primary,
                      title: context.l10n.roleCustomerTitle,
                      subtitle: context.l10n.roleCustomerDesc,
                      badge: context.l10n.roleCustomerBadge,
                      perks: [
                        context.l10n.roleCustomerPerk1,
                        context.l10n.roleCustomerPerk2,
                        context.l10n.roleCustomerPerk3,
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildRoleCard(
                      context: context,
                      role: AppRole.provider,
                      icon: Icons.engineering_rounded,
                      accentColor: const Color(0xFFD6900F),
                      title: context.l10n.roleProviderTitle,
                      subtitle: context.l10n.roleProviderDesc,
                      badge: context.l10n.roleProviderBadge,
                      perks: [
                        context.l10n.roleProviderPerk1,
                        context.l10n.roleProviderPerk2,
                        context.l10n.roleProviderPerk3,
                      ],
                    ),
                  ],
                ),
              ),

              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required BuildContext context,
    required AppRole role,
    required IconData icon,
    required Color accentColor,
    required String title,
    required String subtitle,
    required String badge,
    required List<String> perks,
  }) {
    final isSelected = _selectedRole == role;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isProcessing ? null : () => _selectRole(role),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.themeSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : context.themeBorder.withValues(alpha: 0.9),
              width: isSelected ? 2 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: accentColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: context.themeInk,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badge,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: accentColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: context.themeTextSecondary,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: context.themeBorder.withValues(alpha: 0.6)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: perks.map((perk) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 14,
                        color: accentColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        perk,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: context.themeTextSecondary,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
