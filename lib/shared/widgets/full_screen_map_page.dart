import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../theme/app_theme.dart';
import '../../utils/l10n_extension.dart';
import 'app_map_view.dart';

// full screen live map view
class FullScreenMapPage extends StatefulWidget {
  final ValueNotifier<List<AppMapMarker>> markersNotifier;
  final ValueNotifier<List<LatLng>?>? routePointsNotifier;
  final LatLng? initialCenter;
  final double initialZoom;
  final CameraFit? initialCameraFit;
  final Widget? headerAction;

  const FullScreenMapPage({
    super.key,
    required this.markersNotifier,
    this.routePointsNotifier,
    this.initialCenter,
    this.initialZoom = 13.0,
    this.initialCameraFit,
    this.headerAction,
  });

  @override
  State<FullScreenMapPage> createState() => _FullScreenMapPageState();
}

class _FullScreenMapPageState extends State<FullScreenMapPage> {
  late List<AppMapMarker> _markers;
  List<LatLng>? _routePoints;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _markers = widget.markersNotifier.value;
    _routePoints = widget.routePointsNotifier?.value;

    try {
      widget.markersNotifier.addListener(_onMarkersChanged);
      widget.routePointsNotifier?.addListener(_onRouteChanged);
      _isListening = true;
    } catch (_) {
      // keep last data if notifier failed
    }
  }

  void _onMarkersChanged() {
    if (!mounted) return;
    setState(() {
      _markers = widget.markersNotifier.value;
    });
  }

  void _onRouteChanged() {
    if (!mounted) return;
    setState(() {
      _routePoints = widget.routePointsNotifier?.value;
    });
  }

  @override
  void dispose() {
    if (_isListening) {
      try {
        widget.markersNotifier.removeListener(_onMarkersChanged);
      } catch (_) {}
      try {
        widget.routePointsNotifier?.removeListener(_onRouteChanged);
      } catch (_) {}
      _isListening = false;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: AppMapView(
                initialCenter: widget.initialCenter,
                initialZoom: widget.initialZoom,
                initialCameraFit: widget.initialCameraFit,
                markers: _markers,
                routePoints: _routePoints,
                interactive: true,
              ),
            ),
            // close button on top left
            Positioned(
              top: 16,
              left: 16,
              child: Material(
                color: context.themeSurface.withValues(alpha: 0.95),
                shape: const CircleBorder(),
                elevation: 3,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: context.themeBorder),
                    ),
                    child: Tooltip(
                      message: context.l10n.closeMap,
                      child: Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: context.themeTextPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // extra top right button like district switch
            if (widget.headerAction != null)
              Positioned(
                top: 16,
                right: 16,
                child: widget.headerAction!,
              ),
          ],
        ),
      ),
    );
  }
}
