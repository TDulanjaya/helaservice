import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  // log a generic custom analytics event
  void logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) {
    if (kDebugMode) {
      debugPrint('[Analytics] Event: $name params: $parameters');
    }
  }

  // log booking created milestone
  void logBookingCreated({
    required String bookingId,
    required String customerId,
    required String providerId,
    required double amount,
  }) {
    logEvent(
      name: 'booking_created',
      parameters: {
        'bookingId': bookingId,
        'customerId': customerId,
        'providerId': providerId,
        'amount': amount,
      },
    );
  }

  // log quote submitted milestone
  void logQuoteSubmitted({
    required String requestId,
    required String providerId,
    required double price,
  }) {
    logEvent(
      name: 'quote_submitted',
      parameters: {
        'requestId': requestId,
        'providerId': providerId,
        'price': price,
      },
    );
  }

  // log job completed milestone
  void logJobCompleted({
    required String bookingId,
    required double finalAmount,
  }) {
    logEvent(
      name: 'job_completed',
      parameters: {
        'bookingId': bookingId,
        'finalAmount': finalAmount,
      },
    );
  }

  // log review submitted milestone
  void logReviewSubmitted({
    required String providerId,
    required int rating,
  }) {
    logEvent(
      name: 'review_submitted',
      parameters: {
        'providerId': providerId,
        'rating': rating,
      },
    );
  }

  // log user blocked milestone
  void logUserBlocked({
    required String blockedUid,
  }) {
    logEvent(
      name: 'user_blocked',
      parameters: {
        'blockedUid': blockedUid,
      },
    );
  }

  // log emergency request triggered
  void logEmergencyRequested({
    required String customerId,
    required String category,
  }) {
    logEvent(
      name: 'emergency_requested',
      parameters: {
        'customerId': customerId,
        'category': category,
      },
    );
  }

  // log non fatal diagnostic error
  void logError(dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[DiagnosticError] $error\n$stackTrace');
    }
  }
}
