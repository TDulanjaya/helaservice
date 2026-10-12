import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_paths.dart';
import '../models/technician.dart';

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
    await _col.doc(id).update({'online': online}).catchError((_) {});
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
    int? dailyRateLkr,
    int? hourlyRateLkr,
    int? perKmRateLkr,
    int? visitFeeLkr,
    int? emergencyRateLkr,
  }) async {
    if (id.isEmpty) return;
    final updates = <String, dynamic>{
      if (dailyRateLkr != null) 'dailyRateLkr': dailyRateLkr,
      if (hourlyRateLkr != null) 'hourlyRateLkr': hourlyRateLkr,
      if (perKmRateLkr != null) 'perKmRateLkr': perKmRateLkr,
      if (visitFeeLkr != null) 'visitFeeLkr': visitFeeLkr,
      if (emergencyRateLkr != null) 'emergencyRateLkr': emergencyRateLkr,
    };
    if (updates.isNotEmpty) {
      await _col.doc(id).update(updates);
    }
  }

  Future<void> deleteTechnician(String id) async {
    if (id.isEmpty) return;
    await _col.doc(id).delete();
  }
}

