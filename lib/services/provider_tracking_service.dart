import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../repositories/technician_repository.dart';
import '../utils/location_utils.dart';

// periodic background location updates for online providers
class ProviderTrackingService {
  ProviderTrackingService._();
  static final ProviderTrackingService instance = ProviderTrackingService._();

  final TechnicianRepository _techRepo = TechnicianRepository();
  StreamSubscription<Position>? _positionSub;
  Timer? _intervalTimer;
  String? _activeProviderId;
  Position? _lastRecordedPosition;

  bool get isTracking => _activeProviderId != null;

  Future<void> startOnlineTracking(String providerId) async {
    if (providerId.isEmpty) return;
    if (_activeProviderId == providerId && _positionSub != null) return;

    stopOnlineTracking();
    _activeProviderId = providerId;

    await _recordLocation(providerId);

    _intervalTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _recordLocation(providerId);
    });

    // push update if provider moved at least 500m
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }

      LocationSettings locationSettings;
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 500,
          intervalDuration: const Duration(minutes: 10),
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 500,
        );
      }

      _positionSub = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (pos) {
          final last = _lastRecordedPosition;
          if (last == null) {
            _updatePosition(providerId, pos);
            return;
          }
          final dist = LocationUtils.calculateDistanceKm(
            last.latitude,
            last.longitude,
            pos.latitude,
            pos.longitude,
          );
          if (dist >= 0.5) {
            _updatePosition(providerId, pos);
          }
        },
        onError: (_) {},
      );
    } catch (_) {}
  }

  void stopOnlineTracking() {
    _intervalTimer?.cancel();
    _intervalTimer = null;
    _positionSub?.cancel();
    _positionSub = null;
    _activeProviderId = null;
    _lastRecordedPosition = null;
  }

  Future<void> _recordLocation(String providerId) async {
    try {
      final pos = await LocationUtils.getCurrentPosition();
      if (pos != null) {
        await _updatePosition(providerId, pos);
      }
    } catch (_) {}
  }

  Future<void> _updatePosition(String providerId, Position pos) async {
    _lastRecordedPosition = pos;
    await _techRepo.updateCurrentLocation(
      providerId,
      latitude: pos.latitude,
      longitude: pos.longitude,
    );
  }
}
