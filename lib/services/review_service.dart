import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../constants/app_config.dart';
import '../constants/firestore_paths.dart';

class ReviewService {
  ReviewService._();
  static final ReviewService instance = ReviewService._();

  final _db = FirebaseFirestore.instance;

  // submit customer review
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
        'rating': rating.clamp(1, 5),
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    // trigger server side rating and jobs count recalculation
    notifyReviewSubmitted(bookingId).catchError((_) {});
  }

  // call server endpoint to recompute provider rating and jobs count
  Future<void> notifyReviewSubmitted(String bookingId) async {
    if (bookingId.isEmpty) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await user.getIdToken();
      if (token == null || token.isEmpty) return;

      final baseUrl = AppConfig.otpApiUrl.replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.parse('$baseUrl/review-submitted');

      await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'bookingId': bookingId}),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('review submitted notify error $e');
    }
  }

  // stream tech reviews
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
