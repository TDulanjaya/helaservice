import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/firestore_paths.dart';
import '../constants/job_status.dart';
import '../models/job_request.dart';
import '../models/quote.dart';
import '../services/notification_service.dart';
import '../utils/exact_location_helper.dart';
import 'booking_repository.dart';

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
      publicData['latitude'] = double.parse(request.latitude!.toStringAsFixed(2));
    }
    if (request.longitude != null) {
      publicData['longitude'] = double.parse(request.longitude!.toStringAsFixed(2));
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
      if (request.accuracyMeters != null) 'accuracyMeters': request.accuracyMeters,
      if (request.houseNo != null && request.houseNo!.isNotEmpty) 'houseNo': request.houseNo,
      if (request.street != null && request.street!.isNotEmpty) 'street': request.street,
      if (request.city != null && request.city!.isNotEmpty) 'city': request.city,
      if (request.directions != null && request.directions!.isNotEmpty) 'directions': request.directions,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return docRef.id;
  }

  Stream<List<JobRequest>> streamOpenRequests({int limit = 50}) {
    return _col.where('status', isEqualTo: JobRequestStatus.open).limit(limit).snapshots().map((snap) {
      final list = snap.docs.map((d) => JobRequest.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return list;
    });
  }

  Stream<List<JobRequest>> streamOpenRequestsForCategory(String category, {int limit = 50}) {
    return _col
        .where('status', isEqualTo: JobRequestStatus.open)
        .where('category', isEqualTo: category)
        .limit(limit)
        .snapshots()
        .map((snap) {
      final items = snap.docs
          .map((d) => JobRequest.fromMap(d.id, d.data()))
          .toList();
      items.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return items;
    });
  }

  Stream<List<JobRequest>> streamCustomerRequests(String customerId, {int limit = 50}) {
    if (customerId.isEmpty) return Stream.value(const []);
    return _col
        .where('customerId', isEqualTo: customerId)
        .limit(limit)
        .snapshots()
        .map((snap) {
      final items = snap.docs
          .map((d) => JobRequest.fromMap(d.id, d.data()))
          .toList();
      items.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return items;
    });
  }

  Stream<JobRequest?> streamJobRequest(String requestId) {
    return _col.doc(requestId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return JobRequest.fromMap(snap.id, snap.data()!);
    });
  }

  Future<JobRequest?> getById(String requestId) async {
    final doc = await _col.doc(requestId).get();
    if (!doc.exists || doc.data() == null) return null;
    return JobRequest.fromMap(doc.id, doc.data()!);
  }

  Future<void> submitQuote(String requestId, Quote quote) async {
    final quoteRef =
        _col.doc(requestId).collection(FirestorePaths.quotes).doc(quote.providerId);
    await quoteRef.set(quote.toMap());

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
      list.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
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
    if (request == null || request.latitude == null || request.longitude == null) {
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
      if (scheduledStartAt.isBefore(DateTime.now().subtract(const Duration(minutes: 15)))) {
        throw 'SCHEDULE_PASSED';
      }
    }

    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final custId = request.customerId.isNotEmpty == true
        ? request.customerId
        : currentUid;

    final quoteDoc = await _col.doc(requestId).collection(FirestorePaths.quotes).doc(quoteId).get();
    final quoteData = quoteDoc.data();
    final rawQuoteType = quoteData?['quoteType'] as String?;
    if (rawQuoteType == null || rawQuoteType.isEmpty) {
      try {
        await _col.doc(requestId).collection(FirestorePaths.quotes).doc(quoteId).update({
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
      final contactSnap = await _col.doc(requestId).collection('private').doc('contact').get();
      contactData = contactSnap.data();
    } catch (_) {}

    // retry once if contact coordinates were missing or invalid
    if (!ExactLocationHelper.validate(contactData)) {
      await Future.delayed(const Duration(milliseconds: 300));
      try {
        final retrySnap = await _col.doc(requestId).collection('private').doc('contact').get();
        contactData = retrySnap.data();
      } catch (_) {}
    }

    if (!ExactLocationHelper.validate(contactData)) {
      throw const ExactLocationUnavailableException();
    }

    final exactLat = (contactData!['latitude'] as num).toDouble();
    final exactLng = (contactData['longitude'] as num).toDouble();
    final exactPhone = (contactData['customerPhone'] as String?)?.isNotEmpty == true
        ? contactData['customerPhone'] as String
        : request.customerPhone;
    final exactAddress = (contactData['address'] as String?)?.isNotEmpty == true
        ? contactData['address'] as String
        : (request.address.isNotEmpty ? request.address : 'Service Location');
    final exactLandmark = (contactData['landmark'] as String?) ?? request.landmark ?? '';
    final accuracyMeters = (contactData['accuracyMeters'] as num?)?.toDouble() ?? request.accuracyMeters;
    final houseNo = (contactData['houseNo'] as String?) ?? request.houseNo;
    final street = (contactData['street'] as String?) ?? request.street;
    final city = (contactData['city'] as String?) ?? request.city;
    final directions = (contactData['directions'] as String?) ?? request.directions;

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
    String providerPhone = '';
    try {
      final techDoc = await FirebaseFirestore.instance
          .collection(FirestorePaths.technicians)
          .doc(providerId)
          .get();
      if (techDoc.exists && techDoc.data() != null) {
        providerPhone = (techDoc.data()?['phone'] as String?) ?? '';
      }
      if (providerPhone.isEmpty) {
        final userDoc = await FirebaseFirestore.instance
            .collection(FirestorePaths.users)
            .doc(providerId)
            .get();
        if (userDoc.exists && userDoc.data() != null) {
          providerPhone = (userDoc.data()?['phone'] as String?) ?? '';
        }
      }
    } catch (_) {}

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
      'priceStatus': resolvedQuote.quoteType == 'firm' ? 'approved' : 'awaiting_confirmation',
      if (resolvedQuote.quoteType == 'firm') 'approvedTotalLkr': resolvedQuote.quotedPrice.round(),
      if (resolvedQuote.priceUnit != null) 'priceUnit': resolvedQuote.priceUnit,
      if (resolvedQuote.unitRateLkr != null) 'unitRateLkr': resolvedQuote.unitRateLkr,
      if (resolvedQuote.quantity != null) 'quantity': resolvedQuote.quantity,
      if (resolvedQuote.materialsEstimateLkr != null) 'materialsEstimateLkr': resolvedQuote.materialsEstimateLkr,
      'visitFeeLkr': resolvedQuote.visitFeeLkr,
      'travelKm': resolvedQuote.travelKm,
      'travelRateLkr': resolvedQuote.travelRateLkr,
      'travelCostLkr': resolvedQuote.travelCostLkr,
      'estimatedTotalLkr': resolvedQuote.quotedPrice.round(),
      'approvedExtrasLkr': 0,
      'proposalCount': 0,
      'type': request.bookingType,
      'scheduleMode': request.scheduleMode,
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
      'description': 'Customer accepted quote from ${resolvedQuote.providerName}',
      'timestamp': FieldValue.serverTimestamp(),
      'actorUid': custId,
      'actorRole': 'customer',
    });

    await batch.commit();

    final allQuotes = await quotesCol.get();
    final declineBatch = FirebaseFirestore.instance.batch();
    bool hasQuotesToDecline = false;
    for (final doc in allQuotes.docs) {
      if (doc.id != quoteId && doc.data()['status'] != 'declined') {
        declineBatch.update(doc.reference, {'status': 'declined'});
        hasQuotesToDecline = true;
      }
    }
    if (hasQuotesToDecline) {
      await declineBatch.commit();
    }

    // notify provider of acceptance
    NotificationService.instance.sendNotification(
      event: 'quote_accepted',
      docId: requestId,
    );

    return bookingRef.id;
  }

  Future<Map<String, dynamic>?> getJobContact(String requestId) async {
    final doc = await _col.doc(requestId).collection('private').doc('contact').get();
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
    batch.set(_col.doc(requestId).collection('private').doc('contact'), {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      if (effectiveNote != null) 'note': effectiveNote,
      if (effectiveNote != null) 'landmark': effectiveNote,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
      if (scheduledStartAt != null) 'scheduledStartAt': Timestamp.fromDate(scheduledStartAt),
      if (scheduledEndAt != null) 'scheduledEndAt': Timestamp.fromDate(scheduledEndAt),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Quote>> streamProviderQuotes(String providerId, {int limit = 50}) {
    return FirebaseFirestore.instance
        .collectionGroup(FirestorePaths.quotes)
        .where('providerId', isEqualTo: providerId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Quote.fromMap(d.id, d.data())).toList());
  }

  Stream<List<JobRequest>> streamAllCustomerRequests({String? statusFilter, int limit = 50}) {
    Query query = _col.orderBy('createdAt', descending: true).limit(limit);
    if (statusFilter != null && statusFilter != 'all') {
      query = _col
          .where('status', isEqualTo: statusFilter)
          .orderBy('createdAt', descending: true)
          .limit(limit);
    }
    return query.snapshots().map((snap) => snap.docs
        .map((d) => JobRequest.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  Future<void> cancelAssignedJob({
    required String requestId,
    required String reason,
    String? bookingId,
    String? quoteId,
    String? cancelledBy,
    String? cancelledByRole,
  }) async {
    final effectiveCancelledBy = cancelledByRole ?? cancelledBy;
    final batch = FirebaseFirestore.instance.batch();

    batch.update(_col.doc(requestId), {
      'status': JobRequestStatus.cancelled,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (quoteId != null && quoteId.isNotEmpty) {
      batch.update(
        _col.doc(requestId).collection(FirestorePaths.quotes).doc(quoteId),
        {'status': 'cancelled'},
      );
    } else {
      final quotesSnap = await _col
          .doc(requestId)
          .collection(FirestorePaths.quotes)
          .where('status', isEqualTo: 'accepted')
          .get();
      for (final doc in quotesSnap.docs) {
        batch.update(doc.reference, {'status': 'cancelled'});
      }
    }

    if (bookingId != null && bookingId.isNotEmpty) {
      batch.update(
        FirebaseFirestore.instance.collection(FirestorePaths.bookings).doc(bookingId),
        {
          'status': JobStatus.cancelled,
          'cancellationReason': reason,
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancelledBy': effectiveCancelledBy ?? 'provider',
        },
      );
    } else {
      final bSnap = await FirebaseFirestore.instance
          .collection(FirestorePaths.bookings)
          .where('jobRequestId', isEqualTo: requestId)
          .get();
      for (final doc in bSnap.docs) {
        batch.update(doc.reference, {
          'status': JobStatus.cancelled,
          'cancellationReason': reason,
          'cancelledAt': FieldValue.serverTimestamp(),
          'cancelledBy': effectiveCancelledBy ?? 'provider',
        });
      }
    }

    await batch.commit();
  }

  Future<void> repostJobRequest(String requestId) async {
    final batch = FirebaseFirestore.instance.batch();
    batch.update(_col.doc(requestId), {
      'status': JobRequestStatus.open,
      'selectedProviderId': FieldValue.delete(),
      'acceptedQuoteId': FieldValue.delete(),
      'agreedPrice': FieldValue.delete(),
      'cancellationReason': FieldValue.delete(),
      'repostedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    final quotesSnap =
        await _col.doc(requestId).collection(FirestorePaths.quotes).get();
    for (final doc in quotesSnap.docs) {
      batch.update(doc.reference, {'status': 'pending'});
    }

    await batch.commit();
  }

  Future<void> deleteJobRequest(String requestId) async {
    final quotesSnap =
        await _col.doc(requestId).collection(FirestorePaths.quotes).get();
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in quotesSnap.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_col.doc(requestId));
    await batch.commit();
  }

  Future<void> updateRequestStatus(String requestId, String status) async {
    await _col.doc(requestId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
