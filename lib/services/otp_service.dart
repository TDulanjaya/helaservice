import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class OtpVerificationResult {
  final bool isValid;
  final String? errorMessage;

  const OtpVerificationResult({required this.isValid, this.errorMessage});
}

class OtpService {
  static final OtpService _instance = OtpService._internal();
  factory OtpService() => _instance;
  OtpService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generates a 6-digit code and queues the email.
  Future<String> generateAndSendEmailOtp(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final random = Random.secure();
    final otpCode = (100000 + random.nextInt(900000)).toString();

    final now = DateTime.now();
    final expiresAt = now.add(const Duration(minutes: 10));

    await _firestore.collection('email_verifications').doc(cleanEmail).set({
      'email': cleanEmail,
      'otp': otpCode,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'verified': false,
      'attempts': 0,
    });

    try {
      await _firestore.collection('mail').add({
        'to': [cleanEmail],
        'message': {
          'subject': 'Your HelaService Verification Code: $otpCode',
          'text':
              'Your HelaService account verification code is: $otpCode. This code will expire in 10 minutes.',
          'html': '''
            <div style="font-family: Arial, sans-serif; max-width: 500px; margin: auto; padding: 24px; border: 1px solid #E2E8F0; border-radius: 12px; background: #FFFFFF;">
              <h2 style="color: #D6900F; margin-bottom: 8px;">HelaService Verification</h2>
              <p style="color: #475569; font-size: 14px; margin-bottom: 20px;">Use the 6-digit code below to complete your HelaService registration:</p>
              <div style="background: #F1F5F9; padding: 16px; border-radius: 8px; text-align: center; letter-spacing: 6px; font-size: 28px; font-weight: bold; color: #0F172A; margin-bottom: 20px;">
                $otpCode
              </div>
              <p style="color: #64748B; font-size: 12px; line-height: 1.5;">This code expires in 10 minutes. If you did not request this registration, please disregard this email.</p>
            </div>
          ''',
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    return otpCode;
  }

  // Verifies the code and checks expiration.
  Future<OtpVerificationResult> verifyEmailOtp(
    String email,
    String enteredCode,
  ) async {
    final cleanEmail = email.trim().toLowerCase();
    final code = enteredCode.trim();

    try {
      final doc = await _firestore
          .collection('email_verifications')
          .doc(cleanEmail)
          .get();

      if (!doc.exists || doc.data() == null) {
        return const OtpVerificationResult(
          isValid: false,
          errorMessage: 'No verification request found for this email. Please request a new code.',
        );
      }

      final data = doc.data()!;
      final expectedOtp = data['otp']?.toString() ?? '';
      final Timestamp? expiresTimestamp = data['expiresAt'] as Timestamp?;
      final int attempts = (data['attempts'] as int?) ?? 0;

      if (attempts >= 5) {
        return const OtpVerificationResult(
          isValid: false,
          errorMessage: 'Too many incorrect attempts. Please request a new verification code.',
        );
      }

      if (expiresTimestamp != null &&
          DateTime.now().isAfter(expiresTimestamp.toDate())) {
        return const OtpVerificationResult(
          isValid: false,
          errorMessage: 'This verification code has expired. Please request a new one.',
        );
      }

      if (expectedOtp != code) {
        await _firestore.collection('email_verifications').doc(cleanEmail).update({
          'attempts': attempts + 1,
        }).catchError((_) {});

        return const OtpVerificationResult(
          isValid: false,
          errorMessage: 'Incorrect verification code. Please check your email and try again.',
        );
      }

      await _firestore.collection('email_verifications').doc(cleanEmail).update({
        'verified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
      }).catchError((_) {});

      return const OtpVerificationResult(isValid: true);
    } catch (e) {
      return OtpVerificationResult(
        isValid: false,
        errorMessage: 'Verification failed: ${e.toString()}',
      );
    }
  }
}
