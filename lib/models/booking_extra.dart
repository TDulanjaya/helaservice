import 'package:cloud_firestore/cloud_firestore.dart';

class BookingExtra {
  final String id;
  final String providerId;
  final String customerId;
  final int amountLkr;
  final String description;
  final String status; // 'proposed', 'approved', 'rejected'
  final DateTime? createdAt;
  final DateTime? customerRespondedAt;

  const BookingExtra({
    this.id = '',
    required this.providerId,
    required this.customerId,
    required this.amountLkr,
    required this.description,
    this.status = 'proposed',
    this.createdAt,
    this.customerRespondedAt,
  });

  Map<String, dynamic> toMap() => {
        'providerId': providerId,
        'customerId': customerId,
        'amountLkr': amountLkr,
        'description': description,
        'status': status,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        if (customerRespondedAt != null)
          'customerRespondedAt': Timestamp.fromDate(customerRespondedAt!),
      };

  factory BookingExtra.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return BookingExtra(
      id: id,
      providerId: map['providerId'] ?? '',
      customerId: map['customerId'] ?? '',
      amountLkr: (map['amountLkr'] as num?)?.toInt() ?? 0,
      description: map['description'] ?? '',
      status: map['status'] ?? 'proposed',
      createdAt: parseDate(map['createdAt']),
      customerRespondedAt: parseDate(map['customerRespondedAt']),
    );
  }
}
