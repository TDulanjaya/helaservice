import 'package:cloud_firestore/cloud_firestore.dart';

class Booking {
  final String id;
  final String customerId;
  final String providerId;
  final String providerName;
  final String status;
  final DateTime? createdAt;
  final String time;
  final String relativeTime;
  final String title;
  final String estRate;
  final String customerName;
  final String customerInitials;
  final String customerPhone;
  final String providerPhone;
  final double? customerLatitude;
  final double? customerLongitude;
  final double? agreedPrice;
  final String? entryInstructions;
  final String? jobRequestId;
  final String location;
  final String distance;
  final String? delayReason;
  final int? delayMinutes;
  final int? rating;
  final DateTime? providerAcceptedAt;

  const Booking({
    this.id = '',
    required this.customerId,
    required this.providerId,
    this.providerName = '',
    this.status = 'pending',
    this.createdAt,
    required this.time,
    required this.relativeTime,
    required this.title,
    required this.estRate,
    required this.customerName,
    required this.customerInitials,
    this.customerPhone = '',
    this.providerPhone = '',
    this.customerLatitude,
    this.customerLongitude,
    this.agreedPrice,
    this.entryInstructions,
    this.jobRequestId,
    required this.location,
    required this.distance,
    this.delayReason,
    this.delayMinutes,
    this.rating,
    this.providerAcceptedAt,
  });

  Map<String, dynamic> toMap() => {
        'customerId': customerId,
        'providerId': providerId,
        if (providerName.isNotEmpty) 'providerName': providerName,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
        'time': time,
        'relativeTime': relativeTime,
        'title': title,
        'estRate': estRate,
        'customerName': customerName,
        'customerInitials': customerInitials,
        'customerPhone': customerPhone,
        'providerPhone': providerPhone,
        if (customerLatitude != null) 'customerLatitude': customerLatitude,
        if (customerLongitude != null) 'customerLongitude': customerLongitude,
        if (agreedPrice != null) 'agreedPrice': agreedPrice,
        if (entryInstructions != null) 'entryInstructions': entryInstructions,
        if (jobRequestId != null) 'jobRequestId': jobRequestId,
        if (delayReason != null) 'delayReason': delayReason,
        if (delayMinutes != null) 'delayMinutes': delayMinutes,
        if (rating != null) 'rating': rating,
        if (providerAcceptedAt != null)
          'providerAcceptedAt': Timestamp.fromDate(providerAcceptedAt!),
        'location': location,
        'distance': distance,
      };

  factory Booking.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['createdAt'];
    final pat = map['providerAcceptedAt'];
    return Booking(
      id: id,
      customerId: map['customerId'] ?? '',
      providerId: map['providerId'] ?? '',
      providerName: map['providerName'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: ts is Timestamp ? ts.toDate() : null,
      time: map['time'] ?? '',
      relativeTime: map['relativeTime'] ?? '',
      title: map['title'] ?? '',
      estRate: map['estRate'] ?? '',
      customerName: map['customerName'] ?? '',
      customerInitials: map['customerInitials'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      providerPhone: map['providerPhone'] ?? '',
      customerLatitude: (map['customerLatitude'] as num?)?.toDouble(),
      customerLongitude: (map['customerLongitude'] as num?)?.toDouble(),
      agreedPrice: (map['agreedPrice'] as num?)?.toDouble(),
      entryInstructions: map['entryInstructions'],
      jobRequestId: map['jobRequestId'],
      delayReason: map['delayReason'],
      delayMinutes: (map['delayMinutes'] as num?)?.toInt(),
      rating: (map['rating'] as num?)?.toInt(),
      providerAcceptedAt: pat is Timestamp ? pat.toDate() : null,
      location: map['location'] ?? '',
      distance: map['distance'] ?? '',
    );
  }
}

