import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/firestore_paths.dart';
import '../models/blocked_user.dart';

class BlockRepository {
  static final BlockRepository _instance = BlockRepository._internal();
  factory BlockRepository() => _instance;
  BlockRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _blockedCol(String uid) {
    return _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection('private')
        .doc('blocked')
        .collection('list');
  }

  // block a user
  Future<void> blockUser({
    required String blockedUid,
    required String name,
    String reason = '',
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid.isEmpty || blockedUid.isEmpty) return;

    final blocked = BlockedUser(
      id: blockedUid,
      blockedUid: blockedUid,
      name: name,
      reason: reason,
      createdAt: DateTime.now(),
    );

    // save under private blocked list
    await _blockedCol(currentUid).doc(blockedUid).set(blocked.toMap());

    // also save in legacy blocked subcollection for backwards compatibility
    await _firestore
        .collection(FirestorePaths.users)
        .doc(currentUid)
        .collection('blocked')
        .doc(blockedUid)
        .set(blocked.toMap());
  }

  // unblock a user
  Future<void> unblockUser(String blockedUid) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid.isEmpty || blockedUid.isEmpty) return;

    await _blockedCol(currentUid).doc(blockedUid).delete();
    await _firestore
        .collection(FirestorePaths.users)
        .doc(currentUid)
        .collection('blocked')
        .doc(blockedUid)
        .delete();
  }

  // stream list of blocked users
  Stream<List<BlockedUser>> streamBlockedUsers() {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid.isEmpty) {
      return Stream.value(const []);
    }

    return _blockedCol(currentUid).snapshots().map((snap) {
      return snap.docs
          .map((doc) => BlockedUser.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  // check if specific user is blocked
  Future<bool> isUserBlocked(String otherUid) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid.isEmpty || otherUid.isEmpty) {
      return false;
    }

    final doc = await _blockedCol(currentUid).doc(otherUid).get();
    return doc.exists;
  }

  // stream boolean if other user is blocked
  Stream<bool> streamIsUserBlocked(String otherUid) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || currentUid.isEmpty || otherUid.isEmpty) {
      return Stream.value(false);
    }

    return _blockedCol(currentUid)
        .doc(otherUid)
        .snapshots()
        .map((snap) => snap.exists);
  }
}
