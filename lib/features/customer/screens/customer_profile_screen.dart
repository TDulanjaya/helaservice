import 'package:flutter/foundation.dart';
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
import '../../../shared/widgets/job_location_picker.dart';
import '../../../app_router.dart';
import '../../../models/saved_address.dart';
import '../../../repositories/saved_address_repository.dart';
import '../../../utils/l10n_extension.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/legal_content_sheet.dart';
import '../../auth/screens/complete_profile_screen.dart';
import '../../support/screens/help_support_screen.dart';
import '../../provider/screens/provider_pending_screen.dart';

class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  void _showEditProfileSheet(BuildContext context) {
    final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
    final user = roleProvider.currentUser;

    final nameController = TextEditingController(text: user?.displayName ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');

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
              const SizedBox(height: 20),
              PrimaryButton(
                label: context.l10n.save,
                onPressed: () {
                  if (user != null) {
                    final updated = user.copyWith(
                      displayName: nameController.text.trim(),
                      phone: phoneController.text.trim(),
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

  void _showEditAddressDialog(
      BuildContext context, String uid, SavedAddress addr) {
    final labelController = TextEditingController(text: addr.label);
    final addressController = TextEditingController(text: addr.address);
    final landmarkController =
        TextEditingController(text: addr.effectiveNote ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          context.l10n.editSavedAddress,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: InputDecoration(
                labelText: context.l10n.savedAddressLabelHint,
                prefixIcon: const Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: context.l10n.location,
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: landmarkController,
              decoration: InputDecoration(
                labelText: context.l10n.landmarkNoteOptional,
                prefixIcon: const Icon(Icons.notes_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final newLabel = labelController.text.trim();
              final newAddr = addressController.text.trim();
              final newLandmark = landmarkController.text.trim();

              if (newLabel.isNotEmpty && newAddr.isNotEmpty) {
                await SavedAddressRepository().updateSavedAddress(
                  userId: uid,
                  addressId: addr.id,
                  label: newLabel,
                  address: newAddr,
                  note: newLandmark,
                  landmark: newLandmark,
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(context.l10n.save),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAddress(
      BuildContext context, String uid, SavedAddress addr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.l10n.deleteSavedAddress),
        content:
            Text('${context.l10n.confirmDeleteSavedAddress} ("${addr.label}")'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              await SavedAddressRepository().deleteSavedAddress(
                userId: uid,
                addressId: addr.id,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(context.l10n.delete),
          ),
        ],
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
            onPressed: () async {
              Navigator.pop(ctx);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              try {
                await pv.Provider.of<RoleProvider>(context, listen: false)
                    .logout();
              } finally {
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.login,
                    (route) => false,
                  );
                }
              }
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

  // delete account
  void _deleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.deleteAccountTitle),
        content: Text(context.l10n.deleteAccountConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              try {
                await pv.Provider.of<RoleProvider>(context, listen: false)
                    .deleteAccount();
              } finally {
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.login,
                    (route) => false,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(context.l10n.deleteAccountConfirmAction),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = pv.Provider.of<RoleProvider>(context);
    final user = roleProvider.currentUser;
    final uid = user?.id ?? '';

    final displayName = user?.displayName.isNotEmpty == true
        ? user!.displayName
        : context.l10n.customerLabel;
    final email = user?.email.isNotEmpty == true ? user!.email : '';
    final phone = user?.phone?.isNotEmpty == true ? user!.phone! : '';

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
            // customer header card
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

            // contact info
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
                        phone.isNotEmpty
                            ? '+94 $phone'
                            : context.l10n.phoneNotSet,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // saved addresses section
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bookmark_border_rounded,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            context.l10n.savedAddresses,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final picked =
                              await JobLocationPicker.pickLocation(context);
                          if (picked != null && uid.isNotEmpty) {
                            await SavedAddressRepository().addSavedAddress(
                              userId: uid,
                              label: picked.label ?? 'other',
                              latitude: picked.latitude,
                              longitude: picked.longitude,
                              address: picked.address,
                              note: picked.effectiveNote,
                              landmark: picked.effectiveNote,
                            );
                          }
                        },
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text(context.l10n.addNew),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (uid.isEmpty)
                    Text(
                      context.l10n.signInToManageSavedAddresses,
                      style: TextStyle(
                          color: context.themeTextSecondary, fontSize: 12),
                    )
                  else
                    StreamBuilder<List<SavedAddress>>(
                      stream:
                          SavedAddressRepository().streamSavedAddresses(uid),
                      builder: (context, snapshot) {
                        final addresses = snapshot.data ?? [];
                        if (addresses.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: Text(
                                context.l10n.noSavedAddressesSubtitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.themeTextSecondary,
                                ),
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: addresses.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 16,
                            color: context.themeBorder.withValues(alpha: 0.6),
                          ),
                          itemBuilder: (context, index) {
                            final item = addresses[index];
                            final isHome = item.label.toLowerCase() == 'home';
                            final isWork = item.label.toLowerCase() == 'work';
                            final displayLabel = isHome
                                ? context.l10n.addressLabelHome
                                : (isWork
                                    ? context.l10n.addressLabelWork
                                    : (item.label.toLowerCase() == 'other'
                                        ? context.l10n.addressLabelOther
                                        : item.label));
                            return Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isHome
                                        ? Icons.home_rounded
                                        : (isWork
                                            ? Icons.work_rounded
                                            : Icons.location_on_rounded),
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayLabel,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.address,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: context.themeTextSecondary,
                                        ),
                                      ),
                                      if (item.effectiveNote != null &&
                                          item.effectiveNote!.isNotEmpty) ...[
                                        const SizedBox(height: 1),
                                        Text(
                                          '${context.l10n.providerNoteLabel}: ${item.effectiveNote!}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontStyle: FontStyle.italic,
                                            color: context.themeTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon:
                                      const Icon(Icons.edit_outlined, size: 16),
                                  tooltip: context.l10n.edit,
                                  onPressed: () => _showEditAddressDialog(
                                      context, uid, item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 16, color: AppColors.error),
                                  tooltip: context.l10n.delete,
                                  onPressed: () =>
                                      _confirmDeleteAddress(context, uid, item),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // settings section
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
                            children: [
                              Container(
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: context.themeBorder,
                                  borderRadius: BorderRadius.circular(2),
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
                  title: context.l10n.appLanguageLabel,
                  subtitle: context.l10n
                      .currentMode(localeProvider.languageDisplayName),
                  onTap: () => LanguageSelectSheet.show(context),
                );
              },
            ),
            _SettingsTile(
              icon: Icons.help_outline_rounded,
              title: context.l10n.helpSupportTitle,
              subtitle: context.l10n.helpSupportSubtitle,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                );
              },
            ),
            _SettingsTile(
              icon: Icons.person_remove_outlined,
              iconColor: AppColors.error,
              iconBgColor: AppColors.error.withValues(alpha: 0.12),
              titleColor: AppColors.error,
              title: context.l10n.deleteAccountTitle,
              subtitle: context.l10n.deleteAccountSubtitle,
              onTap: () => _deleteAccount(context),
            ),
            const SizedBox(height: 12),

            // become provider card
            if (!roleProvider.isRegisteredProvider)
              AppCard(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CompleteProfileScreen(
                        initialProfile: user,
                        targetRole: AppRole.provider,
                      ),
                    ),
                  );
                },
                color: const Color(0xFFD6900F).withValues(alpha: 0.1),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6900F).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.engineering_rounded,
                        color: Color(0xFFD6900F),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.becomeProvider,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            context.l10n.becomeProviderSubtitle,
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

            // provider application status badge
            if (roleProvider.isRegisteredProvider &&
                !roleProvider.isApprovedProvider)
              AppCard(
                onTap: () {
                  if (kDebugMode) {
                    debugPrint(
                        '[navdbg] -> pending from customer_profile_screen.dart');
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ProviderPendingScreen(
                        isExistingCustomer: true,
                      ),
                    ),
                  );
                },
                color: const Color(0xFFD6900F).withValues(alpha: 0.1),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD6900F).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.hourglass_top_rounded,
                        color: Color(0xFFD6900F),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.providerApplicationStatusBadge,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            context.l10n.providerApplicationUnderReview,
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

            if (roleProvider.isAuthorizedAdmin) ...[
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
                      child: const Icon(
                        Icons.admin_panel_settings_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.switchOperationalView,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            context.l10n.switchOperationalViewDesc,
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
            ] else if (roleProvider.isApprovedProvider) ...[
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
                      child: const Icon(
                        Icons.swap_vert_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.switchToProvider,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            context.l10n.switchToProviderSubtitle,
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
            ],
            const SizedBox(height: 16),
            AppOutlineButton(
              label: context.l10n.logout,
              icon: Icons.logout,
              color: AppColors.error,
              onPressed: () => _logout(context),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () =>
                      LegalContentSheet.show(context, initialTabIndex: 0),
                  child: Text(
                    context.l10n.privacyPolicy,
                    style: TextStyle(
                        fontSize: 12, color: context.themeTextSecondary),
                  ),
                ),
                Text('•', style: TextStyle(color: context.themeBorder)),
                TextButton(
                  onPressed: () =>
                      LegalContentSheet.show(context, initialTabIndex: 1),
                  child: Text(
                    context.l10n.termsOfService,
                    style: TextStyle(
                        fontSize: 12, color: context.themeTextSecondary),
                  ),
                ),
              ],
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
  final Color? iconColor;
  final Color? iconBgColor;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.iconBgColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.primary;
    final effectiveIconBgColor =
        iconBgColor ?? AppColors.primary.withValues(alpha: 0.12);

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
              color: effectiveIconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: effectiveIconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: titleColor ?? context.themeTextPrimary,
                  ),
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
