import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/admin_log.dart';

// service to record admin audit events
class AdminLogService {
  AdminLogService._();
  static final AdminLogService instance = AdminLogService._();

  final _col = FirebaseFirestore.instance.collection('adminLogs');

  // record single admin action
  Future<void> logAction({
    required String action,
    required String targetType,
    required String targetId,
    required String details,
    Map<String, dynamic>? metadata,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final adminUid = user?.uid ?? '';
    final adminEmail = user?.email ?? '';

    if (adminUid.isEmpty) return;

    try {
      final docRef = _col.doc();
      await docRef.set({
        'adminUid': adminUid,
        'adminEmail': adminEmail,
        'action': action,
        'targetType': targetType,
        'targetId': targetId,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        if (metadata != null) 'metadata': metadata,
      });
    } catch (e) {
      debugPrint('failed to write admin log: $e');
    }
  }

  // stream recent admin logs
  Stream<List<AdminLog>> streamRecentLogs({int limit = 100}) {
    return _col
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => AdminLog.fromMap(d.id, d.data())).toList());
  }
}
