import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../constants/firestore_paths.dart';
import '../../models/job_location.dart';
import '../../models/saved_address.dart';
import '../../repositories/saved_address_repository.dart';
import '../../utils/permission_utils.dart';
import '../../utils/l10n_extension.dart';
import '../../utils/location_search_helper.dart';
import 'app_map_view.dart';
import 'primary_button.dart';
import 'icon_square_button.dart';

// location picker with pin and search
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

  bool _userChoseLocation = false;
  bool _userActed = false;
  bool _detailsFromChip = false;
  double? _chipLat;
  double? _chipLon;

  bool _isMapMoving = false;
  bool _isGpsLoading = false;
  bool _gpsFailed = false;
  bool _permissionPermanentlyDenied = false;
  bool _isGeocodingLoading = false;
  bool _isDetailsExpanded = false;
  String? _savedWithLabel;

  String _shortAddress = '';
  String _fullAddress = '';
  String _street = '';
  String _city = '';

  Timer? _geocodeDebounce;
  Timer? _searchDebounce;
  Timer? _mapMoveStopTimer;
  DateTime _lastNetworkRequestTime = DateTime.fromMillisecondsSinceEpoch(0);

  bool _isSearching = false;
  String? _searchErrorMessage;
  List<PlaceSuggestion> _searchResults = [];
  final Map<String, List<PlaceSuggestion>> _searchCache = {};
  int _searchSequence = 0;

  List<JobLocation> _recentPlaces = [];
  bool _hasLoadedRecentPlaces = false;

  final List<String> _labelOptions = ['home', 'work', 'other'];

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _userChoseLocation = true;
      _userActed = true;
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
        _useCurrentGps(auto: true);
      });
    }
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    _searchDebounce?.cancel();
    _mapMoveStopTimer?.cancel();
    _houseNoController.dispose();
    _noteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get _canConfirm => LocationSearchHelper.canConfirmLocation(
        userChoseLocation: _userChoseLocation,
        latitude: _latitude,
        longitude: _longitude,
        isGeocodingLoading: _isGeocodingLoading,
      );

  // headers for osm apis
  Map<String, String> get _networkHeaders => kIsWeb
      ? const <String, String>{}
      : const <String, String>{
          'User-Agent': 'HelaService-App/1.0 (https://helaservice.vercel.app)',
          'Referer': 'https://helaservice.vercel.app',
        };

  // rate limit api calls
  Future<void> _rateLimit() async {
    final now = DateTime.now();
    final elapsed = now.difference(_lastNetworkRequestTime);
    if (elapsed.inMilliseconds < 1000) {
      await Future.delayed(
          Duration(milliseconds: 1000 - elapsed.inMilliseconds));
    }
    _lastNetworkRequestTime = DateTime.now();
  }

  // format short address text
  String _formatShortAddress(String raw) {
    if (raw.trim().isEmpty) return '';
    final parts =
        raw.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (parts.length <= 3) {
      final joined = parts.join(', ');
      return joined.length > 60 ? '${joined.substring(0, 57)}...' : joined;
    }
    final shortParts = parts.take(3).toList();
    final candidate = shortParts.join(', ');
    return candidate.length > 60
        ? '${candidate.substring(0, 57)}...'
        : candidate;
  }

  // get address for current pin
  Future<void> _reverseGeocode(double lat, double lon) async {
    await _rateLimit();
    if (!mounted) return;
    setState(() => _isGeocodingLoading = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon',
      );
      final response = await http
          .get(url, headers: _networkHeaders)
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

  // clear extra details if pin moved far
  void _checkClearChipDetails(double newLat, double newLon) {
    if (_detailsFromChip && _chipLat != null && _chipLon != null) {
      if (LocationSearchHelper.shouldClearChipDetails(
        detailsFromChip: _detailsFromChip,
        chipLat: _chipLat!,
        chipLon: _chipLon!,
        newLat: newLat,
        newLon: newLon,
      )) {
        _houseNoController.clear();
        _noteController.clear();
        _detailsFromChip = false;
        _chipLat = null;
        _chipLon = null;
      }
    }
  }

  // update pin when map moves
  void _onMapCameraMoved(LatLng center, {required bool hasGesture}) {
    if (hasGesture) {
      _userActed = true;
      _userChoseLocation = true;
      _checkClearChipDetails(center.latitude, center.longitude);
    }

    setState(() {
      _latitude = center.latitude;
      _longitude = center.longitude;
      if (hasGesture) {
        _isMapMoving = true;
        _accuracyMeters = null;
      }
    });

    _mapMoveStopTimer?.cancel();
    _mapMoveStopTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() => _isMapMoving = false);
      }
    });

    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 800), () {
      _reverseGeocode(center.latitude, center.longitude);
    });
  }

  // start gps location request
  Future<void> _useCurrentGps({bool auto = false}) async {
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

      if (!mounted) return;

      final shouldApply = LocationSearchHelper.shouldApplyGpsLocation(
        isAutoGps: auto,
        userActed: _userActed,
      );
      if (!shouldApply) {
        setState(() {
          _isGpsLoading = false;
        });
        return;
      }

      _userActed = true;
      _userChoseLocation = true;
      _checkClearChipDetails(pos.latitude, pos.longitude);

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
      });
    }
  }

  // search places as user types
  void _onSearchQueryChanged(String query) {
    _searchDebounce?.cancel();
    final q = query.trim();
    if (q.length < 3) {
      setState(() {
        _searchResults = [];
        _searchErrorMessage = null;
        _isSearching = false;
      });
      return;
    }

    if (_searchCache.containsKey(q.toLowerCase())) {
      setState(() {
        _searchResults = _searchCache[q.toLowerCase()]!;
        _searchErrorMessage = null;
        _isSearching = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _executePhotonSearch(q);
    });
  }

  // send search request
  Future<void> _executePhotonSearch(String query) async {
    final currentSeq = ++_searchSequence;
    await _rateLimit();
    if (!mounted || currentSeq != _searchSequence) return;

    setState(() {
      _isSearching = true;
      _searchErrorMessage = null;
    });

    final centerLat = _latitude ?? kColomboCenter.latitude;
    final centerLon = _longitude ?? kColomboCenter.longitude;

    try {
      final url = Uri.parse(
        'https://photon.komoot.io/api/?q=${Uri.encodeComponent(query)}&lang=en&limit=6&lat=$centerLat&lon=$centerLon&bbox=${LocationSearchHelper.minLon},${LocationSearchHelper.minLat},${LocationSearchHelper.maxLon},${LocationSearchHelper.maxLat}',
      );

      final response = await http
          .get(url, headers: _networkHeaders)
          .timeout(const Duration(seconds: 5));

      if (currentSeq != _searchSequence) return;

      if (response.statusCode == 200 && mounted) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final features = (data['features'] as List<dynamic>?) ?? [];

        final List<PlaceSuggestion> parsed = [];
        for (final item in features) {
          if (item is Map<String, dynamic>) {
            final suggestion = LocationSearchHelper.parsePhotonFeature(item);
            if (suggestion != null) {
              parsed.add(suggestion);
            }
          }
        }

        _searchCache[query.toLowerCase()] = parsed;
        setState(() {
          _searchResults = parsed;
          _isSearching = false;
          _searchErrorMessage = parsed.isEmpty ? 'no_results' : null;
        });
      } else {
        if (mounted) {
          setState(() {
            _searchResults = [];
            _isSearching = false;
            _searchErrorMessage = 'search_unavailable';
          });
        }
      }
    } catch (_) {
      if (mounted && currentSeq == _searchSequence) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
          _searchErrorMessage = 'search_unavailable';
        });
      }
    }
  }

  // search on enter key
  Future<void> _onSearchSubmitted(String query) async {
    final q = query.trim();
    if (q.length < 2) return;

    // use cached results if available
    if (_searchCache.containsKey(q.toLowerCase()) &&
        _searchCache[q.toLowerCase()]!.isNotEmpty) {
      setState(() {
        _searchResults = _searchCache[q.toLowerCase()]!;
        _searchErrorMessage = null;
      });
      return;
    }

    // fallback search on submit
    await _rateLimit();
    if (!mounted) return;
    setState(() {
      _isSearching = true;
      _searchErrorMessage = null;
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=jsonv2&q=${Uri.encodeComponent(q)}&countrycodes=lk&limit=6',
      );
      final response = await http
          .get(url, headers: _networkHeaders)
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200 && mounted) {
        final list = (json.decode(response.body) as List<dynamic>?) ?? [];
        final List<PlaceSuggestion> parsed = [];

        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final suggestion = LocationSearchHelper.parseNominatimItem(item);
            if (suggestion != null) {
              parsed.add(suggestion);
            }
          }
        }

        setState(() {
          _searchResults = parsed;
          _isSearching = false;
          _searchErrorMessage = parsed.isEmpty ? 'no_results' : null;
        });
      } else {
        if (mounted) {
          setState(() {
            _searchResults = [];
            _isSearching = false;
            _searchErrorMessage = 'search_unavailable';
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
          _searchErrorMessage = 'search_unavailable';
        });
      }
    }
  }

  void _onSelectSuggestion(PlaceSuggestion item) {
    _userActed = true;
    _checkClearChipDetails(item.latitude, item.longitude);

    setState(() {
      _userChoseLocation = true;
      _latitude = item.latitude;
      _longitude = item.longitude;
      _accuracyMeters = null;
      _fullAddress = item.fullDisplay;
      _shortAddress = _formatShortAddress(item.fullDisplay);
      _searchResults = [];
      _searchErrorMessage = null;
      _searchController.clear();
      FocusScope.of(context).unfocus();
    });

    _mapController.move(LatLng(item.latitude, item.longitude), 18.0);
    _reverseGeocode(item.latitude, item.longitude);
  }

  void _onSelectSavedAddress(SavedAddress addr) {
    _userActed = true;
    _detailsFromChip = true;
    _chipLat = addr.latitude;
    _chipLon = addr.longitude;

    setState(() {
      _userChoseLocation = true;
      _latitude = addr.latitude;
      _longitude = addr.longitude;
      _accuracyMeters = addr.accuracyMeters;
      _fullAddress = addr.address;
      _shortAddress = _formatShortAddress(addr.address);
      _street = addr.street ?? '';
      _city = addr.city ?? '';
      _houseNoController.text = addr.houseNo ?? '';
      _noteController.text = addr.effectiveNote ?? '';
      _searchResults = [];
      _searchErrorMessage = null;
    });

    _mapController.move(LatLng(addr.latitude, addr.longitude), 18.0);
    _reverseGeocode(addr.latitude, addr.longitude);
  }

  void _onSelectRecentPlace(JobLocation loc) {
    _userActed = true;
    _detailsFromChip = true;
    _chipLat = loc.latitude;
    _chipLon = loc.longitude;

    setState(() {
      _userChoseLocation = true;
      _latitude = loc.latitude;
      _longitude = loc.longitude;
      _accuracyMeters = loc.accuracyMeters;
      _fullAddress = loc.address;
      _shortAddress = _formatShortAddress(loc.address);
      _street = loc.street ?? '';
      _city = loc.city ?? '';
      _houseNoController.text = loc.houseNo ?? '';
      _noteController.text = loc.effectiveNote ?? '';
      _searchResults = [];
      _searchErrorMessage = null;
    });

    _mapController.move(LatLng(loc.latitude, loc.longitude), 18.0);
    _reverseGeocode(loc.latitude, loc.longitude);
  }

  // load customer recent places
  Future<void> _loadRecentPlaces(
    String uid,
    List<SavedAddress> savedAddresses,
  ) async {
    if (_hasLoadedRecentPlaces || uid.isEmpty) return;
    _hasLoadedRecentPlaces = true;

    try {
      final snap = await FirebaseFirestore.instance
          .collection(FirestorePaths.jobRequests)
          .where('customerId', isEqualTo: uid)
          .limit(20)
          .get();

      final docs = snap.docs.toList();
      docs.sort((a, b) {
        final aCreated = a.data()['createdAt'];
        final bCreated = b.data()['createdAt'];
        final aMillis =
            aCreated is Timestamp ? aCreated.millisecondsSinceEpoch : 0;
        final bMillis =
            bCreated is Timestamp ? bCreated.millisecondsSinceEpoch : 0;
        return bMillis.compareTo(aMillis);
      });

      final List<JobLocation> candidates = [];
      for (final doc in docs.take(10)) {
        try {
          final contactSnap =
              await doc.reference.collection('private').doc('contact').get();
          if (contactSnap.exists) {
            final data = contactSnap.data();
            final lat = data?['latitude'] as num?;
            final lon = data?['longitude'] as num?;
            final addr = data?['address'] as String?;
            if (lat != null && lon != null && addr != null && addr.isNotEmpty) {
              candidates.add(JobLocation(
                latitude: lat.toDouble(),
                longitude: lon.toDouble(),
                address: addr,
                note: data?['note'] as String?,
                landmark: data?['landmark'] as String?,
                houseNo: data?['houseNo'] as String?,
                street: data?['street'] as String?,
                city: data?['city'] as String?,
              ));
            }
          }
        } catch (_) {}
      }

      final unique = LocationSearchHelper.deduplicateRecentPlaces(
        savedAddresses: savedAddresses,
        recentPlaces: candidates,
        max: 3,
      );

      if (mounted) {
        setState(() => _recentPlaces = unique);
      }
    } catch (e) {
      debugPrint('[JobLocationPicker] load recent places error: $e');
    }
  }

  // save address with label
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
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
        houseNo: _houseNoController.text.trim().isNotEmpty
            ? _houseNoController.text.trim()
            : null,
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
            icon: Icons.close,
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
                  // search box at the top
                  TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (q) => _onSearchSubmitted(q),
                    onChanged: (q) => _onSearchQueryChanged(q),
                    decoration: InputDecoration(
                      hintText: context.l10n.searchPlaceHint,
                      prefixIcon: const Icon(Icons.search, size: 20),
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
                          : (_searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    _onSearchQueryChanged('');
                                  },
                                )
                              : IconButton(
                                  icon: const Icon(Icons.search, size: 18),
                                  onPressed: () => _onSearchSubmitted(
                                      _searchController.text),
                                )),
                      filled: true,
                      fillColor: context.themeSurfaceLow,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.themeBorder),
                      ),
                    ),
                  ),

                  // search suggestions list
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
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: context.themeBorder),
                        itemBuilder: (context, i) {
                          final item = _searchResults[i];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.place_outlined, size: 18),
                            title: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: item.shortArea.isNotEmpty
                                ? Text(
                                    item.shortArea,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: context.themeTextSecondary,
                                    ),
                                  )
                                : null,
                            onTap: () => _onSelectSuggestion(item),
                          );
                        },
                      ),
                    ),
                  ] else if (_searchErrorMessage != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: context.themeSurfaceLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _searchErrorMessage == 'no_results'
                                ? Icons.search_off_rounded
                                : Icons.info_outline_rounded,
                            size: 16,
                            color: context.themeTextSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _searchErrorMessage == 'no_results'
                                  ? context.l10n.noSearchResults
                                  : context.l10n.searchUnavailableFallback,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: context.themeTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // quick chips under search box
                  if (uid.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    StreamBuilder<List<SavedAddress>>(
                      stream:
                          SavedAddressRepository().streamSavedAddresses(uid),
                      builder: (context, snapshot) {
                        final savedList = snapshot.data ?? [];
                        if (savedList.isNotEmpty) {
                          _loadRecentPlaces(uid, savedList);
                        }

                        if (savedList.isEmpty && _recentPlaces.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return SizedBox(
                          height: 38,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              // saved address chips
                              ...savedList.map((addr) {
                                final isHome =
                                    addr.label.toLowerCase() == 'home';
                                final isWork =
                                    addr.label.toLowerCase() == 'work';
                                final labelText = isHome
                                    ? context.l10n.addressLabelHome
                                    : (isWork
                                        ? context.l10n.addressLabelWork
                                        : addr.label);
                                final icon = isHome
                                    ? Icons.home_outlined
                                    : (isWork
                                        ? Icons.work_outline
                                        : Icons.place_outlined);

                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ActionChip(
                                    avatar: Icon(icon, size: 14),
                                    label: Text(labelText),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () =>
                                        _onSelectSavedAddress(addr),
                                  ),
                                );
                              }),

                              // recent places chips
                              ..._recentPlaces.map((recent) {
                                final chipLabel = _formatShortAddress(
                                    recent.address.split(',').first.trim());
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ActionChip(
                                    avatar: const Icon(Icons.history, size: 14),
                                    label: Text(chipLabel.isNotEmpty
                                        ? chipLabel
                                        : context.l10n.recentPlaces),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () =>
                                        _onSelectRecentPlace(recent),
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 10),

                  // map view with center pin
                  Container(
                    height: 270,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _userChoseLocation
                            ? AppColors.primary
                            : context.themeBorder,
                        width: _userChoseLocation ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: context.isDark ? 0.3 : 0.05),
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
                          initialZoom: (_latitude != null && _longitude != null)
                              ? 18.0
                              : 13.0,
                          interactive: true,
                          onPositionChanged: (camera, hasGesture) {
                            _onMapCameraMoved(camera.center,
                                hasGesture: hasGesture);
                          },
                          onTap: (tapPosition, point) {
                            _userActed = true;
                            _userChoseLocation = true;
                            _checkClearChipDetails(
                                point.latitude, point.longitude);
                            _mapController.move(
                                point, _mapController.camera.zoom);
                            _onMapCameraMoved(point, hasGesture: true);
                          },
                        ),

                        // center pin icon
                        IgnorePointer(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  curve: Curves.easeOutCubic,
                                  transform: Matrix4.translationValues(
                                    0,
                                    _isMapMoving ? -12 : 0,
                                    0,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: _userChoseLocation
                                          ? AppColors.primary
                                          : Colors.grey,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                              alpha:
                                                  _isMapMoving ? 0.35 : 0.25),
                                          blurRadius: _isMapMoving ? 10 : 6,
                                          offset:
                                              Offset(0, _isMapMoving ? 8 : 4),
                                        ),
                                      ],
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  curve: Curves.easeOutCubic,
                                  transform: Matrix4.translationValues(
                                    0,
                                    _isMapMoving ? -12 : 0,
                                    0,
                                  ),
                                  width: 3,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(1.5),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: _isMapMoving ? 8 : 12,
                                  height: _isMapMoving ? 3 : 4,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(
                                        alpha: _isMapMoving ? 0.2 : 0.4),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // gps accuracy badge
                        if (_accuracyMeters != null)
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 5),
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
                                    color: _accuracyMeters! > 50
                                        ? AppColors.warning
                                        : AppColors.success,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    context.l10n.accuracyBadge(
                                        _accuracyMeters!.round()),
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

                        // gps loading badge
                        if (_isGpsLoading)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
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
                          ),

                        // gps button in corner
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: Material(
                            color: context.themeSurface,
                            elevation: 3,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              onTap: () => _useCurrentGps(auto: false),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.my_location,
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

                  // address bar under map
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
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
                          Icon(
                            Icons.location_on,
                            size: 18,
                            color: _userChoseLocation
                                ? AppColors.primary
                                : context.themeTextSecondary,
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
                              color: _shortAddress.isNotEmpty
                                  ? context.themeInk
                                  : context.themeTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // gps error message
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
                                onPressed: () => _useCurrentGps(auto: false),
                                icon:
                                    const Icon(Icons.refresh_rounded, size: 16),
                                label: Text(context.l10n.tryGpsAgain),
                                style: OutlinedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  foregroundColor: AppColors.error,
                                  side:
                                      const BorderSide(color: AppColors.error),
                                ),
                              ),
                              // hide settings on web
                              if (!kIsWeb && _permissionPermanentlyDenied)
                                OutlinedButton.icon(
                                  onPressed: () => Geolocator.openAppSettings(),
                                  icon: const Icon(Icons.settings_outlined,
                                      size: 16),
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

                  const SizedBox(height: 12),

                  // extra details input
                  Container(
                    decoration: BoxDecoration(
                      color: context.themeSurfaceLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.themeBorder),
                    ),
                    child: Theme(
                      data: Theme.of(context)
                          .copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        initiallyExpanded: _isDetailsExpanded,
                        onExpansionChanged: (exp) =>
                            setState(() => _isDetailsExpanded = exp),
                        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                        childrenPadding:
                            const EdgeInsets.fromLTRB(14, 0, 14, 14),
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
                            onChanged: (_) {
                              _detailsFromChip = false;
                            },
                            decoration: InputDecoration(
                              counterText: '',
                              hintText:
                                  '${context.l10n.houseAptNo} (e.g. 12/B)',
                              prefixIcon:
                                  const Icon(Icons.home_outlined, size: 18),
                              filled: true,
                              fillColor: context.themeSurface,
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: context.themeBorder),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _noteController,
                            maxLength: 300,
                            maxLines: 2,
                            onChanged: (_) {
                              _detailsFromChip = false;
                            },
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: context.l10n.providerNoteHint,
                              prefixIcon:
                                  const Icon(Icons.note_alt_outlined, size: 18),
                              filled: true,
                              fillColor: context.themeSurface,
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide:
                                    BorderSide(color: context.themeBorder),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // save address chips
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
                            final icon = key == 'home'
                                ? Icons.home_outlined
                                : (key == 'work'
                                    ? Icons.work_outline
                                    : Icons.place_outlined);

                            return ActionChip(
                              avatar: Icon(icon, size: 14),
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSaved) ...[
                                    const Icon(Icons.check,
                                        size: 12, color: AppColors.success),
                                    const SizedBox(width: 3),
                                  ],
                                  Text(labelText),
                                ],
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
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

            // confirm button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: context.themeSurface,
                border: Border(top: BorderSide(color: context.themeBorder)),
              ),
              child: SizedBox(
                height: 50,
                width: double.infinity,
                child: PrimaryButton(
                  label: context.l10n.confirmLocation,
                  onPressed: _canConfirm ? _confirmLocation : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
