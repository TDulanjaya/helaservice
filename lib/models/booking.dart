import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/job_status.dart';

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
  final String bookingType;
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
    this.bookingType = 'asap',
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
  });

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
        if (cancellationReason != null) 'cancellationReason': cancellationReason,
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
          'customerConfirmedPaidAt': Timestamp.fromDate(customerConfirmedPaidAt!),
        if (paymentDisputed != null) 'paymentDisputed': paymentDisputed,
        if (paymentDisputeReason != null) 'paymentDisputeReason': paymentDisputeReason,
        if (paymentDisputedAt != null)
          'paymentDisputedAt': Timestamp.fromDate(paymentDisputedAt!),
        'bookingType': bookingType,
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
      bookingType: map['bookingType']?.toString() ?? 'asap',
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
    String? bookingType,
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
      customerConfirmedPaidAt: customerConfirmedPaidAt ?? this.customerConfirmedPaidAt,
      paymentDisputed: paymentDisputed ?? this.paymentDisputed,
      paymentDisputeReason: paymentDisputeReason ?? this.paymentDisputeReason,
      paymentDisputedAt: paymentDisputedAt ?? this.paymentDisputedAt,
      bookingType: bookingType ?? this.bookingType,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledSlot: scheduledSlot ?? this.scheduledSlot,
      rescheduleRequestedBy: rescheduleRequestedBy ?? this.rescheduleRequestedBy,
      rescheduleProposedDate: rescheduleProposedDate ?? this.rescheduleProposedDate,
      rescheduleProposedSlot: rescheduleProposedSlot ?? this.rescheduleProposedSlot,
      rescheduleReason: rescheduleReason ?? this.rescheduleReason,
      rescheduleRequestedAt: rescheduleRequestedAt ?? this.rescheduleRequestedAt,
      rescheduledAt: rescheduledAt ?? this.rescheduledAt,
      rescheduleDeclinedAt: rescheduleDeclinedAt ?? this.rescheduleDeclinedAt,
      rescheduleDeclinedBy: rescheduleDeclinedBy ?? this.rescheduleDeclinedBy,
      beforePhotos: beforePhotos ?? this.beforePhotos,
      afterPhotos: afterPhotos ?? this.afterPhotos,
    );
  }

  String formattedPrice(BuildContext context) {
    if (agreedPrice != null && agreedPrice! > 0) {
      return NumberFormat.currency(symbol: 'LKR ', decimalDigits: 0).format(agreedPrice);
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
}

