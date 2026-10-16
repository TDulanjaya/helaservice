import 'package:latlong2/latlong.dart';
import 'location_utils.dart';

class ExactLocationUnavailableException implements Exception {
  final String message;
  const ExactLocationUnavailableException(
      [this.message = 'Exact location unavailable']);

  @override
  String toString() => 'ExactLocationUnavailableException: $message';
}

enum NavigationLocationState {
  ready,
  missingCustomer,
  gettingProviderLocation,
  providerLocationFailed,
}

class ExactLocationHelper {
  // coordinates must be valid numbers and within lat/long range
  static bool validate(Map<String, dynamic>? data) {
    if (data == null) return false;
    final lat = data['latitude'];
    final lng = data['longitude'];
    if (lat is! num || lng is! num) return false;

    final latVal = lat.toDouble();
    final lngVal = lng.toDouble();
    if (latVal.isNaN || lngVal.isNaN) return false;
    if (latVal < -90.0 || latVal > 90.0) return false;
    if (lngVal < -180.0 || lngVal > 180.0) return false;
    // reject 0,0 (null island)
    if (latVal == 0.0 && lngVal == 0.0) return false;

    return true;
  }

  static LatLng? resolveCustomerPoint({double? latitude, double? longitude}) {
    if (latitude == null || longitude == null) return null;
    if (latitude.isNaN || longitude.isNaN) return null;
    if (latitude < -90.0 || latitude > 90.0) return null;
    if (longitude < -180.0 || longitude > 180.0) return null;
    if (latitude == 0.0 && longitude == 0.0) return null;
    return LatLng(latitude, longitude);
  }

  static LatLng? resolveTechPoint(LatLng? gpsPosition) {
    if (gpsPosition == null) return null;
    if (gpsPosition.latitude.isNaN || gpsPosition.longitude.isNaN) return null;
    if (gpsPosition.latitude < -90.0 || gpsPosition.latitude > 90.0) {
      return null;
    }
    if (gpsPosition.longitude < -180.0 || gpsPosition.longitude > 180.0) {
      return null;
    }
    if (gpsPosition.latitude == 0.0 && gpsPosition.longitude == 0.0) {
      return null;
    }
    return gpsPosition;
  }

  // determines screen state based on available coordinates
  static NavigationLocationState evaluateState({
    required LatLng? customerPoint,
    required LatLng? techPoint,
    bool gpsFailed = false,
  }) {
    if (customerPoint == null) {
      return NavigationLocationState.missingCustomer;
    }
    if (techPoint == null) {
      return gpsFailed
          ? NavigationLocationState.providerLocationFailed
          : NavigationLocationState.gettingProviderLocation;
    }
    return NavigationLocationState.ready;
  }

  // check if route needs recalculation
  static bool shouldRefreshRoute({
    required LatLng? currentPos,
    required LatLng? lastRoutePos,
    required DateTime? lastFetchedAt,
    required DateTime now,
    bool isEstimated = false,
  }) {
    if (currentPos == null) return false;
    if (lastRoutePos == null || lastFetchedAt == null) return true;

    final elapsed = now.difference(lastFetchedAt);
    // rate limit to at most once every 2 minutes
    if (elapsed < const Duration(minutes: 2)) return false;

    // retry sooner if previous route was just an estimate
    if (isEstimated) return true;

    // refresh if moved at least 300m
    final distKm = LocationUtils.calculateDistanceKm(
      currentPos.latitude,
      currentPos.longitude,
      lastRoutePos.latitude,
      lastRoutePos.longitude,
    );
    return distKm * 1000.0 >= 300.0;
  }
}
