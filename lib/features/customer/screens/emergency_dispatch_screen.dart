import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart' as pv;
import '../../../theme/app_theme.dart';
import '../../../models/technician.dart';
import '../../../models/booking.dart';
import '../../../models/admin_models.dart';
import '../../../constants/job_status.dart';
import '../../../repositories/technician_repository.dart';
import '../../../repositories/booking_repository.dart';
import '../../../repositories/category_repository.dart';
import '../../../repositories/saved_address_repository.dart';
import '../../../repositories/user_repository.dart';
import '../../../models/saved_address.dart';
import '../../../services/analytics_service.dart';
import '../../../services/category_service.dart';
import '../../../state/role_provider.dart';
import '../../../utils/location_utils.dart';
import '../../../utils/permission_utils.dart';
import '../../../utils/map_launcher.dart';
import '../../../utils/l10n_extension.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/icon_square_button.dart';
import '../../../models/job_location.dart';
import '../../../shared/widgets/job_location_picker.dart';
import '../../../utils/customer_location_prefs.dart';
import '../../../utils/location_search_helper.dart';
import '../../../utils/provider_pricing_helper.dart';
import 'live_tracking_screen.dart';

// emergency dispatch screen for urgent callouts within fifteen kilometers
class EmergencyDispatchScreen extends StatefulWidget {
  final String? initialCategory;

  const EmergencyDispatchScreen({
    super.key,
    this.initialCategory,
  });

  @override
  State<EmergencyDispatchScreen> createState() =>
      _EmergencyDispatchScreenState();
}

class _EmergencyDispatchScreenState extends State<EmergencyDispatchScreen>
    with SingleTickerProviderStateMixin {
  final TechnicianRepository _techRepo = TechnicianRepository();
  final BookingRepository _bookingRepo = BookingRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();

  String _selectedCategory = '';
  late AnimationController _pulseController;
  bool _isCreatingBooking = false;

  // cache streams to avoid flicker
  late final Stream<List<CategoryRow>> _categoriesStream;
  late final Stream<List<Technician>> _techStream;
  Stream<List<SavedAddress>>? _savedAddressesStream;
  String? _savedAddressUid;
  Key _countdownKey = UniqueKey();

  double? _userLat;
  double? _userLng;
  String _userAddress = '';

  bool _isGpsLoading = false;
  bool _gpsFailed = false;
  bool _permissionPermanentlyDenied = false;
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  DateTime _lastNetworkRequestTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCategory?.trim() ?? '';
    final resolved = initial.isNotEmpty
        ? CategoryService.instance.resolveCategoryId(initial)
        : '';
    _selectedCategory = resolved.isNotEmpty ? resolved : initial;
    _categoriesStream = _categoryRepo.streamLiveCategories();
    _techStream = _techRepo.streamApprovedTechnicians();
    _initSavedAddressesStream(FirebaseAuth.instance.currentUser?.uid);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _resolveUserLocation();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initSavedAddressesStream(FirebaseAuth.instance.currentUser?.uid);
  }

  void _initSavedAddressesStream(String? uid) {
    if (uid == null || uid.isEmpty) {
      _savedAddressesStream = null;
      _savedAddressUid = null;
      return;
    }
    if (_savedAddressUid == uid) return;
    _savedAddressUid = uid;
    _savedAddressesStream = SavedAddressRepository().streamSavedAddresses(uid);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _rateLimit() async {
    final now = DateTime.now();
    final elapsed = now.difference(_lastNetworkRequestTime);
    if (elapsed.inMilliseconds < 1000) {
      await Future.delayed(
          Duration(milliseconds: 1000 - elapsed.inMilliseconds));
    }
    _lastNetworkRequestTime = DateTime.now();
  }

  Future<void> _reverseGeocode(double lat, double lon) async {
    await _rateLimit();
    if (!mounted) return;

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon',
      );
      final response = await http
          .get(
            url,
            headers: kIsWeb
                ? const <String, String>{}
                : const <String, String>{
                    'User-Agent': 'HelaService-App/1.0',
                    'Referer': 'https://helaservice.vercel.app',
                  },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final displayName = (data['display_name'] as String?) ?? '';
        final addr = data['address'] as Map<String, dynamic>?;

        String road = '';
        String area = '';
        String city = '';

        if (addr != null) {
          road = (addr['road'] ?? addr['street'] ?? '') as String;
          area = (addr['suburb'] ??
              addr['neighbourhood'] ??
              addr['village'] ??
              '') as String;
          city = (addr['city'] ??
              addr['town'] ??
              addr['municipality'] ??
              addr['county'] ??
              '') as String;
        }

        final parts = [road, area, city].where((s) => s.isNotEmpty).toList();
        final formatted = parts.isNotEmpty ? parts.join(', ') : displayName;

        if (mounted) {
          setState(() {
            _userAddress = formatted.isNotEmpty ? formatted : displayName;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _resolveUserLocation() async {
    setState(() {
      _isGpsLoading = true;
      _gpsFailed = false;
      _permissionPermanentlyDenied = false;
    });

    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isGpsLoading = false;
            _gpsFailed = true;
            _permissionPermanentlyDenied = true;
          });
        }
        return;
      }

      if (!mounted) return;
      final granted =
          await PermissionUtils.requestLocationWithRationale(context);
      if (!granted) {
        final postPerm = await Geolocator.checkPermission();
        if (mounted) {
          setState(() {
            _isGpsLoading = false;
            _gpsFailed = true;
            _permissionPermanentlyDenied =
                postPerm == LocationPermission.deniedForever;
          });
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (mounted) {
        if (LocationSearchHelper.isWithinSriLanka(
            lat: pos.latitude, lon: pos.longitude)) {
          setState(() {
            _userLat = pos.latitude;
            _userLng = pos.longitude;
            _isGpsLoading = false;
            _gpsFailed = false;
          });
          unawaited(_reverseGeocode(pos.latitude, pos.longitude));
        } else {
          setState(() {
            _isGpsLoading = false;
            _gpsFailed = true;
          });
        }
      }
    } catch (_) {
      // check last known position within 10 minutes
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          final ageMins = DateTime.now().difference(last.timestamp).inMinutes;
          if (ageMins <= 10 &&
              LocationSearchHelper.isWithinSriLanka(
                  lat: last.latitude, lon: last.longitude)) {
            if (mounted) {
              setState(() {
                _userLat = last.latitude;
                _userLng = last.longitude;
                _isGpsLoading = false;
                _gpsFailed = false;
              });
              unawaited(_reverseGeocode(last.latitude, last.longitude));
              return;
            }
          }
        }
      } catch (_) {}

      // check saved customer home location
      final homeLoc = await CustomerLocationPrefs.getHomeLocation();
      if (homeLoc != null &&
          LocationSearchHelper.isWithinSriLanka(
              lat: homeLoc.latitude, lon: homeLoc.longitude)) {
        if (mounted) {
          setState(() {
            _userLat = homeLoc.latitude;
            _userLng = homeLoc.longitude;
            _userAddress = homeLoc.shortArea;
            _isGpsLoading = false;
            _gpsFailed = false;
          });
          return;
        }
      }

      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid != null && currentUid.isNotEmpty) {
        try {
          final profile = await UserRepository().getUserById(currentUid);
          if (profile?.latitude != null &&
              profile?.longitude != null &&
              LocationSearchHelper.isWithinSriLanka(
                  lat: profile!.latitude!, lon: profile.longitude!)) {
            if (mounted) {
              setState(() {
                _userLat = profile.latitude;
                _userLng = profile.longitude;
                _userAddress = profile.address ?? '';
                _isGpsLoading = false;
                _gpsFailed = false;
              });
              return;
            }
          }
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _isGpsLoading = false;
          _gpsFailed = true;
        });
      }
    }
  }

  Future<void> _searchMap(String query) async {
    final q = query.trim();
    if (q.length < 2) return;

    await _rateLimit();
    if (!mounted) return;
    setState(() => _isSearching = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=jsonv2&q=${Uri.encodeComponent(q)}&countrycodes=lk&limit=5',
      );
      final response = await http
          .get(
            url,
            headers: kIsWeb
                ? const <String, String>{}
                : const <String, String>{
                    'User-Agent': 'HelaService-App/1.0',
                    'Referer': 'https://helaservice.vercel.app',
                  },
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200 && mounted) {
        final list = (json.decode(response.body) as List<dynamic>?) ?? [];
        setState(() {
          _searchResults =
              list.map((item) => item as Map<String, dynamic>).toList();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _searchResults = []);
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  void _onSelectSearchResult(Map<String, dynamic> item) {
    final lat = double.tryParse(item['lat']?.toString() ?? '');
    final lon = double.tryParse(item['lon']?.toString() ?? '');
    if (lat == null || lon == null) return;

    final displayName = item['display_name']?.toString() ?? '';

    setState(() {
      _userLat = lat;
      _userLng = lon;
      _userAddress = displayName;
      _searchResults = [];
      _searchController.clear();
      _gpsFailed = false;
      FocusScope.of(context).unfocus();
    });
  }

  void _onSelectSavedAddress(SavedAddress addr) {
    setState(() {
      _userLat = addr.latitude;
      _userLng = addr.longitude;
      _userAddress = addr.address;
      _gpsFailed = false;
    });
  }


  // calculate real distance in kilometers between customer pin and provider location
  double? _getDistanceKm(Technician tech) {
    if (_userLat == null || _userLng == null) return null;
    final eff = tech.effectiveLocation;
    if (!eff.hasLocation) return null;
    return LocationUtils.calculateDistanceKm(
      _userLat!,
      _userLng!,
      eff.latitude!,
      eff.longitude!,
    );
  }

  // estimated minutes for emergency arrival
  int _calculateEtaMinutes(double distKm) {
    final mins = (distKm * 2.5 + 8).round();
    return mins.clamp(10, 45);
  }

  void _confirmEmergencyCallout(BuildContext context, Technician tech) async {
    if (_userLat == null || _userLng == null) {
      final picked = await JobLocationPicker.pickLocation(
        context,
        title: context.l10n.selectPinOnMap,
      );
      if (picked == null || !context.mounted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.locationRequiredToBook),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      setState(() {
        _userLat = picked.latitude;
        _userLng = picked.longitude;
        _userAddress = picked.address;
        _gpsFailed = false;
      });
    }

    if (!context.mounted) return;
    final inspectionFee = ProviderPricingHelper.resolveVisitFee(tech);
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
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
                  inspectionFee > 0
                      ? context.l10n.confirmEmergencyBookingDesc(
                          tech.name,
                          inspectionFee.toString(),
                        )
                      : context.l10n.confirmEmergencyInspectBookingDesc(
                          tech.name,
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
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.map_outlined, size: 18),
                      tooltip: context.l10n.selectPinOnMap,
                      onPressed: () async {
                        final picked = await JobLocationPicker.pickLocation(
                          context,
                          initialLocation: _userLat != null && _userLng != null
                              ? JobLocation(
                                  latitude: _userLat!,
                                  longitude: _userLng!,
                                  address: addressController.text,
                                )
                              : null,
                        );
                        if (picked != null) {
                          setSheetState(() {
                            _userLat = picked.latitude;
                            _userLng = picked.longitude;
                            _userAddress = picked.address;
                            addressController.text = picked.address;
                          });
                          setState(() {});
                        }
                      },
                    ),
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
                            final currentAddress =
                                addressController.text.trim();
                            if (currentAddress.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      context.l10n.pleaseEnterServiceLocation),
                                ),
                              );
                              return;
                            }
                            if (_userLat == null || _userLng == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text(context.l10n.locationRequiredToBook),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }

                            Navigator.pop(ctx);
                            await _executeEmergencyBooking(
                              tech: tech,
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
    required String address,
    required String notes,
  }) async {
    final roleProvider = pv.Provider.of<RoleProvider>(context, listen: false);
    final user = roleProvider.currentUser;
    setState(() => _isCreatingBooking = true);

    try {
      if (_userLat == null || _userLng == null) {
        setState(() => _isCreatingBooking = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.locationRequiredToBook),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final inspectionFee = ProviderPricingHelper.resolveVisitFee(tech);

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
        estRate: inspectionFee > 0 ? 'LKR $inspectionFee' : '',
        agreedPrice: inspectionFee.toDouble(),
        time: '',
        entryInstructions: notes,
        createdAt: DateTime.now(),
        type: 'urgent',
        expiresAt: DateTime.now().add(const Duration(minutes: 3)),
        quoteType: 'inspect',
        priceStatus: 'awaiting_confirmation',
        visitFeeLkr: inspectionFee,
        travelCostLkr: 0,
        estimatedTotalLkr: inspectionFee,
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
      if (kDebugMode) {
        debugPrint('[EmergencyDispatch] booking error: $e');
      }
      if (mounted) {
        final message = e.toString().contains('LOCATION_REQUIRED')
            ? context.l10n.locationRequiredToBook
            : (e.toString().contains('PROVIDER_CATEGORY_MISSING')
                ? context.l10n.errorProviderCategoryMissing
                : context.l10n.somethingWentWrong);
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
              setState(() {
                _countdownKey = UniqueKey();
              });
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
                  _EmergencyCountdownBadge(key: _countdownKey),
                ],
              ),
            ),

            // customer location badge when pin is set or fallback if failed
            if (_userLat != null && _userLng != null) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: context.themeSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.themeBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _userAddress.isNotEmpty
                            ? _userAddress
                            : '${_userLat!.toStringAsFixed(4)}, ${_userLng!.toStringAsFixed(4)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        final picked = await JobLocationPicker.pickLocation(
                          context,
                          initialLocation: JobLocation(
                            latitude: _userLat!,
                            longitude: _userLng!,
                            address: _userAddress,
                          ),
                        );
                        if (picked != null) {
                          setState(() {
                            _userLat = picked.latitude;
                            _userLng = picked.longitude;
                            _userAddress = picked.address;
                          });
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit_location_alt_outlined,
                                size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              context.l10n.searchOnMap,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_gpsFailed || _userLat == null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_off_rounded,
                                color: AppColors.error,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  context.l10n.couldNotGetLocationFallback,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed:
                                    _isGpsLoading ? null : _resolveUserLocation,
                                icon: _isGpsLoading
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Icon(Icons.refresh_rounded,
                                        size: 16),
                                label: Text(context.l10n.tryGpsAgain),
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  foregroundColor: AppColors.error,
                                  side:
                                      const BorderSide(color: AppColors.error),
                                ),
                              ),
                              if (_permissionPermanentlyDenied)
                                OutlinedButton.icon(
                                  onPressed: () => Geolocator.openAppSettings(),
                                  icon: const Icon(Icons.settings_outlined,
                                      size: 16),
                                  label: Text(context.l10n.openSettings),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final picked =
                                      await JobLocationPicker.pickLocation(
                                          context);
                                  if (picked != null) {
                                    setState(() {
                                      _userLat = picked.latitude;
                                      _userLng = picked.longitude;
                                      _userAddress = picked.address;
                                      _gpsFailed = false;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.map_outlined, size: 16),
                                label: Text(context.l10n.searchOnMap),
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (q) => _searchMap(q),
                      onChanged: (q) {
                        _searchDebounce?.cancel();
                        if (q.trim().length < 3) {
                          setState(() => _searchResults = []);
                          return;
                        }
                        _searchDebounce =
                            Timer(const Duration(milliseconds: 1000), () {
                          _searchMap(q);
                        });
                      },
                      decoration: InputDecoration(
                        hintText: context.l10n.searchPlaceHint,
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.arrow_forward_rounded,
                                    size: 18),
                                onPressed: () =>
                                    _searchMap(_searchController.text),
                              ),
                        filled: true,
                        fillColor: context.themeSurfaceLow,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: context.themeBorder),
                        ),
                      ),
                    ),
                    if (_searchResults.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 140),
                        decoration: BoxDecoration(
                          color: context.themeSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.themeBorder),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: context.themeBorder),
                          itemBuilder: (context, i) {
                            final item = _searchResults[i];
                            final name = item['display_name']?.toString() ?? '';
                            return ListTile(
                              dense: true,
                              leading:
                                  const Icon(Icons.place_outlined, size: 18),
                              title: Text(
                                name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                              onTap: () => _onSelectSearchResult(item),
                            );
                          },
                        ),
                      ),
                    ],
                    if (_savedAddressesStream != null) ...[
                      const SizedBox(height: 10),
                      StreamBuilder<List<SavedAddress>>(
                        stream: _savedAddressesStream,
                        builder: (context, snapshot) {
                          final addresses = snapshot.data ?? [];
                          if (addresses.isEmpty) return const SizedBox.shrink();

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.savedAddresses,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 54,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: addresses.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (context, index) {
                                    final item = addresses[index];
                                    final isHome =
                                        item.label.toLowerCase() == 'home';
                                    final isWork =
                                        item.label.toLowerCase() == 'work';
                                    final itemDisplayLabel = isHome
                                        ? context.l10n.addressLabelHome
                                        : (isWork
                                            ? context.l10n.addressLabelWork
                                            : (item.label.toLowerCase() ==
                                                    'other'
                                                ? context.l10n.addressLabelOther
                                                : item.label));

                                    return InkWell(
                                      onTap: () => _onSelectSavedAddress(item),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: 140,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: context.themeSurface,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: context.themeBorder),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  isHome
                                                      ? Icons.home_rounded
                                                      : (isWork
                                                          ? Icons.work_rounded
                                                          : Icons
                                                              .place_rounded),
                                                  size: 13,
                                                  color: AppColors.primary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  itemDisplayLabel,
                                                  style: const TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item.address,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                color:
                                                    context.themeTextSecondary,
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
                    ],
                  ],
                ),
              ),
            ],

            // trade category filter pills
            StreamBuilder<List<CategoryRow>>(
              stream: _categoriesStream,
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
                        final localized = CategoryService.instance
                            .nameOf(cat.id, context: context);
                        final catName =
                            localized.isNotEmpty ? localized : cat.name;
                        final isSelected = _selectedCategory.toLowerCase() ==
                            cat.id.toLowerCase();
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
                              () =>
                                  _selectedCategory = isSelected ? '' : cat.id,
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
                stream: _techStream,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting &&
                      !snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allTechs = snap.data ?? [];
                  final filtered = allTechs.where((t) {
                    if (!t.online) return false;
                    if (!t.emergencyAvailable) return false;
                    if (ProviderPricingHelper.resolveVisitFee(t) <= 0) return false;
                    if (_selectedCategory.isNotEmpty) {
                      if (t.category.trim().toLowerCase() !=
                          _selectedCategory.trim().toLowerCase()) {
                        return false;
                      }
                    }
                    if (_userLat != null && _userLng != null) {
                      final dist = _getDistanceKm(t);
                      if (dist == null) return false;
                      final maxRadius = math.min(t.serviceRadiusKm, 15.0);
                      if (dist > maxRadius) return false;
                    }
                    return true;
                  }).toList();

                  // closest first, tiebreak on rating
                  filtered.sort((a, b) {
                    if (_userLat != null && _userLng != null) {
                      final distA = _getDistanceKm(a) ?? double.infinity;
                      final distB = _getDistanceKm(b) ?? double.infinity;
                      final cmp = distA.compareTo(distB);
                      if (cmp != 0) return cmp;
                    }
                    return (b.rating ?? 0.0).compareTo(a.rating ?? 0.0);
                  });

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
                                color:
                                    context.themeBorder.withValues(alpha: 0.3),
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
                      final etaMins =
                          distKm != null ? _calculateEtaMinutes(distKm) : null;
                      final inspectionFee =
                          ProviderPricingHelper.resolveVisitFee(tech);

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
                                          if (tech.isNewProvider ||
                                              tech.rating == null) ...[
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                          if (distKm != null) ...[
                                            const SizedBox(width: 10),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                                tech.effectiveLocation.isCurrent
                                                    ? context.l10n.awayNow(
                                                        distKm
                                                            .toStringAsFixed(1),
                                                      )
                                                    : context.l10n.basedAway(
                                                        distKm
                                                            .toStringAsFixed(1),
                                                      ),
                                                style: const TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ],
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
                                      context.l10n.inspectionFeeLkr(
                                          inspectionFee.toString()),
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: context.themeTextPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                if (etaMins != null)
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
                                            context.l10n
                                                .emergencyEtaApprox(etaMins),
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
                                    : () =>
                                        _confirmEmergencyCallout(context, tech),
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

// timer badge that updates every second
class _EmergencyCountdownBadge extends StatefulWidget {
  const _EmergencyCountdownBadge({super.key});

  @override
  State<_EmergencyCountdownBadge> createState() =>
      _EmergencyCountdownBadgeState();
}

class _EmergencyCountdownBadgeState extends State<_EmergencyCountdownBadge> {
  Timer? _timer;
  int _remaining = 120;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remaining > 0) {
        setState(() => _remaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _formatTimer(_remaining),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
          fontFeatures: [],
        ),
      ),
    );
  }
}
