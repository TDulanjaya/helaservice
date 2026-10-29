import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../utils/location_utils.dart';

class RouteInfo {
  final List<LatLng> points;
  final double distanceKm;
  final int durationMinutes;
  final String formattedDistance;
  final String formattedDuration;
  final bool isEstimated;

  const RouteInfo({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
    required this.formattedDistance,
    required this.formattedDuration,
    this.isEstimated = false,
  });

  factory RouteInfo.empty() => const RouteInfo(
        points: [],
        distanceKm: 0,
        durationMinutes: 0,
        formattedDistance: '',
        formattedDuration: '',
        isEstimated: false,
      );

  factory RouteInfo.fallback(LatLng start, LatLng end) {
    final straightKm = LocationUtils.calculateDistanceKm(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
    // rough road distance (~1.3x)
    final roadKm = straightKm * 1.30;
    final durationMins = ((roadKm / 25.0) * 60).round().clamp(1, 180);

    final distStr = roadKm < 1.0
        ? '${(roadKm * 1000).round()} m'
        : '${roadKm.toStringAsFixed(1)} km';

    return RouteInfo(
      points: [start, end],
      distanceKm: roadKm,
      durationMinutes: durationMins,
      formattedDistance: '$distStr (Estimated)',
      formattedDuration: '$durationMins mins (Estimated)',
      isEstimated: true,
    );
  }
}

class RoutingService {
  RoutingService._();
  static final RoutingService _instance = RoutingService._();
  factory RoutingService() => _instance;

  final Map<String, RouteInfo> _cache = {};
  DateTime? _lastOsrmAttempt;

  Future<RouteInfo> getDrivingRoute({
    required LatLng origin,
    required LatLng destination,
    bool forceRefresh = false,
  }) async {
    final cacheKey =
        '${origin.latitude.toStringAsFixed(4)},${origin.longitude.toStringAsFixed(4)}_${destination.latitude.toStringAsFixed(4)},${destination.longitude.toStringAsFixed(4)}';

    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey]!;
      if (!cached.isEstimated) {
        return cached;
      }
    }

    final now = DateTime.now();
    if (_lastOsrmAttempt != null &&
        now.difference(_lastOsrmAttempt!).inSeconds < 30 &&
        _cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }
    _lastOsrmAttempt = now;

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response = await http.get(url, headers: {
        'User-Agent': 'HelaService-App/1.0'
      }).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List?;

        if (routes != null && routes.isNotEmpty) {
          final route = routes.first;
          final double distanceMeters = (route['distance'] as num).toDouble();
          final double durationSeconds = (route['duration'] as num).toDouble();

          final geometry = route['geometry'] as Map<String, dynamic>?;
          final coordinates = geometry?['coordinates'] as List?;

          final points = <LatLng>[];
          if (coordinates != null && coordinates.isNotEmpty) {
            for (final coord in coordinates) {
              final lon = (coord[0] as num).toDouble();
              final lat = (coord[1] as num).toDouble();
              points.add(LatLng(lat, lon));
            }
          }

          if (points.isEmpty) {
            points.addAll([origin, destination]);
          }

          final distanceKm = distanceMeters / 1000.0;
          final durationMins = (durationSeconds / 60.0).round().clamp(1, 300);

          final result = RouteInfo(
            points: points,
            distanceKm: distanceKm,
            durationMinutes: durationMins,
            formattedDistance: distanceKm < 1.0
                ? '${distanceMeters.round()} m'
                : '${distanceKm.toStringAsFixed(1)} km',
            formattedDuration: '$durationMins mins',
            isEstimated: false,
          );

          _cache[cacheKey] = result;
          return result;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('RoutingService road calculation notice (using fallback): $e');
      }
    }

    // fallback straight line route if osrm is offline or rate limited
    final fallback = RouteInfo.fallback(origin, destination);
    _cache[cacheKey] = fallback;
    return fallback;
  }
}
