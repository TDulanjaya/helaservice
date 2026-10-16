import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../constants/firestore_paths.dart';
import '../constants/job_status.dart';

class LiveLocationService {
  LiveLocationService._();
  static final LiveLocationService instance = LiveLocationService._();

  StreamSubscription<Position>? _positionSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _bookingStatusSub;
  bool _isTracking = false;
  String? _trackingUserId;
  String? _activeBookingId;
  final _positionController = StreamController<Position>.broadcast();
  Position? _lastKnownPosition;

  bool get isTracking => _isTracking;
  String? get activeBookingId => _activeBookingId;
  Stream<Position> get positionStream => _positionController.stream;
  Position? get lastKnownPosition => _lastKnownPosition;

  // start tracking tied to active booking lifecycle
  Future<bool> startTrackingForBooking({
    required String bookingId,
    required String userId,
    List<String>? allowedViewers,
    String? notificationTitle,
    String? notificationText,
  }) async {
    if (bookingId.isEmpty || userId.isEmpty) return false;

    // re-attach if already tracking same booking
    if (_isTracking && _activeBookingId == bookingId) {
      return true;
    }

    if (_isTracking) {
      stopTracking();
    }

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
      _activeBookingId = bookingId;

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
            'bookingId': bookingId,
            if (allowedViewers != null && allowedViewers.isNotEmpty)
              'allowedViewers': allowedViewers,
          }, SetOptions(merge: true));
        },
        onError: (_) {},
      );

      // listen to booking status; auto-stop when no longer en route
      _bookingStatusSub?.cancel();
      _bookingStatusSub = FirebaseFirestore.instance
          .collection(FirestorePaths.bookings)
          .doc(bookingId)
          .snapshots()
          .listen((snap) {
        if (!snap.exists || snap.data() == null) {
          stopTracking(forBookingId: bookingId);
          return;
        }
        final status = snap.data()?['status'] as String?;
        if (status != JobStatus.enRoute && status != JobStatus.confirmed) {
          stopTracking(forBookingId: bookingId);
        }
      }, onError: (_) {});

      return true;
    } catch (_) {
      _isTracking = false;
      _activeBookingId = null;
      _trackingUserId = null;
      return false;
    }
  }

  // legacy wrapper
  Future<bool> startTracking(
    String userId, {
    List<String>? allowedViewers,
    String? notificationTitle,
    String? notificationText,
    String? bookingId,
  }) {
    return startTrackingForBooking(
      bookingId: bookingId ?? 'legacy',
      userId: userId,
      allowedViewers: allowedViewers,
      notificationTitle: notificationTitle,
      notificationText: notificationText,
    );
  }

  // idempotent stop tracking
  Future<void> stopTracking({String? forBookingId}) async {
    if (forBookingId != null &&
        _activeBookingId != null &&
        _activeBookingId != forBookingId) {
      return;
    }

    _bookingStatusSub?.cancel();
    _bookingStatusSub = null;

    _positionSub?.cancel();
    _positionSub = null;
    _isTracking = false;

    if (_trackingUserId != null) {
      try {
        await FirebaseFirestore.instance
            .collection(FirestorePaths.liveLocations)
            .doc(_trackingUserId!)
            .delete();
      } catch (_) {}
      _trackingUserId = null;
    }
    _activeBookingId = null;
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
