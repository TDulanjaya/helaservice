import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/firestore_paths.dart';
import '../constants/job_status.dart';
import '../models/job_request.dart';
import '../models/quote.dart';
import '../services/notification_service.dart';
import '../services/session_guard.dart';
import '../utils/exact_location_helper.dart';
import '../utils/schedule_helpers.dart';
import 'booking_repository.dart';

enum CannotQuoteReason {
  declined,
  cancelledByProvider,
  alreadyAccepted,
  generic,
}

class CannotQuoteException implements Exception {
  final CannotQuoteReason reason;
  final String? message;
  const CannotQuoteException(this.reason, [this.message]);

  @override
  String toString() => 'CannotQuoteException: $reason ($message)';
}

class JobRequestRepository {
  final FirebaseFirestore? _customFirestore;

  JobRequestRepository({FirebaseFirestore? firestore})
      : _customFirestore = firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      (_customFirestore ?? FirebaseFirestore.instance)
          .collection(FirestorePaths.jobRequests);

  Future<String> createJobRequest(JobRequest request) async {
    final docRef = _col.doc();
    final batch = FirebaseFirestore.instance.batch();

    // public job request doc with rounded coordinates
    final publicData = request.toMap();
    publicData.remove('customerPhone');
    publicData.remove('address');
    publicData.remove('landmark');
    publicData.remove('houseNo');
    publicData.remove('street');
    publicData.remove('city');
    publicData.remove('directions');
    publicData.remove('accuracyMeters');
    publicData.remove('note');
    if (request.latitude != null) {
      publicData['latitude'] =
          double.parse(request.latitude!.toStringAsFixed(2));
    }
    if (request.longitude != null) {
      publicData['longitude'] =
          double.parse(request.longitude!.toStringAsFixed(2));
    }

    batch.set(docRef, publicData);

    // private contact doc
    final contactRef = docRef.collection('private').doc('contact');
    final noteText = (request.note != null && request.note!.isNotEmpty)
        ? request.note!
        : (request.landmark ?? '');
    batch.set(contactRef, {
      'customerPhone': request.customerPhone,
      'address': request.address,
      if (noteText.isNotEmpty) 'note': noteText,
      'landmark': noteText,
      'latitude': request.latitude,
      'longitude': request.longitude,
      if (request.accuracyMeters != null)
        'accuracyMeters': request.accuracyMeters,
      if (request.houseNo != null && request.houseNo!.isNotEmpty)
        'houseNo': request.houseNo,
      if (request.street != null && request.street!.isNotEmpty)
        'street': request.street,
      if (request.city != null && request.city!.isNotEmpty)
        'city': request.city,
      if (request.directions != null && request.directions!.isNotEmpty)
        'directions': request.directions,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final commitFuture = batch.commit();
    try {
      await commitFuture.timeout(const Duration(seconds: 15));
    } on TimeoutException {
      debugPrint(
          '[JobRequestRepo] batch commit timed out after 15s; queued write pending');
      commitFuture.catchError((e) {
        debugPrint('[JobRequestRepo] background commit failed: $e');
      });
    }

    return docRef.id;
  }

  Stream<List<JobRequest>> streamOpenRequests({int limit = 50}) {
    return _col
        .where('status', isEqualTo: JobRequestStatus.open)
        .limit(limit)
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => JobRequest.fromMap(d.id, d.data())).toList();
      list.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return list;
    });
  }

  Stream<List<JobRequest>> streamOpenRequestsForCategory(String category,
      {int limit = 50}) {
    return _col
        .where('status', isEqualTo: JobRequestStatus.open)
        .where('category', isEqualTo: category)
        .limit(limit)
        .snapshots()
        .withSessionGuard()
        .map((snap) {
      final items =
          snap.docs.map((d) => JobRequest.fromMap(d.id, d.data())).toList();
      items.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return items;
    });
  }

  Stream<List<JobRequest>> streamCustomerRequests(String customerId,
      {int limit = 50}) {
    if (customerId.isEmpty) return Stream.value(const []);
    return _col
        .where('customerId', isEqualTo: customerId)
        .limit(limit)
        .snapshots()
        .withSessionGuard()
        .map((snap) {
      final items =
          snap.docs.map((d) => JobRequest.fromMap(d.id, d.data())).toList();
      items.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return items;
    });
  }

  Stream<JobRequest?> streamJobRequest(String requestId) {
    return _col.doc(requestId).snapshots().withSessionGuard().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return JobRequest.fromMap(snap.id, snap.data()!);
    });
  }

  // stream raw snapshot with metadata for pending write tracking
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamJobRequestSnapshot(
      String requestId) {
    return _col.doc(requestId).snapshots(includeMetadataChanges: true);
  }

  Future<JobRequest?> getById(String requestId) async {
    final doc = await _col.doc(requestId).get();
    if (!doc.exists || doc.data() == null) return null;
    return JobRequest.fromMap(doc.id, doc.data()!);
  }

  Future<Quote?> getQuoteForProvider(
      String requestId, String providerId) async {
    final doc = await _col
        .doc(requestId)
        .collection(FirestorePaths.quotes)
        .doc(providerId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return Quote.fromMap(doc.id, doc.data()!);
  }

  Future<void> submitQuote(String requestId, Quote quote) async {
    final quoteRef = _col
        .doc(requestId)
        .collection(FirestorePaths.quotes)
        .doc(quote.providerId);
    final existingSnap = await quoteRef.get();
    final batch = FirebaseFirestore.instance.batch();

    if (existingSnap.exists) {
      final existingStatus = existingSnap.data()?['status'] as String?;
      if (existingStatus == 'declined' || existingStatus == 'not_selected') {
        throw const CannotQuoteException(CannotQuoteReason.declined);
      }
      if (existingStatus == 'cancelled_by_provider') {
        throw const CannotQuoteException(CannotQuoteReason.cancelledByProvider);
      }
      if (existingStatus == 'accepted') {
        throw const CannotQuoteException(CannotQuoteReason.alreadyAccepted);
      }
      if (existingStatus != 'job_closed' &&
          existingStatus != 'withdrawn' &&
          existingStatus != 'pending') {
        throw const CannotQuoteException(CannotQuoteReason.generic);
      }

      final updateData = quote.toMap();
      updateData['status'] = 'pending';
      updateData['updatedAt'] = FieldValue.serverTimestamp();
      if (quote.quoteType == 'inspect') {
        updateData['priceUnit'] = FieldValue.delete();
        updateData['unitRateLkr'] = FieldValue.delete();
        updateData['quantity'] = FieldValue.delete();
        updateData['materialsEstimateLkr'] = FieldValue.delete();
      } else if (quote.materialsEstimateLkr == null) {
        updateData['materialsEstimateLkr'] = FieldValue.delete();
      }
      updateData.remove('createdAt');
      updateData.remove('providerId');
      updateData.remove('requestId');
      updateData.remove('jobRequestId');
      updateData.remove('createdBy');
      batch.update(quoteRef, updateData);
    } else {
      batch.set(quoteRef, quote.toMap());
      batch.update(_col.doc(requestId), {
        'quoteCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    // send alert to customer
    NotificationService.instance.sendNotification(
      event: 'quote_received',
      docId: requestId,
    );
  }

  Stream<List<Quote>> streamQuotesForRequest(String requestId) {
    return _col
        .doc(requestId)
        .collection(FirestorePaths.quotes)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => Quote.fromMap(d.id, d.data())).toList();
      list.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return list;
    });
  }

  Future<String> acceptQuote({
    required String requestId,
    required String quoteId,
    required String providerId,
    required double agreedPrice,
    JobRequest? request,
    Quote? quote,
  }) async {
    if (request == null ||
        request.latitude == null ||
        request.longitude == null) {
      throw Exception('JOB_LOCATION_MISSING');
    }

    // stop if slot has already passed
    DateTime? scheduledStartAt;
    if (request.scheduledEndAt != null) {
      if (request.scheduledEndAt!.isBefore(DateTime.now())) {
        throw 'SCHEDULE_PASSED';
      }
    } else if (request.scheduledDate != null) {
      scheduledStartAt = computeScheduledStartAt(
        request.scheduledDate!,
        request.scheduledSlot,
      );
      if (scheduledStartAt
          .isBefore(DateTime.now().subtract(const Duration(minutes: 15)))) {
        throw 'SCHEDULE_PASSED';
      }
    }

    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final custId =
        request.customerId.isNotEmpty == true ? request.customerId : currentUid;

    final quoteDoc = await _col
        .doc(requestId)
        .collection(FirestorePaths.quotes)
        .doc(quoteId)
        .get();
    if (!quoteDoc.exists) {
      throw Exception('This quote is no longer available');
    }
    final quoteData = quoteDoc.data();
    final quoteStatus = quoteData?['status'] as String?;
    if (quoteStatus != 'pending') {
      throw Exception('This quote is no longer available');
    }
    final rawQuoteType = quoteData?['quoteType'] as String?;
    if (rawQuoteType == null || rawQuoteType.isEmpty) {
      try {
        await _col
            .doc(requestId)
            .collection(FirestorePaths.quotes)
            .doc(quoteId)
            .update({
          'status': 'declined',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
      throw Exception('QUOTE_OUTDATED');
    }

    final resolvedQuote = quote ?? Quote.fromMap(quoteId, quoteData!);

    // fetch private customer coordinates
    Map<String, dynamic>? contactData;
    try {
      final contactSnap =
          await _col.doc(requestId).collection('private').doc('contact').get();
      contactData = contactSnap.data();
    } catch (_) {}

    // retry once if contact coordinates were missing or invalid
    if (!ExactLocationHelper.validate(contactData)) {
      await Future.delayed(const Duration(milliseconds: 300));
      try {
        final retrySnap = await _col
            .doc(requestId)
            .collection('private')
            .doc('contact')
            .get();
        contactData = retrySnap.data();
      } catch (_) {}
    }

    if (!ExactLocationHelper.validate(contactData)) {
      throw const ExactLocationUnavailableException();
    }

    final exactLat = (contactData!['latitude'] as num).toDouble();
    final exactLng = (contactData['longitude'] as num).toDouble();
    final exactPhone =
        (contactData['customerPhone'] as String?)?.isNotEmpty == true
            ? contactData['customerPhone'] as String
            : request.customerPhone;
    final exactAddress = (contactData['address'] as String?)?.isNotEmpty == true
        ? contactData['address'] as String
        : (request.address.isNotEmpty ? request.address : 'Service Location');
    final exactLandmark =
        (contactData['landmark'] as String?) ?? request.landmark ?? '';
    final accuracyMeters =
        (contactData['accuracyMeters'] as num?)?.toDouble() ??
            request.accuracyMeters;
    final houseNo = (contactData['houseNo'] as String?) ?? request.houseNo;
    final street = (contactData['street'] as String?) ?? request.street;
    final city = (contactData['city'] as String?) ?? request.city;
    final directions =
        (contactData['directions'] as String?) ?? request.directions;

    final pin = (100000 + Random().nextInt(900000)).toString();

    final batch = FirebaseFirestore.instance.batch();
    final bookingRef =
        FirebaseFirestore.instance.collection(FirestorePaths.bookings).doc();
    final pinRef = bookingRef.collection('private').doc('pin');

    batch.set(pinRef, {
      'pin': pin,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.update(_col.doc(requestId), {
      'status': JobRequestStatus.assigned,
      'selectedProviderId': providerId,
      'acceptedQuoteId': quoteId,
      'agreedPrice': agreedPrice,
      'bookingId': bookingRef.id,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final quotesCol = _col.doc(requestId).collection(FirestorePaths.quotes);
    batch.update(quotesCol.doc(quoteId), {'status': 'accepted'});

    // get provider phone for contact info
    String providerPhone = resolvedQuote.providerPhone;
    if (providerPhone.isEmpty) {
      try {
        final techDoc = await FirebaseFirestore.instance
            .collection(FirestorePaths.technicians)
            .doc(providerId)
            .get();
        if (techDoc.exists && techDoc.data() != null) {
          providerPhone = (techDoc.data()?['phone'] as String?) ?? '';
        }
      } catch (_) {}
    }

    final bookingPrice = resolvedQuote.quotedPrice.round();

    final bookingData = <String, dynamic>{
      'customerId': custId,
      'providerId': providerId,
      'providerName': resolvedQuote.providerName,
      'status': JobStatus.confirmed,
      'createdAt': FieldValue.serverTimestamp(),
      'time': 'Scheduled Now',
      'relativeTime': 'Just now',
      'title': request.title.isNotEmpty == true
          ? request.title
          : 'Domestic Service Request',
      'estRate': 'LKR $bookingPrice',
      'agreedPrice': bookingPrice,
      'customerName': request.customerName.isNotEmpty == true
          ? request.customerName
          : 'Customer',
      'customerInitials': request.customerName.isNotEmpty
          ? request.customerName[0].toUpperCase()
          : 'C',
      'customerPhone': exactPhone,
      'providerPhone': providerPhone,
      'customerLatitude': exactLat,
      'customerLongitude': exactLng,
      'location': exactAddress,
      'entryInstructions': exactLandmark,
      'distance': '${resolvedQuote.etaMinutes} mins ETA',
      'jobRequestId': requestId,
      'quoteId': quoteId,
      'quoteType': resolvedQuote.quoteType,
      'priceStatus': resolvedQuote.quoteType == 'firm'
          ? 'approved'
          : 'awaiting_confirmation',
      if (resolvedQuote.quoteType == 'firm')
        'approvedTotalLkr': resolvedQuote.quotedPrice.round(),
      if (resolvedQuote.priceUnit != null) 'priceUnit': resolvedQuote.priceUnit,
      if (resolvedQuote.unitRateLkr != null)
        'unitRateLkr': resolvedQuote.unitRateLkr,
      if (resolvedQuote.quantity != null) 'quantity': resolvedQuote.quantity,
      if (resolvedQuote.materialsEstimateLkr != null)
        'materialsEstimateLkr': resolvedQuote.materialsEstimateLkr,
      'visitFeeLkr': resolvedQuote.visitFeeLkr,
      'travelKm': resolvedQuote.travelKm,
      'travelRateLkr': resolvedQuote.travelRateLkr,
      'travelCostLkr': resolvedQuote.travelCostLkr,
      'estimatedTotalLkr': resolvedQuote.quotedPrice.round(),
      'approvedExtrasLkr': 0,
      'proposalCount': 0,
      'type': request.bookingType,
      'scheduleMode': request.scheduleMode,
      if (request.scheduleMode == 'flexible' &&
          resolvedQuote.proposedStartAt != null) ...{
        'scheduledDate': Timestamp.fromDate(DateTime(
          resolvedQuote.proposedStartAt!.year,
          resolvedQuote.proposedStartAt!.month,
          resolvedQuote.proposedStartAt!.day,
        )),
        'scheduledStartAt': Timestamp.fromDate(resolvedQuote.proposedStartAt!),
        if (resolvedQuote.proposedEndAt != null)
          'scheduledEndAt': Timestamp.fromDate(resolvedQuote.proposedEndAt!),
        if (resolvedQuote.proposedSlot != null &&
            resolvedQuote.proposedSlot!.isNotEmpty)
          'scheduledSlot': resolvedQuote.proposedSlot,
      } else ...{
        if (request.scheduledDate != null)
          'scheduledDate': Timestamp.fromDate(request.scheduledDate!),
        if (request.scheduledStartAt != null)
          'scheduledStartAt': Timestamp.fromDate(request.scheduledStartAt!)
        else if (scheduledStartAt != null)
          'scheduledStartAt': Timestamp.fromDate(scheduledStartAt),
        if (request.scheduledEndAt != null)
          'scheduledEndAt': Timestamp.fromDate(request.scheduledEndAt!),
        if (request.scheduledSlot != null && request.scheduledSlot!.isNotEmpty)
          'scheduledSlot': request.scheduledSlot,
      },
      if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
      if (houseNo != null && houseNo.isNotEmpty) 'houseNo': houseNo,
      if (street != null && street.isNotEmpty) 'street': street,
      if (city != null && city.isNotEmpty) 'city': city,
      if (directions != null && directions.isNotEmpty) 'directions': directions,
    };

    batch.set(bookingRef, bookingData);

    // timeline event
    final eventRef = bookingRef.collection('timeline').doc();
    batch.set(eventRef, {
      'action': 'created',
      'title': 'Booking Confirmed',
      'description':
          'Customer accepted quote from ${resolvedQuote.providerName}',
      'timestamp': FieldValue.serverTimestamp(),
      'actorUid': custId,
      'actorRole': 'customer',
    });

    await batch.commit();

    // notify provider that quote was accepted
    NotificationService.instance.sendNotification(
      event: 'quote_accepted',
      docId: requestId,
    );

    return bookingRef.id;
  }

  Future<void> withdrawQuote(String requestId, String quoteId) async {
    final quoteRef =
        _col.doc(requestId).collection(FirestorePaths.quotes).doc(quoteId);
    await quoteRef.update({
      'status': 'withdrawn',
      'withdrawnAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getJobContact(String requestId) async {
    final doc =
        await _col.doc(requestId).collection('private').doc('contact').get();
    return doc.data();
  }

  Future<void> updateJobLocation({
    required String requestId,
    required double latitude,
    required double longitude,
    required String address,
    String? landmark,
    String? note,
    String? district,
  }) async {
    final roundedLat = double.parse(latitude.toStringAsFixed(2));
    final roundedLng = double.parse(longitude.toStringAsFixed(2));
    final effectiveNote = (note != null && note.isNotEmpty) ? note : landmark;

    final batch = FirebaseFirestore.instance.batch();
    batch.update(_col.doc(requestId), {
      'latitude': roundedLat,
      'longitude': roundedLng,
      if (district != null) 'district': district,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
        _col.doc(requestId).collection('private').doc('contact'),
        {
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          if (effectiveNote != null) 'note': effectiveNote,
          if (effectiveNote != null) 'landmark': effectiveNote,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> updateJobSchedule({
    required String requestId,
    required DateTime scheduledDate,
    String? scheduledSlot,
    String? scheduleMode,
    DateTime? scheduledStartAt,
    DateTime? scheduledEndAt,
  }) async {
    await _col.doc(requestId).update({
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      if (scheduledSlot != null && scheduledSlot.isNotEmpty)
        'scheduledSlot': scheduledSlot,
      if (scheduleMode != null) 'scheduleMode': scheduleMode,
      if (scheduledStartAt != null)
        'scheduledStartAt': Timestamp.fromDate(scheduledStartAt),
      if (scheduledEndAt != null)
        'scheduledEndAt': Timestamp.fromDate(scheduledEndAt),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Quote>> streamProviderQuotes(String providerId,
      {int limit = 50}) {
    return FirebaseFirestore.instance
        .collectionGroup(FirestorePaths.quotes)
        .where('providerId', isEqualTo: providerId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .withSessionGuard()
        .map((snap) =>
            snap.docs.map((d) => Quote.fromMap(d.id, d.data())).toList());
  }

  Stream<List<JobRequest>> streamAllCustomerRequests(
      {String? statusFilter, int limit = 50}) {
    Query query = _col.orderBy('createdAt', descending: true).limit(limit);
    if (statusFilter != null && statusFilter != 'all') {
      query = _col
          .where('status', isEqualTo: statusFilter)
          .orderBy('createdAt', descending: true)
          .limit(limit);
    }
    return query.snapshots().withSessionGuard().map((snap) => snap.docs
        .map((d) => JobRequest.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  @Deprecated(
      'Use BookingCancellationSheet and BookingRepository.cancelBooking instead')
  Future<void> cancelAssignedJob({
    required String requestId,
    required String reason,
    String? bookingId,
    String? quoteId,
    String? cancelledBy,
    String? cancelledByRole,
  }) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final effectiveUid = (cancelledBy != null &&
            cancelledBy.isNotEmpty &&
            cancelledBy != 'customer' &&
            cancelledBy != 'provider')
        ? cancelledBy
        : currentUid;
    final isCustomerCancelling = cancelledByRole == 'customer';
    final role = isCustomerCancelling ? 'customer' : 'provider';

    // locate booking id if not passed
    String? resolvedBookingId = bookingId;
    if (resolvedBookingId == null || resolvedBookingId.isEmpty) {
      final reqDoc = await _col.doc(requestId).get();
      resolvedBookingId = reqDoc.data()?['bookingId'] as String?;
      if (resolvedBookingId == null || resolvedBookingId.isEmpty) {
        final bSnap = await FirebaseFirestore.instance
            .collection(FirestorePaths.bookings)
            .where('jobRequestId', isEqualTo: requestId)
            .where(
              role == 'customer' ? 'customerId' : 'providerId',
              isEqualTo: effectiveUid,
            )
            .limit(1)
            .get();
        if (bSnap.docs.isNotEmpty) {
          resolvedBookingId = bSnap.docs.first.id;
        }
      }
    }

    if (resolvedBookingId != null && resolvedBookingId.isNotEmpty) {
      await BookingRepository().cancelBooking(
        bookingId: resolvedBookingId,
        reason: reason,
        cancelledBy: effectiveUid,
        cancelledByRole: role,
        jobRequestId: requestId,
        chooseAnotherQuote: false,
      );
    }
  }

  Future<void> renewJobPost({
    required String requestId,
    required String scheduleMode,
    DateTime? scheduledDate,
    DateTime? scheduledStartAt,
    DateTime? scheduledEndAt,
    String? scheduledSlot,
    int? flexibleWindowDays,
    DateTime? expiresAt,
    List<JobMediaItem>? sanitizedPhotos,
    bool dropVideo = false,
  }) async {
    final docRef = _col.doc(requestId);

    final now = DateTime.now();
    final resolvedExpiresAt = (expiresAt != null && expiresAt.isAfter(now))
        ? expiresAt
        : ScheduleHelpers.endOfDay(scheduledDate ?? now);

    DateTime? effectiveStartAt = scheduledStartAt;
    DateTime? effectiveEndAt = scheduledEndAt;
    final isToday = (scheduledDate != null &&
            ScheduleHelpers.isToday(scheduledDate)) ||
        (effectiveStartAt != null && ScheduleHelpers.isToday(effectiveStartAt));
    if (isToday && effectiveStartAt != null && effectiveEndAt != null) {
      // defensively clamp start to now if scheduled for today
      final clamped = ScheduleHelpers.clampWindowToNow(
        startAt: effectiveStartAt,
        endAt: effectiveEndAt,
        nowOverride: now,
      );
      if (!clamped.hasPassed) {
        effectiveStartAt = clamped.startAt;
        effectiveEndAt = clamped.endAt;
      }
    }

    final data = <String, dynamic>{
      'status': JobRequestStatus.open,
      'scheduleMode': scheduleMode,
      'bookingType': scheduleMode == 'today' ? 'asap' : 'scheduled',
      'renewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'mediaWarningSentAt': FieldValue.delete(),
      'expiresAt': Timestamp.fromDate(resolvedExpiresAt),
    };

    if (scheduledDate != null) {
      data['scheduledDate'] = Timestamp.fromDate(scheduledDate);
    }
    if (effectiveStartAt != null) {
      data['scheduledStartAt'] = Timestamp.fromDate(effectiveStartAt);
    } else {
      data['scheduledStartAt'] = FieldValue.delete();
    }
    if (effectiveEndAt != null) {
      data['scheduledEndAt'] = Timestamp.fromDate(effectiveEndAt);
    } else {
      data['scheduledEndAt'] = FieldValue.delete();
    }
    if (scheduledSlot != null && scheduledSlot.isNotEmpty) {
      data['scheduledSlot'] = scheduledSlot;
    } else {
      data['scheduledSlot'] = FieldValue.delete();
    }
    if (flexibleWindowDays != null) {
      data['flexibleWindowDays'] = flexibleWindowDays;
    } else {
      data['flexibleWindowDays'] = FieldValue.delete();
    }
    if (sanitizedPhotos != null) {
      data['photos'] = sanitizedPhotos.map((p) => p.toMap()).toList();
      data['photoUrls'] = sanitizedPhotos.map((p) => p.url).toList();
    }
    if (dropVideo) {
      data['video'] = FieldValue.delete();
    }

    if (kDebugMode) {
      debugPrint('[JobRequestRepo] renewJobPost update map keys and value types:');
      data.forEach((key, value) {
        debugPrint('  $key: ${value.runtimeType}');
      });
    }

    await docRef.update(data);

    unawaited(
      NotificationService.instance
          .sendNotification(
            event: 'job_posted',
            docId: requestId,
          )
          .catchError((e) {
        debugPrint('[JobRequestRepo] renew alert error: $e');
        return false;
      }),
    );
  }

  Future<void> deleteJobPost(String requestId, {String? previousStatus}) async {
    await _col.doc(requestId).update({
      'status': 'deleted',
      if (previousStatus != null && previousStatus.isNotEmpty)
        'previousStatus': previousStatus,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> undoDeleteJobPost(
      String requestId, String previousStatus) async {
    await _col.doc(requestId).update({
      'status': previousStatus,
      'deletedAt': FieldValue.delete(),
      'previousStatus': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> hideJobPostFromCustomer(String requestId) async {
    await _col.doc(requestId).update({
      'hiddenByCustomer': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getJobPrivateContact(String requestId) async {
    final doc =
        await _col.doc(requestId).collection('private').doc('contact').get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  Future<void> updateJobPost({
    required String requestId,
    required String title,
    required String description,
    required String scheduleMode,
    DateTime? scheduledDate,
    DateTime? scheduledStartAt,
    DateTime? scheduledEndAt,
    String? scheduledSlot,
    int? flexibleWindowDays,
    List<JobMediaItem>? photos,
    JobVideoItem? video,
    bool updateLocation = false,
    double? latitude,
    double? longitude,
    String? district,
    String? address,
    String? landmark,
    String? note,
    String? houseNo,
    String? street,
    String? city,
    String? directions,
    double? accuracyMeters,
    bool hasQuotes = false,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    final jobRef = _col.doc(requestId);

    final Map<String, dynamic> jobUpdates = {
      'title': title,
      'description': description,
      'scheduleMode': scheduleMode,
      if (scheduledDate != null)
        'scheduledDate': Timestamp.fromDate(scheduledDate),
      if (scheduledStartAt != null)
        'scheduledStartAt': Timestamp.fromDate(scheduledStartAt),
      if (scheduledEndAt != null)
        'scheduledEndAt': Timestamp.fromDate(scheduledEndAt),
      if (scheduledSlot != null && scheduledSlot.isNotEmpty)
        'scheduledSlot': scheduledSlot,
      if (flexibleWindowDays != null) 'flexibleWindowDays': flexibleWindowDays,
      'photos': (photos ?? []).map((p) => p.toMap()).toList(),
      if (video != null)
        'video': video.toMap()
      else
        'video': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (updateLocation && latitude != null && longitude != null) {
      final roundedLat = double.parse(latitude.toStringAsFixed(2));
      final roundedLng = double.parse(longitude.toStringAsFixed(2));
      jobUpdates['latitude'] = roundedLat;
      jobUpdates['longitude'] = roundedLng;
      if (district != null) jobUpdates['district'] = district;

      final contactRef = jobRef.collection('private').doc('contact');
      final effectiveNote = (note != null && note.isNotEmpty) ? note : landmark;
      batch.set(
        contactRef,
        {
          'latitude': latitude,
          'longitude': longitude,
          if (address != null) 'address': address,
          if (effectiveNote != null) 'note': effectiveNote,
          if (effectiveNote != null) 'landmark': effectiveNote,
          if (houseNo != null) 'houseNo': houseNo,
          if (street != null) 'street': street,
          if (city != null) 'city': city,
          if (directions != null) 'directions': directions,
          if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    if (hasQuotes) {
      jobUpdates['jobUpdatedAt'] = FieldValue.serverTimestamp();
    }

    batch.update(jobRef, jobUpdates);
    await batch.commit();

    if (hasQuotes) {
      try {
        await NotificationService.instance.sendNotification(
          event: 'job_updated',
          docId: requestId,
        );
      } catch (e) {
        debugPrint('[JobRepo] notify job_updated error: $e');
      }
    }
  }

  Future<void> cancelJobRequest({
    required String requestId,
    required String reason,
    required String cancelledBy,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    batch.update(_col.doc(requestId), {
      'status': JobRequestStatus.cancelled,
      'cancelReason': reason,
      'cancellationReason': reason,
      'cancelledAt': FieldValue.serverTimestamp(),
      'cancelledBy': cancelledBy,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final quotesSnap = await _col
        .doc(requestId)
        .collection(FirestorePaths.quotes)
        .where('status', isEqualTo: 'pending')
        .get();

    for (final doc in quotesSnap.docs) {
      batch.update(doc.reference, {
        'status': 'job_closed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    try {
      await NotificationService.instance.sendNotification(
        event: 'job_closed',
        docId: requestId,
      );
    } catch (e) {
      debugPrint('[JobRepo] notify job_closed error: $e');
    }
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    await _col.doc(requestId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
