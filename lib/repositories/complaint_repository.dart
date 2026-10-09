import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_paths.dart';
import '../models/complaint.dart';

class ComplaintRepository {
  static final ComplaintRepository _instance = ComplaintRepository._internal();
  factory ComplaintRepository() => _instance;
  ComplaintRepository._internal();

  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection(FirestorePaths.complaints);

  // submit new complaint
  Future<String> submitComplaint(Complaint complaint) async {
    final targetId = complaint.providerId.trim().toLowerCase();
    final senderId = complaint.customerId.trim().toLowerCase();
    if (targetId == 'admin_support' ||
        targetId == 'admin' ||
        complaint.accusedRole?.toLowerCase() == 'admin' ||
        senderId == 'admin_support') {
      throw ArgumentError('Admins cannot be reported.');
    }
    final docRef = await _col.add(complaint.toMap());
    return docRef.id;
  }

  Stream<List<Complaint>> streamAllComplaints({int limit = 50}) {
    return _col
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((doc) => Complaint.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<List<Complaint>> streamComplaintsForProvider(String providerId, {int limit = 50}) {
    if (providerId.isEmpty) return Stream.value(const []);
    return _col
        .where('providerId', isEqualTo: providerId)
        .limit(limit)
        .snapshots()
        .map((snap) {
      final items = snap.docs
          .map((doc) => Complaint.fromMap(doc.id, doc.data()))
          .toList();
      items.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return items;
    });
  }

  Future<void> updateComplaintStatus(
    String complaintId,
    String status, {
    String? adminNotes,
  }) async {
    if (complaintId.isEmpty) return;
    final Map<String, dynamic> updateData = {
      'status': status,
      'reviewedAt': FieldValue.serverTimestamp(),
    };
    if (adminNotes != null && adminNotes.isNotEmpty) {
      updateData['adminNotes'] = adminNotes;
    }
    await _col.doc(complaintId).update(updateData);
  }
}
