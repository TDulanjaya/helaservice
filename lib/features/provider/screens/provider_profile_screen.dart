import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import '../../../theme/app_theme.dart';
import '../../../state/role_provider.dart';
import '../../../shared/widgets/role_switch_sheet.dart';
import '../../../app_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/booking.dart';
import '../../../repositories/booking_repository.dart';
import '../../../repositories/technician_repository.dart';
import '../../../services/review_service.dart';
import '../../../state/theme_provider.dart';
import '../../../state/locale_provider.dart';
import '../../../shared/widgets/language_select_sheet.dart';
import '../../../utils/location_utils.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/app_localizations_helpers.dart';
import '../../../shared/widgets/user_avatar.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  bool _emergencyAvailable = true;
  bool _updatingLocation = false;

  Future<void> _refreshGpsLocation(BuildContext context) async {
    setState(() => _updatingLocation = true);
    try {
      final pos = await LocationUtils.getCurrentPosition();
      if (pos != null && context.mounted) {
        final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
        final current = roleProvider.currentUser;
        if (current != null) {
          final updated = current.copyWith(
            latitude: pos.latitude,
            longitude: pos.longitude,
          );
          await roleProvider.completeUserProfile(updated);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${context.l10n.gpsDetected}: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}',
                ),
                backgroundColor: AppColors.primary,
              ),
            );
          }
        }
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.gpsHint),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingLocation = false);
    }
  }

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.logout),
        content: Text(context.l10n.logoutConfirm),
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
        : 'Service Provider';
    final email = user?.email.isNotEmpty == true
        ? user!.email
        : '';
    final phone = user?.phone?.isNotEmpty == true ? user!.phone! : '';
    final category = user?.serviceCategory ?? 'Specialist';
    final district = user?.district ?? 'Sri Lanka';
    final nic = user?.nic?.isNotEmpty == true ? user!.nic! : '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.artisanProfile,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: context.l10n.switchRole,
            onPressed: () => showRoleSwitchSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.themeSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.themeBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      UserAvatar(
                        uid: user?.id,
                        displayName: displayName,
                        photoUrl: user?.photoUrl,
                        radius: 34,
                        editable: true,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              LocalizedData.getCategory(context, category),
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.themeTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<List<Booking>>(
                    stream: BookingRepository().streamProviderBookings(user?.id ?? ''),
                    builder: (context, snapshot) {
                      final bookings = snapshot.data ?? [];
                      final completed = bookings.where((b) => b.status == 'completed').length;
                      final delayed = bookings.where((b) => b.delayReason != null && b.delayReason!.isNotEmpty).length;
                      final onTimePercent = completed > 0
                          ? (((completed - delayed).clamp(0, completed) / completed) * 100).round()
                          : 100;

                      return StreamBuilder<List<Map<String, dynamic>>>(
                        stream: ReviewService.instance.streamProviderReviews(user?.id ?? ''),
                        builder: (context, revSnap) {
                          final reviews = revSnap.data ?? [];
                          final double? avgRating = reviews.isNotEmpty
                              ? (reviews
                                      .map((r) =>
                                          (r['rating'] as num?)?.toDouble() ??
                                          5.0)
                                      .reduce((a, b) => a + b) /
                                  reviews.length)
                              : null;

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.themeSurfaceLow,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: context.themeBorder),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _StatColumn(
                                    label: context.l10n.rating,
                                    value: avgRating != null
                                        ? avgRating.toStringAsFixed(1)
                                        : (completed > 0 ? '5.0' : 'New'),
                                    sub: reviews.isNotEmpty
                                        ? '${reviews.length} reviews'
                                        : (completed > 0
                                            ? '$completed jobs'
                                            : 'Fleet Active'),
                                  ),
                                ),
                                Container(
                                    width: 1,
                                    height: 28,
                                    color: context.themeBorder),
                                Expanded(
                                  child: _StatColumn(
                                    label: context.l10n.jobsDone,
                                    value: '$completed',
                                    sub: context.l10n.completed,
                                  ),
                                ),
                                Container(
                                    width: 1,
                                    height: 28,
                                    color: context.themeBorder),
                                Expanded(
                                  child: _StatColumn(
                                    label: context.l10n.onTimeArrival,
                                    value: '$onTimePercent%',
                                    sub: context.l10n.promptArrival,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.themeSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.themeBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        context.l10n.verifiedArtisan,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('NIC: $nic',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    '${context.l10n.operatingDistrict}: ${LocalizedData.getDistrict(context, district)}${phone.isNotEmpty ? ' · ${context.l10n.phone}: +94 $phone' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.themeTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      context.l10n.nicUploaded,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            Text(
              context.l10n.baseLocation,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.themeSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.themeBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.my_location, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.latitude != null
                                  ? 'GPS: ${user!.latitude!.toStringAsFixed(4)}, ${user.longitude!.toStringAsFixed(4)}'
                                  : context.l10n.noGpsSet,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              context.l10n.distanceCalcHint,
                              style: TextStyle(fontSize: 11.5, color: context.themeTextSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: OutlinedButton.icon(
                      onPressed: _updatingLocation ? null : () => _refreshGpsLocation(context),
                      icon: _updatingLocation
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.gps_fixed, size: 15),
                      label: Text(
                        _updatingLocation ? context.l10n.statusPending : context.l10n.autoDetectGps,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            Text(
              context.l10n.jobDispatchSettings,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: context.themeSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.themeBorder),
              ),
              child: SwitchListTile(
                value: _emergencyAvailable,
                activeThumbColor: AppColors.primary,
                title: Text(
                  context.l10n.emergencyCallout,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  context.l10n.emergencyCalloutDesc,
                  style: TextStyle(
                      fontSize: 11.5, color: context.themeTextSecondary),
                ),
                onChanged: (val) async {
                  setState(() => _emergencyAvailable = val);
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid != null && uid.isNotEmpty) {
                    await TechnicianRepository().updateEmergencyStatus(uid, val);
                  }
                },
              ),
            ),

            const SizedBox(height: 18),
            Text(
              context.l10n.appearance,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: context.themeSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.themeBorder),
              ),
              child: pv.Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return ListTile(
                    leading: Icon(
                      themeProvider.isDark(context)
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    title: Text(context.l10n.themeMode,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      '${context.l10n.currentTheme}: ${themeProvider.getModeDisplayName(context)} (${context.l10n.tapToChange})',
                      style: TextStyle(
                          fontSize: 11.5, color: context.themeTextSecondary),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: context.themeSurface,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (sheetCtx) => SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(context.l10n.themeMode,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                ListTile(
                                  leading: const Icon(Icons.brightness_auto),
                                  title: Text(context.l10n.themeSystem),
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
                                  title: Text(context.l10n.themeLight),
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
                                  title: Text(context.l10n.themeDark),
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
            ),

            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: context.themeSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.themeBorder),
              ),
              child: pv.Consumer<LocaleProvider>(
                builder: (context, localeProvider, _) {
                  return ListTile(
                    leading: const Icon(Icons.language,
                        color: AppColors.primary),
                    title: Text(context.l10n.appLanguage,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      '${context.l10n.currentLanguage}: ${localeProvider.languageDisplayName} (${context.l10n.tapToChange})',
                      style: TextStyle(
                          fontSize: 12, color: context.themeTextSecondary),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios,
                        size: 14, color: AppColors.outline),
                    onTap: () => LanguageSelectSheet.show(context),
                  );
                },
              ),
            ),

            const SizedBox(height: 14),
            InkWell(
              onTap: () => showRoleSwitchSheet(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.themeSurfaceLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: context.themeBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.home_repair_service_outlined,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.switchToCustomer,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            context.l10n.switchToCustomerDesc,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: context.themeTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 14, color: context.themeTextSecondary),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, color: AppColors.error, size: 18),
              label: Text(
                context.l10n.logout,
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final String sub;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        ),
        Text(
          sub,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: context.themeTextSecondary),
        ),
      ],
    );
  }
}
