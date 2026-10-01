import 'package:cloud_firestore/cloud_firestore.dart';

class Complaint {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String providerId;
  final String providerName;
  final String providerTrade;
  final String? bookingId;
  final String reason;
  final String description;
  final String status;
  final String? adminNotes;
  final DateTime? createdAt;

  const Complaint({
    this.id = '',
    required this.customerId,
    required this.customerName,
    this.customerPhone = '',
    required this.providerId,
    required this.providerName,
    required this.providerTrade,
    this.bookingId,
    required this.reason,
    required this.description,
    this.status = 'pending',
    this.adminNotes,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'providerId': providerId,
        'providerName': providerName,
        'providerTrade': providerTrade,
        if (bookingId != null) 'bookingId': bookingId,
        'reason': reason,
        'description': description,
        'status': status,
        if (adminNotes != null) 'adminNotes': adminNotes,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  factory Complaint.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['createdAt'];
    return Complaint(
      id: id,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? 'Customer',
      customerPhone: map['customerPhone'] ?? '',
      providerId: map['providerId'] ?? '',
      providerName: map['providerName'] ?? 'Service Provider',
      providerTrade: map['providerTrade'] ?? '',
      bookingId: map['bookingId'],
      reason: map['reason'] ?? 'General Dispute',
      description: map['description'] ?? '',
      status: map['status'] ?? 'pending',
      adminNotes: map['adminNotes'],
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
