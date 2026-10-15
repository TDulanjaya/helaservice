import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../constants/firestore_paths.dart';

class LiveLocationService {
  LiveLocationService._();
  static final LiveLocationService instance = LiveLocationService._();

  StreamSubscription<Position>? _positionSub;
  bool _isTracking = false;
  String? _trackingUserId;
  final _positionController = StreamController<Position>.broadcast();
  Position? _lastKnownPosition;

  bool get isTracking => _isTracking;
  Stream<Position> get positionStream => _positionController.stream;
  Position? get lastKnownPosition => _lastKnownPosition;

  Future<bool> startTracking(
    String userId, {
    List<String>? allowedViewers,
    String? notificationTitle,
    String? notificationText,
  }) async {
    if (_isTracking) return true;

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return false;
      }
      if (permission == LocationPermission.deniedForever) return false;

      _isTracking = true;
      _trackingUserId = userId;

      LocationSettings locationSettings;
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20,
          foregroundNotificationConfig: ForegroundNotificationConfig(
            notificationTitle: notificationTitle ?? 'HelaService',
            notificationText:
                notificationText ?? 'Sharing your location with the customer',
            enableWakeLock: true,
          ),
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20,
        );
      }

      _positionSub = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (pos) {
          _lastKnownPosition = pos;
          _positionController.add(pos);
          FirebaseFirestore.instance
              .collection(FirestorePaths.liveLocations)
              .doc(userId)
              .set({
            'latitude': pos.latitude,
            'longitude': pos.longitude,
            'heading': pos.heading,
            'speed': pos.speed,
            'updatedAt': FieldValue.serverTimestamp(),
            'userId': userId,
            if (allowedViewers != null && allowedViewers.isNotEmpty)
              'allowedViewers': allowedViewers,
          }, SetOptions(merge: true));
        },
        onError: (_) {},
      );
      return true;
    } catch (_) {
      _isTracking = false;
      return false;
    }
  }

  void stopTracking() {
    _positionSub?.cancel();
    _positionSub = null;
    _isTracking = false;

    if (_trackingUserId != null) {
      FirebaseFirestore.instance
          .collection(FirestorePaths.liveLocations)
          .doc(_trackingUserId!)
          .delete()
          .catchError((_) {});
      _trackingUserId = null;
    }
  }

  Stream<LatLng?> streamUserLocation(String userId) {
    return FirebaseFirestore.instance
        .collection(FirestorePaths.liveLocations)
        .doc(userId)
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      final data = snap.data()!;
      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return null;
      return LatLng(lat, lng);
    });
  }

  Stream<Map<String, dynamic>?> streamUserLocationData(String userId) {
    return FirebaseFirestore.instance
        .collection(FirestorePaths.liveLocations)
        .doc(userId)
        .snapshots()
        .map((snap) => snap.exists ? snap.data() : null);
  }
}
