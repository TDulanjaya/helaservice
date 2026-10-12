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
  final _landmarkController = TextEditingController();
  final MapController _mapController = MapController();

  double? _latitude;
  double? _longitude;
  bool _isGpsLoading = false;
  bool _isSavingAddress = false;
  String _selectedLabel = 'home';
  bool _saveForFuture = false;
  bool _isMapMode = false;

  final List<String> _labelOptions = ['home', 'work', 'other'];

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _latitude = widget.initialLocation!.latitude;
      _longitude = widget.initialLocation!.longitude;
      _addressController.text = widget.initialLocation!.address;
      _landmarkController.text = widget.initialLocation!.landmark ?? '';
      _selectedLabel = widget.initialLocation!.label?.toLowerCase() ?? 'home';
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  bool get _canConfirm =>
      _latitude != null &&
      _longitude != null &&
      _addressController.text.trim().isNotEmpty;

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
          timeLimit: Duration(seconds: 10),
        ),
      );

      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
        if (_addressController.text.trim().isEmpty) {
          _addressController.text =
              'GPS Location (${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)})';
        }
      });

      _mapController.move(LatLng(pos.latitude, pos.longitude), 15.5);
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
      _addressController.text = addr.address;
      _landmarkController.text = addr.landmark ?? '';
      _selectedLabel = addr.label;
    });
    _mapController.move(LatLng(addr.latitude, addr.longitude), 15.5);
  }

  Future<void> _confirmLocation() async {
    if (!_canConfirm) return;

    final addressText = _addressController.text.trim();
    final landmarkText = _landmarkController.text.trim();
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
                  // action buttons
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
                            context.l10n.useCurrentGpsLocation,
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
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() => _isMapMode = !_isMapMode);
                        },
                        icon: Icon(
                          _isMapMode ? Icons.list_rounded : Icons.map_rounded,
                          size: 18,
                        ),
                        label: Text(_isMapMode ? context.l10n.pickerTabForm : context.l10n.pickerTabMapPin),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // map view with center pin
                  Container(
                    height: _isMapMode ? 280 : 180,
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
                          initialZoom: 14.5,
                          interactive: true,
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
                        // set pin button
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final center = _mapController.camera.center;
                              setState(() {
                                _latitude = center.latitude;
                                _longitude = center.longitude;
                                if (_addressController.text.trim().isEmpty) {
                                  _addressController.text =
                                      'Pin at ${center.latitude.toStringAsFixed(4)}, ${center.longitude.toStringAsFixed(4)}';
                                }
                              });
                            },
                            icon: const Icon(Icons.pin_drop_rounded, size: 16),
                            label: Text(
                              _latitude != null ? context.l10n.updatePinButton : context.l10n.setPinHereButton,
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
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
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

                  // address input field
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

                  // landmark input field
                  Text(
                    context.l10n.landmarkOrNoteOptional,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _landmarkController,
                    decoration: InputDecoration(
                      hintText: context.l10n.landmarkHint,
                      prefixIcon: const Icon(Icons.notes_rounded),
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
                      context.l10n.saveAddressForFuture,
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
