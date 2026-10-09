import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../constants/firestore_paths.dart';
import '../constants/job_status.dart';
import '../models/booking.dart';
import '../models/booking_timeline_event.dart';
import '../services/notification_service.dart';

class PinVerificationResult {
  final bool success;
  final int attempts;
  final String? errorMessage;
  const PinVerificationResult({
    required this.success,
    this.attempts = 0,
    this.errorMessage,
  });
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
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? booking.customerId;
    final pin = (100000 + Random().nextInt(900000)).toString();

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

    String? linkedJobRequestId = booking.jobRequestId;

    if (linkedJobRequestId == null || linkedJobRequestId.isEmpty) {
      // create linked job request for direct booking
      final jobReqRef = FirebaseFirestore.instance.collection(FirestorePaths.jobRequests).doc();
      final quoteRef = jobReqRef.collection(FirestorePaths.quotes).doc();
      linkedJobRequestId = jobReqRef.id;

      final roundedLat = booking.customerLatitude != null
          ? double.parse(booking.customerLatitude!.toStringAsFixed(2))
          : null;
      final roundedLng = booking.customerLongitude != null
          ? double.parse(booking.customerLongitude!.toStringAsFixed(2))
          : null;

      batch.set(jobReqRef, {
        'customerId': currentUid,
        'customerName': booking.customerName,
        'title': booking.title,
        'category': 'General',
        'description': booking.entryInstructions != null && booking.entryInstructions!.isNotEmpty
            ? 'Direct booking with ${booking.providerName}. Note: ${booking.entryInstructions}'
            : 'Direct booking with ${booking.providerName}',
        if (roundedLat != null) 'latitude': roundedLat,
        if (roundedLng != null) 'longitude': roundedLng,
        'status': JobRequestStatus.pendingProvider,
        'selectedProviderId': booking.providerId,
        'acceptedQuoteId': quoteRef.id,
        'agreedPrice': rateNum,
        'quoteCount': 1,
        'bookingId': bookingRef.id,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final jobReqContactRef = jobReqRef.collection('private').doc('contact');
      batch.set(jobReqContactRef, {
        'customerPhone': booking.customerPhone,
        'address': booking.location,
        'landmark': booking.entryInstructions ?? '',
        'latitude': booking.customerLatitude,
        'longitude': booking.customerLongitude,
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.set(quoteRef, {
        'providerId': booking.providerId,
        'providerName': booking.providerName,
        'providerPhone': booking.providerPhone,
        'quotedPrice': rateNum,
        'etaMinutes': 30,
        'status': 'pending_provider',
        'createdBy': currentUid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    final bookingData = booking.toMap();
    bookingData['customerId'] = currentUid;
    bookingData['jobRequestId'] = linkedJobRequestId;
    bookingData['agreedPrice'] = rateNum;
    bookingData['status'] = JobStatus.pending;
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
    batch.update(_col.doc(bookingId), {
      'status': JobStatus.declined,
      'declinedAt': FieldValue.serverTimestamp(),
      'declineReason': reason ?? 'Provider unavailable',
    });

    if (jobRequestId != null && jobRequestId.isNotEmpty) {
      final reqRef = FirebaseFirestore.instance
          .collection(FirestorePaths.jobRequests)
          .doc(jobRequestId);
      batch.update(reqRef, {
        'status': JobRequestStatus.cancelled,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    addTimelineEventToBatch(
      batch: batch,
      bookingId: bookingId,
      action: 'declined',
      title: 'Provider Declined',
      description: reason ?? 'Provider unavailable',
      actorUid: uid,
      actorRole: 'provider',
    );

    await batch.commit();
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

  // provider confirms arrival
  Future<void> confirmArrival({
    required String bookingId,
    String? jobRequestId,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final batch = FirebaseFirestore.instance.batch();
    batch.update(_col.doc(bookingId), {
      'status': JobStatus.inProgress,
      'arrivedAt': FieldValue.serverTimestamp(),
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
      action: 'arrived',
      title: 'Provider Arrived',
      description: 'Provider arrived and started work',
      actorUid: uid,
      actorRole: 'provider',
    );

    await batch.commit();

    // send arrival alert
    NotificationService.instance.sendNotification(
      event: 'booking_arrived',
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
  }) async {
    final cleanPin = enteredPin.trim();
    if (cleanPin.length != 6 && cleanPin.length != 4) {
      return const PinVerificationResult(
        success: false,
        errorMessage: 'PIN must be 6 digits.',
      );
    }

    try {
      final docSnap = await _col.doc(bookingId).get();
      if (!docSnap.exists) {
        return const PinVerificationResult(
          success: false,
          errorMessage: 'Booking not found.',
        );
      }

      final currentAttempts =
          (docSnap.data()?['pinAttempts'] as num?)?.toInt() ?? 0;
      if (currentAttempts >= 5) {
        return const PinVerificationResult(
          success: false,
          attempts: 5,
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
      if (finalAmount != null && finalAmount > 0) {
        updateData['finalAmount'] = finalAmount;
      }
      if (paymentNote != null && paymentNote.trim().isNotEmpty) {
        updateData['paymentNote'] = paymentNote.trim();
      }

      batch.update(_col.doc(bookingId), updateData);

      final reqId = jobRequestId;
      if (reqId != null && reqId.isNotEmpty) {
        final reqRef = FirebaseFirestore.instance
            .collection(FirestorePaths.jobRequests)
            .doc(reqId);
        batch.update(reqRef, {
          'status': JobRequestStatus.completed,
          'completedAt': FieldValue.serverTimestamp(),
        });
      }

      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      addTimelineEventToBatch(
        batch: batch,
        bookingId: bookingId,
        action: 'completed',
        title: 'Job Completed',
        description: finalAmount != null
            ? 'Work finished. Cash collected: LKR ${finalAmount.toStringAsFixed(0)}'
            : 'Work finished and verified with PIN',
        actorUid: uid,
        actorRole: 'provider',
        metadata: {
          if (finalAmount != null) 'finalAmount': finalAmount,
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
      int attempts = 1;
      try {
        final snap = await _col.doc(bookingId).get();
        attempts = (snap.data()?['pinAttempts'] as num?)?.toInt() ?? 1;
      } catch (_) {}

      if (attempts >= 5) {
        return const PinVerificationResult(
          success: false,
          attempts: 5,
          errorMessage:
              'Too many wrong PINs. Ask the customer to reset the PIN attempts in their booking.',
        );
      }
      return PinVerificationResult(
        success: false,
        attempts: attempts,
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
  Future<void> disputePayment(String bookingId, {required String reason}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final batch = FirebaseFirestore.instance.batch();
    batch.update(_col.doc(bookingId), {
      'paymentDisputed': true,
      'paymentDisputeReason': reason,
      'paymentDisputedAt': FieldValue.serverTimestamp(),
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
    await batch.commit();
  }

  // reset pin attempt count
  Future<void> resetPinAttempts(String bookingId) async {
    await _col.doc(bookingId).update({'pinAttempts': 0});
  }

  // cancel booking
  Future<void> cancelBooking({
    required String bookingId,
    required String reason,
    required String cancelledBy,
    String? jobRequestId,
  }) async {
    final doc = await _col.doc(bookingId).get();
    if (!doc.exists) throw Exception('Booking not found');
    final currentStatus = doc.data()?['status'] as String? ?? JobStatus.pending;

    if (!JobStatus.canCancel(currentStatus)) {
      throw Exception('Cannot cancel booking in progress. Please contact support.');
    }

    final batch = FirebaseFirestore.instance.batch();
    batch.update(_col.doc(bookingId), {
      'status': JobStatus.cancelled,
      'cancellationReason': reason,
      'cancelledBy': cancelledBy,
      'cancelledAt': FieldValue.serverTimestamp(),
    });

    final reqId = jobRequestId ?? doc.data()?['jobRequestId'] as String?;
    if (reqId != null && reqId.isNotEmpty) {
      final reqRef = FirebaseFirestore.instance
          .collection(FirestorePaths.jobRequests)
          .doc(reqId);
      batch.update(reqRef, {
        'status': JobRequestStatus.cancelled,
        'cancellationReason': reason,
        'cancelledBy': cancelledBy,
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    }

    addTimelineEventToBatch(
      batch: batch,
      bookingId: bookingId,
      action: 'cancelled',
      title: 'Booking Cancelled',
      description: reason,
      actorUid: cancelledBy,
      actorRole: 'user',
      metadata: {'reason': reason, 'cancelledBy': cancelledBy},
    );

    await batch.commit();
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
      final items = snap.docs.map((d) => Booking.fromMap(d.id, d.data())).toList();
      items.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return items;
    });
  }

  Stream<List<Booking>> streamBookingsForProvider(String providerId, {int limit = 50}) {
    return _col.where('providerId', isEqualTo: providerId).limit(limit).snapshots().map((snap) {
      final items = snap.docs.map((d) => Booking.fromMap(d.id, d.data())).toList();
      items.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return items;
    });
  }

  Stream<List<Booking>> streamProviderBookings(String providerId, {int limit = 50}) =>
      streamBookingsForProvider(providerId, limit: limit);

  Stream<List<Booking>> streamBookingsForCustomer(String customerId, {int limit = 50}) {
    return _col.where('customerId', isEqualTo: customerId).limit(limit).snapshots().map((snap) {
      final items = snap.docs.map((d) => Booking.fromMap(d.id, d.data())).toList();
      items.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return items;
    });
  }

  Stream<List<Booking>> streamCustomerBookings(String customerId, {int limit = 50}) =>
      streamBookingsForCustomer(customerId, limit: limit);

  Stream<Booking?> streamBooking(String bookingId) {
    if (bookingId.isEmpty) return Stream.value(null);
    return _col.doc(bookingId).snapshots().map((snap) {
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

  Future<void> reportDelay(String bookingId, {required String reason, required int delayMinutes}) async {
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
      description: '$actorRole requested reschedule to ${proposedDate.year}/${proposedDate.month}/${proposedDate.day} $proposedSlot. Reason: $reason',
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
      updates['time'] = '${proposedDate.year}/${proposedDate.month}/${proposedDate.day} $proposedSlot';
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
      description: '$actorRole declined the proposed reschedule${declineReason != null ? ': $declineReason' : ''}',
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
  Stream<Booking?> streamBookingById(String bookingId) => streamBooking(bookingId);
}


