import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart' as vmt;
import '../../theme/app_theme.dart';
import '../../utils/l10n_extension.dart';

bool get _isDesktopOrWeb {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;
}

// center coordinates
const LatLng kSriLankaCenter = LatLng(7.8731, 80.7718);
const LatLng kColomboCenter = LatLng(6.9271, 79.8612);

class AppMapMarker {
  final LatLng point;
  final Widget child;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const AppMapMarker({
    required this.point,
    required this.child,
    this.width = 40,
    this.height = 40,
    this.onTap,
  });

  // customer marker
  factory AppMapMarker.customer({
    required LatLng point,
    String? label,
    VoidCallback? onTap,
  }) {
    return AppMapMarker(
      point: point,
      width: 60,
      height: 62,
      onTap: onTap,
      child: SizedBox(
        width: 60,
        height: 62,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.home_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Builder(
                builder: (ctx) => Text(
                  label ?? ctx.l10n.customerLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // technician marker
  factory AppMapMarker.provider({
    required LatLng point,
    String? label,
    bool enRoute = true,
    VoidCallback? onTap,
  }) {
    return AppMapMarker(
      point: point,
      width: 64,
      height: 62,
      onTap: onTap,
      child: SizedBox(
        width: 64,
        height: 62,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondaryContainer.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                enRoute ? Icons.two_wheeler_rounded : Icons.build_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Builder(
                builder: (ctx) => Text(
                  label ?? ctx.l10n.custArtisanLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // district marker
  factory AppMapMarker.hub({
    required LatLng point,
    required String label,
    required int count,
    bool isLarge = false,
    Color? color,
    VoidCallback? onTap,
  }) {
    final isZero = count == 0;
    final size = isZero ? 24.0 : (isLarge ? 42.0 : 32.0);
    final totalHeight = size + 18.0; // total height with label and spacing
    final markerColor = color ?? (isZero ? const Color(0xFF9E9E9E) : AppColors.primary);

    return AppMapMarker(
      point: point,
      width: 76,
      height: totalHeight,
      onTap: onTap,
      child: SizedBox(
        width: 76,
        height: totalHeight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: markerColor,
                shape: BoxShape.circle,
                boxShadow: isZero
                    ? null
                    : [
                        BoxShadow(
                          color: markerColor.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                border: Border.all(color: Colors.white, width: isZero ? 1.5 : 2),
              ),
              alignment: Alignment.center,
              child: Text(
                '$count',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isZero ? 9.5 : (isLarge ? 13 : 11),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: isZero ? Colors.black54 : Colors.black87,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isZero ? Colors.white70 : Colors.white,
                  fontSize: 9,
                  fontWeight: isZero ? FontWeight.normal : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppMapView extends StatefulWidget {
  final LatLng? initialCenter;
  final double initialZoom;
  final CameraFit? initialCameraFit;
  final List<AppMapMarker> markers;
  final List<LatLng>? routePoints;
  final bool interactive;
  final MapController? controller;
  final VoidCallback? onMapReady;
  final EdgeInsets? padding;
  final VoidCallback? onExpand;

  const AppMapView({
    super.key,
    this.initialCenter,
    this.initialZoom = 13.0,
    this.initialCameraFit,
    this.markers = const [],
    this.routePoints,
    this.interactive = true,
    this.controller,
    this.onMapReady,
    this.padding,
    this.onExpand,
  });

  @override
  State<AppMapView> createState() => _AppMapViewState();
}

class _AppMapViewState extends State<AppMapView> {
  late final MapController _mapController;

  static vmt.Style? _cachedLightStyle;
  static Future<vmt.Style>? _pendingLightStyleLoad;

  vmt.Style? _vectorStyle;

  @override
  void initState() {
    super.initState();
    _mapController = widget.controller ?? MapController();
    _loadLightStyle();
  }

  void _loadLightStyle() {
    // raster tiles for web and desktop
    if (_isDesktopOrWeb) {
      return;
    }

    if (_cachedLightStyle != null) {
      _vectorStyle = _cachedLightStyle;
      return;
    }

    _vectorStyle = null;

    _getOrFetchLightStyle().then((style) {
      if (mounted) {
        setState(() {
          _vectorStyle = style;
        });
      }
    }).catchError((error) {
      debugPrint(
          '[AppMapView] OpenFreeMap style loading error: $error. Falling back to OpenStreetMap raster tiles.');
      if (mounted) {
        setState(() {
          _vectorStyle = null;
        });
      }
    });
  }

  static Future<vmt.Style> _getOrFetchLightStyle() {
    if (_cachedLightStyle != null) return Future.value(_cachedLightStyle);
    if (_pendingLightStyleLoad != null) return _pendingLightStyleLoad!;

    final future = _fetchLightStyle().then((style) {
      _cachedLightStyle = style;
      _pendingLightStyleLoad = null;
      return style;
    }).catchError((error) {
      _pendingLightStyleLoad = null;
      throw error;
    });

    _pendingLightStyleLoad = future;
    return future;
  }

  static Future<vmt.Style> _fetchLightStyle() async {
    // light map tiles
    const primaryUri = 'https://tiles.openfreemap.org/styles/liberty';

    try {
      return await vmt.StyleReader(uri: primaryUri)
          .read()
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint(
          '[AppMapView] Liberty style failed ($e), falling back to positron style.');
      const positronUri = 'https://tiles.openfreemap.org/styles/positron';
      try {
        return await vmt.StyleReader(
          uri: positronUri,
        ).read().timeout(const Duration(seconds: 10));
      } catch (err) {
        debugPrint('[AppMapView] Positron style also failed: $err');
        rethrow;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.initialCenter ??
        (widget.markers.isNotEmpty
            ? widget.markers.first.point
            : kColomboCenter);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: context.themeSurface,
        child: Stack(
          children: [
            MouseRegion(
              cursor: widget.interactive
                  ? SystemMouseCursors.grab
                  : MouseCursor.defer,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: widget.initialCameraFit != null
                      ? (widget.initialCenter ?? const LatLng(7.85, 80.725))
                      : center,
                  initialZoom: widget.initialZoom,
                  initialCameraFit: widget.initialCameraFit,
                  minZoom: 5.0,
                  maxZoom: 18.0,
                  interactionOptions: InteractionOptions(
                    flags: widget.interactive
                        ? InteractiveFlag.all
                        : InteractiveFlag.none,
                    scrollWheelVelocity: 0.005,
                  ),
                  onMapReady: widget.onMapReady,
                ),
                children: [
                  // vector tiles for mobile
                  if (!_isDesktopOrWeb && _vectorStyle != null)
                    vmt.VectorTileLayer(
                      key: const ValueKey('vmt_light_layer'),
                      theme: _vectorStyle!.theme,
                      sprites: _vectorStyle!.sprites,
                      tileProviders: _vectorStyle!.providers,
                    )
                  else
                    // fallback to raster tiles
                    TileLayer(
                      key: const ValueKey('osm_raster_layer'),
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.helaservice.helaservice',
                      maxZoom: 19,
                    ),
                  if (widget.routePoints != null &&
                      widget.routePoints!.length > 1)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: widget.routePoints!,
                          strokeWidth: 4.0,
                          color: AppColors.primary,
                          borderStrokeWidth: 2.0,
                          borderColor: Colors.white,
                        ),
                      ],
                    ),
                  if (widget.markers.isNotEmpty)
                    MarkerLayer(
                      markers: widget.markers.map((m) {
                        return Marker(
                          point: m.point,
                          width: m.width,
                          height: m.height,
                          child: GestureDetector(
                            onTap: m.onTap,
                            child: m.child,
                          ),
                        );
                      }).toList(),
                    ),
                  RichAttributionWidget(
                    alignment: AttributionAlignment.bottomLeft,
                    popupInitialDisplayDuration: const Duration(seconds: 4),
                    showFlutterMapAttribution: false,
                    popupBackgroundColor: context.themeSurface,
                    animationConfig: const FadeRAWA(),
                    attributions: const [
                      TextSourceAttribution('OpenFreeMap'),
                      TextSourceAttribution('OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),
            ),
            // expand button
            if (widget.onExpand != null)
              Positioned(
                top: 10,
                right: 10,
                child: Material(
                  color: context.themeSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: context.themeBorder),
                  ),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: widget.onExpand,
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Tooltip(
                        message: context.l10n.expandMap,
                        child: Icon(
                          Icons.open_in_full,
                          size: 18,
                          color: context.themeTextPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // zoom controls
            if (widget.interactive)
              Positioned(
                right: 10,
                bottom: 10,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MapCtrlBtn(
                      icon: Icons.add,
                      tooltip: context.l10n.zoomIn,
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(
                          _mapController.camera.center,
                          (currentZoom + 1).clamp(5.0, 18.0),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    _MapCtrlBtn(
                      icon: Icons.remove,
                      tooltip: context.l10n.zoomOut,
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(
                          _mapController.camera.center,
                          (currentZoom - 1).clamp(5.0, 18.0),
                        );
                      },
                    ),
                    if (widget.initialCameraFit != null ||
                        widget.initialCenter != null) ...[
                      const SizedBox(height: 4),
                      _MapCtrlBtn(
                        icon: Icons.filter_center_focus_rounded,
                        tooltip: context.l10n.recenterMap,
                        onPressed: () {
                          if (widget.initialCameraFit != null) {
                            _mapController.fitCamera(widget.initialCameraFit!);
                          } else {
                            _mapController.move(
                              widget.initialCenter ?? center,
                              widget.initialZoom,
                            );
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MapCtrlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const _MapCtrlBtn({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    Widget btn = Material(
      color: context.themeSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: context.themeBorder),
      ),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 18, color: context.themeTextPrimary),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: btn,
      );
    }
    return btn;
  }
}
