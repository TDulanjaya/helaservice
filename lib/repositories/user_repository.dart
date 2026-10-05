import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_paths.dart';
import '../models/user_profile.dart';

class UserRepository {
  static final UserRepository _instance = UserRepository._internal();
  factory UserRepository() => _instance;
  UserRepository._internal();

  final _db = FirebaseFirestore.instance;

  // get user profile
  Future<UserProfile?> getUserById(String uid) async {
    if (uid.isEmpty) return null;
    try {
      final doc = await _db.collection(FirestorePaths.users).doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserProfile.fromMap(doc.data()!);
    } catch (_) {
      return null;
    }
  }

  // stream user profile
  Stream<UserProfile?> streamUserById(String uid) {
    if (uid.isEmpty) return Stream.value(null);
    return _db
        .collection(FirestorePaths.users)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists && doc.data() != null
            ? UserProfile.fromMap(doc.data()!, documentId: doc.id)
            : null);
  }

  // stream all users for management
  Stream<List<UserProfile>> streamAllUsers() {
    return _db.collection(FirestorePaths.users).snapshots().map((snapshot) {
      final list = <UserProfile>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          list.add(UserProfile.fromMap(data, documentId: doc.id));
        } catch (_) {}
      }
      return list;
    });
  }

  // check if a user is a super admin
  Future<bool> isSuperAdminUser(String userId) async {
    if (userId.isEmpty) return false;
    try {
      // 1. check superAdmins collection
      final superDoc = await _db.collection('superAdmins').doc(userId).get();
      if (superDoc.exists) return true;

      // 2. check admins collection
      final adminDoc =
          await _db.collection(FirestorePaths.admins).doc(userId).get();
      if (adminDoc.exists) {
        final data = adminDoc.data();
        final roleStr = data?['role']?.toString().toLowerCase();
        if (roleStr == 'super_admin' || roleStr == 'superadmin') {
          return true;
        }
      }

      // 3. check users collection
      final userDoc =
          await _db.collection(FirestorePaths.users).doc(userId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        final adminRoleStr = data?['adminRole']?.toString().toLowerCase();
        final roleStr = data?['role']?.toString().toLowerCase();
        if (adminRoleStr == 'super_admin' ||
            adminRoleStr == 'superadmin' ||
            roleStr == 'super_admin' ||
            roleStr == 'superadmin' ||
            data?['isSuperAdmin'] == true) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  // ban or unban user (customer or technician)
  Future<void> toggleUserBanStatus({
    required String userId,
    required bool isBanned,
    String? reason,
  }) async {
    if (userId.isEmpty) return;

    // safeguard: super admins can never be banned
    if (isBanned) {
      final isSuper = await isSuperAdminUser(userId);
      if (isSuper) {
        throw Exception('Super Admin accounts cannot be suspended.');
      }
    }

    final batch = _db.batch();

    // 1. update users collection (applies to both customer & provider)
    final userRef = _db.collection(FirestorePaths.users).doc(userId);
    batch.set(
      userRef,
      {
        'isBanned': isBanned,
        'banned': isBanned,
        'status': isBanned ? 'suspended' : 'active',
        if (reason != null && reason.isNotEmpty) 'banReason': reason,
        'banUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // 2. update technicians collection if technician document exists
    final techRef = _db.collection(FirestorePaths.technicians).doc(userId);
    final techSnap = await techRef.get();
    if (techSnap.exists) {
      batch.update(techRef, {
        'isBanned': isBanned,
        'banned': isBanned,
        if (isBanned) 'online': false,
        if (reason != null && reason.isNotEmpty) 'banReason': reason,
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}
