import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String customerId;
  final String providerId;
  final String status;
  final DateTime? createdAt;
  final String time;
  final String relativeTime;
  final String title;
  final String estRate;
  final String customerName;
  final String customerInitials;
  final String location;
  final String distance;

  const Booking({
    this.id = '',
    required this.customerId,
    required this.providerId,
    this.status = 'pending',
    this.createdAt,
    required this.time,
    required this.relativeTime,
    required this.title,
    required this.estRate,
    required this.customerName,
    required this.customerInitials,
    required this.location,
    required this.distance,
  });

  Map<String, dynamic> toMap() => {
        'customerId': customerId,
        'providerId': providerId,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
        'time': time,
        'relativeTime': relativeTime,
        'title': title,
        'estRate': estRate,
        'customerName': customerName,
        'customerInitials': customerInitials,
        'location': location,
        'distance': distance,
      };

  factory Booking.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['createdAt'];
    return Booking(
      id: id,
      customerId: map['customerId'] ?? '',
      providerId: map['providerId'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: ts is Timestamp ? ts.toDate() : null,
      time: map['time'] ?? '',
      relativeTime: map['relativeTime'] ?? '',
      title: map['title'] ?? '',
      estRate: map['estRate'] ?? '',
      customerName: map['customerName'] ?? '',
      customerInitials: map['customerInitials'] ?? '',
      location: map['location'] ?? '',
      distance: map['distance'] ?? '',
    );
  }
}
