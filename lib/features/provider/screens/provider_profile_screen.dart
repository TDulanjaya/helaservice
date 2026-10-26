import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart' as pv;
import '../../../theme/app_theme.dart';
import '../../../state/role_provider.dart';
import '../../../shared/widgets/role_switch_sheet.dart';
import '../../../app_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/booking.dart';
import '../../../models/technician.dart';
import '../../../models/user_profile.dart';
import '../../../models/job_location.dart';
import '../../../shared/widgets/job_location_picker.dart';
import '../widgets/working_hours_sheet.dart';
import '../widgets/portfolio_management_sheet.dart';
import '../widgets/certificate_management_sheet.dart';
import '../widgets/rate_card_sheet.dart';
import '../../../repositories/booking_repository.dart';
import '../../../services/category_service.dart';
import '../../../repositories/technician_repository.dart';
import '../../../services/review_service.dart';
import '../../../state/theme_provider.dart';
import '../../../state/locale_provider.dart';
import '../../../shared/widgets/language_select_sheet.dart';
import '../../../utils/location_utils.dart';
import '../../../utils/provider_location_helper.dart';
import '../../../utils/provider_pricing_helper.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/app_localizations_helpers.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/legal_content_sheet.dart';
import '../../support/screens/help_support_screen.dart';
import '../../auth/screens/complete_profile_screen.dart';

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  bool? _localEmergencyAvailable;
  double? _localRadiusKm;
  bool _updatingLocation = false;
  Stream<Technician?>? _techStream;
  String _subscribedUid = '';

  // cache technician stream
  void _initTechStream(String uid) {
    if (_subscribedUid != uid) {
      _subscribedUid = uid;
      _techStream = uid.isNotEmpty
          ? TechnicianRepository().streamById(uid)
          : const Stream.empty();
    }
  }

  // format relative time
  String _formatRelativeTime(BuildContext context, DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return context.l10n.timeJustNow;
    if (diff.inMinutes < 60) return context.l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return context.l10n.timeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return context.l10n.timeDaysAgo(diff.inDays);
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  // format base location text
  String _formatBaseLocationSubtitle(
    BuildContext context,
    UserProfile? user,
    Technician? tech,
  ) {
    final hasLat = tech?.baseLat != null || user?.latitude != null;
    final hasLng = tech?.baseLng != null || user?.longitude != null;
    final hasAddress = (tech?.baseAddress?.isNotEmpty == true) ||
        (user?.address?.isNotEmpty == true);

    if (!hasLat && !hasLng && !hasAddress) {
      return context.l10n.notSetYet;
    }

    final rawAddress = (tech?.baseAddress?.isNotEmpty == true)
        ? tech!.baseAddress!
        : (user?.address ?? '');
    final area =
        (tech?.baseArea?.isNotEmpty == true ? tech!.baseArea! : null) ??
            extractBaseArea(address: rawAddress);
    final district = (user?.district?.isNotEmpty == true)
        ? LocalizedData.getDistrict(context, user!.district!)
        : '';

    String areaDisplay = '';
    if (area != null && area.isNotEmpty) {
      if (district.isNotEmpty && area.toLowerCase() != district.toLowerCase()) {
        areaDisplay = '$area, $district';
      } else {
        areaDisplay = area;
      }
    } else if (district.isNotEmpty) {
      areaDisplay = district;
    } else if (rawAddress.isNotEmpty) {
      areaDisplay = rawAddress;
    } else if (hasLat && hasLng) {
      final lat = tech?.baseLat ?? user!.latitude!;
      final lng = tech?.baseLng ?? user!.longitude!;
      areaDisplay = '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
    }

    final updatedDt = tech?.baseLocationUpdatedAt ?? tech?.currentLocationAt;
    if (updatedDt != null) {
      final timeStr = _formatRelativeTime(context, updatedDt);
      return areaDisplay.isNotEmpty
          ? '$areaDisplay · ${context.l10n.updatedTimeAgo(timeStr)}'
          : context.l10n.updatedTimeAgo(timeStr);
    }

    return areaDisplay.isNotEmpty ? areaDisplay : context.l10n.notSetYet;
  }

  Future<void> _refreshGpsLocation(BuildContext context) async {
    setState(() => _updatingLocation = true);
    try {
      final pos = await LocationUtils.getCurrentPosition();
      if (pos != null && context.mounted) {
        final roleProvider =
            pv.Provider.of<RoleProvider>(context, listen: false);
        final current = roleProvider.currentUser;
        if (current != null) {
          final updated = current.copyWith(
            latitude: pos.latitude,
            longitude: pos.longitude,
          );
          await roleProvider.completeUserProfile(updated);
          final uid = current.id.isNotEmpty
              ? current.id
              : (FirebaseAuth.instance.currentUser?.uid ?? '');
          if (uid.isNotEmpty) {
            final area = extractBaseArea(address: current.address);
            await TechnicianRepository().updateBaseLocation(
              uid,
              latitude: pos.latitude,
              longitude: pos.longitude,
              address: current.address,
              baseArea: area,
            );
          }
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

  Future<void> _pickBaseLocation(BuildContext context) async {
    final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
    final current = roleProvider.currentUser;
    final initialLoc = (current?.latitude != null && current?.longitude != null)
        ? JobLocation(
            latitude: current!.latitude!,
            longitude: current.longitude!,
            address: current.address ?? '',
          )
        : null;

    final picked = await JobLocationPicker.pickLocation(
      context,
      title: context.l10n.baseLocationTitle,
      initialLocation: initialLoc,
    );

    if (picked != null && context.mounted) {
      final updated = (current ??
              UserProfile(
                id: FirebaseAuth.instance.currentUser?.uid ?? '',
                email: '',
                displayName: '',
              ))
          .copyWith(
        latitude: picked.latitude,
        longitude: picked.longitude,
        address: picked.address,
      );
      await roleProvider.completeUserProfile(updated);
      final uid = current?.id ?? FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isNotEmpty) {
        final area =
            extractBaseArea(city: picked.city, address: picked.address);
        await TechnicianRepository().updateBaseLocation(
          uid,
          latitude: picked.latitude,
          longitude: picked.longitude,
          address: picked.address,
          baseArea: area,
        );
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(picked.address.isNotEmpty
                ? picked.address
                : '${picked.latitude.toStringAsFixed(4)}, ${picked.longitude.toStringAsFixed(4)}'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
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
            ),
            child: Text(context.l10n.logout),
          ),
        ],
      ),
    );
  }

  // delete account dialog and execution
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
            ),
            child: Text(context.l10n.deleteAccountConfirmAction),
          ),
        ],
      ),
    );
  }

  String _maskNic(String nic) {
    if (nic.isEmpty) return '';
    final trimmed = nic.trim();
    if (trimmed.length >= 8) {
      final start = trimmed.substring(0, 4);
      final end = trimmed.substring(trimmed.length - 3);
      return '$start•••••$end';
    }
    return trimmed;
  }

  String _buildRateCardSummary(BuildContext context, Technician tech) {
    final modes = tech.resolvedPricingModes;
    final parts = <String>[];
    final formatter = NumberFormat.decimalPattern('en_US');

    if (modes.contains(ProviderPricingHelper.modeDay) &&
        tech.dailyRateLkr != null &&
        tech.dailyRateLkr! > 0) {
      parts.add(context.l10n.ratePerDay(formatter.format(tech.dailyRateLkr)));
    }

    if (modes.contains(ProviderPricingHelper.modeHour) &&
        tech.hourlyRateLkr > 0) {
      parts.add(context.l10n.ratePerHour(formatter.format(tech.hourlyRateLkr)));
    }

    if (modes.contains(ProviderPricingHelper.modeJob)) {
      if (tech.baseRateLkr > 0) {
        parts.add(
            context.l10n.pricePerJobAmount(formatter.format(tech.baseRateLkr)));
      } else {
        parts.add(context.l10n.quoteEachJob);
      }
    }

    if (modes.contains(ProviderPricingHelper.modeVisit) &&
        tech.effectiveVisitFeeLkr > 0) {
      parts.add(context.l10n
          .rateVisitFee(formatter.format(tech.effectiveVisitFeeLkr)));
    }

    if (modes.contains(ProviderPricingHelper.modeTravel) &&
        tech.perKmRateLkr != null &&
        tech.perKmRateLkr! > 0) {
      parts.add(context.l10n.ratePerKm(formatter.format(tech.perKmRateLkr)));
    }

    if (parts.isEmpty) {
      return context.l10n.setYourUsualRates;
    }

    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = pv.Provider.of<RoleProvider>(context);
    final user = roleProvider.currentUser;
    _initTechStream(user?.id ?? '');

    final displayName = user?.displayName.isNotEmpty == true
        ? user!.displayName
        : context.l10n.roleProvider;
    final email = user?.email.isNotEmpty == true ? user!.email : '';
    final phone = user?.phone?.isNotEmpty == true ? user!.phone! : '';
    final category = user?.serviceCategory ?? '';
    final district = user?.district ?? context.l10n.cdmSriLanka;
    final nic = user?.nic?.isNotEmpty == true ? user!.nic! : '';
    final resolvedCatName =
        CategoryService.instance.nameOf(category, context: context);
    final categoryName = resolvedCatName.isNotEmpty
        ? resolvedCatName
        : context.l10n.provSpecialist;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.l10n.artisanProfile,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: context.l10n.switchRole,
            onPressed: () => showRoleSwitchSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              16, 8, 16, AppBottomNav.contentBottomPadding),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: context.themeSurface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: context.themeBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: context.isDark ? 0.25 : 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
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
                        radius: 36,
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
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$categoryName · ${LocalizedData.getDistrict(context, district)}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            if (email.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: context.themeTextSecondary,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF22C55E)
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 12,
                                    color: Color(0xFF22C55E),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    context.l10n.verifiedArtisan,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF22C55E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<List<Booking>>(
                    stream: BookingRepository()
                        .streamProviderBookings(user?.id ?? ''),
                    builder: (context, snapshot) {
                      final bookings = snapshot.data ?? [];
                      final completed =
                          bookings.where((b) => b.status == 'completed').length;
                      final delayed = bookings
                          .where((b) =>
                              b.delayReason != null &&
                              b.delayReason!.isNotEmpty)
                          .length;
                      final onTimePercent = completed > 0
                          ? (((completed - delayed).clamp(0, completed) /
                                      completed) *
                                  100)
                              .round()
                          : 100;

                      return StreamBuilder<List<Map<String, dynamic>>>(
                        stream: ReviewService.instance
                            .streamProviderReviews(user?.id ?? ''),
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

                          final ratingValue = avgRating != null
                              ? avgRating.toStringAsFixed(1)
                              : (completed > 0 ? '5.0' : context.l10n.newLabel);
                          final ratingSub = reviews.isNotEmpty
                              ? context.l10n.nReviews(reviews.length)
                              : (completed > 0
                                  ? context.l10n.nJobsCompleted(completed)
                                  : context.l10n.fleetActive);

                          return Row(
                            children: [
                              _StatCard(
                                icon: Icons.star_rounded,
                                iconColor: Colors.amber,
                                value: ratingValue,
                                label: context.l10n.rating,
                                sub: ratingSub,
                              ),
                              const SizedBox(width: 8),
                              _StatCard(
                                icon: Icons.check_circle_rounded,
                                iconColor: const Color(0xFF22C55E),
                                value: '$completed',
                                label: context.l10n.jobsDone,
                                sub: context.l10n.completed,
                              ),
                              const SizedBox(width: 8),
                              _StatCard(
                                icon: Icons.timer_outlined,
                                iconColor: AppColors.primary,
                                value: '$onTimePercent%',
                                label: context.l10n.onTimeArrival,
                                sub: context.l10n.promptArrival,
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.themeSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.themeBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.badge_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        context.l10n.verifiedArtisan.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.nicNumberLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.themeTextSecondary,
                        ),
                      ),
                      Text(
                        nic.isNotEmpty
                            ? _maskNic(nic)
                            : context.l10n.notProvided,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            context.l10n.nicUploaded,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: context.themeBorder),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.operatingDistrict,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.themeTextSecondary,
                        ),
                      ),
                      Text(
                        LocalizedData.getDistrict(context, district),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.l10n.phone,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.themeTextSecondary,
                          ),
                        ),
                        Text(
                          '+94 $phone',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.l10n.baseLocation,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder<Technician?>(
              stream: _techStream,
              builder: (context, techSnap) {
                final tech = techSnap.data;
                final subtitle =
                    _formatBaseLocationSubtitle(context, user, tech);
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.themeSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.themeBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.my_location_rounded,
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
                                  context.l10n.baseLocationTitle,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: context.themeTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: _updatingLocation
                                  ? null
                                  : () => _refreshGpsLocation(context),
                              icon: _updatingLocation
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.gps_fixed_rounded,
                                      size: 18),
                              label: Text(
                                context.l10n.useCurrentLocation,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: () => _pickBaseLocation(context),
                              icon: const Icon(Icons.map_outlined, size: 18),
                              label: Text(
                                context.l10n.pickOnMap,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side:
                                    const BorderSide(color: AppColors.primary),
                                foregroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            Text(
              context.l10n.jobDispatchSettings,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            StreamBuilder<Technician?>(
              stream: _techStream,
              builder: (context, techSnap) {
                if (techSnap.connectionState == ConnectionState.waiting &&
                    !techSnap.hasData) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: context.themeSurface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: context.themeBorder),
                    ),
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                final tech = techSnap.data;
                if (tech == null) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.themeSurface,
                      borderRadius: BorderRadius.circular(18),
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
                                color:
                                    AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.assignment_ind_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                context.l10n.providerProfileNotSetupDesc,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: context.themeTextSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CompleteProfileScreen(
                                    initialProfile: user,
                                    targetRole: AppRole.provider,
                                  ),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              context.l10n.completeRegistrationAction,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final radiusKm = _localRadiusKm ?? tech.serviceRadiusKm;
                final isEmergency =
                    _localEmergencyAvailable ?? tech.emergencyAvailable;

                return Container(
                  decoration: BoxDecoration(
                    color: context.themeSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.themeBorder),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        value: isEmergency,
                        activeThumbColor: Colors.white,
                        activeTrackColor: const Color(0xFF22C55E),
                        title: Text(
                          context.l10n.emergencyCallout,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          context.l10n.emergencyCalloutDesc,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: context.themeTextSecondary,
                          ),
                        ),
                        onChanged: (val) {
                          final oldVal = isEmergency;
                          setState(() => _localEmergencyAvailable = val);
                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          if (uid == null || uid.isEmpty) return;
                          final messenger = ScaffoldMessenger.of(context);
                          final offlineMsg = context.l10n.savedOfflineSyncLater;
                          final errorMsg =
                              context.l10n.couldNotSaveCheckConnection;

                          TechnicianRepository()
                              .updateEmergencyStatus(uid, val)
                              .timeout(const Duration(seconds: 8))
                              .then((_) {
                            if (mounted) {
                              setState(() => _localEmergencyAvailable = null);
                            }
                          }).catchError((err) {
                            if (err is TimeoutException) {
                              if (mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(offlineMsg),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              }
                            } else {
                              if (mounted) {
                                setState(
                                    () => _localEmergencyAvailable = oldVal);
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(errorMsg),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          });
                        },
                      ),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          context.l10n.myRateCard,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          _buildRateCardSummary(context, tech),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: context.themeTextSecondary,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: context.themeTextSecondary,
                        ),
                        onTap: () => RateCardSheet.show(context, tech),
                      ),
                      Divider(height: 1, color: context.themeBorder),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.schedule_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          context.l10n.workingHoursTitle,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          tech.isAvailableNow
                              ? context.l10n.availableNow
                              : context.l10n.outsideWorkingHours,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: tech.isAvailableNow
                                ? const Color(0xFF22C55E)
                                : context.themeTextSecondary,
                            fontWeight: tech.isAvailableNow
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: context.themeTextSecondary,
                        ),
                        onTap: () => WorkingHoursSheet.show(context, tech),
                      ),
                      Divider(height: 1, color: context.themeBorder),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.radar_rounded,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      context.l10n.serviceRadiusTitle,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    context.l10n
                                        .serviceRadiusKm(radiusKm.round()),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              context.l10n.serviceRadiusSubtitle,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: context.themeTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Slider(
                              value: radiusKm.clamp(5.0, 50.0),
                              min: 5,
                              max: 50,
                              divisions: 9,
                              label: '${radiusKm.round()} km',
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                setState(() => _localRadiusKm = val);
                              },
                              onChangeEnd: (val) {
                                final oldRadius = tech.serviceRadiusKm;
                                final uid =
                                    FirebaseAuth.instance.currentUser?.uid;
                                if (uid == null || uid.isEmpty) return;
                                final messenger = ScaffoldMessenger.of(context);
                                final offlineMsg =
                                    context.l10n.savedOfflineSyncLater;
                                final errorMsg =
                                    context.l10n.couldNotSaveCheckConnection;

                                TechnicianRepository()
                                    .updateServiceRadius(uid, val)
                                    .timeout(const Duration(seconds: 8))
                                    .then((_) {
                                  if (mounted) {
                                    setState(() => _localRadiusKm = null);
                                  }
                                }).catchError((err) {
                                  if (err is TimeoutException) {
                                    if (mounted) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(offlineMsg),
                                          backgroundColor: AppColors.primary,
                                        ),
                                      );
                                    }
                                  } else {
                                    if (mounted) {
                                      setState(
                                          () => _localRadiusKm = oldRadius);
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(errorMsg),
                                          backgroundColor: AppColors.error,
                                        ),
                                      );
                                    }
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: context.themeSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.themeBorder),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.collections_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  context.l10n.portfolioTitle,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  context.l10n.portfolioSubtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: context.themeTextSecondary,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: context.themeTextSecondary,
                ),
                onTap: () {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid != null && uid.isNotEmpty) {
                    PortfolioManagementSheet.show(context, uid);
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: context.themeSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.themeBorder),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.card_membership_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  context.l10n.certApprovedSectionTitle,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  context.l10n.certAddMore,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: context.themeTextSecondary,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: context.themeTextSecondary,
                ),
                onTap: () {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid != null && uid.isNotEmpty) {
                    CertificateManagementSheet.show(context, uid);
                  }
                },
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.l10n.appearance,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: context.themeSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.themeBorder),
              ),
              child: pv.Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        themeProvider.isDark(context)
                            ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      context.l10n.themeMode,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      '${context.l10n.currentTheme}: ${themeProvider.getModeDisplayName(context)}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: context.themeTextSecondary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: context.themeTextSecondary,
                    ),
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
                                  trailing:
                                      themeProvider.mode == ThemeMode.system
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
                                  trailing:
                                      themeProvider.mode == ThemeMode.light
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
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: context.themeSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.themeBorder),
              ),
              child: pv.Consumer<LocaleProvider>(
                builder: (context, localeProvider, _) {
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.language_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      context.l10n.appLanguage,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      '${context.l10n.currentLanguage}: ${localeProvider.languageDisplayName}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: context.themeTextSecondary,
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: context.themeTextSecondary,
                    ),
                    onTap: () => LanguageSelectSheet.show(context),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: context.themeSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.themeBorder),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.help_outline_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  context.l10n.helpSupportTitle,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  context.l10n.helpSupportSubtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: context.themeTextSecondary,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: context.themeTextSecondary,
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const HelpSupportScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => showRoleSwitchSheet(context),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.themeSurfaceLow,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: context.themeBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.home_repair_service_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
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
                          const SizedBox(height: 2),
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
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: context.themeTextSecondary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
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
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout_rounded,
                  color: AppColors.error, size: 18),
              label: Text(
                context.l10n.logout,
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                  color: AppColors.error.withValues(alpha: 0.4),
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _deleteAccount(context),
              child: Text(
                context.l10n.deleteAccountTitle,
                style: TextStyle(
                  fontSize: 12,
                  color: context.themeTextSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String sub;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: context.themeSurfaceLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.themeBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: context.themeTextSecondary,
              ),
            ),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9.5,
                color: context.themeTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
