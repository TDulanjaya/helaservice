import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_paths.dart';
import '../models/complaint.dart';
import '../models/support_message.dart';
import '../services/notification_service.dart';

class ComplaintRepository {
  static final ComplaintRepository _instance = ComplaintRepository._internal();
  factory ComplaintRepository() => _instance;
  ComplaintRepository._internal();

  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection(FirestorePaths.complaints);

  // submit new complaint / support ticket
  Future<String> submitComplaint(Complaint complaint) async {
    final targetId = (complaint.reportedUid ?? complaint.providerId).trim().toLowerCase();
    final senderId = complaint.effectiveReporterUid.trim().toLowerCase();
    if (targetId == 'admin_support' ||
        targetId == 'admin' ||
        complaint.reportedRole?.toLowerCase() == 'admin' ||
        complaint.accusedRole?.toLowerCase() == 'admin' ||
        senderId == 'admin_support') {
      throw ArgumentError('Admins cannot be reported.');
    }
    final docRef = await _col.add(complaint.toMap());
    unawaited(NotificationService.instance.sendNotification(
      event: 'support_ticket_created',
      docId: docRef.id,
    ));
    return docRef.id;
  }

  // stream user's own tickets
  Stream<List<Complaint>> streamMyTickets(String userId) {
    if (userId.isEmpty) return Stream.value(const []);
    return _col
        .where('reporterUid', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((doc) => Complaint.fromMap(doc.id, doc.data()))
          .toList();
      list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return list;
    });
  }

  // stream single ticket
  Stream<Complaint?> streamTicket(String ticketId) {
    if (ticketId.isEmpty) return Stream.value(null);
    return _col.doc(ticketId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return Complaint.fromMap(snap.id, snap.data()!);
    });
  }

  // stream all complaints for admin
  Stream<List<Complaint>> streamAllComplaints({int limit = 100}) {
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

  Stream<List<Complaint>> streamComplaintsForProvider(String providerId) {
    if (providerId.isEmpty) return Stream.value(const []);
    return _col
        .where('reportedUid', isEqualTo: providerId)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Complaint.fromMap(doc.id, doc.data())).toList());
  }

  // stream messages in a ticket thread
  Stream<List<SupportMessage>> streamMessages(String ticketId) {
    if (ticketId.isEmpty) return Stream.value(const []);
    return _col
        .doc(ticketId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((d) => SupportMessage.fromMap(d.id, d.data()))
          .toList();
    });
  }

  // add message to ticket thread
  Future<void> addMessage(String ticketId, SupportMessage message) async {
    if (ticketId.isEmpty) return;
    final ticketDoc = await _col.doc(ticketId).get();
    final currentStatus = ticketDoc.data()?['status'] as String?;
    if (currentStatus == 'closed') {
      throw StateError('Cannot reply to a closed ticket');
    }

    final batch = FirebaseFirestore.instance.batch();
    final msgRef = _col.doc(ticketId).collection('messages').doc();
    batch.set(msgRef, message.toMap());

    final Map<String, dynamic> ticketUpdate = {
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (message.isAdmin) {
      ticketUpdate['status'] = 'waiting_user';
    } else if (currentStatus == 'waiting_user') {
      ticketUpdate['status'] = 'open';
    }

    batch.update(_col.doc(ticketId), ticketUpdate);
    await batch.commit();

    if (message.isAdmin) {
      unawaited(NotificationService.instance.sendNotification(
        event: 'support_admin_reply',
        docId: ticketId,
      ));
    }
  }

  // admin updates ticket status
  Future<void> updateComplaintStatus(
    String complaintId,
    String status, {
    String? adminNotes,
    String? assignedAdminId,
    String? resolutionNote,
  }) async {
    if (complaintId.isEmpty) return;
    final Map<String, dynamic> updateData = {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == 'resolved' || status == 'closed') {
      updateData['resolvedAt'] = FieldValue.serverTimestamp();
    }
    if (adminNotes != null && adminNotes.isNotEmpty) {
      updateData['adminNotes'] = adminNotes;
    }
    if (resolutionNote != null && resolutionNote.isNotEmpty) {
      updateData['resolutionNote'] = resolutionNote;
    }
    if (assignedAdminId != null) {
      updateData['assignedAdminId'] = assignedAdminId;
    }
    await _col.doc(complaintId).update(updateData);

    if (status == 'resolved' || status == 'closed') {
      unawaited(NotificationService.instance.sendNotification(
        event: 'support_ticket_resolved',
        docId: complaintId,
      ));
    }
  }

  // reporter closes own ticket
  Future<void> closeTicket(String ticketId) async {
    if (ticketId.isEmpty) return;
    await _col.doc(ticketId).update({
      'status': 'closed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
