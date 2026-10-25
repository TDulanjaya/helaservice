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
  final DateTime? updatedAt;
  final DateTime? proposedStartAt;
  final DateTime? proposedEndAt;
  final String? proposedSlot;
  final DateTime? withdrawnAt;
  final DateTime? jobUpdatedAt;

  // price breakdown
  final String quoteType;
  final String? priceUnit;
  final int? unitRateLkr;
  final double? quantity;
  final int? materialsEstimateLkr;
  final int visitFeeLkr;
  final double travelKm;
  final int travelRateLkr;
  final int travelCostLkr;

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
    this.updatedAt,
    this.proposedStartAt,
    this.proposedEndAt,
    this.proposedSlot,
    this.withdrawnAt,
    this.jobUpdatedAt,
    this.quoteType = 'inspect',
    this.priceUnit,
    this.unitRateLkr,
    this.quantity,
    this.materialsEstimateLkr,
    this.visitFeeLkr = 0,
    this.travelKm = 0.0,
    this.travelRateLkr = 0,
    this.travelCostLkr = 0,
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
        'providerTrade': providerTrade,
        'providerLocation': providerLocation,
        'etaMinutes': etaMinutes,
        'notes': notes,
        'status': status,
        if (proposedStartAt != null)
          'proposedStartAt': Timestamp.fromDate(proposedStartAt!),
        if (proposedEndAt != null)
          'proposedEndAt': Timestamp.fromDate(proposedEndAt!),
        if (proposedSlot != null && proposedSlot!.isNotEmpty)
          'proposedSlot': proposedSlot,
        if (withdrawnAt != null)
          'withdrawnAt': Timestamp.fromDate(withdrawnAt!),
        if (jobUpdatedAt != null)
          'jobUpdatedAt': Timestamp.fromDate(jobUpdatedAt!),
        'quoteType': quoteType,
        if (quoteType != 'inspect' && priceUnit != null) 'priceUnit': priceUnit,
        if (quoteType != 'inspect' && unitRateLkr != null)
          'unitRateLkr': unitRateLkr,
        if (quoteType != 'inspect' && quantity != null) 'quantity': quantity,
        if (quoteType != 'inspect' && materialsEstimateLkr != null)
          'materialsEstimateLkr': materialsEstimateLkr,
        'visitFeeLkr': visitFeeLkr,
        'travelKm': travelKm,
        'travelRateLkr': travelRateLkr,
        'travelCostLkr': travelCostLkr,
        'quotedPrice': quotedPrice.round(),
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory Quote.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['createdAt'];
    final uts = map['updatedAt'];
    final pStartTs = map['proposedStartAt'];
    final pEndTs = map['proposedEndAt'];
    final wTs = map['withdrawnAt'];
    final juaTs = map['jobUpdatedAt'];
    var rawStatus = map['status'] as String? ?? 'pending';
    if (rawStatus == 'declined') rawStatus = 'not_selected';
    if (rawStatus == 'cancelled') rawStatus = 'job_closed';

    return Quote(
      id: id,
      requestId: map['requestId'] ?? '',
      providerId: map['providerId'] ?? '',
      createdBy:
          (map['createdBy'] as String?) ?? (map['providerId'] as String? ?? ''),
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
      status: rawStatus,
      createdAt: ts is Timestamp ? ts.toDate() : null,
      updatedAt: uts is Timestamp ? uts.toDate() : null,
      proposedStartAt: pStartTs is Timestamp ? pStartTs.toDate() : null,
      proposedEndAt: pEndTs is Timestamp ? pEndTs.toDate() : null,
      proposedSlot: map['proposedSlot'] as String?,
      withdrawnAt: wTs is Timestamp ? wTs.toDate() : null,
      jobUpdatedAt: juaTs is Timestamp ? juaTs.toDate() : null,
      quoteType: map['quoteType'] as String? ?? 'inspect',
      priceUnit: map['priceUnit'] as String?,
      unitRateLkr: (map['unitRateLkr'] as num?)?.toInt(),
      quantity: (map['quantity'] as num?)?.toDouble(),
      materialsEstimateLkr: (map['materialsEstimateLkr'] as num?)?.toInt(),
      visitFeeLkr: (map['visitFeeLkr'] as num?)?.toInt() ?? 0,
      travelKm: (map['travelKm'] as num?)?.toDouble() ?? 0.0,
      travelRateLkr: (map['travelRateLkr'] as num?)?.toInt() ?? 0,
      travelCostLkr: (map['travelCostLkr'] as num?)?.toInt() ?? 0,
    );
  }
}
