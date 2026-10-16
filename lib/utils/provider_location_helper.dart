import '../models/technician.dart';

enum ProviderLocationSource {
  current,
  base,
  none,
}

// keep 2 decimals (~1.1 km) for public privacy
double roundToTwoDecimals(double value) {
  return (value * 100.0).roundToDouble() / 100.0;
}

class EffectiveProviderLocation {
  final double? latitude;
  final double? longitude;
  final ProviderLocationSource source;
  final String? areaName;
  final DateTime? timestamp;

  const EffectiveProviderLocation({
    this.latitude,
    this.longitude,
    required this.source,
    this.areaName,
    this.timestamp,
  });

  static const none =
      EffectiveProviderLocation(source: ProviderLocationSource.none);

  bool get hasLocation => latitude != null && longitude != null;
  bool get isCurrent => source == ProviderLocationSource.current;
  bool get isBase => source == ProviderLocationSource.base;
}

EffectiveProviderLocation getEffectiveProviderLocation(
  Technician technician, {
  DateTime? now,
}) {
  final currentTime = now ?? DateTime.now();

  // live gps fix if online and fresh (within 30 mins)
  if (technician.online &&
      technician.currentLat != null &&
      technician.currentLng != null &&
      technician.currentLocationAt != null) {
    final diff = currentTime.difference(technician.currentLocationAt!).abs();
    if (diff.inMinutes < 30) {
      return EffectiveProviderLocation(
        latitude: technician.currentLat,
        longitude: technician.currentLng,
        source: ProviderLocationSource.current,
        timestamp: technician.currentLocationAt,
      );
    }
  }

  // fallback to base workshop or home location
  final baseLat = technician.baseLat ?? technician.latitude;
  final baseLng = technician.baseLng ?? technician.longitude;
  if (baseLat != null && baseLng != null) {
    final area = technician.baseArea?.trim().isNotEmpty == true
        ? technician.baseArea!.trim()
        : (extractBaseArea(address: technician.baseAddress) ??
            (technician.serviceArea.trim().isNotEmpty
                ? technician.serviceArea.trim()
                : null));
    return EffectiveProviderLocation(
      latitude: baseLat,
      longitude: baseLng,
      source: ProviderLocationSource.base,
      areaName: area,
    );
  }

  return const EffectiveProviderLocation(
    source: ProviderLocationSource.none,
  );
}

String? extractBaseArea({String? city, String? address}) {
  if (city != null && city.trim().isNotEmpty) {
    final c = city.trim();
    return c.length > 25 ? c.substring(0, 25).trim() : c;
  }
  if (address != null && address.trim().isNotEmpty) {
    final parts = address
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isNotEmpty) {
      String candidate = parts.first;
      // skip house or plot number
      if (parts.length > 1 &&
          RegExp(r'^(no\.?|\d+[\w/-]*)', caseSensitive: false)
              .hasMatch(candidate)) {
        candidate = parts[1];
      }
      return candidate.length > 25
          ? candidate.substring(0, 25).trim()
          : candidate;
    }
  }
  return null;
}
