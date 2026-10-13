import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../models/job_location.dart';
import '../../models/saved_address.dart';
import '../../repositories/saved_address_repository.dart';
import '../../utils/permission_utils.dart';
import '../../utils/l10n_extension.dart';
import 'app_map_view.dart';
import 'primary_button.dart';
import 'icon_square_button.dart';

// location picker with gps-first flow and map search
class JobLocationPicker extends StatefulWidget {
  final JobLocation? initialLocation;
  final String? title;

  const JobLocationPicker({
    super.key,
    this.initialLocation,
    this.title,
  });

  static Future<JobLocation?> pickLocation(
    BuildContext context, {
    JobLocation? initialLocation,
    String? title,
  }) {
    return Navigator.of(context).push<JobLocation>(
      MaterialPageRoute(
        builder: (_) => JobLocationPicker(
          initialLocation: initialLocation,
          title: title,
        ),
      ),
    );
  }

  @override
  State<JobLocationPicker> createState() => _JobLocationPickerState();
}

class _JobLocationPickerState extends State<JobLocationPicker> {
  final MapController _mapController = MapController();
  final _houseNoController = TextEditingController();
  final _noteController = TextEditingController();
  final _searchController = TextEditingController();

  double? _latitude;
  double? _longitude;
  double? _accuracyMeters;

  bool _isGpsLoading = false;
  bool _gpsFailed = false;
  bool _permissionPermanentlyDenied = false;
  bool _showAlternativePlaces = false;
  bool _isGeocodingLoading = false;
  bool _isDetailsExpanded = false;
  String? _savedWithLabel;

  String _shortAddress = '';
  String _fullAddress = '';
  String _street = '';
  String _city = '';

  Timer? _geocodeDebounce;
  Timer? _searchDebounce;
  DateTime _lastNetworkRequestTime = DateTime.fromMillisecondsSinceEpoch(0);

  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];

  final List<String> _labelOptions = ['home', 'work', 'other'];

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _latitude = widget.initialLocation!.latitude;
      _longitude = widget.initialLocation!.longitude;
      _accuracyMeters = widget.initialLocation!.accuracyMeters;
      _fullAddress = widget.initialLocation!.address;
      _shortAddress = _formatShortAddress(widget.initialLocation!.address);
      _street = widget.initialLocation!.street ?? '';
      _city = widget.initialLocation!.city ?? '';
      _houseNoController.text = widget.initialLocation!.houseNo ?? '';
      _noteController.text = widget.initialLocation!.effectiveNote ?? '';
    } else {
      // auto start gps on open
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _useCurrentGps();
      });
    }
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    _searchDebounce?.cancel();
    _houseNoController.dispose();
    _noteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get _canConfirm => _latitude != null && _longitude != null;

  // rate limiter helper for nominatim (1 req per second max)
  Future<void> _rateLimit() async {
    final now = DateTime.now();
    final elapsed = now.difference(_lastNetworkRequestTime);
    if (elapsed.inMilliseconds < 1000) {
      await Future.delayed(Duration(milliseconds: 1000 - elapsed.inMilliseconds));
    }
    _lastNetworkRequestTime = DateTime.now();
  }

  // format address to road, area, town (~60 chars max)
  String _formatShortAddress(String raw) {
    if (raw.trim().isEmpty) return '';
    final parts = raw.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (parts.length <= 3) {
      final joined = parts.join(', ');
      return joined.length > 60 ? '${joined.substring(0, 57)}...' : joined;
    }
    final shortParts = parts.take(3).toList();
    final candidate = shortParts.join(', ');
    return candidate.length > 60 ? '${candidate.substring(0, 57)}...' : candidate;
  }

  // reverse geocode pin using nominatim
  Future<void> _reverseGeocode(double lat, double lon) async {
    await _rateLimit();
    if (!mounted) return;
    setState(() => _isGeocodingLoading = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon',
      );
      final response = await http.get(
        url,
        headers: kIsWeb
            ? const <String, String>{}
            : const <String, String>{
                'User-Agent': 'HelaService-App/1.0',
                'Referer': 'https://helaservice.vercel.app',
              },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final displayName = (data['display_name'] as String?) ?? '';
        final addr = data['address'] as Map<String, dynamic>?;

        String road = '';
        String area = '';
        String city = '';

        if (addr != null) {
          road = (addr['road'] ?? addr['street'] ?? '') as String;
          area = (addr['suburb'] ?? addr['neighbourhood'] ?? addr['village'] ?? '') as String;
          city = (addr['city'] ?? addr['town'] ?? addr['municipality'] ?? addr['county'] ?? '') as String;
        }

        final parts = [road, area, city].where((s) => s.isNotEmpty).toList();
        final formatted = parts.isNotEmpty ? parts.join(', ') : displayName;

        if (mounted) {
          setState(() {
            _fullAddress = displayName.isNotEmpty ? displayName : formatted;
            _street = road;
            _city = city;
            _shortAddress = formatted.length > 60
                ? '${formatted.substring(0, 57)}...'
                : formatted;
          });
        }
      } else {
        _setFallbackCoordinates(lat, lon);
      }
    } catch (_) {
      _setFallbackCoordinates(lat, lon);
    } finally {
      if (mounted) {
        setState(() => _isGeocodingLoading = false);
      }
    }
  }

  void _setFallbackCoordinates(double lat, double lon) {
    if (!mounted) return;
    final fallback = '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}';
    setState(() {
      _shortAddress = fallback;
      _fullAddress = fallback;
    });
  }

  // handle map drag
  void _onMapCameraMoved(LatLng center) {
    setState(() {
      _latitude = center.latitude;
      _longitude = center.longitude;
      // manual drag clears gps accuracy badge
      _accuracyMeters = null;
    });

    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 800), () {
      _reverseGeocode(center.latitude, center.longitude);
    });
  }

  // start high accuracy gps
  Future<void> _useCurrentGps() async {
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
            _showAlternativePlaces = true;
          });
        }
        return;
      }

      if (!mounted) return;
      final granted = await PermissionUtils.requestLocationWithRationale(context);
      if (!granted) {
        final postPerm = await Geolocator.checkPermission();
        if (mounted) {
          setState(() {
            _isGpsLoading = false;
            _gpsFailed = true;
            _permissionPermanentlyDenied = postPerm == LocationPermission.deniedForever;
            _showAlternativePlaces = true;
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

      if (!mounted) return;
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        _accuracyMeters = pos.accuracy;
        _isGpsLoading = false;
        _gpsFailed = false;
      });

      _mapController.move(LatLng(pos.latitude, pos.longitude), 18.0);
      _reverseGeocode(pos.latitude, pos.longitude);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isGpsLoading = false;
        _gpsFailed = true;
        _showAlternativePlaces = true;
      });
    }
  }

  // search on map via nominatim
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
      final response = await http.get(
        url,
        headers: kIsWeb
            ? const <String, String>{}
            : const <String, String>{
                'User-Agent': 'HelaService-App/1.0',
                'Referer': 'https://helaservice.vercel.app',
              },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200 && mounted) {
        final list = (json.decode(response.body) as List<dynamic>?) ?? [];
        setState(() {
          _searchResults = list.map((item) => item as Map<String, dynamic>).toList();
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
      _latitude = lat;
      _longitude = lon;
      _accuracyMeters = null;
      _fullAddress = displayName;
      _shortAddress = _formatShortAddress(displayName);
      _searchResults = [];
      _searchController.clear();
      FocusScope.of(context).unfocus();
    });

    _mapController.move(LatLng(lat, lon), 18.0);
    _reverseGeocode(lat, lon);
  }

  void _onSelectSavedAddress(SavedAddress addr) {
    setState(() {
      _latitude = addr.latitude;
      _longitude = addr.longitude;
      _accuracyMeters = addr.accuracyMeters;
      _fullAddress = addr.address;
      _shortAddress = _formatShortAddress(addr.address);
      _street = addr.street ?? '';
      _city = addr.city ?? '';
      _houseNoController.text = addr.houseNo ?? '';
      _noteController.text = addr.effectiveNote ?? '';
      _showAlternativePlaces = false;
    });

    _mapController.move(LatLng(addr.latitude, addr.longitude), 18.0);
  }

  // quick save place with label
  Future<void> _quickSavePlace(String label) async {
    if (!_canConfirm) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    setState(() => _savedWithLabel = label);

    try {
      await SavedAddressRepository().addSavedAddress(
        userId: uid,
        label: label,
        latitude: _latitude!,
        longitude: _longitude!,
        address: _fullAddress.isNotEmpty ? _fullAddress : _shortAddress,
        note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
        houseNo: _houseNoController.text.trim().isNotEmpty ? _houseNoController.text.trim() : null,
        street: _street.isNotEmpty ? _street : null,
        city: _city.isNotEmpty ? _city : null,
        accuracyMeters: _accuracyMeters,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n.saved}: $label'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('[JobLocationPicker] save place error: $e');
    }
  }

  void _confirmLocation() {
    if (!_canConfirm) return;

    final noteText = _noteController.text.trim();
    final houseNoText = _houseNoController.text.trim();
    final finalAddress = _fullAddress.isNotEmpty ? _fullAddress : _shortAddress;

    final location = JobLocation(
      latitude: _latitude!,
      longitude: _longitude!,
      address: finalAddress,
      note: noteText.isNotEmpty ? noteText : null,
      landmark: noteText.isNotEmpty ? noteText : null,
      houseNo: houseNoText.isNotEmpty ? houseNoText : null,
      street: _street.isNotEmpty ? _street : null,
      city: _city.isNotEmpty ? _city : null,
      accuracyMeters: _accuracyMeters,
    );

    Navigator.of(context).pop(location);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final centerLatLng = (_latitude != null && _longitude != null)
        ? LatLng(_latitude!, _longitude!)
        : kColomboCenter;

    return Scaffold(
      backgroundColor: context.themeBg,
      appBar: AppBar(
        backgroundColor: context.themeSurface,
        elevation: 0,
        leading: Center(
          child: IconSquareButton.small(
            icon: Icons.close_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        title: Text(
          widget.title ?? context.l10n.selectServiceLocation,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: context.themeInk,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  // map container with center pin
                  Container(
                    height: 260,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _latitude != null ? AppColors.primary : context.themeBorder,
                        width: _latitude != null ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AppMapView(
                          controller: _mapController,
                          initialCenter: centerLatLng,
                          initialZoom: (_latitude != null && _longitude != null) ? 18.0 : 13.0,
                          interactive: true,
                          onPositionChanged: (camera, hasGesture) {
                            if (hasGesture) {
                              _onMapCameraMoved(camera.center);
                            }
                          },
                        ),

                        // draggable center pin
                        IgnorePointer(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _latitude != null ? AppColors.primary : Colors.grey,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              Container(
                                width: 4,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              Container(
                                width: 10,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // top badge: accuracy
                        if (_accuracyMeters != null)
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.gps_fixed_rounded,
                                    size: 12,
                                    color: _accuracyMeters! > 50 ? AppColors.warning : AppColors.success,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    context.l10n.accuracyBadge(_accuracyMeters!.round()),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // top badge: loading gps indicator
                        if (_isGpsLoading)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'GPS...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          // recenter gps button
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: Material(
                              color: context.themeSurface,
                              elevation: 3,
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                onTap: _useCurrentGps,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: const Icon(
                                    Icons.my_location_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // read-only address bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: context.themeSurfaceLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.themeBorder),
                    ),
                    child: Row(
                      children: [
                        if (_isGeocodingLoading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        else
                          const Icon(
                            Icons.location_on_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _shortAddress.isNotEmpty
                                ? _shortAddress
                                : (_latitude != null
                                    ? '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}'
                                    : context.l10n.selectPinOnMap),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _shortAddress.isNotEmpty ? context.themeInk : context.themeTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // inline hint: move pin to your gate (when accuracy > 50m)
                  if (_accuracyMeters != null && _accuracyMeters! > 50) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.touch_app_outlined,
                          size: 15,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            context.l10n.movePinToGateHint,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // gps failure state
                  if (_gpsFailed) ...[
                    const SizedBox(height: 12),
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
                            children: [
                              OutlinedButton.icon(
                                onPressed: _useCurrentGps,
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: Text(context.l10n.tryGpsAgain),
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(color: AppColors.error),
                                ),
                              ),
                              if (_permissionPermanentlyDenied)
                                OutlinedButton.icon(
                                  onPressed: () => Geolocator.openAppSettings(),
                                  icon: const Icon(Icons.settings_outlined, size: 16),
                                  label: Text(context.l10n.openSettings),
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // alternative places section (search on map + saved addresses)
                  if (_showAlternativePlaces || _gpsFailed) ...[
                    const SizedBox(height: 14),

                    // search input
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
                        _searchDebounce = Timer(const Duration(milliseconds: 1000), () {
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
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                                onPressed: () => _searchMap(_searchController.text),
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

                    // search results list
                    if (_searchResults.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: context.themeSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.themeBorder),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: context.themeBorder),
                          itemBuilder: (context, i) {
                            final item = _searchResults[i];
                            final name = item['display_name']?.toString() ?? '';
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.place_outlined, size: 18),
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

                    // saved addresses chips
                    if (uid.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      StreamBuilder<List<SavedAddress>>(
                        stream: SavedAddressRepository().streamSavedAddresses(uid),
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
                                height: 58,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: addresses.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                                  itemBuilder: (context, index) {
                                    final item = addresses[index];
                                    final isHome = item.label.toLowerCase() == 'home';
                                    final isWork = item.label.toLowerCase() == 'work';
                                    final itemDisplayLabel = isHome
                                        ? context.l10n.addressLabelHome
                                        : (isWork
                                            ? context.l10n.addressLabelWork
                                            : (item.label.toLowerCase() == 'other'
                                                ? context.l10n.addressLabelOther
                                                : item.label));

                                    return InkWell(
                                      onTap: () => _onSelectSavedAddress(item),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: 150,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: context.themeSurfaceLow,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: context.themeBorder),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  isHome
                                                      ? Icons.home_rounded
                                                      : (isWork
                                                          ? Icons.work_rounded
                                                          : Icons.location_on_rounded),
                                                  size: 13,
                                                  color: AppColors.primary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  itemDisplayLabel,
                                                  style: const TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w800,
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
                                                color: context.themeTextSecondary,
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

                  const SizedBox(height: 12),

                  // collapsible: add details for the provider
                  Container(
                    decoration: BoxDecoration(
                      color: context.themeSurfaceLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.themeBorder),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: _isDetailsExpanded,
                        onExpansionChanged: (exp) => setState(() => _isDetailsExpanded = exp),
                        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        title: Text(
                          context.l10n.addDetailsForProvider,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        children: [
                          TextField(
                            controller: _houseNoController,
                            maxLength: 100,
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: '${context.l10n.houseAptNo} (e.g. 12/B)',
                              prefixIcon: const Icon(Icons.home_outlined, size: 18),
                              filled: true,
                              fillColor: context.themeSurface,
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: context.themeBorder),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _noteController,
                            maxLength: 300,
                            maxLines: 2,
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: context.l10n.providerNoteHint,
                              prefixIcon: const Icon(Icons.note_alt_outlined, size: 18),
                              filled: true,
                              fillColor: context.themeSurface,
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: context.themeBorder),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // quick save place chips
                  if (_canConfirm && uid.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '${context.l10n.saveThisPlace}:',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: context.themeTextSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Wrap(
                          spacing: 6,
                          children: _labelOptions.map((key) {
                            final isSaved = _savedWithLabel == key;
                            final labelText = key == 'home'
                                ? context.l10n.addressLabelHome
                                : (key == 'work'
                                    ? context.l10n.addressLabelWork
                                    : context.l10n.addressLabelOther);

                            return ActionChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSaved) ...[
                                    const Icon(Icons.check, size: 12, color: AppColors.success),
                                    const SizedBox(width: 3),
                                  ],
                                  Text(labelText),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _quickSavePlace(key),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // bottom action section
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: context.themeSurface,
                border: Border(top: BorderSide(color: context.themeBorder)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: PrimaryButton(
                      label: context.l10n.confirmLocation,
                      onPressed: _canConfirm ? _confirmLocation : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showAlternativePlaces = !_showAlternativePlaces;
                      });
                    },
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: Text(
                      context.l10n.notHereChooseAnother,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.themeTextSecondary,
                      ),
                    ),
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
