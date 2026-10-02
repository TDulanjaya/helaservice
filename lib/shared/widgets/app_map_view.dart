import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart' as vmt;
import '../../theme/app_theme.dart';
import '../../utils/l10n_extension.dart';

/// Center point of Sri Lanka.
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

  /// Marker for a customer location.
  factory AppMapMarker.customer({
    required LatLng point,
    String label = 'Customer',
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
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Marker for a technician location.
  factory AppMapMarker.provider({
    required LatLng point,
    String label = 'Artisan',
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
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Marker for a district hub.
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
    final totalHeight = size + 18.0; // icon circle + label + spacing
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

  static final Map<Brightness, vmt.Style> _styleCache = {};
  static final Map<Brightness, Future<vmt.Style>> _pendingStyleLoads = {};

  vmt.Style? _vectorStyle;
  bool _hasStyleError = false;
  Brightness? _activeBrightness;

  @override
  void initState() {
    super.initState();
    _mapController = widget.controller ?? MapController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    if (_activeBrightness != brightness) {
      _loadStyleForBrightness(brightness);
    }
  }

  void _loadStyleForBrightness(Brightness brightness) {
    _activeBrightness = brightness;
    final cached = _styleCache[brightness];
    if (cached != null) {
      _vectorStyle = cached;
      _hasStyleError = false;
      return;
    }

    _vectorStyle = null;
    _hasStyleError = false;

    _getOrFetchStyle(brightness).then((style) {
      if (mounted && _activeBrightness == brightness) {
        setState(() {
          _vectorStyle = style;
          _hasStyleError = false;
        });
      }
    }).catchError((error) {
      debugPrint(
          '[AppMapView] OpenFreeMap style loading error: $error. Falling back to OpenStreetMap raster tiles.');
      if (mounted && _activeBrightness == brightness) {
        setState(() {
          _vectorStyle = null;
          _hasStyleError = true;
        });
      }
    });
  }

  static Future<vmt.Style> _getOrFetchStyle(Brightness brightness) {
    final cached = _styleCache[brightness];
    if (cached != null) return Future.value(cached);

    final pending = _pendingStyleLoads[brightness];
    if (pending != null) return pending;

    final future = _fetchStyle(brightness).then((style) {
      _styleCache[brightness] = style;
      _pendingStyleLoads.remove(brightness);
      return style;
    }).catchError((error) {
      _pendingStyleLoads.remove(brightness);
      throw error;
    });

    _pendingStyleLoads[brightness] = future;
    return future;
  }

  static Future<vmt.Style> _fetchStyle(Brightness brightness) async {
    final isDark = brightness == Brightness.dark;
    final primaryUri = isDark
        ? 'https://tiles.openfreemap.org/styles/dark'
        : 'https://tiles.openfreemap.org/styles/liberty';

    try {
      return await vmt.StyleReader(uri: primaryUri)
          .read()
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      if (isDark) {
        debugPrint(
            '[AppMapView] Dark style failed ($e), falling back to positron style.');
        try {
          return await vmt.StyleReader(
            uri: 'https://tiles.openfreemap.org/styles/positron',
          ).read().timeout(const Duration(seconds: 10));
        } catch (err) {
          debugPrint('[AppMapView] Positron style also failed: $err');
          rethrow;
        }
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
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
            FlutterMap(
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
                ),
                onMapReady: widget.onMapReady,
              ),
              children: [
                if (_vectorStyle != null)
                  vmt.VectorTileLayer(
                    key: ValueKey('vmt_${isDark ? "dark" : "light"}'),
                    theme: _vectorStyle!.theme,
                    sprites: _vectorStyle!.sprites,
                    tileProviders: _vectorStyle!.providers,
                  )
                else if (_hasStyleError)
                  TileLayer(
                    key: const ValueKey('osm_raster_fallback'),
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.helaservice.helaservice',
                    maxZoom: 19,
                  ),
                if (widget.routePoints != null && widget.routePoints!.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: widget.routePoints!,
                        strokeWidth: 4.0,
                        color: AppColors.primary,
                        borderStrokeWidth: 2.0,
                        borderColor: isDark ? Colors.black : Colors.white,
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
            // expand button in top right corner
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
            // zoom buttons when map is interactive
            if (widget.interactive)
              Positioned(
                right: 10,
                bottom: 10,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MapCtrlBtn(
                      icon: Icons.add,
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
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(
                          _mapController.camera.center,
                          (currentZoom - 1).clamp(5.0, 18.0),
                        );
                      },
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


class _MapCtrlBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _MapCtrlBtn({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
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
  }
}
