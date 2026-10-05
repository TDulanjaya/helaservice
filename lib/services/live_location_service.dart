import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../constants/firestore_paths.dart';

// live location service
class LiveLocationService {
  LiveLocationService._();
  static final LiveLocationService instance = LiveLocationService._();

  StreamSubscription<Position>? _positionSub;
  bool _isTracking = false;
  String? _trackingUserId;

  bool get isTracking => _isTracking;

  // start tracking
  Future<void> startTracking(String userId, {List<String>? allowedViewers}) async {
    if (_isTracking) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _isTracking = true;
    _trackingUserId = userId;

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      ),
    ).listen(
      (pos) {
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
  }

  // stop tracking
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

  // stream tech location
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

  // stream location data
  Stream<Map<String, dynamic>?> streamUserLocationData(String userId) {
    return FirebaseFirestore.instance
        .collection(FirestorePaths.liveLocations)
        .doc(userId)
        .snapshots()
        .map((snap) => snap.exists ? snap.data() : null);
  }
}
