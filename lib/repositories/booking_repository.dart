import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../constants/firestore_paths.dart';
import '../constants/job_status.dart';
import '../models/booking.dart';
import '../models/booking_extra.dart';
import '../models/booking_timeline_event.dart';
import '../services/notification_service.dart';
import '../services/session_guard.dart';
import '../utils/schedule_helpers.dart';

class PinVerificationResult {
  final bool success;
  final int attempts;
  final String? errorMessage;
  final String? errorCode;
  const PinVerificationResult({
    required this.success,
    this.attempts = 0,
    this.errorMessage,
    this.errorCode,
  });
}

DateTime computeScheduledStartAt(DateTime date, String? slot) {
  return ScheduleHelpers.computeLegacyScheduledStartAt(date, slot);
}

class BookingRepository {
  final _col = FirebaseFirestore.instance.collection(FirestorePaths.bookings);

  // add timeline event to batch
  void addTimelineEventToBatch({
    required WriteBatch batch,
    required String bookingId,
    required String action,
    required String title,
    required String description,
    required String actorUid,
    required String actorRole,
    Map<String, dynamic>? metadata,
  }) {
    final eventRef = _col.doc(bookingId).collection('timeline').doc();
    batch.set(eventRef, {
      'action': action,
      'title': title,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
      'actorUid': actorUid,
      'actorRole': actorRole,
      if (metadata != null) 'metadata': metadata,
    });
  }

  // log timeline event standalone
  Future<void> logTimelineEvent({
    required String bookingId,
    required String action,
    required String title,
    required String description,
    required String actorUid,
    required String actorRole,
    Map<String, dynamic>? metadata,
  }) async {
    final eventRef = _col.doc(bookingId).collection('timeline').doc();
    await eventRef.set({
      'action': action,
      'title': title,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
      'actorUid': actorUid,
      'actorRole': actorRole,
      if (metadata != null) 'metadata': metadata,
    });
  }

  // stream timeline events
  Stream<List<BookingTimelineEvent>> streamTimelineEvents(String bookingId) {
    if (bookingId.isEmpty) return Stream.value([]);
    return _col
        .doc(bookingId)
        .collection('timeline')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => BookingTimelineEvent.fromMap(d.id, d.data()))
            .toList());
  }

  Future<String> createBooking(Booking booking) async {
    final currentUid =
        FirebaseAuth.instance.currentUser?.uid ?? booking.customerId;
    final pin = (100000 + Random.secure().nextInt(900000)).toString();

    final batch = FirebaseFirestore.instance.batch();
    final bookingRef = _col.doc();
    final pinRef = bookingRef.collection('private').doc('pin');

    // write private pin doc in same batch
    batch.set(pinRef, {
      'pin': pin,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final rateNum = booking.agreedPrice ??
        double.tryParse(booking.estRate.replaceAll(RegExp(r'[^0-9.]'), '')) ??
        0.0;

    int? resolvedVisitFee = booking.visitFeeLkr;
    String? providerCategory;
    try {
      final techDoc = await FirebaseFirestore.instance
          .collection(FirestorePaths.technicians)
          .doc(booking.providerId)
          .get();
      if (techDoc.exists && techDoc.data() != null) {
        final data = techDoc.data()!;
        final cat = (data['category'] as String?) ?? (data['trade'] as String?);
        if (cat != null && cat.trim().isNotEmpty) {
          providerCategory = cat.trim();
        }
        if (booking.quoteId == null) {
          if (booking.type == 'urgent') {
            resolvedVisitFee = (data['emergencyRateLkr'] as num?)?.toInt() ??
                (data['baseRateLkr'] as num?)?.toInt() ??
                0;
          } else {
            resolvedVisitFee = (data['visitFeeLkr'] as num?)?.toInt() ??
                (data['baseRateLkr'] as num?)?.toInt() ??
                0;
          }
        }
      }
    } catch (_) {}

    if (providerCategory == null || providerCategory.isEmpty) {
      throw 'PROVIDER_CATEGORY_MISSING';
    }

    String? linkedJobRequestId = booking.jobRequestId;

    if (linkedJobRequestId == null || linkedJobRequestId.isEmpty) {
      if (booking.customerLatitude == null ||
          booking.customerLongitude == null) {
        throw Exception('LOCATION_REQUIRED');
      }

      // create linked job request for direct booking
      final jobReqRef = FirebaseFirestore.instance
          .collection(FirestorePaths.jobRequests)
          .doc();
      linkedJobRequestId = jobReqRef.id;

      final roundedLat =
          double.parse(booking.customerLatitude!.toStringAsFixed(2));
      final roundedLng =
          double.parse(booking.customerLongitude!.toStringAsFixed(2));

      batch.set(jobReqRef, {
        'customerId': currentUid,
        'customerName': booking.customerName,
        'title': booking.title,
        'category': providerCategory,
        'description': 'Direct booking with ${booking.providerName}',
        'latitude': roundedLat,
        'longitude': roundedLng,
        'status': JobRequestStatus.pendingProvider,
        'selectedProviderId': booking.providerId,
        'agreedPrice': rateNum.round(),
        'quoteCount': 0,
        'bookingId': bookingRef.id,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final jobReqContactRef = jobReqRef.collection('private').doc('contact');
      final entryNote = booking.entryInstructions ?? '';
      batch.set(jobReqContactRef, {
        'customerPhone': booking.customerPhone,
        'address': booking.location,
        if (entryNote.isNotEmpty) 'note': entryNote,
        'landmark': entryNote,
        'latitude': booking.customerLatitude,
        'longitude': booking.customerLongitude,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    final bookingData = booking.toMap();
    bookingData['customerId'] = currentUid;
    bookingData['jobRequestId'] = linkedJobRequestId;
    bookingData['status'] = JobStatus.pending;
    if (booking.type == 'urgent') {
      bookingData['type'] = 'urgent';
      bookingData['expiresAt'] = Timestamp.fromDate(
        booking.expiresAt ?? DateTime.now().add(const Duration(minutes: 3)),
      );
    }
    if (booking.quoteId == null) {
      final fee = resolvedVisitFee ?? booking.visitFeeLkr ?? 0;
      bookingData['quoteType'] = 'inspect';
      bookingData['priceStatus'] = 'awaiting_confirmation';
      bookingData['visitFeeLkr'] = fee;
      bookingData['travelCostLkr'] = 0;
      bookingData['approvedExtrasLkr'] = 0;
      bookingData['proposalCount'] = 0;
      bookingData['estimatedTotalLkr'] = fee;
      bookingData['agreedPrice'] = fee;
    } else {
      bookingData['agreedPrice'] = rateNum.round();
      if (resolvedVisitFee != null) {
        bookingData['visitFeeLkr'] = resolvedVisitFee;
      }
    }

    if (booking.scheduledDate != null) {
      bookingData['scheduledStartAt'] = Timestamp.fromDate(
        computeScheduledStartAt(booking.scheduledDate!, booking.scheduledSlot),
      );
    }
    bookingData.remove('providerAcceptedAt');
    batch.set(bookingRef, bookingData);

    addTimelineEventToBatch(
      batch: batch,
      bookingId: bookingRef.id,
      action: 'created',
      title: 'Booking Created',
      description: 'Customer created booking request',
      actorUid: currentUid,
      actorRole: 'customer',
    );

    await batch.commit();
    return bookingRef.id;
  }

  // provider accepts direct booking
  Future<void> acceptBookingByProvider({
    required String bookingId,
    String? jobRequestId,
    String? quoteId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final batch = FirebaseFirestore.instance.batch();
    batch.update(_col.doc(bookingId), {
      'status': JobStatus.confirmed,
      'providerAcceptedAt': FieldValue.serverTimestamp(),
    });

    if (jobRequestId != null && jobRequestId.isNotEmpty) {
      final reqRef = FirebaseFirestore.instance
          .collection(FirestorePaths.jobRequests)
          .doc(jobRequestId);
      batch.update(reqRef, {
        'status': JobRequestStatus.assigned,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (quoteId != null && quoteId.isNotEmpty) {
        final quoteRef = reqRef.collection(FirestorePaths.quotes).doc(quoteId);
        batch.update(quoteRef, {'status': 'accepted'});
      }
    }

    addTimelineEventToBatch(
      batch: batch,
      bookingId: bookingId,
      action: 'accepted',
      title: 'Provider Accepted',
      description: 'Provider accepted the booking',
      actorUid: uid,
      actorRole: 'provider',
    );

    await batch.commit();

    // send push alert to customer
    NotificationService.instance.sendNotification(
      event: 'booking_confirmed',
      docId: bookingId,
    );
  }

  // provider declines direct booking
  Future<void> declineBookingByProvider({
    required String bookingId,
    String? jobRequestId,
    String? reason,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final batch = FirebaseFirestore.instance.batch();
    final effectiveReason = reason ?? 'Provider unavailable';

    batch.update(_col.doc(bookingId), {
      'status': JobStatus.declined,
      'declinedAt': FieldValue.serverTimestamp(),
      'declineReason': effectiveReason,
      'cancelledBy': uid,
      'cancelledAt': FieldValue.serverTimestamp(),
    });

    if (jobRequestId != null && jobRequestId.isNotEmpty) {
      final reqDoc = await FirebaseFirestore.instance
          .collection(FirestorePaths.jobRequests)
          .doc(jobRequestId)
          .get();
      if (reqDoc.exists) {
        final reqData = reqDoc.data() ?? {};
        final expTs = reqData['expiresAt'];
        DateTime? exp;
        if (expTs is Timestamp) {
          exp = expTs.toDate();
        }
        final isPast = exp != null && DateTime.now().isAfter(exp);
        final newJobStatus =
            isPast ? JobRequestStatus.expired : JobRequestStatus.open;

        batch.update(reqDoc.reference, {
          'status': newJobStatus,
          'selectedProviderId': FieldValue.delete(),
          'acceptedQuoteId': FieldValue.delete(),
          'bookingId': FieldValue.delete(),
          'agreedPrice': FieldValue.delete(),
          'cancellationReason': effectiveReason,
          'cancelledBy': uid,
          'cancelledAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final qSnap = await reqDoc.reference
            .collection(FirestorePaths.quotes)
            .where('providerId', isEqualTo: uid)
            .get();
        for (final q in qSnap.docs) {
          batch.update(q.reference, {
            'status': 'cancelled_by_provider',
            'cancelledAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    }

    addTimelineEventToBatch(
      batch: batch,
      bookingId: bookingId,
      action: 'declined',
      title: 'Provider Declined',
      description: effectiveReason,
      actorUid: uid,
      actorRole: 'provider',
    );

    await batch.commit();

    try {
      await NotificationService.instance.sendNotification(
        event: 'provider_cancelled',
        docId: bookingId,
      );
    } catch (e) {
      debugPrint('[BookingRepo] notify provider decline error: $e');
    }
  }

  // provider starts travel
  Future<void> startNavigation(String bookingId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final batch = FirebaseFirestore.instance.batch();
    batch.update(_col.doc(bookingId), {
      'status': JobStatus.enRoute,
      'enRouteStartedAt': FieldValue.serverTimestamp(),
    });

    addTimelineEventToBatch(
      batch: batch,
      bookingId: bookingId,
      action: 'en_route',
      title: 'Provider En Route',
      description: 'Provider started journey to location',
      actorUid: uid,
      actorRole: 'provider',
    );

    await batch.commit();

    // send en route alert
    NotificationService.instance.sendNotification(
      event: 'booking_en_route',
      docId: bookingId,
    );
  }

  // provider claims arrival with GPS metrics
  Future<void> claimArrival({
    required String bookingId,
    required double latitude,
    required double longitude,
    required int accuracyM,
    required int distanceM,
    required bool outsideZone,
    required bool isMocked,
    required int currentClaimCount,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final batch = FirebaseFirestore.instance.batch();

    final roundedLat = double.parse(latitude.toStringAsFixed(5));
    final roundedLng = double.parse(longitude.toStringAsFixed(5));

    batch.update(_col.doc(bookingId), {
      'arrivalStatus': 'claimed',
      'arrivalClaimedAt': FieldValue.serverTimestamp(),
      'arrivalLat': roundedLat,
      'arrivalLng': roundedLng,
      'arrivalAccuracyM': accuracyM,
      'arrivalDistanceM': distanceM,
      'arrivalOutsideZone': outsideZone,
      'arrivalMocked': isMocked,
      'arrivalClaimCount': currentClaimCount + 1,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    addTimelineEventToBatch(
      batch: batch,
      bookingId: bookingId,
      action: 'arrival_claimed',
      title: 'Arrival Claimed',
      description:
          'Provider claimed arrival ($distanceM m away${outsideZone ? ', outside zone' : ''})',
      actorUid: uid,
      actorRole: 'provider',
    );

    await batch.commit();

    NotificationService.instance.sendNotification(
      event: 'arrival_claimed',
      docId: bookingId,
    );
  }

  // customer confirms provider arrival
  Future<void> confirmCustomerArrival({
    required String bookingId,
    String? jobRequestId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final batch = FirebaseFirestore.instance.batch();

    batch.update(_col.doc(bookingId), {
      'status': JobStatus.inProgress,
      'arrivalStatus': 'confirmed',
      'arrivedAt': FieldValue.serverTimestamp(),
      'arrivalConfirmedBy': 'customer',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (jobRequestId != null && jobRequestId.isNotEmpty) {
      final reqRef = FirebaseFirestore.instance
          .collection(FirestorePaths.jobRequests)
          .doc(jobRequestId);
      batch.update(reqRef, {
        'status': JobRequestStatus.inProgress,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    addTimelineEventToBatch(
      batch: batch,
      bookingId: bookingId,
      action: 'arrival_confirmed',
      title: 'Arrival Confirmed',
      description: 'Customer confirmed provider arrival',
      actorUid: uid,
      actorRole: 'customer',
    );

    await batch.commit();

    NotificationService.instance.sendNotification(
      event: 'arrival_confirmed',
      docId: bookingId,
    );
  }

  // customer denies provider arrival
  Future<void> denyCustomerArrival({
    required String bookingId,
    required int currentDeniedCount,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final batch = FirebaseFirestore.instance.batch();

    batch.update(_col.doc(bookingId), {
      'arrivalStatus': 'denied',
      'arrivalDeniedCount': currentDeniedCount + 1,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    addTimelineEventToBatch(
      batch: batch,
      bookingId: bookingId,
      action: 'arrival_denied',
      title: 'Arrival Denied',
      description: 'Customer reported provider has not arrived',
      actorUid: uid,
      actorRole: 'customer',
    );

    await batch.commit();

    NotificationService.instance.sendNotification(
      event: 'arrival_denied',
      docId: bookingId,
    );
  }

  // provider auto-starts after 10 min timeout if inside zone and not mocked
  Future<void> autoStartArrival({
    required String bookingId,
    String? jobRequestId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final batch = FirebaseFirestore.instance.batch();

    batch.update(_col.doc(bookingId), {
      'status': JobStatus.inProgress,
      'arrivalStatus': 'auto_started',
      'arrivedAt': FieldValue.serverTimestamp(),
      'arrivalConfirmedBy': 'gps_timeout',
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (jobRequestId != null && jobRequestId.isNotEmpty) {
      final reqRef = FirebaseFirestore.instance
          .collection(FirestorePaths.jobRequests)
          .doc(jobRequestId);
      batch.update(reqRef, {
        'status': JobRequestStatus.inProgress,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    addTimelineEventToBatch(
      batch: batch,
      bookingId: bookingId,
      action: 'arrival_auto_started',
      title: 'Auto-Started After Verification',
      description: 'Started after 10m customer timeout with verified GPS',
      actorUid: uid,
      actorRole: 'provider',
    );

    await batch.commit();

    NotificationService.instance.sendNotification(
      event: 'arrival_auto_started',
      docId: bookingId,
    );
  }

  // customer reports provider no-show
  Future<void> reportNoShow({
    required String bookingId,
    String? jobRequestId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final batch = FirebaseFirestore.instance.batch();

    batch.update(_col.doc(bookingId), {
      'status': JobStatus.cancelled,
      'cancellationReason': 'provider_no_show',
      'noShow': true,
      'cancelledAt': FieldValue.serverTimestamp(),
      'cancelledBy': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (jobRequestId != null && jobRequestId.isNotEmpty) {
      final reqRef = FirebaseFirestore.instance
          .collection(FirestorePaths.jobRequests)
          .doc(jobRequestId);
      batch.update(reqRef, {
        'status': JobRequestStatus.cancelled,
        'cancellationReason': 'provider_no_show',
        'cancelledBy': uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    addTimelineEventToBatch(
      batch: batch,
      bookingId: bookingId,
      action: 'no_show_reported',
      title: 'Provider No-Show',
      description: 'Customer cancelled due to provider no-show',
      actorUid: uid,
      actorRole: 'customer',
    );

    await batch.commit();

    NotificationService.instance.sendNotification(
      event: 'no_show_reported',
      docId: bookingId,
    );
  }

  // provider completes job with pin
  Future<PinVerificationResult> verifyAndCompleteJob({
    required String bookingId,
    required String enteredPin,
    String? jobRequestId,
    double? finalAmount,
    String? paymentNote,
    String completionType = 'normal',
  }) async {
    final cleanPin = enteredPin.trim();
    if (cleanPin.length != 6 && cleanPin.length != 4) {
      return const PinVerificationResult(
        success: false,
        errorCode: 'invalid_pin_length',
        errorMessage: 'PIN must be 6 digits.',
      );
    }

    try {
      if (bookingId.trim().isEmpty) {
        return const PinVerificationResult(
          success: false,
          errorCode: 'invalid_id',
          errorMessage: 'Booking or job request not found.',
        );
      }

      final docSnap = await _col.doc(bookingId).get();
      if (!docSnap.exists) {
        return const PinVerificationResult(
          success: false,
          errorCode: 'not_found',
          errorMessage: 'Booking or job request not found.',
        );
      }

      final bookingMap = docSnap.data() ?? {};

      // pre-flight: booking must be in_progress
      final bookingStatus = bookingMap['status'] as String? ?? '';
      if (bookingStatus != JobStatus.inProgress) {
        return const PinVerificationResult(
          success: false,
          errorCode: 'not_in_progress',
          errorMessage: 'Please mark arrival first',
        );
      }

      // pre-flight: job request id must exist
      final effectiveJobRequestId = (jobRequestId != null && jobRequestId.trim().isNotEmpty)
          ? jobRequestId.trim()
          : (bookingMap['jobRequestId'] as String?)?.trim() ?? '';
      if (effectiveJobRequestId.isEmpty) {
        return const PinVerificationResult(
          success: false,
          errorCode: 'invalid_id',
          errorMessage: 'Booking or job request not found.',
        );
      }

      // pre-flight: check job request exists
      final jobSnap = await FirebaseFirestore.instance
          .collection(FirestorePaths.jobRequests)
          .doc(effectiveJobRequestId)
          .get();
      if (!jobSnap.exists) {
        return const PinVerificationResult(
          success: false,
          errorCode: 'invalid_id',
          errorMessage: 'Booking or job request not found.',
        );
      }

      // pre-flight: price must be approved for estimate / inspect
      final quoteType = bookingMap['quoteType'] as String? ?? '';
      final priceStatus = bookingMap['priceStatus'] as String? ?? '';
      final hasPriceStatus = bookingMap.containsKey('priceStatus');

      if ((quoteType == 'estimate' || quoteType == 'inspect') &&
          completionType != 'visit_only' &&
          priceStatus != 'approved') {
        return const PinVerificationResult(
          success: false,
          errorCode: 'price_not_confirmed',
          errorMessage: 'Please confirm the price with the customer first',
        );
      }

      // pre-flight: final amount must be an integer > 0
      int intFinalAmount = 0;
      if (hasPriceStatus) {
        if (completionType == 'visit_only') {
          final visitFee = (bookingMap['visitFeeLkr'] as num?)?.round() ??
              (bookingMap['agreedPrice'] as num?)?.round() ??
              0;
          intFinalAmount = visitFee;
        } else {
          final approvedTotal =
              (bookingMap['approvedTotalLkr'] as num?)?.round() ??
                  (bookingMap['agreedPrice'] as num?)?.round() ??
                  0;
          intFinalAmount = approvedTotal;
        }
      } else {
        if (finalAmount != null && finalAmount > 0) {
          intFinalAmount = finalAmount.round();
        } else {
          intFinalAmount = (bookingMap['agreedPrice'] as num?)?.round() ?? 0;
        }
      }

      if (intFinalAmount <= 0) {
        return const PinVerificationResult(
          success: false,
          errorCode: 'invalid_amount',
          errorMessage: 'Final amount must be greater than 0.',
        );
      }

      final currentAttempts =
          (bookingMap['pinAttempts'] as num?)?.toInt() ?? 0;
      if (currentAttempts >= 5) {
        return const PinVerificationResult(
          success: false,
          attempts: 5,
          errorCode: 'too_many_attempts',
          errorMessage:
              'Too many wrong PINs. Ask the customer to reset the PIN attempts in their booking.',
        );
      }

      final newAttempts = currentAttempts + 1;

      // update pin attempt count first
      await _col.doc(bookingId).update({'pinAttempts': newAttempts});

      // send completion update
      final batch = FirebaseFirestore.instance.batch();

      final updateData = <String, dynamic>{
        'status': JobStatus.completed,
        'enteredPin': cleanPin,
        'completedAt': FieldValue.serverTimestamp(),
        'paymentMethod': 'cash',
        'providerMarkedPaidAt': FieldValue.serverTimestamp(),
      };

      if (hasPriceStatus) {
        updateData['completionType'] = completionType;
        updateData['finalAmount'] = intFinalAmount;
      } else {
        if (intFinalAmount > 0) {
          updateData['finalAmount'] = intFinalAmount;
        }
      }

      if (paymentNote != null && paymentNote.trim().isNotEmpty) {
        updateData['paymentNote'] = paymentNote.trim();
      }

      batch.update(_col.doc(bookingId), updateData);

      final reqRef = FirebaseFirestore.instance
          .collection(FirestorePaths.jobRequests)
          .doc(effectiveJobRequestId);
      batch.update(reqRef, {
        'status': JobRequestStatus.completed,
        'completedAt': FieldValue.serverTimestamp(),
      });

      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final action =
          completionType == 'visit_only' ? 'completed_visit_only' : 'completed';
      final title =
          completionType == 'visit_only' ? 'Visit Completed' : 'Job Completed';
      final description = completionType == 'visit_only'
          ? 'Visit fee collected: LKR $intFinalAmount'
          : 'Work finished. Cash collected: LKR $intFinalAmount';
      addTimelineEventToBatch(
        batch: batch,
        bookingId: bookingId,
        action: action,
        title: title,
        description: description,
        actorUid: uid,
        actorRole: 'provider',
        metadata: {
          'finalAmount': intFinalAmount,
          if (paymentNote != null) 'paymentNote': paymentNote,
        },
      );

      await batch.commit();

      // notify customer of job completion
      NotificationService.instance.sendNotification(
        event: 'booking_completed',
        docId: bookingId,
      );

      return PinVerificationResult(success: true, attempts: newAttempts);
    } catch (e) {
      debugPrint('[BookingRepository] Complete job error (PIN check): $e');

      if (e is FirebaseException &&
          (e.code == 'unavailable' || e.code == 'deadline-exceeded')) {
        return const PinVerificationResult(
          success: false,
          errorCode: 'network_error',
          errorMessage:
              'Network error. Please check your connection and try again.',
        );
      }

      int attempts = 1;
      try {
        final snap = await _col.doc(bookingId).get();
        attempts = (snap.data()?['pinAttempts'] as num?)?.toInt() ?? 1;
      } catch (_) {}

      if (attempts >= 5) {
        return const PinVerificationResult(
          success: false,
          attempts: 5,
          errorCode: 'too_many_attempts',
          errorMessage:
              'Too many wrong PINs. Ask the customer to reset the PIN attempts in their booking.',
        );
      }
      return PinVerificationResult(
        success: false,
        attempts: attempts,
        errorCode: 'incorrect_pin',
        errorMessage: 'Incorrect PIN ($attempts of 5 attempts used)',
      );
    }
  }

  // customer confirms cash payment
  Future<void> confirmPayment(String bookingId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final batch = FirebaseFirestore.instance.batch();
    batch.update(_col.doc(bookingId), {
      'customerConfirmedPaidAt': FieldValue.serverTimestamp(),
    });
    addTimelineEventToBatch(
      batch: batch,
      bookingId: bookingId,
      action: 'payment_confirmed',
      title: 'Payment Confirmed',
      description: 'Customer confirmed cash payment handover',
      actorUid: uid,
      actorRole: 'customer',
    );
    await batch.commit();

    // notify provider that cash was confirmed
    NotificationService.instance.sendNotification(
      event: 'payment_confirmed',
      docId: bookingId,
    );
  }

  // customer disputes payment
  Future<void> disputePayment(String bookingId,
      {required String reason}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final bookingDoc = await _col.doc(bookingId).get();
    final bookingData = bookingDoc.data();
    final providerId = (bookingData?['providerId'] as String?) ?? '';
    final complaintRef =
        FirebaseFirestore.instance.collection(FirestorePaths.complaints).doc();

    final batch = FirebaseFirestore.instance.batch();
    batch.update(_col.doc(bookingId), {
      'paymentDisputed': true,
      'paymentDisputeReason': reason,
      'paymentDisputedAt': FieldValue.serverTimestamp(),
      'disputeTicketId': complaintRef.id,
    });
    addTimelineEventToBatch(
      batch: batch,
      bookingId: bookingId,
      action: 'payment_disputed',
      title: 'Payment Disputed',
      description: 'Customer reported dispute: $reason',
      actorUid: uid,
      actorRole: 'customer',
      metadata: {'reason': reason},
    );
    final currentUser = FirebaseAuth.instance.currentUser;
    final reporterName = currentUser?.displayName?.trim().isNotEmpty == true
        ? currentUser!.displayName!.trim()
        : (currentUser?.email ?? '');

    final complaintData = {
      'type': 'payment_dispute',
      'reporterUid': uid,
      'reporterRole': 'customer',
      if (reporterName.isNotEmpty) 'reporterName': reporterName,
      if (providerId.isNotEmpty) 'reportedUid': providerId,
      if (providerId.isNotEmpty) 'reportedRole': 'provider',
      'bookingId': bookingId,
      'subject': 'Payment Dispute: $bookingId',
      'description': reason,
      'photos': <String>[],
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessageAt': FieldValue.serverTimestamp(),
    };
    if (kDebugMode) {
      debugPrint(
          '[BookingRepository] disputePayment keys: ${complaintData.keys.toList()}');
    }
    batch.set(complaintRef, complaintData);
    await batch.commit();
    unawaited(NotificationService.instance.sendNotification(
      event: 'support_ticket_created',
      docId: complaintRef.id,
    ));
  }

  // reset pin attempt count
  Future<void> resetPinAttempts(String bookingId) async {
    await _col.doc(bookingId).update({'pinAttempts': 0});
  }

  // cancel booking for customer or provider
  Future<void> cancelBooking({
    required String bookingId,
    required String reason,
    String? cancelledBy,
    String? cancelledByRole,
    String? jobRequestId,
    bool chooseAnotherQuote = false,
  }) async {
    final doc = await _col.doc(bookingId).get();
    if (!doc.exists) throw Exception('Booking not found');
    final bData = doc.data() ?? {};
    final currentStatus = bData['status'] as String? ?? JobStatus.pending;

    if (!JobStatus.canCancel(currentStatus)) {
      throw Exception(
          'Cannot cancel booking in progress. Please contact support.');
    }

    final uid = FirebaseAuth.instance.currentUser?.uid ??
        cancelledBy ??
        (bData['customerId'] as String? ?? '');
    final isCustomer = cancelledByRole != null
        ? (cancelledByRole == 'customer')
        : (bData['customerId'] == uid);
    final role = isCustomer ? 'customer' : 'provider';
    final batch = FirebaseFirestore.instance.batch();

    batch.update(_col.doc(bookingId), {
      'status': JobStatus.cancelled,
      'cancellationReason': reason,
      'cancelledBy': uid,
      'cancelledByRole': role,
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final reqId = jobRequestId ?? bData['jobRequestId'] as String?;
    if (reqId != null && reqId.isNotEmpty) {
      final reqRef = FirebaseFirestore.instance
          .collection(FirestorePaths.jobRequests)
          .doc(reqId);
      final reqDoc = await reqRef.get();
      final reqData = reqDoc.data() ?? {};

      if (isCustomer) {
        if (chooseAnotherQuote) {
          // reopen or expire job request when choosing another quote
          final expTs = reqData['expiresAt'];
          DateTime? exp;
          if (expTs is Timestamp) {
            exp = expTs.toDate();
          }
          final isPast = exp != null && DateTime.now().isAfter(exp);
          final newJobStatus =
              isPast ? JobRequestStatus.expired : JobRequestStatus.open;

          batch.update(reqRef, {
            'status': newJobStatus,
            'selectedProviderId': FieldValue.delete(),
            'acceptedQuoteId': FieldValue.delete(),
            'bookingId': FieldValue.delete(),
            'agreedPrice': FieldValue.delete(),
            'cancellationReason': reason,
            'cancelledBy': uid,
            'cancelledAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          final acceptedQuoteId = reqData['acceptedQuoteId'] as String? ??
              bData['quoteId'] as String?;
          if (acceptedQuoteId != null && acceptedQuoteId.isNotEmpty) {
            final qRef =
                reqRef.collection(FirestorePaths.quotes).doc(acceptedQuoteId);
            batch.update(qRef, {
              'status': 'declined',
              'customerRespondedAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            final qSnap = await reqRef
                .collection(FirestorePaths.quotes)
                .where('status', isEqualTo: 'accepted')
                .get();
            for (final q in qSnap.docs) {
              batch.update(q.reference, {
                'status': 'declined',
                'customerRespondedAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              });
            }
          }
        } else {
          // customer cancels the whole job request
          batch.update(reqRef, {
            'status': JobRequestStatus.cancelled,
            'cancellationReason': reason,
            'cancelledBy': uid,
            'cancelledAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        // provider cancelling active booking
        final expTs = reqData['expiresAt'];
        DateTime? exp;
        if (expTs is Timestamp) {
          exp = expTs.toDate();
        }
        final isPast = exp != null && DateTime.now().isAfter(exp);
        final newJobStatus =
            isPast ? JobRequestStatus.expired : JobRequestStatus.open;

        batch.update(reqRef, {
          'status': newJobStatus,
          'selectedProviderId': FieldValue.delete(),
          'acceptedQuoteId': FieldValue.delete(),
          'bookingId': FieldValue.delete(),
          'agreedPrice': FieldValue.delete(),
          'cancellationReason': reason,
          'cancelledBy': uid,
          'cancelledAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final provUid = bData['providerId'] as String? ?? uid;
        final qSnap = await reqRef
            .collection(FirestorePaths.quotes)
            .where('providerId', isEqualTo: provUid)
            .get();
        for (final q in qSnap.docs) {
          batch.update(q.reference, {
            'status': 'cancelled_by_provider',
            'cancelledAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    }

    // add cancellation timeline entry
    addTimelineEventToBatch(
      batch: batch,
      bookingId: bookingId,
      action: 'cancelled',
      title: 'Booking Cancelled',
      description: reason,
      actorUid: uid,
      actorRole: role,
      metadata: {
        'reason': reason,
        'cancelledBy': uid,
        'cancelledByRole': role,
        if (chooseAnotherQuote) 'chooseAnotherQuote': true,
      },
    );

    await batch.commit();

    // stop tracking and delete live location when provider cancels
    if (!isCustomer) {
      try {
        final provUid = bData['providerId'] as String? ?? uid;
        await FirebaseFirestore.instance
            .collection(FirestorePaths.liveLocations)
            .doc(provUid)
            .delete();
      } catch (_) {}
    }

    try {
      if (isCustomer) {
        await NotificationService.instance.sendNotification(
          event: 'booking_cancelled',
          docId: bookingId,
        );
      } else {
        await NotificationService.instance.sendNotification(
          event: 'provider_cancelled',
          docId: bookingId,
        );
      }
    } catch (e) {
      debugPrint('[BookingRepo] notify cancel error: $e');
    }
  }

  Future<void> updateStatus(String bookingId, String status) async {
    await _col.doc(bookingId).update({'status': status});
  }

  // stream private pin for customer
  Stream<String?> streamBookingPin(String bookingId) {
    if (bookingId.isEmpty) return Stream.value(null);
    return _col
        .doc(bookingId)
        .collection('private')
        .doc('pin')
        .snapshots()
        .map((snap) => snap.data()?['pin'] as String?);
  }

  // migrate legacy pin format
  Future<void> migrateLegacyPinIfNeeded(
      String bookingId, Map<String, dynamic> data) async {
    final legacyPin = data['completionPin']?.toString();
    if (legacyPin == null || legacyPin.trim().isEmpty) return;

    try {
      final pinDocRef = _col.doc(bookingId).collection('private').doc('pin');
      final pinSnap = await pinDocRef.get();

      final batch = FirebaseFirestore.instance.batch();
      if (!pinSnap.exists) {
        batch.set(pinDocRef, {
          'pin': legacyPin.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      batch.update(_col.doc(bookingId), {
        'completionPin': FieldValue.delete(),
      });

      final reqId = data['jobRequestId']?.toString();
      if (reqId != null && reqId.isNotEmpty) {
        final reqRef = FirebaseFirestore.instance
            .collection(FirestorePaths.jobRequests)
            .doc(reqId);
        batch.update(reqRef, {
          'completionPin': FieldValue.delete(),
        });
      }

      await batch.commit();
    } catch (e) {
      debugPrint('[BookingRepository] Legacy PIN migration note: $e');
    }
  }

  Stream<List<Booking>> streamAllBookings({int limit = 100}) {
    return _col.limit(limit).snapshots().map((snap) {
      final items =
          snap.docs.map((d) => Booking.fromMap(d.id, d.data())).toList();
      items.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return items;
    });
  }

  Stream<List<Booking>> streamBookingsForProvider(String providerId,
      {int limit = 50}) {
    return _col
        .where('providerId', isEqualTo: providerId)
        .limit(limit)
        .snapshots()
        .withSessionGuard()
        .map((snap) {
      final items =
          snap.docs.map((d) => Booking.fromMap(d.id, d.data())).toList();
      items.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return items;
    });
  }

  Stream<List<Booking>> streamProviderBookings(String providerId,
          {int limit = 50}) =>
      streamBookingsForProvider(providerId, limit: limit);

  Future<List<Booking>> getActiveBookingsForProvider(String providerId) async {
    if (providerId.isEmpty) return const [];
    final snap = await _col
        .where('providerId', isEqualTo: providerId)
        .where('status', whereIn: [
      JobStatus.confirmed,
      JobStatus.enRoute,
      JobStatus.inProgress,
    ]).get();
    return snap.docs.map((d) => Booking.fromMap(d.id, d.data())).toList();
  }

  Stream<List<Booking>> streamBookingsForCustomer(String customerId,
      {int limit = 50}) {
    return _col
        .where('customerId', isEqualTo: customerId)
        .limit(limit)
        .snapshots()
        .withSessionGuard()
        .map((snap) {
      final items =
          snap.docs.map((d) => Booking.fromMap(d.id, d.data())).toList();
      items.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return items;
    });
  }

  Stream<List<Booking>> streamCustomerBookings(String customerId,
          {int limit = 50}) =>
      streamBookingsForCustomer(customerId, limit: limit);

  Stream<Booking?> streamBooking(String bookingId) {
    if (bookingId.isEmpty) return Stream.value(null);
    return _col.doc(bookingId).snapshots().withSessionGuard().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return Booking.fromMap(snap.id, snap.data()!);
    });
  }

  Future<Booking?> getBookingById(String bookingId) async {
    if (bookingId.isEmpty) return null;
    final doc = await _col.doc(bookingId).get();
    if (!doc.exists || doc.data() == null) return null;
    return Booking.fromMap(doc.id, doc.data()!);
  }

  Future<void> reportDelay(String bookingId,
      {required String reason, required int delayMinutes}) async {
    if (bookingId.isEmpty) return;
    await _col.doc(bookingId).update({
      'delayReason': reason,
      'delayMinutes': delayMinutes,
      'delayedAt': FieldValue.serverTimestamp(),
    });
  }

  // propose booking reschedule
  Future<void> requestReschedule({
    required String bookingId,
    required String requestedBy,
    required DateTime proposedDate,
    required String proposedSlot,
    required String reason,
    required String actorRole,
  }) async {
    if (bookingId.isEmpty) return;

    final bookingDoc = await _col.doc(bookingId).get();
    if (!bookingDoc.exists || bookingDoc.data() == null) return;

    final batch = FirebaseFirestore.instance.batch();
    final bookingRef = _col.doc(bookingId);

    batch.update(bookingRef, {
      'rescheduleRequestedBy': requestedBy,
      'rescheduleProposedDate': Timestamp.fromDate(proposedDate),
      'rescheduleProposedSlot': proposedSlot,
      'rescheduleReason': reason,
      'rescheduleRequestedAt': FieldValue.serverTimestamp(),
    });

    addTimelineEventToBatch(
      batch: batch,
      bookingId: bookingId,
      action: 'reschedule_requested',
      title: 'Reschedule Requested',
      description:
          '$actorRole requested reschedule to ${proposedDate.year}/${proposedDate.month}/${proposedDate.day} $proposedSlot. Reason: $reason',
      actorUid: requestedBy,
      actorRole: actorRole,
      metadata: {
        'proposedDate': Timestamp.fromDate(proposedDate),
        'proposedSlot': proposedSlot,
        'reason': reason,
      },
    );

    await batch.commit();

    NotificationService.instance.sendNotification(
      event: 'reschedule_requested',
      docId: bookingId,
    );
  }

  // accept proposed booking reschedule
  Future<void> acceptReschedule({
    required String bookingId,
    required String acceptedBy,
    required String actorRole,
  }) async {
    if (bookingId.isEmpty) return;

    final bookingDoc = await _col.doc(bookingId).get();
    if (!bookingDoc.exists || bookingDoc.data() == null) return;
    final booking = Booking.fromMap(bookingDoc.id, bookingDoc.data()!);

    final proposedDate = booking.rescheduleProposedDate;
    final proposedSlot = booking.rescheduleProposedSlot ?? '';

    final batch = FirebaseFirestore.instance.batch();
    final bookingRef = _col.doc(bookingId);

    final updates = <String, dynamic>{
      'rescheduledAt': FieldValue.serverTimestamp(),
      'rescheduleRequestedBy': FieldValue.delete(),
      'rescheduleProposedDate': FieldValue.delete(),
      'rescheduleProposedSlot': FieldValue.delete(),
      'rescheduleReason': FieldValue.delete(),
      'rescheduleRequestedAt': FieldValue.delete(),
    };

    if (proposedDate != null) {
      updates['scheduledDate'] = Timestamp.fromDate(proposedDate);
      updates['scheduledStartAt'] = Timestamp.fromDate(
        computeScheduledStartAt(proposedDate, proposedSlot),
      );
      updates['time'] =
          '${proposedDate.year}/${proposedDate.month}/${proposedDate.day} $proposedSlot';
    }
    if (proposedSlot.isNotEmpty) {
      updates['scheduledSlot'] = proposedSlot;
    }

    batch.update(bookingRef, updates);

    addTimelineEventToBatch(
      batch: batch,
      bookingId: bookingId,
      action: 'reschedule_accepted',
      title: 'Reschedule Accepted',
      description: '$actorRole accepted the proposed reschedule',
      actorUid: acceptedBy,
      actorRole: actorRole,
    );

    await batch.commit();

    NotificationService.instance.sendNotification(
      event: 'reschedule_accepted',
      docId: bookingId,
    );
  }

  // decline proposed booking reschedule
  Future<void> declineReschedule({
    required String bookingId,
    required String declinedBy,
    required String actorRole,
    String? declineReason,
  }) async {
    if (bookingId.isEmpty) return;

    final bookingDoc = await _col.doc(bookingId).get();
    if (!bookingDoc.exists || bookingDoc.data() == null) return;

    final batch = FirebaseFirestore.instance.batch();
    final bookingRef = _col.doc(bookingId);

    batch.update(bookingRef, {
      'rescheduleDeclinedAt': FieldValue.serverTimestamp(),
      'rescheduleDeclinedBy': declinedBy,
      'rescheduleRequestedBy': FieldValue.delete(),
      'rescheduleProposedDate': FieldValue.delete(),
      'rescheduleProposedSlot': FieldValue.delete(),
      'rescheduleReason': FieldValue.delete(),
      'rescheduleRequestedAt': FieldValue.delete(),
    });

    addTimelineEventToBatch(
      batch: batch,
      bookingId: bookingId,
      action: 'reschedule_declined',
      title: 'Reschedule Declined',
      description:
          '$actorRole declined the proposed reschedule${declineReason != null ? ': $declineReason' : ''}',
      actorUid: declinedBy,
      actorRole: actorRole,
    );

    await batch.commit();

    NotificationService.instance.sendNotification(
      event: 'reschedule_declined',
      docId: bookingId,
    );
  }

  // add before photo to booking
  Future<void> addBeforePhoto({
    required String bookingId,
    required String photoUrl,
  }) async {
    if (bookingId.isEmpty || photoUrl.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final batch = FirebaseFirestore.instance.batch();
    batch.update(_col.doc(bookingId), {
      'beforePhotos': FieldValue.arrayUnion([photoUrl]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    addTimelineEventToBatch(
      batch: batch,
      bookingId: bookingId,
      action: 'before_photo_added',
      title: 'Before Photo Uploaded',
      description: 'Provider uploaded initial inspection photo',
      actorUid: uid,
      actorRole: 'provider',
    );

    await batch.commit();
  }

  // add after photo to booking
  Future<void> addAfterPhoto({
    required String bookingId,
    required String photoUrl,
  }) async {
    if (bookingId.isEmpty || photoUrl.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final batch = FirebaseFirestore.instance.batch();
    batch.update(_col.doc(bookingId), {
      'afterPhotos': FieldValue.arrayUnion([photoUrl]),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    addTimelineEventToBatch(
      batch: batch,
      bookingId: bookingId,
      action: 'after_photo_added',
      title: 'After Photo Uploaded',
      description: 'Provider uploaded completed work photo',
      actorUid: uid,
      actorRole: 'provider',
    );

    await batch.commit();
  }

  // stream single booking by id
  Stream<Booking?> streamBookingById(String bookingId) =>
      streamBooking(bookingId);

  // confirm same price
  Future<void> confirmPriceSame(String bookingId, double agreedPrice) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final batch = FirebaseFirestore.instance.batch();
    batch.update(_col.doc(bookingId), {
      'priceStatus': 'approved',
      'approvedTotalLkr': agreedPrice.round(),
      'priceConfirmedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    addTimelineEventToBatch(
      batch: batch,
      bookingId: bookingId,
      action: 'price_kept',
      title: 'Price Kept',
      description:
          'Provider confirmed initial quoted price of LKR ${agreedPrice.round()}',
      actorUid: uid,
      actorRole: 'provider',
    );

    await batch.commit();
  }

  // propose new price
  Future<void> proposeNewPrice(
    String bookingId,
    Map<String, dynamic> proposedPrice, {
    int currentProposalCount = 0,
  }) async {
    final snap = await _col.doc(bookingId).get();
    final data = snap.data();
    if (data != null) {
      if (data['priceStatus'] == 'rejected') {
        throw Exception('Cannot propose new price after customer rejected.');
      }
      if (data['quoteType'] == 'firm') {
        throw Exception('Cannot propose new price on a firm quote.');
      }
      final count =
          (data['proposalCount'] as num?)?.toInt() ?? currentProposalCount;
      if (count >= 3) {
        throw Exception('Maximum 3 proposals reached.');
      }
    }

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final batch = FirebaseFirestore.instance.batch();
    batch.update(_col.doc(bookingId), {
      'priceStatus': 'proposed',
      'proposedPrice': proposedPrice,
      'proposalCount': FieldValue.increment(1),
      'priceProposedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    addTimelineEventToBatch(
      batch: batch,
      bookingId: bookingId,
      action: 'price_proposed',
      title: 'Price Revised',
      description:
          'Provider proposed updated price of LKR ${proposedPrice['totalLkr']}',
      actorUid: uid,
      actorRole: 'provider',
      metadata: proposedPrice,
    );

    await batch.commit();

    NotificationService.instance.sendNotification(
      event: 'price_proposed',
      docId: bookingId,
    );
  }

  // customer responds to price proposal
  Future<void> customerRespondToProposedPrice(
    String bookingId, {
    required bool approve,
    required int totalLkr,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final batch = FirebaseFirestore.instance.batch();

    if (approve) {
      batch.update(_col.doc(bookingId), {
        'priceStatus': 'approved',
        'approvedTotalLkr': totalLkr,
        'priceApprovedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      addTimelineEventToBatch(
        batch: batch,
        bookingId: bookingId,
        action: 'price_approved',
        title: 'Price Approved',
        description: 'Customer approved revised price of LKR $totalLkr',
        actorUid: uid,
        actorRole: 'customer',
      );
    } else {
      batch.update(_col.doc(bookingId), {
        'priceStatus': 'rejected',
        'priceRejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      addTimelineEventToBatch(
        batch: batch,
        bookingId: bookingId,
        action: 'price_rejected',
        title: 'Price Rejected',
        description: 'Customer rejected revised price',
        actorUid: uid,
        actorRole: 'customer',
      );
    }

    await batch.commit();

    NotificationService.instance.sendNotification(
      event: 'price_responded',
      docId: bookingId,
    );
  }

  // propose extra work
  Future<String> proposeExtra({
    required String bookingId,
    required String customerId,
    required int amountLkr,
    required String description,
    List<String>? photos,
  }) async {
    if (amountLkr < 1 || amountLkr > 1000000) {
      throw Exception('Extra amount must be between LKR 1 and 1,000,000.');
    }
    if (description.isEmpty || description.length > 300) {
      throw Exception(
          'Extra description must be between 1 and 300 characters.');
    }
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final extraRef = _col.doc(bookingId).collection('extras').doc();

    final batch = FirebaseFirestore.instance.batch();
    batch.set(extraRef, {
      'providerId': uid,
      'customerId': customerId,
      'amountLkr': amountLkr,
      'description': description,
      if (photos != null && photos.isNotEmpty) 'photos': photos,
      'status': 'proposed',
      'createdAt': FieldValue.serverTimestamp(),
    });

    addTimelineEventToBatch(
      batch: batch,
      bookingId: bookingId,
      action: 'extra_requested',
      title: 'Extra Work Requested',
      description: 'Provider requested extra LKR $amountLkr: $description',
      actorUid: uid,
      actorRole: 'provider',
      metadata: {'amountLkr': amountLkr, 'description': description},
    );

    await batch.commit();

    NotificationService.instance.sendNotification(
      event: 'extra_requested',
      docId: bookingId,
    );

    return extraRef.id;
  }

  // customer responds to extra
  Future<void> customerRespondToExtra({
    required String bookingId,
    required String extraId,
    required int extraAmountLkr,
    required bool approve,
    required int currentApprovedExtrasLkr,
    required int currentApprovedTotalLkr,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final extraRef = _col.doc(bookingId).collection('extras').doc(extraId);
    final batch = FirebaseFirestore.instance.batch();

    if (approve) {
      batch.update(extraRef, {
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });
      batch.update(_col.doc(bookingId), {
        'approvedExtrasLkr': currentApprovedExtrasLkr + extraAmountLkr,
        'approvedTotalLkr': currentApprovedTotalLkr + extraAmountLkr,
        'lastApprovedExtraId': extraId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      addTimelineEventToBatch(
        batch: batch,
        bookingId: bookingId,
        action: 'extra_approved',
        title: 'Extra Work Approved',
        description: 'Customer approved extra LKR $extraAmountLkr',
        actorUid: uid,
        actorRole: 'customer',
      );
    } else {
      batch.update(extraRef, {
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });
      addTimelineEventToBatch(
        batch: batch,
        bookingId: bookingId,
        action: 'extra_rejected',
        title: 'Extra Work Rejected',
        description: 'Customer rejected extra work request',
        actorUid: uid,
        actorRole: 'customer',
      );
    }

    await batch.commit();

    NotificationService.instance.sendNotification(
      event: 'extra_responded',
      docId: bookingId,
    );
  }

  // stream extras
  Stream<List<BookingExtra>> streamExtras(String bookingId) {
    if (bookingId.isEmpty) return Stream.value([]);
    return _col.doc(bookingId).collection('extras').snapshots().map((snap) {
      final list =
          snap.docs.map((d) => BookingExtra.fromMap(d.id, d.data())).toList();
      list.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return list;
    });
  }
}
