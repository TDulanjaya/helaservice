import 'dart:math';
import '../models/job_location.dart';
import '../models/saved_address.dart';

// place suggestion from search
class PlaceSuggestion {
  final String name;
  final String shortArea;
  final double latitude;
  final double longitude;

  const PlaceSuggestion({
    required this.name,
    required this.shortArea,
    required this.latitude,
    required this.longitude,
  });

  String get fullDisplay =>
      shortArea.isNotEmpty ? '$name, $shortArea' : name;
}

// helper methods for location search
class LocationSearchHelper {
  // sri lanka map boundaries
  static const double minLat = 5.8;
  static const double maxLat = 10.0;
  static const double minLon = 79.5;
  static const double maxLon = 82.0;

  // check if coordinate is in sri lanka
  static bool isWithinSriLanka({
    required double lat,
    required double lon,
    String? countryCode,
    String? country,
  }) {
    if (countryCode != null && countryCode.toUpperCase() == 'LK') {
      return true;
    }
    if (country != null && country.toLowerCase().contains('sri lanka')) {
      return true;
    }
    return lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon;
  }

  // parse photon search result
  static PlaceSuggestion? parsePhotonFeature(Map<String, dynamic> feature) {
    final geometry = feature['geometry'] as Map<String, dynamic>?;
    final coordinates = geometry?['coordinates'] as List<dynamic>?;
    if (coordinates == null || coordinates.length < 2) return null;

    final lon = (coordinates[0] as num).toDouble();
    final lat = (coordinates[1] as num).toDouble();

    final properties = (feature['properties'] as Map<String, dynamic>?) ?? {};
    final countryCode = properties['countrycode']?.toString();
    final country = properties['country']?.toString();

    // check country boundaries
    if (!isWithinSriLanka(
      lat: lat,
      lon: lon,
      countryCode: countryCode,
      country: country,
    )) {
      return null;
    }

    final rawName = properties['name']?.toString().trim() ?? '';
    final street = properties['street']?.toString().trim() ?? '';
    final city = (properties['city'] ??
            properties['town'] ??
            properties['district'] ??
            properties['locality'])
        ?.toString()
        .trim() ??
        '';
    final state = properties['state']?.toString().trim() ?? '';

    final name = rawName.isNotEmpty
        ? rawName
        : (street.isNotEmpty ? street : (city.isNotEmpty ? city : 'Place'));

    final areaParts = <String>[];
    if (street.isNotEmpty && street != name) areaParts.add(street);
    if (city.isNotEmpty && city != name && !areaParts.contains(city)) {
      areaParts.add(city);
    }
    if (state.isNotEmpty && state != name && !areaParts.contains(state)) {
      areaParts.add(state);
    }

    return PlaceSuggestion(
      name: name,
      shortArea: areaParts.join(', '),
      latitude: lat,
      longitude: lon,
    );
  }

  // parse nominatim search result
  static PlaceSuggestion? parseNominatimItem(Map<String, dynamic> item) {
    final lat = double.tryParse(item['lat']?.toString() ?? '');
    final lon = double.tryParse(item['lon']?.toString() ?? '');
    if (lat == null || lon == null) return null;

    final rawDisplay = item['display_name']?.toString() ?? '';
    final address = item['address'] as Map<String, dynamic>?;

    final countryCode = address?['country_code']?.toString();
    final country = address?['country']?.toString();

    if (!isWithinSriLanka(
      lat: lat,
      lon: lon,
      countryCode: countryCode,
      country: country,
    )) {
      return null;
    }

    final parts = rawDisplay
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final name = parts.isNotEmpty ? parts.first : 'Place';
    final areaParts = parts.skip(1).take(2).toList();

    return PlaceSuggestion(
      name: name,
      shortArea: areaParts.join(', '),
      latitude: lat,
      longitude: lon,
    );
  }

  // get distance between two points in meters
  static double distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * (pi / 180.0);
    final dLon = (lon2 - lon1) * (pi / 180.0);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) *
            cos(lat2 * (pi / 180.0)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  // remove duplicate recent places
  static List<JobLocation> deduplicateRecentPlaces({
    required List<SavedAddress> savedAddresses,
    required List<JobLocation> recentPlaces,
    int max = 3,
  }) {
    final List<JobLocation> results = [];

    for (final recent in recentPlaces) {
      if (results.length >= max) break;

      // skip if matches saved address
      bool matchesSaved = false;
      for (final saved in savedAddresses) {
        final dist = distanceMeters(
          recent.latitude,
          recent.longitude,
          saved.latitude,
          saved.longitude,
        );
        if (dist < 50.0) {
          matchesSaved = true;
          break;
        }
        if (recent.address.trim().toLowerCase() ==
            saved.address.trim().toLowerCase()) {
          matchesSaved = true;
          break;
        }
      }
      if (matchesSaved) continue;

      // skip if already added
      bool matchesExisting = false;
      for (final existing in results) {
        final dist = distanceMeters(
          recent.latitude,
          recent.longitude,
          existing.latitude,
          existing.longitude,
        );
        if (dist < 50.0) {
          matchesExisting = true;
          break;
        }
        if (recent.address.trim().toLowerCase() ==
            existing.address.trim().toLowerCase()) {
          matchesExisting = true;
          break;
        }
      }
      if (matchesExisting) continue;

      results.add(recent);
    }

    return results;
  }

  // check if confirm button can be enabled
  static bool canConfirmLocation({
    required bool userChoseLocation,
    required double? latitude,
    required double? longitude,
    required bool isGeocodingLoading,
  }) {
    if (!userChoseLocation) return false;
    if (latitude == null || longitude == null) return false;
    if (isGeocodingLoading) return false;
    return true;
  }

  // check if gps should move the pin
  static bool shouldApplyGpsLocation({
    required bool isAutoGps,
    required bool userActed,
  }) {
    // manual tap always updates pin
    if (!isAutoGps) return true;
    // ignore auto gps if user already moved map
    if (userActed) return false;
    return true;
  }

  // check if extra details should clear after move
  static bool shouldClearChipDetails({
    required bool detailsFromChip,
    required double chipLat,
    required double chipLon,
    required double newLat,
    required double newLon,
  }) {
    // keep details if user typed them
    if (!detailsFromChip) return false;
    final dist = distanceMeters(chipLat, chipLon, newLat, newLon);
    return dist > 50.0;
  }

  // keep choice flag when gps fails
  static bool resolveUserChoseLocationOnGpsFailure({
    required bool previousValue,
  }) {
    return previousValue;
  }
}

