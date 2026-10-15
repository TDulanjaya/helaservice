import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_paths.dart';
import '../models/user_profile.dart';
import '../models/admin_user.dart';
import '../state/role_provider.dart';

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
      var profile = UserProfile.fromMap(doc.data()!, documentId: doc.id);
      try {
        final locDoc = await _db
            .collection(FirestorePaths.users)
            .doc(uid)
            .collection('private')
            .doc('location')
            .get();
        if (locDoc.exists && locDoc.data() != null) {
          final lData = locDoc.data()!;
          final lat = (lData['latitude'] as num?)?.toDouble();
          final lng = (lData['longitude'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            profile = profile.copyWith(latitude: lat, longitude: lng);
          }
        }
      } catch (_) {}
      return profile;
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
        .asyncMap((doc) async {
      if (!doc.exists || doc.data() == null) return null;
      var profile = UserProfile.fromMap(doc.data()!, documentId: doc.id);
      try {
        final locDoc = await _db
            .collection(FirestorePaths.users)
            .doc(uid)
            .collection('private')
            .doc('location')
            .get();
        if (locDoc.exists && locDoc.data() != null) {
          final lData = locDoc.data()!;
          final lat = (lData['latitude'] as num?)?.toDouble();
          final lng = (lData['longitude'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            profile = profile.copyWith(latitude: lat, longitude: lng);
          }
        }
      } catch (_) {}
      return profile;
    });
  }

  // stream all users for admin
  Stream<List<UserProfile>> streamAllUsers() => streamAllUnifiedUsers();

  Stream<List<UserProfile>> streamAllUnifiedUsers() {
    late StreamController<List<UserProfile>> controller;
    StreamSubscription? subUsers;
    StreamSubscription? subTechs;
    StreamSubscription? subAdmins;
    StreamSubscription? subSuper;

    List<QueryDocumentSnapshot<Map<String, dynamic>>> userDocs = [];
    List<QueryDocumentSnapshot<Map<String, dynamic>>> techDocs = [];
    List<QueryDocumentSnapshot<Map<String, dynamic>>> adminDocs = [];
    Set<String> superAdminUids = {};

    void emit() {
      if (controller.isClosed) return;
      final userMap = <String, UserProfile>{};

      // load customers
      for (final doc in userDocs) {
        try {
          final data = doc.data();
          final p = UserProfile.fromMap(data, documentId: doc.id);
          userMap[doc.id] = p;
        } catch (_) {}
      }

      // load technicians
      for (final doc in techDocs) {
        try {
          final data = doc.data();
          final id = doc.id;
          final isBanned =
              (data['isBanned'] == true) || (data['banned'] == true);
          final banReason = data['banReason']?.toString();
          final name = data['name']?.toString() ?? '';
          final phone = data['phone']?.toString();
          final district = data['district']?.toString() ??
              data['serviceArea']?.toString();
          final serviceCategory = data['title']?.toString() ??
              data['serviceCategory']?.toString();
          final lat = (data['baseLat'] as num?)?.toDouble() ??
              (data['currentLat'] as num?)?.toDouble() ??
              (data['latitude'] as num?)?.toDouble();
          final lng = (data['baseLng'] as num?)?.toDouble() ??
              (data['currentLng'] as num?)?.toDouble() ??
              (data['longitude'] as num?)?.toDouble();

          if (userMap.containsKey(id)) {
            final existing = userMap[id]!;
            userMap[id] = existing.copyWith(
              role: AppRole.provider,
              isBanned: isBanned || existing.isBanned,
              banReason: banReason ?? existing.banReason,
              displayName: existing.displayName.isNotEmpty
                  ? existing.displayName
                  : name,
              phone: existing.phone?.isNotEmpty == true
                  ? existing.phone
                  : phone,
              district: existing.district?.isNotEmpty == true
                  ? existing.district
                  : district,
              serviceCategory: existing.serviceCategory?.isNotEmpty == true
                  ? existing.serviceCategory
                  : serviceCategory,
              latitude: existing.latitude ?? lat,
              longitude: existing.longitude ?? lng,
            );
          } else {
            userMap[id] = UserProfile(
              id: id,
              email: data['email']?.toString() ?? '',
              displayName: name.isNotEmpty ? name : 'Service Provider',
              role: AppRole.provider,
              phone: phone,
              district: district,
              serviceCategory: serviceCategory,
              latitude: lat,
              longitude: lng,
              isBanned: isBanned,
              banReason: banReason,
              isProfileComplete: true,
            );
          }
        } catch (_) {}
      }

      // load admins
      for (final doc in adminDocs) {
        try {
          final data = doc.data();
          final id = doc.id;
          final adminRole = AdminRole.fromKey(data['role']?.toString());
          final statusStr = data['status']?.toString();
          final isBanned = statusStr == 'suspended';
          final name = data['displayName']?.toString() ?? '';
          final email = data['email']?.toString() ?? '';
          final phone = data['phone']?.toString();

          if (userMap.containsKey(id)) {
            final existing = userMap[id]!;
            userMap[id] = existing.copyWith(
              role: AppRole.admin,
              adminRole: adminRole,
              isBanned: isBanned || existing.isBanned,
              displayName: existing.displayName.isNotEmpty
                  ? existing.displayName
                  : name,
              email: existing.email.isNotEmpty ? existing.email : email,
              phone: existing.phone?.isNotEmpty == true
                  ? existing.phone
                  : phone,
            );
          } else {
            userMap[id] = UserProfile(
              id: id,
              email: email,
              displayName: name.isNotEmpty ? name : 'Administrator',
              role: AppRole.admin,
              adminRole: adminRole,
              phone: phone,
              isBanned: isBanned,
              isProfileComplete: true,
            );
          }
        } catch (_) {}
      }

      // load super admins
      for (final uid in superAdminUids) {
        if (userMap.containsKey(uid)) {
          final existing = userMap[uid]!;
          userMap[uid] = existing.copyWith(
            role: AppRole.admin,
            adminRole: AdminRole.superAdmin,
          );
        } else {
          userMap[uid] = UserProfile(
            id: uid,
            email: '',
            displayName: 'Super Admin',
            role: AppRole.admin,
            adminRole: AdminRole.superAdmin,
            isProfileComplete: true,
          );
        }
      }

      // default role to customer
      final result = userMap.values.map((u) {
        if (u.role == null) {
          return u.copyWith(role: AppRole.customer);
        }
        return u;
      }).toList();

      controller.add(result);
    }

    controller = StreamController<List<UserProfile>>(
      onListen: () {
        subUsers =
            _db.collection(FirestorePaths.users).snapshots().listen((snap) {
          userDocs = snap.docs;
          emit();
        });
        subTechs = _db
            .collection(FirestorePaths.technicians)
            .snapshots()
            .listen((snap) {
          techDocs = snap.docs;
          emit();
        });
        subAdmins =
            _db.collection(FirestorePaths.admins).snapshots().listen((snap) {
          adminDocs = snap.docs;
          emit();
        });
        subSuper = _db.collection('superAdmins').snapshots().listen((snap) {
          superAdminUids = snap.docs.map((d) => d.id).toSet();
          emit();
        });
      },
      onCancel: () {
        subUsers?.cancel();
        subTechs?.cancel();
        subAdmins?.cancel();
        subSuper?.cancel();
      },
    );

    return controller.stream;
  }

  // check if user is super admin
  Future<bool> isSuperAdminUser(String userId) async {
    if (userId.isEmpty) return false;
    try {
      // check super admins
      final superDoc = await _db.collection('superAdmins').doc(userId).get();
      if (superDoc.exists) return true;

      // check admins
      final adminDoc =
          await _db.collection(FirestorePaths.admins).doc(userId).get();
      if (adminDoc.exists) {
        final data = adminDoc.data();
        final roleStr = data?['role']?.toString().toLowerCase();
        if (roleStr == 'super_admin' || roleStr == 'superadmin') {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  // update ban status
  Future<void> toggleUserBanStatus({
    required String userId,
    required bool isBanned,
    String? reason,
  }) async {
    if (userId.isEmpty) return;

    // prevent banning super admins
    if (isBanned) {
      final isSuper = await isSuperAdminUser(userId);
      if (isSuper) {
        throw Exception('Super Admin accounts cannot be suspended.');
      }
    }

    final batch = _db.batch();

    // update users collection
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

    // update technicians collection
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

    // update admins collection
    final adminRef = _db.collection(FirestorePaths.admins).doc(userId);
    final adminSnap = await adminRef.get();
    if (adminSnap.exists) {
      batch.update(adminRef, {
        'status': isBanned ? 'suspended' : 'active',
        'statusUpdatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}
