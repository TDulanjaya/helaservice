import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_paths.dart';

// Manages customer reviews and technician ratings.
class ReviewService {
  ReviewService._();
  static final ReviewService instance = ReviewService._();

  final _db = FirebaseFirestore.instance;

  // Saves the review and completes the booking in one batch.
  Future<void> submitReview({
    required String customerId,
    required String customerName,
    required String providerId,
    required String jobRequestId,
    required String bookingId,
    required int rating,
    required List<String> tags,
    String comment = '',
    int tipAmountLkr = 0,
  }) async {
    final batch = _db.batch();

    // Use bookingId as doc ID to block duplicate reviews.
    final reviewRef = _db.collection(FirestorePaths.reviews).doc(bookingId);
    batch.set(reviewRef, {
      'customerId': customerId,
      'customerName': customerName,
      'providerId': providerId,
      'jobRequestId': jobRequestId,
      'bookingId': bookingId,
      'rating': rating.clamp(1, 5),
      'tags': tags,
      'comment': comment,
      'tipAmountLkr': tipAmountLkr,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (bookingId.isNotEmpty) {
      final bookingRef =
          _db.collection(FirestorePaths.bookings).doc(bookingId);
      batch.update(bookingRef, {
        'status': 'completed',
        'rating': rating.clamp(1, 5),
      });
    }

    if (jobRequestId.isNotEmpty) {
      final jobRef =
          _db.collection(FirestorePaths.jobRequests).doc(jobRequestId);
      batch.update(jobRef, {'status': 'completed'});
    }

    await batch.commit();
  }

  // Listens to recent reviews for a technician.
  Stream<List<Map<String, dynamic>>> streamProviderReviews(String providerId) {
    return _db
        .collection(FirestorePaths.reviews)
        .where('providerId', isEqualTo: providerId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }
}
