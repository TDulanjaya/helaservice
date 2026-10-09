import 'package:cloud_firestore/cloud_firestore.dart';

class Quote {
  final String id;
  final String requestId;
  final String providerId;
  final String createdBy;
  final String providerName;
  final double providerRating;
  final int providerReviewCount;
  final bool providerNicVerified;
  final String providerTrade;
  final double? providerLatitude;
  final double? providerLongitude;
  final double quotedPrice;
  final int etaMinutes;
  final String notes;
  final String providerPhone;
  final String providerLocation;
  final String status;
  final DateTime? createdAt;

  const Quote({
    this.id = '',
    required this.requestId,
    required this.providerId,
    required this.createdBy,
    required this.providerName,
    this.providerRating = 0.0,
    this.providerReviewCount = 0,
    this.providerNicVerified = false,
    this.providerTrade = '',
    this.providerLatitude,
    this.providerLongitude,
    required this.quotedPrice,
    this.etaMinutes = 30,
    this.notes = '',
    this.providerPhone = '',
    this.providerLocation = '',
    this.status = 'pending',
    this.createdAt,
  });

  bool get isExpired =>
      status == 'pending' &&
      createdAt != null &&
      DateTime.now().difference(createdAt!).inHours >= 48;

  Map<String, dynamic> toMap() => {

        'requestId': requestId,
        'providerId': providerId,
        'createdBy': createdBy,
        'providerName': providerName,
        'providerRating': providerRating,
        'providerReviewCount': providerReviewCount,
        'providerNicVerified': providerNicVerified,
        'providerTrade': providerTrade,
        if (providerLatitude != null) 'providerLatitude': providerLatitude,
        if (providerLongitude != null) 'providerLongitude': providerLongitude,
        'quotedPrice': quotedPrice,
        'etaMinutes': etaMinutes,
        'notes': notes,
        'providerPhone': providerPhone,
        'providerLocation': providerLocation,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory Quote.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['createdAt'];
    return Quote(
      id: id,
      requestId: map['requestId'] ?? '',
      providerId: map['providerId'] ?? '',
      createdBy: (map['createdBy'] as String?) ?? (map['providerId'] as String? ?? ''),
      providerName: map['providerName'] ?? '',
      providerRating: (map['providerRating'] as num?)?.toDouble() ?? 0.0,
      providerReviewCount: map['providerReviewCount'] ?? 0,
      providerNicVerified: map['providerNicVerified'] ?? false,
      providerTrade: map['providerTrade'] ?? '',
      providerLatitude: (map['providerLatitude'] as num?)?.toDouble(),
      providerLongitude: (map['providerLongitude'] as num?)?.toDouble(),
      quotedPrice: (map['quotedPrice'] as num?)?.toDouble() ?? 0.0,
      etaMinutes: map['etaMinutes'] ?? 30,
      notes: map['notes'] ?? '',
      providerPhone: map['providerPhone'] ?? '',
      providerLocation: (map['providerLocation'] as String?) ??
          (map['providerDistrict'] as String?) ??
          (map['serviceArea'] as String?) ??
          '',
      status: map['status'] ?? 'pending',
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
