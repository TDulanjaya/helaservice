import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/firestore_paths.dart';
import '../models/job_request.dart';
import '../models/quote.dart';

class JobRequestRepository {
  final _col =
      FirebaseFirestore.instance.collection(FirestorePaths.jobRequests);

  Future<String> createJobRequest(JobRequest request) async {
    final docRef = await _col.add(request.toMap());
    return docRef.id;
  }

  Stream<List<JobRequest>> streamOpenRequests() {
    return _col.where('status', isEqualTo: 'open').snapshots().map((snap) =>
        snap.docs.map((d) => JobRequest.fromMap(d.id, d.data())).toList());
  }

  Stream<List<JobRequest>> streamOpenRequestsForCategory(String category) {
    return _col
        .where('status', isEqualTo: 'open')
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => JobRequest.fromMap(d.id, d.data())).toList());
  }

  Stream<List<JobRequest>> streamCustomerRequests(String customerId) {
    return _col
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => JobRequest.fromMap(d.id, d.data())).toList());
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
  }

  Stream<List<Quote>> streamQuotesForRequest(String requestId) {
    return _col
        .doc(requestId)
        .collection(FirestorePaths.quotes)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Quote.fromMap(d.id, d.data())).toList());
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

    final batch = FirebaseFirestore.instance.batch();

    batch.update(_col.doc(requestId), {
      'status': 'assigned',
      'selectedProviderId': providerId,
      'acceptedQuoteId': quoteId,
      'agreedPrice': agreedPrice,
    });

    final quotesCol = _col.doc(requestId).collection(FirestorePaths.quotes);
    batch.update(quotesCol.doc(quoteId), {'status': 'accepted'});

    final bookingRef =
        FirebaseFirestore.instance.collection(FirestorePaths.bookings).doc();
    batch.set(bookingRef, {
      'customerId': custId,
      'providerId': providerId,
      'providerName': quote?.providerName ?? '',
      'status': 'confirmed',
      'createdAt': FieldValue.serverTimestamp(),
      'time': 'Scheduled Now',
      'relativeTime': 'Just now',
      'title': request?.title.isNotEmpty == true
          ? request!.title
          : 'Domestic Service Request',
      'estRate': 'LKR ${agreedPrice.toStringAsFixed(0)}',
      'agreedPrice': agreedPrice,
      'customerName': request?.customerName.isNotEmpty == true
          ? request!.customerName
          : 'Customer',
      'customerInitials': (request != null && request.customerName.isNotEmpty)
          ? request.customerName[0].toUpperCase()
          : 'C',
      'customerPhone': request?.customerPhone ?? '',
      'providerPhone': quote?.providerPhone ?? '',
      if (request?.latitude != null) 'customerLatitude': request!.latitude,
      if (request?.longitude != null) 'customerLongitude': request!.longitude,
      'location': request?.address.isNotEmpty == true
          ? request!.address
          : 'Western Province',
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

    return bookingRef.id;
  }

  Stream<List<Quote>> streamProviderQuotes(String providerId) {
    return FirebaseFirestore.instance
        .collectionGroup(FirestorePaths.quotes)
        .where('providerId', isEqualTo: providerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Quote.fromMap(d.id, d.data())).toList());
  }
}
