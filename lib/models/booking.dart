import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/job_status.dart';
import '../utils/schedule_helpers.dart';

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
  final String? cancellationReason;
  final String? cancelledBy;
  final DateTime? completedAt;
  final int? pinAttempts;
  final double? finalAmount;
  final String? paymentMethod;
  final String? paymentNote;
  final DateTime? providerMarkedPaidAt;
  final DateTime? customerConfirmedPaidAt;
  final bool? paymentDisputed;
  final String? paymentDisputeReason;
  final DateTime? paymentDisputedAt;
  final String type;
  String get bookingType => type;
  final DateTime? expiresAt;
  final DateTime? scheduledDate;
  final String? scheduledSlot;
  final String? rescheduleRequestedBy;
  final DateTime? rescheduleProposedDate;
  final String? rescheduleProposedSlot;
  final String? rescheduleReason;
  final DateTime? rescheduleRequestedAt;
  final DateTime? rescheduledAt;
  final DateTime? rescheduleDeclinedAt;
  final String? rescheduleDeclinedBy;
  final List<String> beforePhotos;
  final List<String> afterPhotos;

  // price flow and extras
  final String? quoteId;
  final String? quoteType;
  final String?
      priceStatus; // 'awaiting_confirmation', 'proposed', 'approved', 'rejected'
  final Map<String, dynamic>? proposedPrice;
  final int? approvedTotalLkr;
  final int? approvedExtrasLkr;
  final String? lastApprovedExtraId;
  final String? completionType; // 'normal', 'visit_only'
  final int? visitFeeLkr;
  final int? travelCostLkr;
  final double? travelKm;
  final int? travelRateLkr;
  final int? estimatedTotalLkr;
  final int? proposalCount;
  final String? priceUnit;
  final int? unitRateLkr;
  final double? quantity;
  final int? materialsEstimateLkr;
  final DateTime? priceProposedAt;
  final DateTime? priceApprovedAt;
  final DateTime? priceRejectedAt;
  final DateTime? priceConfirmedAt;

  // verified arrival and no-show
  final String?
      arrivalStatus; // 'claimed', 'confirmed', 'denied', 'auto_started'
  final DateTime? arrivalClaimedAt;
  final double? arrivalLat;
  final double? arrivalLng;
  final int? arrivalAccuracyM;
  final int? arrivalDistanceM;
  final bool arrivalOutsideZone;
  final bool arrivalMocked;
  final int arrivalClaimCount;
  final int arrivalDeniedCount;
  final String? arrivalConfirmedBy; // 'customer', 'gps_timeout'
  final DateTime? arrivedAt;
  final bool noShow;
  final DateTime? enRouteStartedAt;
  final DateTime? scheduledStartAt;
  final DateTime? scheduledEndAt;
  final String? scheduleMode;
  final double? accuracyMeters;
  final String? houseNo;
  final String? street;
  final String? city;
  final String? directions;

  int get agreedPriceLkr => agreedPrice?.round() ?? 0;

  const Booking({
    this.id = '',
    required this.customerId,
    required this.providerId,
    this.providerName = '',
    this.status = JobStatus.pending,
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
    this.cancellationReason,
    this.cancelledBy,
    this.completedAt,
    this.pinAttempts,
    this.finalAmount,
    this.paymentMethod,
    this.paymentNote,
    this.providerMarkedPaidAt,
    this.customerConfirmedPaidAt,
    this.paymentDisputed,
    this.paymentDisputeReason,
    this.paymentDisputedAt,
    this.type = 'standard',
    this.expiresAt,
    this.scheduledDate,
    this.scheduledSlot,
    this.rescheduleRequestedBy,
    this.rescheduleProposedDate,
    this.rescheduleProposedSlot,
    this.rescheduleReason,
    this.rescheduleRequestedAt,
    this.rescheduledAt,
    this.rescheduleDeclinedAt,
    this.rescheduleDeclinedBy,
    this.beforePhotos = const [],
    this.afterPhotos = const [],
    this.quoteId,
    this.quoteType,
    this.priceStatus,
    this.proposedPrice,
    this.approvedTotalLkr,
    this.approvedExtrasLkr,
    this.lastApprovedExtraId,
    this.completionType,
    this.visitFeeLkr,
    this.travelCostLkr,
    this.travelKm,
    this.travelRateLkr,
    this.estimatedTotalLkr,
    this.proposalCount,
    this.priceUnit,
    this.unitRateLkr,
    this.quantity,
    this.materialsEstimateLkr,
    this.priceProposedAt,
    this.priceApprovedAt,
    this.priceRejectedAt,
    this.priceConfirmedAt,
    this.arrivalStatus,
    this.arrivalClaimedAt,
    this.arrivalLat,
    this.arrivalLng,
    this.arrivalAccuracyM,
    this.arrivalDistanceM,
    this.arrivalOutsideZone = false,
    this.arrivalMocked = false,
    this.arrivalClaimCount = 0,
    this.arrivalDeniedCount = 0,
    this.arrivalConfirmedBy,
    this.arrivedAt,
    this.noShow = false,
    this.enRouteStartedAt,
    this.scheduledStartAt,
    this.scheduledEndAt,
    this.scheduleMode,
    this.accuracyMeters,
    this.houseNo,
    this.street,
    this.city,
    this.directions,
  });

  bool get isAwaitingPriceConfirmation =>
      priceStatus == 'awaiting_confirmation';
  bool get isPriceProposed => priceStatus == 'proposed';
  bool get isPriceApproved => priceStatus == 'approved';
  bool get isPriceRejected => priceStatus == 'rejected';
  int get currentTotalLkr => approvedTotalLkr ?? agreedPrice?.round() ?? 0;

  bool get hasPendingReschedule =>
      rescheduleRequestedBy != null && rescheduleRequestedBy!.isNotEmpty;

  Map<String, dynamic> toMap() => {
        'customerId': customerId,
        'providerId': providerId,
        if (providerName.isNotEmpty) 'providerName': providerName,
        'status': status,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
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
        if (cancellationReason != null)
          'cancellationReason': cancellationReason,
        if (cancelledBy != null) 'cancelledBy': cancelledBy,
        if (completedAt != null)
          'completedAt': Timestamp.fromDate(completedAt!),
        if (pinAttempts != null) 'pinAttempts': pinAttempts,
        if (finalAmount != null) 'finalAmount': finalAmount,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        if (paymentNote != null) 'paymentNote': paymentNote,
        if (providerMarkedPaidAt != null)
          'providerMarkedPaidAt': Timestamp.fromDate(providerMarkedPaidAt!),
        if (customerConfirmedPaidAt != null)
          'customerConfirmedPaidAt':
              Timestamp.fromDate(customerConfirmedPaidAt!),
        if (paymentDisputed != null) 'paymentDisputed': paymentDisputed,
        if (paymentDisputeReason != null)
          'paymentDisputeReason': paymentDisputeReason,
        if (paymentDisputedAt != null)
          'paymentDisputedAt': Timestamp.fromDate(paymentDisputedAt!),
        'type': type,
        if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
        if (scheduledDate != null)
          'scheduledDate': Timestamp.fromDate(scheduledDate!),
        if (scheduledSlot != null) 'scheduledSlot': scheduledSlot,
        if (rescheduleRequestedBy != null)
          'rescheduleRequestedBy': rescheduleRequestedBy,
        if (rescheduleProposedDate != null)
          'rescheduleProposedDate': Timestamp.fromDate(rescheduleProposedDate!),
        if (rescheduleProposedSlot != null)
          'rescheduleProposedSlot': rescheduleProposedSlot,
        if (rescheduleReason != null) 'rescheduleReason': rescheduleReason,
        if (rescheduleRequestedAt != null)
          'rescheduleRequestedAt': Timestamp.fromDate(rescheduleRequestedAt!),
        if (rescheduledAt != null)
          'rescheduledAt': Timestamp.fromDate(rescheduledAt!),
        if (rescheduleDeclinedAt != null)
          'rescheduleDeclinedAt': Timestamp.fromDate(rescheduleDeclinedAt!),
        if (rescheduleDeclinedBy != null)
          'rescheduleDeclinedBy': rescheduleDeclinedBy,
        'beforePhotos': beforePhotos,
        'afterPhotos': afterPhotos,
        'location': location,
        'distance': distance,
        if (quoteId != null) 'quoteId': quoteId,
        if (quoteType != null) 'quoteType': quoteType,
        if (priceStatus != null) 'priceStatus': priceStatus,
        if (proposedPrice != null) 'proposedPrice': proposedPrice,
        if (approvedTotalLkr != null) 'approvedTotalLkr': approvedTotalLkr,
        if (approvedExtrasLkr != null) 'approvedExtrasLkr': approvedExtrasLkr,
        if (lastApprovedExtraId != null)
          'lastApprovedExtraId': lastApprovedExtraId,
        if (completionType != null) 'completionType': completionType,
        if (visitFeeLkr != null) 'visitFeeLkr': visitFeeLkr,
        if (travelCostLkr != null) 'travelCostLkr': travelCostLkr,
        if (travelKm != null) 'travelKm': travelKm,
        if (travelRateLkr != null) 'travelRateLkr': travelRateLkr,
        if (estimatedTotalLkr != null) 'estimatedTotalLkr': estimatedTotalLkr,
        if (proposalCount != null) 'proposalCount': proposalCount,
        if (priceUnit != null) 'priceUnit': priceUnit,
        if (unitRateLkr != null) 'unitRateLkr': unitRateLkr,
        if (quantity != null) 'quantity': quantity,
        if (materialsEstimateLkr != null)
          'materialsEstimateLkr': materialsEstimateLkr,
        if (priceProposedAt != null)
          'priceProposedAt': Timestamp.fromDate(priceProposedAt!),
        if (priceApprovedAt != null)
          'priceApprovedAt': Timestamp.fromDate(priceApprovedAt!),
        if (priceRejectedAt != null)
          'priceRejectedAt': Timestamp.fromDate(priceRejectedAt!),
        if (priceConfirmedAt != null)
          'priceConfirmedAt': Timestamp.fromDate(priceConfirmedAt!),
        if (arrivalStatus != null) 'arrivalStatus': arrivalStatus,
        if (arrivalClaimedAt != null)
          'arrivalClaimedAt': Timestamp.fromDate(arrivalClaimedAt!),
        if (arrivalLat != null) 'arrivalLat': arrivalLat,
        if (arrivalLng != null) 'arrivalLng': arrivalLng,
        if (arrivalAccuracyM != null) 'arrivalAccuracyM': arrivalAccuracyM,
        if (arrivalDistanceM != null) 'arrivalDistanceM': arrivalDistanceM,
        if (arrivalOutsideZone) 'arrivalOutsideZone': arrivalOutsideZone,
        if (arrivalMocked) 'arrivalMocked': arrivalMocked,
        if (arrivalClaimCount > 0) 'arrivalClaimCount': arrivalClaimCount,
        if (arrivalDeniedCount > 0) 'arrivalDeniedCount': arrivalDeniedCount,
        if (arrivalConfirmedBy != null)
          'arrivalConfirmedBy': arrivalConfirmedBy,
        if (arrivedAt != null) 'arrivedAt': Timestamp.fromDate(arrivedAt!),
        if (noShow) 'noShow': noShow,
        if (enRouteStartedAt != null)
          'enRouteStartedAt': Timestamp.fromDate(enRouteStartedAt!),
        if (scheduledStartAt != null)
          'scheduledStartAt': Timestamp.fromDate(scheduledStartAt!),
        if (scheduledEndAt != null)
          'scheduledEndAt': Timestamp.fromDate(scheduledEndAt!),
        if (scheduleMode != null) 'scheduleMode': scheduleMode,
        if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
        if (houseNo != null) 'houseNo': houseNo,
        if (street != null) 'street': street,
        if (city != null) 'city': city,
        if (directions != null) 'directions': directions,
      };

  factory Booking.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['createdAt'];
    final pat = map['providerAcceptedAt'];
    final cat = map['completedAt'];
    final pmpa = map['providerMarkedPaidAt'];
    final ccpa = map['customerConfirmedPaidAt'];
    final pda = map['paymentDisputedAt'];
    final sdt = map['scheduledDate'];
    final rpd = map['rescheduleProposedDate'];
    final rra = map['rescheduleRequestedAt'];
    final rda = map['rescheduledAt'];
    final rdec = map['rescheduleDeclinedAt'];
    final ppa = map['priceProposedAt'];
    final paa = map['priceApprovedAt'];
    final pra = map['priceRejectedAt'];
    final pca = map['priceConfirmedAt'];
    final expAt = map['expiresAt'];
    final arrClaimAt = map['arrivalClaimedAt'];
    final arrAt = map['arrivedAt'];
    final enRAt = map['enRouteStartedAt'];
    final schedStartAt = map['scheduledStartAt'];
    final schedEndAt = map['scheduledEndAt'];

    return Booking(
      id: id,
      customerId: map['customerId'] ?? '',
      providerId: map['providerId'] ?? '',
      providerName: map['providerName'] ?? '',
      status: map['status'] ?? JobStatus.pending,
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
      cancellationReason: map['cancellationReason'] ?? map['declineReason'],
      cancelledBy: map['cancelledBy'],
      completedAt: cat is Timestamp ? cat.toDate() : null,
      pinAttempts: (map['pinAttempts'] as num?)?.toInt(),
      finalAmount: (map['finalAmount'] as num?)?.toDouble(),
      paymentMethod: map['paymentMethod'] as String?,
      paymentNote: map['paymentNote'] as String?,
      providerMarkedPaidAt: pmpa is Timestamp ? pmpa.toDate() : null,
      customerConfirmedPaidAt: ccpa is Timestamp ? ccpa.toDate() : null,
      paymentDisputed: map['paymentDisputed'] as bool?,
      paymentDisputeReason: map['paymentDisputeReason'] as String?,
      paymentDisputedAt: pda is Timestamp ? pda.toDate() : null,
      type: map['type']?.toString() ??
          map['bookingType']?.toString() ??
          'standard',
      expiresAt: expAt is Timestamp ? expAt.toDate() : null,
      scheduledDate: sdt is Timestamp ? sdt.toDate() : null,
      scheduledSlot: map['scheduledSlot'] as String?,
      rescheduleRequestedBy: map['rescheduleRequestedBy'] as String?,
      rescheduleProposedDate: rpd is Timestamp ? rpd.toDate() : null,
      rescheduleProposedSlot: map['rescheduleProposedSlot'] as String?,
      rescheduleReason: map['rescheduleReason'] as String?,
      rescheduleRequestedAt: rra is Timestamp ? rra.toDate() : null,
      rescheduledAt: rda is Timestamp ? rda.toDate() : null,
      rescheduleDeclinedAt: rdec is Timestamp ? rdec.toDate() : null,
      rescheduleDeclinedBy: map['rescheduleDeclinedBy'] as String?,
      beforePhotos: ((map['beforePhotos'] as List?) ?? [])
          .map((e) => e.toString())
          .toList(),
      afterPhotos: ((map['afterPhotos'] as List?) ?? [])
          .map((e) => e.toString())
          .toList(),
      location: map['location'] ?? '',
      distance: map['distance'] ?? '',
      quoteId: map['quoteId'] as String?,
      quoteType: map['quoteType'] as String?,
      priceStatus: map['priceStatus'] as String?,
      proposedPrice: map['proposedPrice'] is Map
          ? Map<String, dynamic>.from(map['proposedPrice'] as Map)
          : null,
      approvedTotalLkr: (map['approvedTotalLkr'] as num?)?.toInt(),
      approvedExtrasLkr: (map['approvedExtrasLkr'] as num?)?.toInt(),
      lastApprovedExtraId: map['lastApprovedExtraId'] as String?,
      completionType: map['completionType'] as String?,
      visitFeeLkr: (map['visitFeeLkr'] as num?)?.toInt(),
      travelCostLkr: (map['travelCostLkr'] as num?)?.toInt(),
      travelKm: (map['travelKm'] as num?)?.toDouble(),
      travelRateLkr: (map['travelRateLkr'] as num?)?.toInt(),
      estimatedTotalLkr: (map['estimatedTotalLkr'] as num?)?.toInt(),
      proposalCount: (map['proposalCount'] as num?)?.toInt(),
      priceUnit: map['priceUnit'] as String?,
      unitRateLkr: (map['unitRateLkr'] as num?)?.toInt(),
      quantity: (map['quantity'] as num?)?.toDouble(),
      materialsEstimateLkr: (map['materialsEstimateLkr'] as num?)?.toInt(),
      priceProposedAt: ppa is Timestamp ? ppa.toDate() : null,
      priceApprovedAt: paa is Timestamp ? paa.toDate() : null,
      priceRejectedAt: pra is Timestamp ? pra.toDate() : null,
      priceConfirmedAt: pca is Timestamp ? pca.toDate() : null,
      arrivalStatus: map['arrivalStatus'] as String?,
      arrivalClaimedAt: arrClaimAt is Timestamp ? arrClaimAt.toDate() : null,
      arrivalLat: (map['arrivalLat'] as num?)?.toDouble(),
      arrivalLng: (map['arrivalLng'] as num?)?.toDouble(),
      arrivalAccuracyM: (map['arrivalAccuracyM'] as num?)?.toInt(),
      arrivalDistanceM: (map['arrivalDistanceM'] as num?)?.toInt(),
      arrivalOutsideZone: map['arrivalOutsideZone'] as bool? ?? false,
      arrivalMocked: map['arrivalMocked'] as bool? ?? false,
      arrivalClaimCount: (map['arrivalClaimCount'] as num?)?.toInt() ?? 0,
      arrivalDeniedCount: (map['arrivalDeniedCount'] as num?)?.toInt() ?? 0,
      arrivalConfirmedBy: map['arrivalConfirmedBy'] as String?,
      arrivedAt: arrAt is Timestamp ? arrAt.toDate() : null,
      noShow: map['noShow'] as bool? ?? false,
      enRouteStartedAt: enRAt is Timestamp ? enRAt.toDate() : null,
      scheduledStartAt:
          schedStartAt is Timestamp ? schedStartAt.toDate() : null,
      scheduledEndAt: schedEndAt is Timestamp ? schedEndAt.toDate() : null,
      scheduleMode: map['scheduleMode'] as String?,
      accuracyMeters: (map['accuracyMeters'] as num?)?.toDouble(),
      houseNo: map['houseNo'] as String?,
      street: map['street'] as String?,
      city: map['city'] as String?,
      directions: map['directions'] as String?,
    );
  }

  Booking copyWith({
    String? id,
    String? customerId,
    String? providerId,
    String? providerName,
    String? status,
    DateTime? createdAt,
    String? time,
    String? relativeTime,
    String? title,
    String? estRate,
    String? customerName,
    String? customerInitials,
    String? customerPhone,
    String? providerPhone,
    double? customerLatitude,
    double? customerLongitude,
    double? agreedPrice,
    String? entryInstructions,
    String? jobRequestId,
    String? location,
    String? distance,
    String? delayReason,
    int? delayMinutes,
    int? rating,
    DateTime? providerAcceptedAt,
    String? cancellationReason,
    String? cancelledBy,
    DateTime? completedAt,
    int? pinAttempts,
    double? finalAmount,
    String? paymentMethod,
    String? paymentNote,
    DateTime? providerMarkedPaidAt,
    DateTime? customerConfirmedPaidAt,
    bool? paymentDisputed,
    String? paymentDisputeReason,
    DateTime? paymentDisputedAt,
    String? type,
    String? bookingType,
    DateTime? expiresAt,
    DateTime? scheduledDate,
    String? scheduledSlot,
    String? rescheduleRequestedBy,
    DateTime? rescheduleProposedDate,
    String? rescheduleProposedSlot,
    String? rescheduleReason,
    DateTime? rescheduleRequestedAt,
    DateTime? rescheduledAt,
    DateTime? rescheduleDeclinedAt,
    String? rescheduleDeclinedBy,
    List<String>? beforePhotos,
    List<String>? afterPhotos,
    String? quoteId,
    String? quoteType,
    String? priceStatus,
    Map<String, dynamic>? proposedPrice,
    int? approvedTotalLkr,
    int? approvedExtrasLkr,
    String? lastApprovedExtraId,
    String? completionType,
    int? visitFeeLkr,
    int? travelCostLkr,
    double? travelKm,
    int? travelRateLkr,
    int? estimatedTotalLkr,
    int? proposalCount,
    String? priceUnit,
    int? unitRateLkr,
    double? quantity,
    int? materialsEstimateLkr,
    DateTime? priceProposedAt,
    DateTime? priceApprovedAt,
    DateTime? priceRejectedAt,
    DateTime? priceConfirmedAt,
    String? arrivalStatus,
    DateTime? arrivalClaimedAt,
    double? arrivalLat,
    double? arrivalLng,
    int? arrivalAccuracyM,
    int? arrivalDistanceM,
    bool? arrivalOutsideZone,
    bool? arrivalMocked,
    int? arrivalClaimCount,
    int? arrivalDeniedCount,
    String? arrivalConfirmedBy,
    DateTime? arrivedAt,
    bool? noShow,
    DateTime? enRouteStartedAt,
    DateTime? scheduledStartAt,
    DateTime? scheduledEndAt,
    String? scheduleMode,
    double? accuracyMeters,
    String? houseNo,
    String? street,
    String? city,
    String? directions,
  }) {
    return Booking(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      time: time ?? this.time,
      relativeTime: relativeTime ?? this.relativeTime,
      title: title ?? this.title,
      estRate: estRate ?? this.estRate,
      customerName: customerName ?? this.customerName,
      customerInitials: customerInitials ?? this.customerInitials,
      customerPhone: customerPhone ?? this.customerPhone,
      providerPhone: providerPhone ?? this.providerPhone,
      customerLatitude: customerLatitude ?? this.customerLatitude,
      customerLongitude: customerLongitude ?? this.customerLongitude,
      agreedPrice: agreedPrice ?? this.agreedPrice,
      entryInstructions: entryInstructions ?? this.entryInstructions,
      jobRequestId: jobRequestId ?? this.jobRequestId,
      location: location ?? this.location,
      distance: distance ?? this.distance,
      delayReason: delayReason ?? this.delayReason,
      delayMinutes: delayMinutes ?? this.delayMinutes,
      rating: rating ?? this.rating,
      providerAcceptedAt: providerAcceptedAt ?? this.providerAcceptedAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      completedAt: completedAt ?? this.completedAt,
      pinAttempts: pinAttempts ?? this.pinAttempts,
      finalAmount: finalAmount ?? this.finalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentNote: paymentNote ?? this.paymentNote,
      providerMarkedPaidAt: providerMarkedPaidAt ?? this.providerMarkedPaidAt,
      customerConfirmedPaidAt:
          customerConfirmedPaidAt ?? this.customerConfirmedPaidAt,
      paymentDisputed: paymentDisputed ?? this.paymentDisputed,
      paymentDisputeReason: paymentDisputeReason ?? this.paymentDisputeReason,
      paymentDisputedAt: paymentDisputedAt ?? this.paymentDisputedAt,
      type: type ?? bookingType ?? this.type,
      expiresAt: expiresAt ?? this.expiresAt,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledSlot: scheduledSlot ?? this.scheduledSlot,
      rescheduleRequestedBy:
          rescheduleRequestedBy ?? this.rescheduleRequestedBy,
      rescheduleProposedDate:
          rescheduleProposedDate ?? this.rescheduleProposedDate,
      rescheduleProposedSlot:
          rescheduleProposedSlot ?? this.rescheduleProposedSlot,
      rescheduleReason: rescheduleReason ?? this.rescheduleReason,
      rescheduleRequestedAt:
          rescheduleRequestedAt ?? this.rescheduleRequestedAt,
      rescheduledAt: rescheduledAt ?? this.rescheduledAt,
      rescheduleDeclinedAt: rescheduleDeclinedAt ?? this.rescheduleDeclinedAt,
      rescheduleDeclinedBy: rescheduleDeclinedBy ?? this.rescheduleDeclinedBy,
      beforePhotos: beforePhotos ?? this.beforePhotos,
      afterPhotos: afterPhotos ?? this.afterPhotos,
      quoteId: quoteId ?? this.quoteId,
      quoteType: quoteType ?? this.quoteType,
      priceStatus: priceStatus ?? this.priceStatus,
      proposedPrice: proposedPrice ?? this.proposedPrice,
      approvedTotalLkr: approvedTotalLkr ?? this.approvedTotalLkr,
      approvedExtrasLkr: approvedExtrasLkr ?? this.approvedExtrasLkr,
      lastApprovedExtraId: lastApprovedExtraId ?? this.lastApprovedExtraId,
      completionType: completionType ?? this.completionType,
      visitFeeLkr: visitFeeLkr ?? this.visitFeeLkr,
      travelCostLkr: travelCostLkr ?? this.travelCostLkr,
      travelKm: travelKm ?? this.travelKm,
      travelRateLkr: travelRateLkr ?? this.travelRateLkr,
      estimatedTotalLkr: estimatedTotalLkr ?? this.estimatedTotalLkr,
      proposalCount: proposalCount ?? this.proposalCount,
      priceUnit: priceUnit ?? this.priceUnit,
      unitRateLkr: unitRateLkr ?? this.unitRateLkr,
      quantity: quantity ?? this.quantity,
      materialsEstimateLkr: materialsEstimateLkr ?? this.materialsEstimateLkr,
      priceProposedAt: priceProposedAt ?? this.priceProposedAt,
      priceApprovedAt: priceApprovedAt ?? this.priceApprovedAt,
      priceRejectedAt: priceRejectedAt ?? this.priceRejectedAt,
      priceConfirmedAt: priceConfirmedAt ?? this.priceConfirmedAt,
      arrivalStatus: arrivalStatus ?? this.arrivalStatus,
      arrivalClaimedAt: arrivalClaimedAt ?? this.arrivalClaimedAt,
      arrivalLat: arrivalLat ?? this.arrivalLat,
      arrivalLng: arrivalLng ?? this.arrivalLng,
      arrivalAccuracyM: arrivalAccuracyM ?? this.arrivalAccuracyM,
      arrivalDistanceM: arrivalDistanceM ?? this.arrivalDistanceM,
      arrivalOutsideZone: arrivalOutsideZone ?? this.arrivalOutsideZone,
      arrivalMocked: arrivalMocked ?? this.arrivalMocked,
      arrivalClaimCount: arrivalClaimCount ?? this.arrivalClaimCount,
      arrivalDeniedCount: arrivalDeniedCount ?? this.arrivalDeniedCount,
      arrivalConfirmedBy: arrivalConfirmedBy ?? this.arrivalConfirmedBy,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      noShow: noShow ?? this.noShow,
      enRouteStartedAt: enRouteStartedAt ?? this.enRouteStartedAt,
      scheduledStartAt: scheduledStartAt ?? this.scheduledStartAt,
      scheduledEndAt: scheduledEndAt ?? this.scheduledEndAt,
      scheduleMode: scheduleMode ?? this.scheduleMode,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      houseNo: houseNo ?? this.houseNo,
      street: street ?? this.street,
      city: city ?? this.city,
      directions: directions ?? this.directions,
    );
  }

  String formattedPrice(BuildContext context) {
    if (agreedPrice != null && agreedPrice! > 0) {
      return NumberFormat.currency(symbol: 'LKR ', decimalDigits: 0)
          .format(agreedPrice);
    }
    return estRate.isNotEmpty ? estRate : '';
  }

  String formattedTime(BuildContext context) {
    if (createdAt != null) {
      final locale = Localizations.localeOf(context).languageCode;
      return DateFormat.yMMMd(locale).add_jm().format(createdAt!);
    }
    return time.isNotEmpty ? time : '';
  }

  bool get isEligibleForNoShow {
    if (status != JobStatus.confirmed && status != JobStatus.enRoute) {
      return false;
    }
    final now = DateTime.now();
    if (status == JobStatus.enRoute) {
      if (arrivalStatus == 'denied') return true;
      if (enRouteStartedAt != null &&
          now.difference(enRouteStartedAt!).inMinutes >= 90) {
        return true;
      }
      return false;
    }
    if (status == JobStatus.confirmed) {
      if (scheduledEndAt != null) {
        if (now.difference(scheduledEndAt!).inMinutes >= 30) return true;
      } else if (scheduledStartAt != null) {
        if (now.difference(scheduledStartAt!).inMinutes >= 60) return true;
      } else if (scheduledDate != null) {
        if (now.difference(scheduledDate!).inDays >= 1) return true;
      }
    }
    return false;
  }

  String formattedScheduledSummary(BuildContext context) {
    return ScheduleHelpers.formatScheduleDisplay(
      context,
      scheduleMode: scheduleMode,
      scheduledDate: scheduledDate,
      scheduledStartAt: scheduledStartAt,
      scheduledEndAt: scheduledEndAt,
      legacySlot: scheduledSlot,
      fallbackTime: time,
    );
  }

  // sort upcoming by scheduled time first then created date
  static int compareUpcoming(Booking a, Booking b) {
    final aTime = a.scheduledStartAt ?? a.scheduledDate;
    final bTime = b.scheduledStartAt ?? b.scheduledDate;
    if (aTime != null && bTime != null) {
      final cmp = aTime.compareTo(bTime);
      if (cmp != 0) return cmp;
    } else if (aTime != null) {
      return -1;
    } else if (bTime != null) {
      return 1;
    }
    final aCreated = a.createdAt;
    final bCreated = b.createdAt;
    if (aCreated != null && bCreated != null) {
      return aCreated.compareTo(bCreated);
    } else if (aCreated != null) {
      return -1;
    } else if (bCreated != null) {
      return 1;
    }
    return 0;
  }
}
