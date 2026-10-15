import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_paths.dart';
import '../models/technician.dart';
import '../utils/provider_location_helper.dart';
import '../utils/provider_pricing_helper.dart';

class TechnicianRepository {
  final _col = FirebaseFirestore.instance.collection(FirestorePaths.technicians);

  Stream<List<Technician>> streamTechnicians() {
    return _col.snapshots().map((snap) {
      final items =
          snap.docs.map((d) => Technician.fromMap(d.id, d.data())).toList();
      items.sort((a, b) => (b.rating ?? 0.0).compareTo(a.rating ?? 0.0));
      return items;
    });
  }

  Stream<List<Technician>> streamApprovedTechnicians() {
    return _col.snapshots().map((snap) {
      final items = snap.docs
          .map((d) => Technician.fromMap(d.id, d.data()))
          .where((t) => t.isApproved)
          .toList();
      items.sort((a, b) => (b.rating ?? 0.0).compareTo(a.rating ?? 0.0));
      return items;
    });
  }

  Future<Technician?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return Technician.fromMap(doc.id, doc.data()!);
  }

  Stream<Technician?> streamById(String id) {
    if (id.isEmpty) return Stream.value(null);
    return _col.doc(id).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return Technician.fromMap(snap.id, snap.data()!);
    });
  }

  Future<void> updateOnlineStatus(String id, bool online) async {
    if (id.isEmpty) return;
    final Map<String, dynamic> updates = {'online': online};
    if (!online) {
      // clear current coords when offline
      updates['currentLat'] = FieldValue.delete();
      updates['currentLng'] = FieldValue.delete();
      updates['currentLocationAt'] = FieldValue.delete();
    }
    await _col.doc(id).update(updates).catchError((_) {});
  }

  Future<void> updateCurrentLocation(
    String id, {
    required double latitude,
    required double longitude,
  }) async {
    if (id.isEmpty) return;
    await _col.doc(id).update({
      'currentLat': roundToTwoDecimals(latitude),
      'currentLng': roundToTwoDecimals(longitude),
      'currentLocationAt': FieldValue.serverTimestamp(),
    }).catchError((_) {});
  }

  Future<void> updateBaseLocation(
    String id, {
    required double latitude,
    required double longitude,
    String? address,
    String? baseArea,
  }) async {
    if (id.isEmpty) return;
    await _col.doc(id).update({
      'baseLat': roundToTwoDecimals(latitude),
      'baseLng': roundToTwoDecimals(longitude),
      'latitude': roundToTwoDecimals(latitude),
      'longitude': roundToTwoDecimals(longitude),
      if (address != null && address.trim().isNotEmpty)
        'baseAddress': address.trim(),
      if (baseArea != null && baseArea.trim().isNotEmpty)
        'baseArea': baseArea.trim(),
    }).catchError((_) {});
  }

  Future<void> updateEmergencyStatus(String id, bool emergencyAvailable) async {
    if (id.isEmpty) return;
    await _col.doc(id).update({'emergencyAvailable': emergencyAvailable}).catchError((_) {});
  }

  // update provider working hours schedule
  Future<void> updateWorkingHours(
      String id, Map<String, WorkingDaySchedule> hours) async {
    if (id.isEmpty) return;
    final data = hours.map((k, v) => MapEntry(k, v.toMap()));
    await _col.doc(id).update({'workingHours': data}).catchError((_) {});
  }

  // update provider service radius in kilometers
  Future<void> updateServiceRadius(String id, double radiusKm) async {
    if (id.isEmpty) return;
    await _col.doc(id).update({'serviceRadiusKm': radiusKm}).catchError((_) {});
  }

  Future<void> toggleBanStatus(String id, bool isBanned, {String? reason}) async {
    if (id.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    final techDoc = _col.doc(id);
    batch.update(techDoc, {
      'isBanned': isBanned,
      'banned': isBanned,
      if (reason != null) 'banReason': reason,
      if (isBanned) 'online': false,
      'statusUpdatedAt': FieldValue.serverTimestamp(),
    });

    final userDoc = FirebaseFirestore.instance.collection(FirestorePaths.users).doc(id);
    batch.set(userDoc, {
      'banned': isBanned,
      'status': isBanned ? 'suspended' : 'active',
      if (reason != null) 'banReason': reason,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  // update provider rate card
  Future<void> updateRates(
    String id, {
    List<String>? pricingModes,
    int? dailyRateLkr,
    int? hourlyRateLkr,
    int? perKmRateLkr,
    int? visitFeeLkr,
    int? emergencyRateLkr,
  }) async {
    if (id.isEmpty) return;
    final techUpdates = <String, dynamic>{};
    final userUpdates = <String, dynamic>{};

    if (pricingModes != null) {
      techUpdates['pricingModes'] = pricingModes;
      userUpdates['pricingModes'] = pricingModes;

      if (pricingModes.contains(ProviderPricingHelper.modeHour) && hourlyRateLkr != null && hourlyRateLkr > 0) {
        techUpdates['hourlyRateLkr'] = hourlyRateLkr;
        userUpdates['hourlyRateLkr'] = hourlyRateLkr;
      } else {
        techUpdates['hourlyRateLkr'] = FieldValue.delete();
        userUpdates['hourlyRateLkr'] = FieldValue.delete();
      }

      if (pricingModes.contains(ProviderPricingHelper.modeDay) && dailyRateLkr != null && dailyRateLkr > 0) {
        techUpdates['dailyRateLkr'] = dailyRateLkr;
        userUpdates['dailyRateLkr'] = dailyRateLkr;
      } else {
        techUpdates['dailyRateLkr'] = FieldValue.delete();
        userUpdates['dailyRateLkr'] = FieldValue.delete();
      }

      if (pricingModes.contains(ProviderPricingHelper.modeTravel) && perKmRateLkr != null && perKmRateLkr > 0) {
        techUpdates['perKmRateLkr'] = perKmRateLkr;
        userUpdates['perKmRateLkr'] = perKmRateLkr;
      } else {
        techUpdates['perKmRateLkr'] = FieldValue.delete();
        userUpdates['perKmRateLkr'] = FieldValue.delete();
      }

      if (pricingModes.contains(ProviderPricingHelper.modeVisit) && visitFeeLkr != null && visitFeeLkr > 0) {
        techUpdates['visitFeeLkr'] = visitFeeLkr;
        userUpdates['visitFeeLkr'] = visitFeeLkr;
      } else {
        techUpdates['visitFeeLkr'] = FieldValue.delete();
        userUpdates['visitFeeLkr'] = FieldValue.delete();
      }
    } else {
      if (dailyRateLkr != null) {
        if (dailyRateLkr > 0) {
          techUpdates['dailyRateLkr'] = dailyRateLkr;
          userUpdates['dailyRateLkr'] = dailyRateLkr;
        } else {
          techUpdates['dailyRateLkr'] = FieldValue.delete();
          userUpdates['dailyRateLkr'] = FieldValue.delete();
        }
      }
      if (hourlyRateLkr != null) {
        if (hourlyRateLkr > 0) {
          techUpdates['hourlyRateLkr'] = hourlyRateLkr;
          userUpdates['hourlyRateLkr'] = hourlyRateLkr;
        } else {
          techUpdates['hourlyRateLkr'] = FieldValue.delete();
          userUpdates['hourlyRateLkr'] = FieldValue.delete();
        }
      }
      if (perKmRateLkr != null) {
        if (perKmRateLkr > 0) {
          techUpdates['perKmRateLkr'] = perKmRateLkr;
          userUpdates['perKmRateLkr'] = perKmRateLkr;
        } else {
          techUpdates['perKmRateLkr'] = FieldValue.delete();
          userUpdates['perKmRateLkr'] = FieldValue.delete();
        }
      }
      if (visitFeeLkr != null) {
        if (visitFeeLkr > 0) {
          techUpdates['visitFeeLkr'] = visitFeeLkr;
          userUpdates['visitFeeLkr'] = visitFeeLkr;
        } else {
          techUpdates['visitFeeLkr'] = FieldValue.delete();
          userUpdates['visitFeeLkr'] = FieldValue.delete();
        }
      }
    }

    if (emergencyRateLkr != null) {
      techUpdates['emergencyRateLkr'] = emergencyRateLkr;
    }

    if (techUpdates.isNotEmpty) {
      final batch = FirebaseFirestore.instance.batch();
      batch.update(_col.doc(id), techUpdates);
      if (userUpdates.isNotEmpty) {
        batch.update(
          FirebaseFirestore.instance.collection(FirestorePaths.users).doc(id),
          userUpdates,
        );
      }
      await batch.commit();
    }
  }

  Future<void> deleteTechnician(String id) async {
    if (id.isEmpty) return;
    await _col.doc(id).delete();
  }
}

