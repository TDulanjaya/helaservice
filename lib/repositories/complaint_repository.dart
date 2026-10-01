import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_paths.dart';
import '../models/complaint.dart';

class ComplaintRepository {
  static final ComplaintRepository _instance = ComplaintRepository._internal();
  factory ComplaintRepository() => _instance;
  ComplaintRepository._internal();

  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection(FirestorePaths.complaints);

  Future<String> submitComplaint(Complaint complaint) async {
    final docRef = await _col.add(complaint.toMap());
    return docRef.id;
  }

  Stream<List<Complaint>> streamAllComplaints() {
    return _col.orderBy('createdAt', descending: true).snapshots().map((snap) {
      return snap.docs
          .map((doc) => Complaint.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<List<Complaint>> streamComplaintsForProvider(String providerId) {
    if (providerId.isEmpty) return Stream.value(const []);
    return _col
        .where('providerId', isEqualTo: providerId)
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
