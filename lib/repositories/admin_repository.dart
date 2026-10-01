import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../constants/firestore_paths.dart';
import '../models/admin_user.dart';

class AdminRepository {
  static final AdminRepository _instance = AdminRepository._internal();
  factory AdminRepository() => _instance;
  AdminRepository._internal();

  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection(FirestorePaths.admins);

  Stream<List<AdminUser>> getAdminsStream() {
    return _col.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return AdminUser.fromMap(doc.data(), id: doc.id);
      }).toList();

      list.sort((a, b) {
        if (a.isSuperAdmin && !b.isSuperAdmin) return -1;
        if (!a.isSuperAdmin && b.isSuperAdmin) return 1;
        final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return bTime.compareTo(aTime);
      });

      return list;
    });
  }

  Future<void> updateAdminRoleAndPermissions(
    String adminId,
    AdminRole role,
    List<AdminPermission> permissions,
  ) async {
    await _col.doc(adminId).update({
      'role': role.key,
      'permissions': permissions.map((p) => p.key).toList(),
    });
  }

  Future<void> toggleAdminStatus(String adminId, bool isActive) async {
    await _col.doc(adminId).update({
      'status': isActive ? 'active' : 'suspended',
    });
  }

  Future<void> deleteAdmin(String adminId) async {
    await _col.doc(adminId).delete();
  }

  Future<AdminUser?> getAdminByEmailOrUid(String identifier) async {
    final cleanId = identifier.trim();
    if (cleanId.isEmpty) return null;

    try {
      final directDoc = await _col.doc(cleanId).get();
      if (directDoc.exists && directDoc.data() != null) {
        return AdminUser.fromMap(directDoc.data()!, id: directDoc.id);
      }

      final emailQuery = await _col
          .where('email', isEqualTo: cleanId.toLowerCase())
          .limit(1)
          .get();

      if (emailQuery.docs.isNotEmpty) {
        final doc = emailQuery.docs.first;
        return AdminUser.fromMap(doc.data(), id: doc.id);
      }
    } catch (_) {}

    return null;
  }

  Future<AdminUser?> getAdminById(String adminId) async {
    try {
      final doc = await _col.doc(adminId).get();
      if (doc.exists && doc.data() != null) {
        return AdminUser.fromMap(doc.data()!, id: doc.id);
      }
    } catch (_) {}
    return null;
  }

  Future<void> touchLastActive(String adminId) async {
    try {
      await _col.doc(adminId).update({
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> updateOwnAdminProfile({String? displayName, String? phone}) async {
    final uid = fb.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName;
    if (phone != null) updates['phone'] = phone;
    if (updates.isNotEmpty) {
      await _col.doc(uid).update(updates);
      if (displayName != null) {
        await fb.FirebaseAuth.instance.currentUser?.updateDisplayName(displayName);
      }
    }
  }
}

