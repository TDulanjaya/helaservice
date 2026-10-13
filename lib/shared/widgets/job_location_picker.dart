import 'dart:async';
import 'dart:convert';
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
  final _addressController = TextEditingController();
  final _houseNoController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _directionsController = TextEditingController();
  final MapController _mapController = MapController();

  double? _latitude;
  double? _longitude;
  double? _accuracyMeters;
  bool _isGpsLoading = false;
  bool _isGeocodingLoading = false;
  bool _isSavingAddress = false;
  String _selectedLabel = 'home';
  bool _saveForFuture = false;

  Timer? _debounceTimer;
  DateTime _lastGeocodeRequestTime = DateTime.fromMillisecondsSinceEpoch(0);

  final List<String> _labelOptions = ['home', 'work', 'other'];

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _latitude = widget.initialLocation!.latitude;
      _longitude = widget.initialLocation!.longitude;
      _accuracyMeters = widget.initialLocation!.accuracyMeters;
      _addressController.text = widget.initialLocation!.address;
      _houseNoController.text = widget.initialLocation!.houseNo ?? '';
      _streetController.text = widget.initialLocation!.street ?? '';
      _cityController.text = widget.initialLocation!.city ?? '';
      _landmarkController.text = widget.initialLocation!.landmark ?? '';
      _directionsController.text = widget.initialLocation!.directions ?? '';
      _selectedLabel = widget.initialLocation!.label?.toLowerCase() ?? 'home';
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _addressController.dispose();
    _houseNoController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _landmarkController.dispose();
    _directionsController.dispose();
    super.dispose();
  }

  bool get _canConfirm => _latitude != null && _longitude != null;

  /// Reverse geocodes using OpenStreetMap Nominatim with debouncing & rate limiting
  Future<void> _reverseGeocode(double lat, double lon) async {
    final now = DateTime.now();
    final elapsed = now.difference(_lastGeocodeRequestTime);
    if (elapsed.inMilliseconds < 1000) {
      await Future.delayed(Duration(milliseconds: 1000 - elapsed.inMilliseconds));
    }
    _lastGeocodeRequestTime = DateTime.now();

    if (!mounted) return;
    setState(() => _isGeocodingLoading = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'HelaService-App/1.0'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final displayName = (data['display_name'] as String?) ?? '';
        final addr = data['address'] as Map<String, dynamic>?;

        if (mounted) {
          setState(() {
            if (displayName.isNotEmpty) {
              _addressController.text = displayName;
            } else {
              _addressController.text =
                  '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}';
            }
            if (addr != null) {
              if (_streetController.text.trim().isEmpty) {
                final road = addr['road'] as String?;
                if (road != null && road.isNotEmpty) _streetController.text = road;
              }
              if (_cityController.text.trim().isEmpty) {
                final city = (addr['city'] ?? addr['town'] ?? addr['suburb'] ?? addr['village']) as String?;
                if (city != null && city.isNotEmpty) _cityController.text = city;
              }
            }
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
    setState(() {
      if (_addressController.text.trim().isEmpty) {
        _addressController.text =
            '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}';
      }
    });
  }

  void _onMapCameraMoved(LatLng center) {
    setState(() {
      _latitude = center.latitude;
      _longitude = center.longitude;
      // manual drag clears GPS accuracy
      _accuracyMeters = null;
    });

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 800), () {
      _reverseGeocode(center.latitude, center.longitude);
    });
  }

  Future<void> _useCurrentGps() async {
    setState(() => _isGpsLoading = true);
    try {
      final granted =
          await PermissionUtils.requestLocationWithRationale(context);
      if (!granted) {
        setState(() => _isGpsLoading = false);
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
      });

      _mapController.move(LatLng(pos.latitude, pos.longitude), 18.0);
      _reverseGeocode(pos.latitude, pos.longitude);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.couldNotDetectLocation(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGpsLoading = false);
      }
    }
  }

  void _onSelectSavedAddress(SavedAddress addr) {
    setState(() {
      _latitude = addr.latitude;
      _longitude = addr.longitude;
      _accuracyMeters = addr.accuracyMeters;
      _addressController.text = addr.address;
      _houseNoController.text = addr.houseNo ?? '';
      _streetController.text = addr.street ?? '';
      _cityController.text = addr.city ?? '';
      _landmarkController.text = addr.landmark ?? '';
      _directionsController.text = addr.directions ?? '';
      _selectedLabel = addr.label;
    });
    _mapController.move(LatLng(addr.latitude, addr.longitude), 18.0);
  }

  Future<void> _confirmLocation() async {
    if (!_canConfirm) return;

    var addressText = _addressController.text.trim();
    if (addressText.isEmpty) {
      final parts = [
        _houseNoController.text.trim(),
        _streetController.text.trim(),
        _cityController.text.trim(),
      ].where((s) => s.isNotEmpty).toList();
      if (parts.isNotEmpty) {
        addressText = parts.join(', ');
      } else {
        addressText = '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}';
      }
    }

    final landmarkText = _landmarkController.text.trim();
    final houseNoText = _houseNoController.text.trim();
    final streetText = _streetController.text.trim();
    final cityText = _cityController.text.trim();
    final directionsText = _directionsController.text.trim();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (_saveForFuture && uid != null && uid.isNotEmpty) {
      setState(() => _isSavingAddress = true);
      try {
        await SavedAddressRepository().addSavedAddress(
          userId: uid,
          label: _selectedLabel,
          latitude: _latitude!,
          longitude: _longitude!,
          address: addressText,
          landmark: landmarkText.isNotEmpty ? landmarkText : null,
          accuracyMeters: _accuracyMeters,
          houseNo: houseNoText.isNotEmpty ? houseNoText : null,
          street: streetText.isNotEmpty ? streetText : null,
          city: cityText.isNotEmpty ? cityText : null,
          directions: directionsText.isNotEmpty ? directionsText : null,
        );
      } catch (e) {
        debugPrint('[JobLocationPicker] Error saving address: $e');
      } finally {
        if (mounted) {
          setState(() => _isSavingAddress = false);
        }
      }
    }

    if (!mounted) return;

    final location = JobLocation(
      latitude: _latitude!,
      longitude: _longitude!,
      address: addressText,
      landmark: landmarkText.isNotEmpty ? landmarkText : null,
      label: _selectedLabel,
      accuracyMeters: _accuracyMeters,
      houseNo: houseNoText.isNotEmpty ? houseNoText : null,
      street: streetText.isNotEmpty ? streetText : null,
      city: cityText.isNotEmpty ? cityText : null,
      directions: directionsText.isNotEmpty ? directionsText : null,
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
                  // GPS action button with accuracy info
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isGpsLoading ? null : _useCurrentGps,
                          icon: _isGpsLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : const Icon(Icons.my_location_rounded,
                                  color: AppColors.primary, size: 18),
                          label: Text(
                            context.l10n.exactCurrentLocation,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      if (_accuracyMeters != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: _accuracyMeters! > 50
                                ? AppColors.warning.withValues(alpha: 0.15)
                                : AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _accuracyMeters! > 50
                                  ? AppColors.warning
                                  : AppColors.success,
                            ),
                          ),
                          child: Text(
                            context.l10n.locationAccuracy(_accuracyMeters!.round()),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _accuracyMeters! > 50
                                  ? AppColors.warning
                                  : AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Warning if accuracy is worse than 50m
                  if (_accuracyMeters != null && _accuracyMeters! > 50) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: AppColors.warning, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.l10n.locationAccuracyLowWarning(
                                  _accuracyMeters!.round()),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Fine tune instruction
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: context.themeSurfaceLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.themeBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.touch_app_rounded,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.l10n.fineTunePinInstruction,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.themeInk,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Map container with draggable center pin
                  Container(
                    height: 240,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _latitude != null
                            ? AppColors.primary
                            : context.themeBorder,
                        width: _latitude != null ? 1.5 : 1,
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
                          initialZoom: (_latitude != null && _longitude != null) ? 18.0 : 14.5,
                          interactive: true,
                          onPositionChanged: (camera, hasGesture) {
                            if (hasGesture) {
                              _onMapCameraMoved(camera.center);
                            }
                          },
                        ),
                        // center pin
                        IgnorePointer(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border:
                                      Border.all(color: Colors.white, width: 2),
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
                        // update pin button
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final center = _mapController.camera.center;
                              _onMapCameraMoved(center);
                            },
                            icon: const Icon(Icons.pin_drop_rounded, size: 16),
                            label: Text(
                              _latitude != null
                                  ? context.l10n.updatePinButton
                                  : context.l10n.setPinHereButton,
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        if (_latitude != null && _longitude != null)
                          Positioned(
                            top: 10,
                            left: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  if (_isGeocodingLoading) ...[
                                    const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Expanded(
                                    child: Text(
                                      _addressController.text.isNotEmpty
                                          ? _addressController.text
                                          : '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // saved addresses
                  if (uid.isNotEmpty) ...[
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
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 64,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: addresses.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final item = addresses[index];
                                  final isCurrent = _latitude != null &&
                                      _longitude != null &&
                                      (_latitude! - item.latitude).abs() <
                                          0.0001 &&
                                      (_longitude! - item.longitude).abs() <
                                          0.0001;

                                  return InkWell(
                                    onTap: () => _onSelectSavedAddress(item),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: 170,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isCurrent
                                            ? AppColors.primary
                                                .withValues(alpha: 0.12)
                                            : context.themeSurfaceLow,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isCurrent
                                              ? AppColors.primary
                                              : context.themeBorder,
                                          width: isCurrent ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Builder(
                                            builder: (ctx) {
                                              final isHome = item.label.toLowerCase() == 'home';
                                              final isWork = item.label.toLowerCase() == 'work';
                                              final itemDisplayLabel = isHome
                                                  ? ctx.l10n.addressLabelHome
                                                  : (isWork
                                                      ? ctx.l10n.addressLabelWork
                                                      : (item.label.toLowerCase() == 'other'
                                                          ? ctx.l10n.addressLabelOther
                                                          : item.label));
                                              return Row(
                                                children: [
                                                  Icon(
                                                    isHome
                                                        ? Icons.home_rounded
                                                        : (isWork
                                                            ? Icons.work_rounded
                                                            : Icons.location_on_rounded),
                                                    size: 14,
                                                    color: isCurrent
                                                        ? AppColors.primary
                                                        : ctx.themeTextSecondary,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    itemDisplayLabel,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w800,
                                                      color: isCurrent
                                                          ? AppColors.primary
                                                          : ctx.themeInk,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item.address,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
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
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),
                  ],

                  // Address Details Fields
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.houseAptNo,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _houseNoController,
                              maxLength: 100,
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: 'e.g. 12/B',
                                prefixIcon: const Icon(Icons.home_outlined),
                                filled: true,
                                fillColor: context.themeSurfaceLow,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: context.themeBorder),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.streetName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _streetController,
                              maxLength: 100,
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: 'e.g. Main Street',
                                prefixIcon: const Icon(Icons.edit_road_outlined),
                                filled: true,
                                fillColor: context.themeSurfaceLow,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: context.themeBorder),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text(
                    context.l10n.townCity,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _cityController,
                    maxLength: 100,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'e.g. Colombo 03',
                      prefixIcon: const Icon(Icons.location_city_outlined),
                      filled: true,
                      fillColor: context.themeSurfaceLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.themeBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Full / formatted address input field
                  Text(
                    '${context.l10n.serviceAddressLabel} *',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _addressController,
                    onChanged: (_) => setState(() {}),
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: context.l10n.serviceAddressHint,
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      filled: true,
                      fillColor: context.themeSurfaceLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.themeBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Landmark
                  Text(
                    context.l10n.landmarkOptional,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _landmarkController,
                    maxLength: 100,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: context.l10n.landmarkHint,
                      prefixIcon: const Icon(Icons.flag_outlined),
                      filled: true,
                      fillColor: context.themeSurfaceLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.themeBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Directions for provider
                  Text(
                    context.l10n.directionsForProvider,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _directionsController,
                    maxLength: 300,
                    maxLines: 2,
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'e.g. Call at gate 2, ring the bell on the right',
                      prefixIcon: const Icon(Icons.directions_outlined),
                      filled: true,
                      fillColor: context.themeSurfaceLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.themeBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // save address option
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: _saveForFuture,
                    onChanged: (val) =>
                        setState(() => _saveForFuture = val ?? false),
                    title: Text(
                      context.l10n.saveThisAddress,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: AppColors.primary,
                  ),

                  if (_saveForFuture) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: _labelOptions.map((labelKey) {
                        final isSel = _selectedLabel == labelKey;
                        final chipText = labelKey == 'home'
                            ? context.l10n.addressLabelHome
                            : (labelKey == 'work'
                                ? context.l10n.addressLabelWork
                                : context.l10n.addressLabelOther);
                        return ChoiceChip(
                          label: Text(chipText),
                          selected: isSel,
                          onSelected: (_) =>
                              setState(() => _selectedLabel = labelKey),
                          selectedColor:
                              AppColors.primary.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSel
                                ? AppColors.primary
                                : context.themeTextSecondary,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            // confirm button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: context.themeSurface,
                border: Border(top: BorderSide(color: context.themeBorder)),
              ),
              child: SizedBox(
                height: 52,
                child: PrimaryButton(
                  label: _latitude == null || _longitude == null
                      ? context.l10n.selectPinOnMap
                      : context.l10n.confirmLocation,
                  onPressed: _canConfirm && !_isSavingAddress
                      ? _confirmLocation
                      : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
