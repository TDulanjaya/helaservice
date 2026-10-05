import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import '../../../theme/app_theme.dart';
import '../../../state/role_provider.dart';
import '../../../state/theme_provider.dart';
import '../../../state/locale_provider.dart';
import '../../../shared/widgets/role_switch_sheet.dart';
import '../../../shared/widgets/language_select_sheet.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/outline_button.dart';
import '../../../shared/widgets/icon_square_button.dart';
import '../../../app_router.dart';
import '../../../models/user_profile.dart';
import '../../../utils/location_utils.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/app_localizations_helpers.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/user_avatar.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  void _showEditProfileSheet(BuildContext context) {
    final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
    final user = roleProvider.currentUser;

    final nameController = TextEditingController(text: user?.displayName ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');
    final addressController = TextEditingController(text: user?.address ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.editProfileAndPhoto,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                  IconSquareButton.small(
                    icon: Icons.close,
                    onTap: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: UserAvatar(
                  uid: user?.id,
                  displayName: user?.displayName ?? ctx.l10n.customerLabel,
                  photoUrl: user?.photoUrl,
                  radius: 40,
                  editable: true,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: context.l10n.fullName,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: context.l10n.phoneLabel,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  prefixText: '+94 ',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: context.l10n.address,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: context.l10n.save,
                onPressed: () {
                  if (user != null) {
                    final updated = user.copyWith(
                      displayName: nameController.text.trim(),
                      phone: phoneController.text.trim(),
                      address: addressController.text.trim(),
                    );
                    roleProvider.completeUserProfile(updated);
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.profileUpdatedSuccess),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.l10n.logoutModalTitle,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(context.l10n.logoutModalConfirm,
            style: TextStyle(color: context.themeTextSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              pv.Provider.of<RoleProvider>(context, listen: false).logout();
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.login,
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(context.l10n.logout),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = pv.Provider.of<RoleProvider>(context);
    final user = roleProvider.currentUser;

    final displayName = user?.displayName.isNotEmpty == true
        ? user!.displayName
        : context.l10n.customerLabel;
    final email = user?.email.isNotEmpty == true ? user!.email : '';
    final phone = user?.phone?.isNotEmpty == true ? user!.phone! : '';
    final address = user?.address?.isNotEmpty == true ? user!.address! : '';
    final district = user?.district ?? context.l10n.custFallbackColombo;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.navProfile,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: IconSquareButton(
                icon: Icons.edit_outlined,
                onTap: () => _showEditProfileSheet(context),
                tooltip: context.l10n.editProfile,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              16, 8, 16, AppBottomNav.contentBottomPadding),
          children: [
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  UserAvatar(
                    uid: user?.id,
                    displayName: displayName,
                    photoUrl: user?.photoUrl,
                    radius: 38,
                    editable: true,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: context.themeTextSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified,
                            color: AppColors.primary, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          context.l10n.verifiedCustomer,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.dispatchAndContactInfo,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showEditProfileSheet(context),
                        child: Text(
                          context.l10n.change,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.phone_iphone,
                          size: 18, color: context.themeTextSecondary),
                      const SizedBox(width: 10),
                      Text(
                        '+94 $phone',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 18, color: context.themeTextSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$address (${LocalizedData.getDistrict(context, district)})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                context.l10n.accountAndServices,
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            _SettingsTile(
              icon: Icons.my_location,
              title: context.l10n.homeServiceGpsLocation,
              subtitle: user?.latitude != null
                  ? context.l10n.custGpsTapToUpdate(
                      user!.latitude!.toStringAsFixed(4),
                      user.longitude!.toStringAsFixed(4))
                  : context.l10n.tapToAutoDetectGps,
              onTap: () async {
                final pos = await LocationUtils.getCurrentPosition();
                if (pos != null && context.mounted) {
                  final updated = (user ??
                          UserProfile(
                            id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
                            email: '',
                          ))
                      .copyWith(
                    latitude: pos.latitude,
                    longitude: pos.longitude,
                  );
                  await roleProvider.completeUserProfile(updated);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.l10n.gpsLocationUpdated(
                              pos.latitude.toStringAsFixed(4),
                              pos.longitude.toStringAsFixed(4)),
                        ),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.couldNotObtainGps),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
            ),
            pv.Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return _SettingsTile(
                  icon: themeProvider.isDark(context)
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                  title: context.l10n.appearanceAndTheme,
                  subtitle: context.l10n
                      .currentMode(themeProvider.getModeDisplayName(context)),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: context.themeSurface,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (sheetCtx) => SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                              Text(context.l10n.chooseAppearance,
                                  style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 14),
                              ListTile(
                                leading: const Icon(Icons.brightness_auto),
                                title: Text(context.l10n.systemDefault),
                                trailing: themeProvider.mode == ThemeMode.system
                                    ? const Icon(Icons.check,
                                        color: AppColors.primary)
                                    : null,
                                onTap: () {
                                  themeProvider.setSystem();
                                  Navigator.pop(sheetCtx);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.light_mode),
                                title: Text(context.l10n.lightMode),
                                trailing: themeProvider.mode == ThemeMode.light
                                    ? const Icon(Icons.check,
                                        color: AppColors.primary)
                                    : null,
                                onTap: () {
                                  themeProvider.setLight();
                                  Navigator.pop(sheetCtx);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.dark_mode),
                                title: Text(context.l10n.darkMode),
                                trailing: themeProvider.mode == ThemeMode.dark
                                    ? const Icon(Icons.check,
                                        color: AppColors.primary)
                                    : null,
                                onTap: () {
                                  themeProvider.setDark();
                                  Navigator.pop(sheetCtx);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            pv.Consumer<LocaleProvider>(
              builder: (context, localeProvider, _) {
                return _SettingsTile(
                  icon: Icons.language,
                  title: 'App Language / භාෂාව / மொழி',
                  subtitle: context.l10n
                      .currentMode(localeProvider.languageDisplayName),
                  onTap: () => LanguageSelectSheet.show(context),
                );
              },
            ),
            const SizedBox(height: 12),
            AppCard(
              onTap: () => showRoleSwitchSheet(context),
              color: context.themeSurfaceLow,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.handyman,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          roleProvider.isAuthorizedAdmin
                              ? context.l10n.switchOperationalView
                              : context.l10n.roleProvider,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          roleProvider.isAuthorizedAdmin
                              ? context.l10n.switchOperationalViewDesc
                              : context.l10n.providerRoleDesc,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: context.themeTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 14, color: AppColors.outline),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AppOutlineButton(
              label: context.l10n.logout,
              icon: Icons.logout,
              color: AppColors.error,
              onPressed: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 16,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                      fontSize: 11.5, color: context.themeTextSecondary),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.outline),
        ],
      ),
    );
  }
}
