import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/firestore_paths.dart';
import '../constants/job_status.dart';
import '../models/job_request.dart';
import '../models/quote.dart';
import '../services/notification_service.dart';

class JobRequestRepository {
  final _col =
      FirebaseFirestore.instance.collection(FirestorePaths.jobRequests);

  Future<String> createJobRequest(JobRequest request) async {
    final docRef = _col.doc();
    final batch = FirebaseFirestore.instance.batch();

    // public job request doc with rounded coordinates
    final publicData = request.toMap();
    publicData.remove('customerPhone');
    publicData.remove('address');
    publicData.remove('landmark');
    if (request.latitude != null) {
      publicData['latitude'] = double.parse(request.latitude!.toStringAsFixed(2));
    }
    if (request.longitude != null) {
      publicData['longitude'] = double.parse(request.longitude!.toStringAsFixed(2));
    }

    batch.set(docRef, publicData);

    // private contact doc
    final contactRef = docRef.collection('private').doc('contact');
    batch.set(contactRef, {
      'customerPhone': request.customerPhone,
      'address': request.address,
      'landmark': request.landmark ?? '',
      'latitude': request.latitude,
      'longitude': request.longitude,
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

  Future<void> submitQuote(String requestId, Quote quote) async {
    final quoteRef =
        _col.doc(requestId).collection(FirestorePaths.quotes).doc();
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
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final custId = (request?.customerId.isNotEmpty == true)
        ? request!.customerId
        : currentUid;

    if (request == null || request.latitude == null || request.longitude == null) {
      throw Exception('JOB_LOCATION_MISSING');
    }

    // generate pin code
    final pin = (100000 + Random().nextInt(900000)).toString();

    final batch = FirebaseFirestore.instance.batch();
    final bookingRef =
        FirebaseFirestore.instance.collection(FirestorePaths.bookings).doc();
    final pinRef = bookingRef.collection('private').doc('pin');

    // set private pin document
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

    // read private contact for full details if present
    Map<String, dynamic>? contactData;
    try {
      final contactSnap = await _col.doc(requestId).collection('private').doc('contact').get();
      contactData = contactSnap.data();
    } catch (e) {
      // ignore if not readable
    }

    final exactPhone = (contactData?['customerPhone'] as String?)?.isNotEmpty == true
        ? contactData!['customerPhone'] as String
        : request.customerPhone;
    final exactAddress = (contactData?['address'] as String?)?.isNotEmpty == true
        ? contactData!['address'] as String
        : (request.address.isNotEmpty ? request.address : 'Service Location');
    final exactLandmark = (contactData?['landmark'] as String?) ?? request.landmark ?? '';
    final exactLat = (contactData?['latitude'] as num?)?.toDouble() ?? request.latitude!;
    final exactLng = (contactData?['longitude'] as num?)?.toDouble() ?? request.longitude!;

    batch.set(bookingRef, {
      'customerId': custId,
      'providerId': providerId,
      'providerName': quote?.providerName ?? '',
      'status': JobStatus.confirmed,
      'createdAt': FieldValue.serverTimestamp(),
      'time': 'Scheduled Now',
      'relativeTime': 'Just now',
      'title': request.title.isNotEmpty == true
          ? request.title
          : 'Domestic Service Request',
      'estRate': 'LKR ${agreedPrice.toStringAsFixed(0)}',
      'agreedPrice': agreedPrice,
      'customerName': request.customerName.isNotEmpty == true
          ? request.customerName
          : 'Customer',
      'customerInitials': request.customerName.isNotEmpty
          ? request.customerName[0].toUpperCase()
          : 'C',
      'customerPhone': exactPhone,
      'providerPhone': quote?.providerPhone ?? '',
      'customerLatitude': exactLat,
      'customerLongitude': exactLng,
      'location': exactAddress,
      'entryInstructions': exactLandmark,
      'distance': quote != null ? '${quote.etaMinutes} mins ETA' : 'Scheduled',
      'jobRequestId': requestId,
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
    String? district,
  }) async {
    final roundedLat = double.parse(latitude.toStringAsFixed(2));
    final roundedLng = double.parse(longitude.toStringAsFixed(2));

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
      if (landmark != null) 'landmark': landmark,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
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
