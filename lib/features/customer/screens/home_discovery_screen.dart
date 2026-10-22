import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart' as pv;
import '../../../theme/app_theme.dart';
import '../../../models/admin_models.dart';
import '../../../models/technician.dart';
import '../../../repositories/category_repository.dart';
import '../../../repositories/technician_repository.dart';
import '../../../services/category_service.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/role_switch_sheet.dart';
import '../../../state/role_provider.dart';
import '../../../services/session_guard.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/permission_utils.dart';
import '../../../utils/customer_location_prefs.dart';
import '../../../utils/location_search_helper.dart';
import '../../../shared/widgets/job_location_picker.dart';
import '../widgets/customer_bookings_view.dart';
import '../../../shared/screens/conversations_inbox_screen.dart';
import 'customer_profile_screen.dart';
import 'post_job_request_screen.dart';
import 'provider_detail_screen.dart';
import 'emergency_dispatch_screen.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/icon_square_button.dart';
import '../../../shared/widgets/hero_card.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../../shared/widgets/notification_bell_icon.dart';
import '../../../utils/provider_pricing_helper.dart';
import '../../../utils/provider_routing_helper.dart';
import '../../auth/screens/complete_profile_screen.dart';
import '../../auth/screens/role_choice_screen.dart';
import '../../provider/screens/provider_pending_screen.dart';

class HomeDiscoveryScreen extends StatefulWidget {
  final int initialIndex;
  const HomeDiscoveryScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeDiscoveryScreen> createState() => _HomeDiscoveryScreenState();
}

class _HomeDiscoveryScreenState extends State<HomeDiscoveryScreen> {
  final CategoryRepository _categoryRepo = CategoryRepository();
  final TechnicianRepository _techRepo = TechnicianRepository();
  final TextEditingController _searchController = TextEditingController();

  static const double _initialDistanceKm = 20.0;
  static const String _initialSortBy = 'nearest';

  CustomerHomeLocation? _homeLocation;
  bool _isLocatingGps = false;
  double? _selectedDistanceKm = _initialDistanceKm; // 5, 10, 20 (default), 50, null for Any
  bool _onlyServesMyArea = false;
  String _sortBy = _initialSortBy; // 'nearest' or 'rating'

  int _selectedCategoryIndex = -1;
  String _selectedCategoryId = '';
  String _selectedCategoryName = '';
  late int _navIndex;
  String _searchQuery = '';
  String _selectedDistrict = '';
  bool _onlineOnly = false;
  bool _emergencyOnly = false;
  double _minRating = 0.0;

  bool get _hasActiveFilters =>
      _onlineOnly ||
      _emergencyOnly ||
      _minRating > 0.0 ||
      _selectedDistanceKm != _initialDistanceKm ||
      _onlyServesMyArea ||
      _sortBy != _initialSortBy;

  @override
  void initState() {
    super.initState();
    _navIndex = widget.initialIndex > 2 ? 2 : widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // check signup status and pending provider
      final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
      final user = roleProvider.currentUser;
      if (user != null) {
        if (user.role == null) {
          if (kDebugMode) {
            debugPrint(
                '[navdbg] home guard: branch user.role == null -> RoleChoiceScreen');
          }
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => RoleChoiceScreen(user: user)),
            (route) => false,
          );
          return;
        }

        if (isSignupUnfinished(user)) {
          if (kDebugMode) {
            debugPrint(
                '[navdbg] home guard: branch isSignupUnfinished -> CompleteProfileScreen');
          }
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => CompleteProfileScreen(initialProfile: user),
            ),
            (route) => false,
          );
          return;
        }

        if (isLockedNewProvider(user, roleProvider.isApprovedProvider)) {
          if (kDebugMode) {
            debugPrint(
                '[navdbg] home guard: branch isLockedNewProvider -> ProviderPendingScreen');
            debugPrint('[navdbg] -> pending from home_discovery_screen.dart');
          }
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const ProviderPendingScreen(
                isExistingCustomer: false,
              ),
            ),
            (route) => false,
          );
          return;
        }

        if (kDebugMode) {
          debugPrint(
              '[navdbg] home guard: branch passed guard -> HomeDiscoveryScreen active');
        }
      } else {
        if (kDebugMode) {
          debugPrint('[navdbg] home guard: branch user is null');
        }
      }

      PermissionUtils.checkAndPromptInitialPermissions(context);
    });
    _initCustomerLocation();
  }

  // restore cached location
  Future<void> _initCustomerLocation() async {
    final home = await CustomerLocationPrefs.getHomeLocation();
    if (home != null && mounted) {
      setState(() => _homeLocation = home);
    }
  }

  // clear saved location and restore default filters
  Future<void> _turnOffLocation() async {
    await CustomerLocationPrefs.clearHomeLocation();
    if (mounted) {
      setState(() {
        _homeLocation = null;
        _sortBy = _initialSortBy;
        _selectedDistanceKm = _initialDistanceKm;
      });
    }
  }

  // fetch gps and refresh nearby artisans
  Future<void> _handleLocationButtonTap() async {
    if (_isLocatingGps) return;

    // prompt if location services are off
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        _showLocationErrorSheet(
          message: context.l10n.locationPermissionOrGpsDisabled,
          isGpsOff: true,
        );
      }
      return;
    }

    // request permission if needed
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        if (mounted) {
          _showLocationErrorSheet(
            message: context.l10n.locationPermissionOrGpsDisabled,
            isDeniedForever: false,
          );
        }
        return;
      }
    }

    if (perm == LocationPermission.deniedForever) {
      if (mounted) {
        _showLocationErrorSheet(
          message: context.l10n.locationPermissionOrGpsDisabled,
          isDeniedForever: true,
        );
      }
      return;
    }

    setState(() => _isLocatingGps = true);

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (!LocationSearchHelper.isWithinSriLanka(
          lat: pos.latitude, lon: pos.longitude)) {
        if (mounted) {
          _showLocationErrorSheet(
            message: context.l10n.yourLocationOutsideSriLanka,
            showManualOnly: true,
          );
        }
        return;
      }

      final area = await _reverseGeocodeToArea(pos.latitude, pos.longitude);
      final homeLoc = CustomerHomeLocation(
        latitude: pos.latitude,
        longitude: pos.longitude,
        shortArea: area,
      );

      // persist locally
      await CustomerLocationPrefs.setHomeLocation(homeLoc);

      if (mounted) {
        setState(() {
          _homeLocation = homeLoc;
          _sortBy = _initialSortBy;
          _selectedDistanceKm = _initialDistanceKm;
        });
      }
    } catch (_) {
      // fallback to recent fix (< 10m old)
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null &&
            DateTime.now().difference(last.timestamp).inMinutes <= 10 &&
            LocationSearchHelper.isWithinSriLanka(
                lat: last.latitude, lon: last.longitude)) {
          final area =
              await _reverseGeocodeToArea(last.latitude, last.longitude);
          final homeLoc = CustomerHomeLocation(
            latitude: last.latitude,
            longitude: last.longitude,
            shortArea: area,
          );
          await CustomerLocationPrefs.setHomeLocation(homeLoc);
          if (mounted) {
            setState(() {
              _homeLocation = homeLoc;
              _sortBy = _initialSortBy;
              _selectedDistanceKm = _initialDistanceKm;
            });
          }
          return;
        }
      } catch (_) {}

      if (mounted) {
        _showLocationErrorSheet(
          message: context.l10n.locationPermissionOrGpsDisabled,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLocatingGps = false);
      }
    }
  }

  // backward compat
  Future<void> _useGpsForHomeLocation() => _handleLocationButtonTap();

  // show options when gps or permission fails
  Future<void> _showLocationErrorSheet({
    required String message,
    bool isGpsOff = false,
    bool isDeniedForever = false,
    bool showManualOnly = false,
  }) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.themeSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: context.themeBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.location_off_rounded,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: context.themeInk,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (!showManualOnly && (isGpsOff || isDeniedForever)) ...[
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      if (isGpsOff) {
                        Geolocator.openLocationSettings();
                      } else {
                        Geolocator.openAppSettings();
                      }
                    },
                    icon: const Icon(Icons.settings_rounded, size: 18),
                    label: Text(context.l10n.openSettings),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showChangeLocationSheet();
                  },
                  icon: const Icon(Icons.edit_location_alt_rounded, size: 18),
                  label: Text(context.l10n.setLocationManually),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.themeInk,
                    side: BorderSide(color: context.themeBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickOnMapForHomeLocation() async {
    final picked = await JobLocationPicker.pickLocation(
      context,
      title: context.l10n.selectServiceLocation,
    );
    if (picked != null) {
      final area = picked.city?.isNotEmpty == true
          ? picked.city!
          : (picked.street?.isNotEmpty == true
              ? picked.street!
              : (picked.address.split(',').first.trim()));
      final homeLoc = CustomerHomeLocation(
        latitude: picked.latitude,
        longitude: picked.longitude,
        shortArea: area.isNotEmpty ? area : 'Sri Lanka',
      );
      await CustomerLocationPrefs.setHomeLocation(homeLoc);
      if (mounted) {
        setState(() {
          _homeLocation = homeLoc;
          _sortBy = _initialSortBy;
          _selectedDistanceKm = _initialDistanceKm;
        });
      }
    }
  }

  Future<String> _reverseGeocodeToArea(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon',
      );
      final response = await http.get(url, headers: const {
        'User-Agent': 'HelaService-App/1.0 (https://helaservice.vercel.app)',
        'Referer': 'https://helaservice.vercel.app',
      }).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null) {
          final city = addr['city'] ??
              addr['town'] ??
              addr['suburb'] ??
              addr['district'] ??
              addr['village'];
          if (city != null && city.toString().trim().isNotEmpty) {
            return city.toString().trim();
          }
        }
      }
    } catch (_) {}
    return '${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)}';
  }

  Future<void> _showChangeLocationSheet() async {
    final recentPlaces = await CustomerLocationPrefs.getRecentPlaces();
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: context.themeBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.selectServiceLocation,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: context.themeInk,
                    ),
                  ),
                  if (_homeLocation != null)
                    TextButton(
                      onPressed: () async {
                        await _turnOffLocation();
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      child: const Text(
                        'Clear',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.my_location_rounded,
                      color: AppColors.primary, size: 20),
                ),
                title: Text(
                  context.l10n.useCurrentLocationAction,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _useGpsForHomeLocation();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.map_outlined,
                      color: AppColors.primary, size: 20),
                ),
                title: Text(
                  context.l10n.searchPlaceAction,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickOnMapForHomeLocation();
                },
              ),
              if (recentPlaces.isNotEmpty) ...[
                const Divider(height: 20),
                Text(
                  context.l10n.recentPlaces,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.themeTextSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: recentPlaces.map((recent) {
                    final label = recent.title.isNotEmpty
                        ? recent.title
                        : recent.address.split(',').first.trim();
                    return ActionChip(
                      avatar: const Icon(Icons.history, size: 14),
                      label: Text(label),
                      onPressed: () async {
                        final homeLoc = CustomerHomeLocation(
                          latitude: recent.latitude,
                          longitude: recent.longitude,
                          shortArea: label,
                        );
                        await CustomerLocationPrefs.setHomeLocation(homeLoc);
                        if (mounted) {
                          setState(() {
                            _homeLocation = homeLoc;
                            _sortBy = _initialSortBy;
                            _selectedDistanceKm = _initialDistanceKm;
                          });
                        }
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // show location options sheet to refresh gps or select another area
  Future<void> _showLocationOptionsMenu() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.themeSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: context.themeBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
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
                title: Text(
                  context.l10n.useCurrentLocationAction,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleLocationButtonTap();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.map_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  context.l10n.chooseAnotherArea,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showChangeLocationSheet();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // header location toggle controls with pill switch and more options button
  Widget _buildLocationHeaderControls() {
    final hasLocation = _homeLocation != null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasLocation) ...[
          Tooltip(
            message: context.l10n.locationOptions,
            child: InkWell(
              onTap: _isLocatingGps ? null : _showLocationOptionsMenu,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 40,
                alignment: Alignment.center,
                child: Icon(
                  Icons.more_horiz_rounded,
                  size: 20,
                  color: _isLocatingGps
                      ? context.themeTextSecondary.withValues(alpha: 0.4)
                      : context.themeTextSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
        MergeSemantics(
          child: Semantics(
            button: true,
            toggled: hasLocation,
            label: context.l10n.showNearbyArtisans,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLocatingGps
                    ? null
                    : () {
                        if (hasLocation) {
                          _turnOffLocation();
                        } else {
                          _handleLocationButtonTap();
                        }
                      },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 40,
                  constraints: const BoxConstraints(minHeight: 40),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: hasLocation
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : context.themeSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: hasLocation
                          ? AppColors.primary
                          : context.themeBorder,
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasLocation
                            ? Icons.location_on_rounded
                            : Icons.near_me_outlined,
                        size: 16,
                        color: hasLocation
                            ? AppColors.primary
                            : context.themeTextSecondary,
                      ),
                      const SizedBox(width: 5),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 72),
                        child: Text(
                          hasLocation
                              ? _homeLocation!.shortArea
                              : context.l10n.nearMe,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: hasLocation
                                ? context.themeInk
                                : context.themeTextSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (_isLocatingGps)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: Center(
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      else
                        IgnorePointer(
                          child: Transform.scale(
                            scale: 0.72,
                            child: Switch(
                              value: hasLocation,
                              onChanged: (_) {},
                              activeThumbColor: AppColors.primary,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // prompt to share location
  Widget _buildNoLocationNearbyCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.near_me_outlined,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.tapLocationToSeeNearby,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.themeInk,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isLocatingGps ? null : _handleLocationButtonTap,
            icon: _isLocatingGps
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.my_location_rounded, size: 18),
            label: Text(context.l10n.shareLocationAction),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _showChangeLocationSheet,
            child: Text(
              context.l10n.setLocationManually,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: context.themeBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n.filterArtisans,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: context.themeInk),
                      ),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setSheetState(() {
                                _onlineOnly = false;
                                _emergencyOnly = false;
                                _minRating = 0.0;
                                _selectedDistanceKm = _initialDistanceKm;
                                _onlyServesMyArea = false;
                                _sortBy = _initialSortBy;
                              });
                              setState(() {
                                _onlineOnly = false;
                                _emergencyOnly = false;
                                _minRating = 0.0;
                                _selectedDistanceKm = _initialDistanceKm;
                                _onlyServesMyArea = false;
                                _sortBy = _initialSortBy;
                              });
                            },
                            child: Text(
                              context.l10n.resetAllFilters,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          IconSquareButton.small(
                            icon: Icons.close_rounded,
                            onTap: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              context.l10n.onlineReadyToBid,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              context.l10n.onlineReadyToBidSub,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: context.themeTextSecondary),
                            ),
                            value: _onlineOnly,
                            activeThumbColor: AppColors.primary,
                            onChanged: (val) {
                              setSheetState(() => _onlineOnly = val);
                              setState(() => _onlineOnly = val);
                            },
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              context.l10n.emergencyDispatch,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              context.l10n.emergencyHelpSubtitle,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: context.themeTextSecondary),
                            ),
                            value: _emergencyOnly,
                            activeThumbColor: AppColors.primary,
                            onChanged: (val) {
                              setSheetState(() => _emergencyOnly = val);
                              setState(() => _emergencyOnly = val);
                            },
                          ),
                          const Divider(height: 24),
                          Text(
                            context.l10n.distanceFilter,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('5 km'),
                                selected: _selectedDistanceKm == 5.0,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: _selectedDistanceKm == 5.0
                                      ? AppColors.onPrimary
                                      : context.themeTextPrimary,
                                  fontWeight: _selectedDistanceKm == 5.0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (_) {
                                  setSheetState(
                                      () => _selectedDistanceKm = 5.0);
                                  setState(() => _selectedDistanceKm = 5.0);
                                },
                              ),
                              ChoiceChip(
                                label: const Text('10 km'),
                                selected: _selectedDistanceKm == 10.0,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: _selectedDistanceKm == 10.0
                                      ? AppColors.onPrimary
                                      : context.themeTextPrimary,
                                  fontWeight: _selectedDistanceKm == 10.0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (_) {
                                  setSheetState(
                                      () => _selectedDistanceKm = 10.0);
                                  setState(() => _selectedDistanceKm = 10.0);
                                },
                              ),
                              ChoiceChip(
                                label: const Text('20 km'),
                                selected: _selectedDistanceKm == 20.0,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: _selectedDistanceKm == 20.0
                                      ? AppColors.onPrimary
                                      : context.themeTextPrimary,
                                  fontWeight: _selectedDistanceKm == 20.0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (_) {
                                  setSheetState(
                                      () => _selectedDistanceKm = 20.0);
                                  setState(() => _selectedDistanceKm = 20.0);
                                },
                              ),
                              ChoiceChip(
                                label: const Text('50 km'),
                                selected: _selectedDistanceKm == 50.0,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: _selectedDistanceKm == 50.0
                                      ? AppColors.onPrimary
                                      : context.themeTextPrimary,
                                  fontWeight: _selectedDistanceKm == 50.0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (_) {
                                  setSheetState(
                                      () => _selectedDistanceKm = 50.0);
                                  setState(() => _selectedDistanceKm = 50.0);
                                },
                              ),
                              ChoiceChip(
                                label: Text(context.l10n.anyDistance),
                                selected: _selectedDistanceKm == null,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: _selectedDistanceKm == null
                                      ? AppColors.onPrimary
                                      : context.themeTextPrimary,
                                  fontWeight: _selectedDistanceKm == null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (_) {
                                  setSheetState(
                                      () => _selectedDistanceKm = null);
                                  setState(() => _selectedDistanceKm = null);
                                },
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              context.l10n.onlyServesMyArea,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            value: _onlyServesMyArea,
                            activeThumbColor: AppColors.primary,
                            onChanged: (val) {
                              setSheetState(() => _onlyServesMyArea = val);
                              setState(() => _onlyServesMyArea = val);
                            },
                          ),
                          const Divider(height: 24),
                          const Text(
                            'Sort by',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: Text(context.l10n.sortByNearest),
                                selected: _sortBy == 'nearest',
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: _sortBy == 'nearest'
                                      ? AppColors.onPrimary
                                      : context.themeTextPrimary,
                                  fontWeight: _sortBy == 'nearest'
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (_) {
                                  setSheetState(() => _sortBy = 'nearest');
                                  setState(() => _sortBy = 'nearest');
                                },
                              ),
                              ChoiceChip(
                                label: Text(context.l10n.sortByTopRated),
                                selected: _sortBy == 'rating',
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: _sortBy == 'rating'
                                      ? AppColors.onPrimary
                                      : context.themeTextPrimary,
                                  fontWeight: _sortBy == 'rating'
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (_) {
                                  setSheetState(() => _sortBy = 'rating');
                                  setState(() => _sortBy = 'rating');
                                },
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Text(
                            context.l10n.customerRating,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: Text(context.l10n.allRatings),
                                selected: _minRating == 0.0,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: _minRating == 0.0
                                      ? AppColors.onPrimary
                                      : context.themeTextPrimary,
                                  fontWeight: _minRating == 0.0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (_) {
                                  setSheetState(() => _minRating = 0.0);
                                  setState(() => _minRating = 0.0);
                                },
                              ),
                              ChoiceChip(
                                label: const Text('4.0+'),
                                selected: _minRating == 4.0,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: _minRating == 4.0
                                      ? AppColors.onPrimary
                                      : context.themeTextPrimary,
                                  fontWeight: _minRating == 4.0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (_) {
                                  setSheetState(() => _minRating = 4.0);
                                  setState(() => _minRating = 4.0);
                                },
                              ),
                              ChoiceChip(
                                label: const Text('4.5+'),
                                selected: _minRating == 4.5,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: _minRating == 4.5
                                      ? AppColors.onPrimary
                                      : context.themeTextPrimary,
                                  fontWeight: _minRating == 4.5
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (_) {
                                  setSheetState(() => _minRating = 4.5);
                                  setState(() => _minRating = 4.5);
                                },
                              ),
                              ChoiceChip(
                                label: const Text('4.8+'),
                                selected: _minRating == 4.8,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: _minRating == 4.8
                                      ? AppColors.onPrimary
                                      : context.themeTextPrimary,
                                  fontWeight: _minRating == 4.8
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (_) {
                                  setSheetState(() => _minRating = 4.8);
                                  setState(() => _minRating = 4.8);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        context.l10n.applyFilters,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navItems = [
      NavItem(Icons.explore, context.l10n.navExplore),
      NavItem(Icons.calendar_month, context.l10n.navBookings),
      NavItem(Icons.person, context.l10n.navProfile),
    ];

    return PopScope(
      canPop: _navIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _navIndex != 0) {
          setState(() => _navIndex = 0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _navIndex,
          children: [
            _buildExploreView(context),
            const CustomerBookingsView(),
            const CustomerProfileScreen(),
          ],
        ),
        bottomNavigationBar: AppBottomNav(
          items: navItems,
          currentIndex: _navIndex,
          onTap: (i) => setState(() => _navIndex = i),
        ),
      ),
    );
  }

  Widget _buildExploreView(BuildContext context) {
    final roleProvider = pv.Provider.of<RoleProvider>(context);
    final canSwitchRole =
        roleProvider.isAuthorizedAdmin || roleProvider.isApprovedProvider;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.themeBg,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.themeBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 34,
                  height: 34,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.appTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: context.themeInk,
                  ),
                ),
                Text(
                  context.l10n.navExplore,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: context.themeMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          const NotificationBellIcon(size: 40),
          const SizedBox(width: 8),
          IconSquareButton(
            icon: Icons.chat_bubble_outline_rounded,
            size: 40,
            iconSize: 20,
            radius: 12,
            tooltip: context.l10n.messages,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ConversationsInboxScreen(),
                ),
              );
            },
          ),
          if (canSwitchRole) ...[
            const SizedBox(width: 8),
            IconSquareButton(
              icon: Icons.swap_vert_rounded,
              size: 40,
              iconSize: 22,
              radius: 12,
              tooltip: context.l10n.switchRole,
              onTap: () => showRoleSwitchSheet(context),
            ),
          ],
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              16, 12, 16, AppBottomNav.contentBottomPadding),
          children: [
            Builder(
              builder: (ctx) {
                final user = pv.Provider.of<RoleProvider>(ctx).currentUser;
                final rawName = user?.displayName.trim() ?? '';
                final cleanName = (rawName.isNotEmpty && !rawName.contains('@'))
                    ? rawName.split(' ').first
                    : context.l10n.roleCustomer;
                return Text(
                  '${context.l10n.greetingAyubowan}, $cleanName!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: context.themeInk,
                    letterSpacing: -0.3,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.findCertifiedArtisans,
              style: TextStyle(
                fontSize: 13,
                color: context.themeTextSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: context.themeSurface,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: context.themeBorder, width: 1.5),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(
                          () => _searchQuery = val.trim().toLowerCase()),
                      style: TextStyle(color: context.themeInk, fontSize: 14),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: context.themeMuted,
                          size: 20,
                        ),
                        hintText: context.l10n.searchServiceHint,
                        hintStyle: TextStyle(
                          color: context.themeMuted,
                          fontSize: 14,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 16),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                color: context.themeMuted,
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _showFilterSheet,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.tune_rounded,
                          size: 22,
                          color: AppColors.onPrimary,
                        ),
                        if (_hasActiveFilters)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            HeroCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.needQuickService,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.postJobBannerDesc,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PostJobRequestScreen(),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.l10n.postJobAndGetQuotes,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right_rounded, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7F1D1D), Color(0xFF991B1B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.urgentHelpBannerTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.urgentHelpBannerDesc,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EmergencyDispatchScreen(),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF991B1B),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: Text(
                      context.l10n.urgentHelpBannerAction,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            StreamBuilder<List<CategoryRow>>(
              stream: _categoryRepo.streamLiveCategories(),
              builder: (context, snapshot) {
                final categories = snapshot.data ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(context.l10n.categories,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        if (_selectedCategoryIndex != -1)
                          TextButton(
                            onPressed: () => setState(() {
                              _selectedCategoryIndex = -1;
                              _selectedCategoryName = '';
                            }),
                            child: Text(context.l10n.filterAll,
                                style: const TextStyle(fontSize: 12)),
                          )
                        else
                          Text('${context.l10n.viewAll} (${categories.length})',
                              style: const TextStyle(
                                  color: AppColors.primary, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 108,
                      child: categories.isEmpty
                          ? (snapshot.connectionState == ConnectionState.waiting
                              ? const Center(child: CircularProgressIndicator())
                              : Center(
                                  child: Text(
                                      context.l10n.noCategoriesAvailable,
                                      style: TextStyle(
                                          color: context.themeTextSecondary,
                                          fontSize: 12))))
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: categories.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, i) {
                                final cat = categories[i];
                                final selected = i == _selectedCategoryIndex;
                                return SizedBox(
                                  width: 76,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (_selectedCategoryIndex == i) {
                                          _selectedCategoryIndex = -1;
                                          _selectedCategoryId = '';
                                          _selectedCategoryName = '';
                                        } else {
                                          _selectedCategoryIndex = i;
                                          _selectedCategoryId = cat.id;
                                          _selectedCategoryName =
                                              CategoryService.instance.nameOf(
                                                  cat.id,
                                                  context: context);
                                        }
                                      });
                                    },
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 58,
                                          height: 58,
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? AppColors.primary
                                                : context.themeSurfaceContainer,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(cat.icon,
                                              color: selected
                                                  ? AppColors.onPrimary
                                                  : context.themeTextSecondary,
                                              size: 26),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          CategoryService.instance
                                              .nameOf(cat.id, context: context),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11,
                                            height: 1.2,
                                            color: selected
                                                ? AppColors.primary
                                                : context.themeTextSecondary,
                                            fontWeight: selected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedCategoryName.isNotEmpty
                        ? '${context.l10n.topArtisans} — $_selectedCategoryName'
                        : (_homeLocation != null
                            ? context.l10n
                                .providersNearArea(_homeLocation!.shortArea)
                            : context.l10n.nearbyArtisans),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 8),
                _buildLocationHeaderControls(),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Technician>>(
              stream: _techRepo.streamApprovedTechnicians(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  SessionGuard.handlePermissionDenied(snapshot.error);
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ));
                }

                // require location before loading the general feed
                if (_homeLocation == null &&
                    _selectedCategoryId.isEmpty &&
                    _searchQuery.isEmpty) {
                  return _buildNoLocationNearbyCard(context);
                }

                final rawList = snapshot.data ?? [];
                final List<_TechDistanceEntry> entries = [];

                for (final tech in rawList) {
                  double? dist;
                  bool serves = true;

                  if (_homeLocation != null) {
                    final effLoc = tech.effectiveLocation;
                    if (effLoc.hasLocation) {
                      dist = Geolocator.distanceBetween(
                            _homeLocation!.latitude,
                            _homeLocation!.longitude,
                            effLoc.latitude!,
                            effLoc.longitude!,
                          ) /
                          1000.0;
                    }

                    if (tech.baseLat != null && tech.baseLng != null) {
                      final distToBase = Geolocator.distanceBetween(
                            _homeLocation!.latitude,
                            _homeLocation!.longitude,
                            tech.baseLat!,
                            tech.baseLng!,
                          ) /
                          1000.0;
                      final radius = tech.serviceRadiusKm > 0
                          ? tech.serviceRadiusKm
                          : 20.0;
                      serves = distToBase <= radius;
                    } else {
                      final area = tech.serviceArea.toLowerCase();
                      final custArea = _homeLocation!.shortArea.toLowerCase();
                      serves = area.isEmpty ||
                          area.contains(custArea) ||
                          custArea.contains(area);
                    }
                  }

                  entries.add(_TechDistanceEntry(
                    tech: tech,
                    distanceKm: dist,
                    servesArea: serves,
                  ));
                }

                var filtered = entries;

                if (_selectedCategoryId.isNotEmpty) {
                  filtered = filtered
                      .where((e) => e.tech.category == _selectedCategoryId)
                      .toList();
                }

                if (_selectedDistrict.isNotEmpty) {
                  filtered = filtered.where((e) {
                    final area = e.tech.serviceArea.toLowerCase();
                    return area.isEmpty ||
                        area.contains(_selectedDistrict.toLowerCase());
                  }).toList();
                }

                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((e) {
                    return e.tech.name.toLowerCase().contains(_searchQuery) ||
                        e.tech.title.toLowerCase().contains(_searchQuery) ||
                        e.tech.serviceArea.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                if (_onlineOnly) {
                  filtered = filtered.where((e) => e.tech.online).toList();
                }
                if (_emergencyOnly) {
                  filtered = filtered
                      .where((e) => e.tech.emergencyRateLkr > 0)
                      .toList();
                }
                if (_minRating > 0.0) {
                  filtered = filtered
                      .where((e) => (e.tech.rating ?? 0.0) >= _minRating)
                      .toList();
                }

                if (_homeLocation != null && _selectedDistanceKm != null) {
                  filtered = filtered
                      .where((e) =>
                          e.distanceKm != null &&
                          e.distanceKm! <= _selectedDistanceKm!)
                      .toList();
                }

                if (_homeLocation != null && _onlyServesMyArea) {
                  filtered = filtered.where((e) => e.servesArea).toList();
                }

                if (_sortBy == 'nearest' && _homeLocation != null) {
                  filtered.sort((a, b) {
                    final distA = a.distanceKm ?? 999999.0;
                    final distB = b.distanceKm ?? 999999.0;
                    final cmp = distA.compareTo(distB);
                    if (cmp != 0) return cmp;
                    return (b.tech.rating ?? 0.0)
                        .compareTo(a.tech.rating ?? 0.0);
                  });
                } else {
                  filtered.sort((a, b) =>
                      (b.tech.rating ?? 0.0).compareTo(a.tech.rating ?? 0.0));
                }

                if (filtered.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: context.themeSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.themeBorder),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.person_search,
                            size: 42, color: AppColors.outline),
                        const SizedBox(height: 10),
                        Text(
                          context.l10n.noArtisansMatchFilters,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.l10n.tryClearingSearchOrFilters,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, color: context.themeTextSecondary),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            if (_homeLocation != null &&
                                _selectedDistanceKm != null) ...[
                              OutlinedButton(
                                onPressed: () =>
                                    setState(() => _selectedDistanceKm = 50.0),
                                child: Text(context.l10n.showUpTo50Km),
                              ),
                              OutlinedButton(
                                onPressed: () =>
                                    setState(() => _selectedDistanceKm = null),
                                child: Text(context.l10n.anyDistance),
                              ),
                            ],
                            TextButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _selectedCategoryIndex = -1;
                                  _selectedCategoryName = '';
                                  _selectedDistrict = '';
                                  _onlineOnly = false;
                                  _emergencyOnly = false;
                                  _minRating = 0.0;
                                  _selectedDistanceKm = 20.0;
                                  _onlyServesMyArea = false;
                                  _sortBy = 'nearest';
                                });
                              },
                              child: Text(context.l10n.resetAllFilters),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _ArtisanCard(
                      tech: item.tech,
                      distanceKm: item.distanceKm,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TechDistanceEntry {
  final Technician tech;
  final double? distanceKm;
  final bool servesArea;
  const _TechDistanceEntry({
    required this.tech,
    this.distanceKm,
    required this.servesArea,
  });
}

class _ArtisanCard extends StatelessWidget {
  final Technician tech;
  final double? distanceKm;
  const _ArtisanCard({required this.tech, this.distanceKm});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProviderDetailScreen(technician: tech),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserAvatar(
            uid: tech.id,
            displayName: tech.name,
            radius: 24,
            backgroundColor: tech.avatarColor,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        tech.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: context.themeInk,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (tech.nicVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.verified_rounded,
                        size: 16,
                        color: AppColors.success,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  tech.title,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.themeTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (tech.isNewProvider) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
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
                        size: 15,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${tech.rating!.toStringAsFixed(1)} (${tech.reviewCount})',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: context.themeInk,
                        ),
                      ),
                    ],
                    const SizedBox(width: 10),
                    Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: context.themeMuted,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        tech.serviceArea.isNotEmpty
                            ? tech.serviceArea
                            : context.l10n.custFallbackColombo,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: context.themeTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (distanceKm != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '•',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: context.themeMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        distanceKm! < 1.0
                            ? context.l10n.under1KmAway
                            : '${distanceKm!.toStringAsFixed(1)} km away',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusPill(
                      type: tech.isAvailableNow
                          ? StatusPillType.online
                          : (tech.online
                              ? StatusPillType.pending
                              : StatusPillType.offline),
                      label: tech.isAvailableNow
                          ? context.l10n.availableNow
                          : (tech.online
                              ? context.l10n.outsideWorkingHours
                              : context.l10n.statusOffline),
                      showDot: true,
                    ),
                    if (tech.online)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              context.l10n.onlineNowBadge,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!tech.hasPricingMode(ProviderPricingHelper.modeTravel))
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          context.l10n.travelIncluded,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            color: context.themeMuted,
            size: 22,
          ),
        ],
      ),
    );
  }
}
