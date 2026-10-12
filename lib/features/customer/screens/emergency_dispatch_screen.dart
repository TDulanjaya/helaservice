import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart' as pv;
import '../../../theme/app_theme.dart';
import '../../../models/technician.dart';
import '../../../models/booking.dart';
import '../../../models/admin_models.dart';
import '../../../constants/job_status.dart';
import '../../../repositories/technician_repository.dart';
import '../../../repositories/booking_repository.dart';
import '../../../repositories/category_repository.dart';
import '../../../services/analytics_service.dart';
import '../../../state/role_provider.dart';
import '../../../utils/location_utils.dart';
import '../../../utils/map_launcher.dart';
import '../../../utils/l10n_extension.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/icon_square_button.dart';
import '../../../shared/widgets/job_location_picker.dart';
import 'live_tracking_screen.dart';

// emergency dispatch screen for urgent callouts within fifteen kilometers
class EmergencyDispatchScreen extends StatefulWidget {
  final String? initialCategory;

  const EmergencyDispatchScreen({
    super.key,
    this.initialCategory,
  });

  @override
  State<EmergencyDispatchScreen> createState() => _EmergencyDispatchScreenState();
}

class _EmergencyDispatchScreenState extends State<EmergencyDispatchScreen>
    with SingleTickerProviderStateMixin {
  final TechnicianRepository _techRepo = TechnicianRepository();
  final BookingRepository _bookingRepo = BookingRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();

  String _selectedCategory = '';
  late AnimationController _pulseController;
  Timer? _countdownTimer;
  int _remainingSeconds = 120;
  bool _isCreatingBooking = false;

  double? _userLat;
  double? _userLng;
  String _userAddress = '';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? '';
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _startCountdown();
    _resolveUserLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _remainingSeconds = 120;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _resolveUserLocation() async {
    final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
    final user = roleProvider.currentUser;

    if (user?.latitude != null && user?.longitude != null) {
      setState(() {
        _userLat = user!.latitude;
        _userLng = user.longitude;
        _userAddress = user.address ?? '';
      });
      return;
    }

    try {
      final pos = await LocationUtils.getCurrentPosition();
      if (pos != null && mounted) {
        setState(() {
          _userLat = pos.latitude;
          _userLng = pos.longitude;
        });
      }
    } catch (_) {}
  }

  // format seconds to mm ss
  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  // calculate distance in kilometers between customer and provider
  double _getDistanceKm(Technician tech) {
    if (_userLat == null || _userLng == null) return 5.0;
    return 3.5;
  }

  // estimated minutes for emergency arrival
  int _calculateEtaMinutes(double distKm) {
    final mins = (distKm * 2.5 + 8).round();
    return mins.clamp(10, 45);
  }

  void _confirmEmergencyCallout(BuildContext context, Technician tech) {
    final rateLkr = tech.emergencyRateLkr > 0 ? tech.emergencyRateLkr : 3500;
    final addressController = TextEditingController(text: _userAddress);
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: ctx.themeSurface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ctx.themeBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: AppColors.error,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.confirmEmergencyBookingTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tech.name,
                            style: TextStyle(
                              fontSize: 13,
                              color: context.themeTextSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.confirmEmergencyBookingDesc(
                    tech.name,
                    rateLkr.toString(),
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    color: context.themeTextSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.emergencyAddressPrompt,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: addressController,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: context.l10n.serviceAddressHint,
                    prefixIcon: const Icon(Icons.location_on_rounded, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  context.l10n.emergencyNotesPrompt,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: context.l10n.emergencyNotesHint,
                    prefixIcon: const Icon(Icons.notes_rounded, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isCreatingBooking
                        ? null
                        : () async {
                            final currentAddress = addressController.text.trim();
                            if (currentAddress.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.l10n.pleaseEnterServiceLocation),
                                ),
                              );
                              return;
                            }

                            Navigator.pop(ctx);
                            await _executeEmergencyBooking(
                              tech: tech,
                              rateLkr: rateLkr,
                              address: currentAddress,
                              notes: notesController.text.trim(),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      context.l10n.requestEmergencyCallout,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _executeEmergencyBooking({
    required Technician tech,
    required int rateLkr,
    required String address,
    required String notes,
  }) async {
    final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
    final user = roleProvider.currentUser;
    setState(() => _isCreatingBooking = true);

    try {
      if (_userLat == null || _userLng == null) {
        setState(() => _isCreatingBooking = false);
        final picked = await JobLocationPicker.pickLocation(
          context,
          title: context.l10n.selectJobLocation,
        );
        if (picked == null ||
            picked.latitude == 0.0 ||
            picked.longitude == 0.0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.locationPermissionRequired),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }
        _userLat = picked.latitude;
        _userLng = picked.longitude;
        if (picked.address.isNotEmpty) {
          _userAddress = picked.address;
        }
        setState(() => _isCreatingBooking = true);
      }

      final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

      final booking = Booking(
        id: '',
        title: tech.category.isNotEmpty ? tech.category : tech.title,
        status: JobStatus.pending,
        providerName: tech.name,
        providerId: tech.id,
        providerPhone: tech.phone,
        customerId: currentUid,
        customerName: user?.displayName ?? '',
        customerInitials: (user?.displayName.isNotEmpty == true)
            ? user!.displayName[0].toUpperCase()
            : 'C',
        customerPhone: user?.phone ?? '',
        location: address.isNotEmpty ? address : _userAddress,
        distance: '',
        relativeTime: '',
        customerLatitude: _userLat!,
        customerLongitude: _userLng!,
        estRate: 'LKR $rateLkr',
        agreedPrice: rateLkr.toDouble(),
        time: '',
        entryInstructions: notes,
        createdAt: DateTime.now(),
        type: 'urgent',
        expiresAt: DateTime.now().add(const Duration(minutes: 3)),
        quoteType: 'inspect',
        priceStatus: 'awaiting_confirmation',
        visitFeeLkr: rateLkr,
        travelCostLkr: 0,
        estimatedTotalLkr: rateLkr,
      );

      final bookingId = await _bookingRepo.createBooking(booking);

      AnalyticsService.instance.logEmergencyRequested(
        customerId: currentUid,
        category: tech.category,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => LiveTrackingScreen(
              booking: booking.copyWith(id: bookingId),
              technician: tech,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().contains('LOCATION_REQUIRED')
            ? context.l10n.locationRequiredToBook
            : (e.toString().contains('PROVIDER_CATEGORY_MISSING')
                ? context.l10n.errorProviderCategoryMissing
                : e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBg,
      appBar: AppBar(
        title: Text(
          context.l10n.emergencyDispatchTitle,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: context.l10n.refreshGps,
            onPressed: () {
              _startCountdown();
              _resolveUserLocation();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // live radar scanning bar and countdown timer
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.error.withValues(
                            alpha: 0.2 + (_pulseController.value * 0.4),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.radar_rounded,
                            color: AppColors.error,
                            size: 16,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.scanningNearbyProviders,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.emergencyDispatchSubtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: context.themeTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _formatTimer(_remainingSeconds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        fontFeatures: [],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // trade category filter pills
            StreamBuilder<List<CategoryRow>>(
              stream: _categoryRepo.streamLiveCategories(),
              builder: (context, catSnap) {
                final categories = catSnap.data ?? [];
                return SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(context.l10n.filterAll),
                          selected: _selectedCategory.isEmpty,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: _selectedCategory.isEmpty
                                ? AppColors.onPrimary
                                : context.themeTextPrimary,
                            fontWeight: _selectedCategory.isEmpty
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                          onSelected: (_) =>
                              setState(() => _selectedCategory = ''),
                        ),
                      ),
                      ...categories.map((cat) {
                        final catName = cat.name;
                        final isSelected =
                            _selectedCategory.toLowerCase() ==
                                catName.toLowerCase();
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(catName),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppColors.onPrimary
                                  : context.themeTextPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (_) => setState(
                              () => _selectedCategory = isSelected ? '' : catName,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            // emergency technicians stream list
            Expanded(
              child: StreamBuilder<List<Technician>>(
                stream: _techRepo.streamApprovedTechnicians(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allTechs = snap.data ?? [];
                  final filtered = allTechs.where((t) {
                    if (!t.online) return false;
                    if (!t.emergencyAvailable) return false;
                    if (_selectedCategory.isNotEmpty) {
                      final matchesCategory = t.category
                              .toLowerCase()
                              .contains(_selectedCategory.toLowerCase()) ||
                          t.title
                              .toLowerCase()
                              .contains(_selectedCategory.toLowerCase());
                      if (!matchesCategory) return false;
                    }
                    return true;
                  }).toList();

                  // sort by rating descending
                  filtered.sort((a, b) => (b.rating ?? 0.0).compareTo(a.rating ?? 0.0));

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: context.themeBorder.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_search_rounded,
                                size: 48,
                                color: context.themeMuted,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              context.l10n.noEmergencyProvidersFound,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.l10n.noEmergencyProvidersDesc,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: context.themeTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final tech = filtered[idx];
                      final distKm = _getDistanceKm(tech);
                      final etaMins = _calculateEtaMinutes(distKm);
                      final rateLkr = tech.emergencyRateLkr > 0
                          ? tech.emergencyRateLkr
                          : 3500;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.themeSurface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: context.themeBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                UserAvatar(
                                  displayName: tech.name,
                                  uid: tech.id,
                                  backgroundColor: tech.avatarColor,
                                  radius: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              tech.name,
                                              style: const TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (tech.nicVerified) ...[
                                            const SizedBox(width: 4),
                                            const Icon(
                                              Icons.verified_rounded,
                                              color: AppColors.primary,
                                              size: 16,
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        tech.category.isNotEmpty
                                            ? tech.category
                                            : tech.title,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: context.themeTextSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          if (tech.isNewProvider || tech.rating == null) ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                context.l10n.newProviderBadge,
                                                style: const TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ] else ...[
                                            const Icon(
                                              Icons.star_rounded,
                                              color: Color(0xFFF59E0B),
                                              size: 15,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              tech.rating!.toStringAsFixed(1),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              context.l10n.distanceKmAway(
                                                distKm.toStringAsFixed(1),
                                              ),
                                              style: const TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Divider(height: 1, color: context.themeBorder),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.l10n.emergencyCalloutRate,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: context.themeTextSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'LKR $rateLkr',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.timer_outlined,
                                          size: 14,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          context.l10n.emergencyEtaApprox(etaMins),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 42,
                              child: ElevatedButton.icon(
                                onPressed: _isCreatingBooking
                                    ? null
                                    : () => _confirmEmergencyCallout(context, tech),
                                icon: const Icon(Icons.bolt_rounded, size: 18),
                                label: Text(
                                  context.l10n.requestEmergencyCallout,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // bottom emergency hotlines section
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: BoxDecoration(
                color: context.themeSurface,
                border: Border(top: BorderSide(color: context.themeBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.emergencyHotlinesTitle,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '119 Police | 1990 Ambulance | 110 Fire',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: context.themeTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconSquareButton.small(
                    icon: Icons.phone_in_talk_rounded,
                    tooltip: context.l10n.call,
                    onTap: () => MapLauncher.openPhoneCall('119'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
