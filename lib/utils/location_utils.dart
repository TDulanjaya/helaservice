import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import '../l10n/app_localizations.dart';
import 'l10n_extension.dart';

class LocationUtils {
  LocationUtils._();

  static const Map<String, ({double lat, double lng})> districtCoordinates = {
    'Colombo': (lat: 6.9271, lng: 79.8612),
    'Gampaha': (lat: 7.0840, lng: 80.0098),
    'Kalutara': (lat: 6.5854, lng: 79.9607),
    'Kandy': (lat: 7.2906, lng: 80.6337),
    'Galle': (lat: 6.0535, lng: 80.2210),
    'Matara': (lat: 5.9549, lng: 80.5550),
    'Kurunegala': (lat: 7.4863, lng: 80.3623),
    'Jaffna': (lat: 9.6615, lng: 80.0255),
    'Anuradhapura': (lat: 8.3114, lng: 80.4037),
    'Ratnapura': (lat: 6.7056, lng: 80.3847),
    'Batticaloa': (lat: 7.7310, lng: 81.6747),
    'Trincomalee': (lat: 8.5874, lng: 81.2152),
    'Badulla': (lat: 6.9934, lng: 81.0550),
    'Matale': (lat: 7.4675, lng: 80.6234),
    'Nuwara Eliya': (lat: 6.9497, lng: 80.7891),
    'Hambantota': (lat: 6.1429, lng: 81.1212),
    'Puttalam': (lat: 8.0408, lng: 79.8394),
    'Polonnaruwa': (lat: 7.9403, lng: 81.0188),
    'Monaragala': (lat: 6.8728, lng: 81.3507),
    'Kegalle': (lat: 7.2513, lng: 80.3464),
    'Ampara': (lat: 7.3018, lng: 81.6747),
    'Mannar': (lat: 8.9810, lng: 79.9044),
    'Vavuniya': (lat: 8.7514, lng: 80.4971),
    'Mullaitivu': (lat: 9.2671, lng: 80.8142),
    'Kilinochchi': (lat: 9.3803, lng: 80.3770),
  };

  static ({double lat, double lng}) getDistrictCoordinates(String district) {
    return districtCoordinates[district] ?? (lat: 6.9271, lng: 79.8612);
  }

  // find district by gps or name
  static String? resolveDistrict({
    double? latitude,
    double? longitude,
    String? district,
    String? serviceArea,
  }) {
    // check nearest district by gps first
    if (latitude != null &&
        longitude != null &&
        (latitude != 0.0 || longitude != 0.0)) {
      String? nearestDistrict;
      double minDistance = double.infinity;
      for (final entry in districtCoordinates.entries) {
        final dist = calculateDistanceKm(
          latitude,
          longitude,
          entry.value.lat,
          entry.value.lng,
        );
        if (dist < minDistance) {
          minDistance = dist;
          nearestDistrict = entry.key;
        }
      }
      return nearestDistrict;
    }

    // fallback to text matching
    final candidate = (district != null && district.trim().isNotEmpty)
        ? district.trim()
        : (serviceArea != null && serviceArea.trim().isNotEmpty)
            ? serviceArea.trim()
            : null;

    if (candidate == null || candidate.isEmpty) {
      return null;
    }

    // exact match
    final lowerCandidate = candidate.toLowerCase();
    for (final d in districtCoordinates.keys) {
      if (d.toLowerCase() == lowerCandidate) {
        return d;
      }
    }

    // match district name inside text
    final sortedDistricts = districtCoordinates.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final d in sortedDistricts) {
      final pattern =
          RegExp(r'\b' + RegExp.escape(d) + r'\b', caseSensitive: false);
      if (pattern.hasMatch(candidate)) {
        return d;
      }
    }

    return null;
  }

  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double p = 0.017453292519943295;
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a));
  }

  static String formatDistance(double km, {AppLocalizations? l10n}) {
    if (l10n != null) {
      if (km < 1.0) {
        return l10n.custMetresAway((km * 1000).round());
      }
      return l10n.custKmAwayValue(km.toStringAsFixed(1));
    }
    if (km < 1.0) {
      return '${(km * 1000).round()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  // format distance for ui
  static String formatDistanceL10n(BuildContext context, double km) {
    if (km < 1.0) {
      return context.l10n.custMetresAway((km * 1000).round());
    }
    return context.l10n.custKmAwayValue(km.toStringAsFixed(1));
  }

  static String formatEstimatedDriveTime(BuildContext context, double km) {
    int mins = ((km / 28.0) * 60).round();
    if (mins < 3) mins = 3;
    return context.l10n.estTravelTime(mins);
  }

  static String getProximityLabel(BuildContext context, double km) {
    if (km < 5.0) {
      return context.l10n.nearbyTag;
    } else if (km <= 15.0) {
      return context.l10n.moderateTag;
    } else {
      return context.l10n.extendedTag;
    }
  }

  static Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}

class ArrivalClaimDecision {
  final double? latitude;
  final double? longitude;
  final int? accuracyM;
  final int? distanceM;
  final bool outsideZone;
  final bool isMocked;
  final bool canAutoStart;
  final bool hasRealGps;

  const ArrivalClaimDecision({
    this.latitude,
    this.longitude,
    this.accuracyM,
    this.distanceM,
    required this.outsideZone,
    required this.isMocked,
    required this.canAutoStart,
    required this.hasRealGps,
  });
}

class ArrivalZoneUtils {
  ArrivalZoneUtils._();

  /// Calculates effective distance taking accuracy into account:
  /// distanceM - min(accuracyM, 100)
  static int effectiveDistance(int distanceM, int accuracyM) {
    final clampedAccuracy =
        accuracyM < 100 ? (accuracyM > 0 ? accuracyM : 0) : 100;
    final diff = distanceM - clampedAccuracy;
    return diff > 0 ? diff : 0;
  }

  /// Inside arrival zone if: distanceM - min(accuracyM, 100) <= 200
  static bool isInsideZone(int distanceM, int accuracyM) {
    final clampedAccuracy =
        accuracyM < 100 ? (accuracyM > 0 ? accuracyM : 0) : 100;
    return (distanceM - clampedAccuracy) <= 200;
  }

  /// Evaluates provider arrival claim using real GPS data.
  /// If no fresh real GPS is available, enforces outsideZone: true and forbids auto-start.
  /// Never falls back to customer coordinates or Colombo.
  static ArrivalClaimDecision evaluateArrivalClaim({
    Position? currentPosition,
    Position? cachedPosition,
    DateTime? cachedTimestamp,
    DateTime? now,
    double? customerLat,
    double? customerLng,
    bool forceOutsideZone = false,
    Duration maxFreshness = const Duration(seconds: 60),
  }) {
    final currentTime = now ?? DateTime.now();
    Position? resolvedPosition = currentPosition;
    if (resolvedPosition == null &&
        cachedPosition != null &&
        cachedTimestamp != null) {
      if (currentTime.difference(cachedTimestamp) <= maxFreshness) {
        resolvedPosition = cachedPosition;
      }
    }

    if (resolvedPosition == null) {
      return const ArrivalClaimDecision(
        latitude: null,
        longitude: null,
        accuracyM: null,
        distanceM: null,
        outsideZone: true,
        isMocked: false,
        canAutoStart: false,
        hasRealGps: false,
      );
    }

    final lat = resolvedPosition.latitude;
    final lng = resolvedPosition.longitude;
    final accuracy = resolvedPosition.accuracy.round();
    final isMocked = resolvedPosition.isMocked;

    int distanceM = 0;
    if (customerLat != null && customerLng != null) {
      distanceM = Geolocator.distanceBetween(
        lat,
        lng,
        customerLat,
        customerLng,
      ).round();
    }

    final insideZone = isInsideZone(distanceM, accuracy);
    final outside = forceOutsideZone || !insideZone;

    return ArrivalClaimDecision(
      latitude: lat,
      longitude: lng,
      accuracyM: accuracy,
      distanceM: distanceM,
      outsideZone: outside,
      isMocked: isMocked,
      canAutoStart: !outside && !isMocked,
      hasRealGps: true,
    );
  }
}
