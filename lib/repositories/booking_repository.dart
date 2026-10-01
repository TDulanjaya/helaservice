import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/firestore_paths.dart';
import '../models/booking.dart';

class BookingRepository {
  final _col = FirebaseFirestore.instance.collection(FirestorePaths.bookings);

  Future<String> createBooking(Booking booking) async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? booking.customerId;

    // Save directly if this booking already has a job request.
    if (booking.jobRequestId != null && booking.jobRequestId!.isNotEmpty) {
      final data = booking.toMap();
      if (currentUid.isNotEmpty) {
        data['customerId'] = currentUid;
      }
      final docRef = await _col.add(data);
      return docRef.id;
    }

    // Create the job request, accepted quote, and booking together in one batch.
    final batch = FirebaseFirestore.instance.batch();
    final jobReqRef = FirebaseFirestore.instance.collection(FirestorePaths.jobRequests).doc();
    final quoteRef = jobReqRef.collection(FirestorePaths.quotes).doc();
    final bookingRef = _col.doc();

    final rateNum = booking.agreedPrice ??
        double.tryParse(booking.estRate.replaceAll(RegExp(r'[^0-9.]'), '')) ??
        0.0;

    batch.set(jobReqRef, {
      'customerId': currentUid,
      'customerName': booking.customerName,
      'customerPhone': booking.customerPhone,
      'title': booking.title.isNotEmpty ? booking.title : 'Direct Service Booking',
      'category': 'General',
      'description': 'Direct booking with ${booking.providerName}',
      'address': booking.location,
      'status': 'assigned',
      'selectedProviderId': booking.providerId,
      'acceptedQuoteId': quoteRef.id,
      'agreedPrice': rateNum,
      'quoteCount': 1,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(quoteRef, {
      'providerId': booking.providerId,
      'providerName': booking.providerName,
      'providerPhone': booking.providerPhone,
      'quotedPrice': rateNum,
      'etaMinutes': 30,
      'status': 'pending_provider',
      'createdBy': FirebaseAuth.instance.currentUser!.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final bookingData = booking.toMap();
    bookingData['customerId'] = currentUid;
    bookingData['jobRequestId'] = jobReqRef.id;
    bookingData['agreedPrice'] = rateNum;
    bookingData['status'] = 'pending';
    bookingData.remove('providerAcceptedAt');
    batch.set(bookingRef, bookingData);

    await batch.commit();
    return bookingRef.id;
  }

  Future<void> acceptBookingByProvider({
    required String bookingId,
    String? jobRequestId,
    String? quoteId,
  }) async {
    final batch = FirebaseFirestore.instance.batch();
    batch.update(_col.doc(bookingId), {
      'status': 'in_progress',
      'providerAcceptedAt': FieldValue.serverTimestamp(),
    });

    if (jobRequestId != null && jobRequestId.isNotEmpty && quoteId != null && quoteId.isNotEmpty) {
      final quoteRef = FirebaseFirestore.instance
          .collection(FirestorePaths.jobRequests)
          .doc(jobRequestId)
          .collection(FirestorePaths.quotes)
          .doc(quoteId);
      batch.update(quoteRef, {'status': 'accepted'});
    }

    await batch.commit();
  }

  Future<void> updateStatus(String bookingId, String status) async {
    await _col.doc(bookingId).update({'status': status});
  }

  Stream<List<Booking>> streamAllBookings() {
    return _col.snapshots().map((snap) {
      final items = snap.docs.map((d) => Booking.fromMap(d.id, d.data())).toList();
      items.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return items;
    });
  }

  Stream<List<Booking>> streamBookingsForProvider(String providerId) {
    return _col.where('providerId', isEqualTo: providerId).snapshots().map((snap) {
      final items = snap.docs.map((d) => Booking.fromMap(d.id, d.data())).toList();
      items.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return items;
    });
  }

  Stream<List<Booking>> streamProviderBookings(String providerId) =>
      streamBookingsForProvider(providerId);

  Stream<List<Booking>> streamBookingsForCustomer(String customerId) {
    return _col.where('customerId', isEqualTo: customerId).snapshots().map((snap) {
      final items = snap.docs.map((d) => Booking.fromMap(d.id, d.data())).toList();
      items.sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
      return items;
    });
  }

  Stream<List<Booking>> streamCustomerBookings(String customerId) =>
      streamBookingsForCustomer(customerId);

  Stream<Booking?> streamBooking(String bookingId) {
    if (bookingId.isEmpty) return Stream.value(null);
    return _col.doc(bookingId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return Booking.fromMap(snap.id, snap.data()!);
    });
  }

  Future<void> reportDelay(String bookingId, {required String reason, required int delayMinutes}) async {
    if (bookingId.isEmpty) return;
    await _col.doc(bookingId).update({
      'delayReason': reason,
      'delayMinutes': delayMinutes,
      'delayedAt': FieldValue.serverTimestamp(),
    });
  }
}
