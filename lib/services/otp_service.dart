import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_config.dart';

class OtpVerificationResult {
  final bool isValid;
  final String? errorMessage;

  const OtpVerificationResult({required this.isValid, this.errorMessage});
}

class OtpService {
  static final OtpService _instance = OtpService._internal();
  factory OtpService() => _instance;
  OtpService._internal();

  DateTime? _lastSentAt;

  int get remainingCooldownSeconds {
    if (_lastSentAt == null) return 0;
    final diff = 60 - DateTime.now().difference(_lastSentAt!).inSeconds;
    return diff > 0 ? diff : 0;
  }

  bool get canResend => remainingCooldownSeconds <= 0;

  /// Calls Vercel Serverless Function: POST /api/send-otp
  Future<void> sendOtp(String email) async {
    final cleanEmail = email.trim().toLowerCase();

    if (_lastSentAt != null && remainingCooldownSeconds > 0) {
      throw Exception(
        'Please wait $remainingCooldownSeconds seconds before requesting a new code.',
      );
    }

    final baseUrl = AppConfig.otpApiUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$baseUrl/send-otp');

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': cleanEmail}),
          )
          .timeout(const Duration(seconds: 15));

      final data = _parseResponseBody(response.body);

      if (response.statusCode == 200) {
        _lastSentAt = DateTime.now();
        return;
      }

      if (response.statusCode == 429) {
        _lastSentAt = DateTime.now();
        final errorMsg = data['error'] as String? ??
            'Too many requests. Please wait a minute before requesting another code.';
        throw Exception(errorMsg);
      }

      if (response.statusCode == 400) {
        throw Exception(data['error'] as String? ?? 'Invalid email address.');
      }

      throw Exception(
        data['error'] as String? ??
            'Failed to send verification code (Error ${response.statusCode}).',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[OtpService sendOtp Error] $e');
      }
      rethrow;
    }
  }

  /// Backward-compatible alias
  Future<void> sendEmailOtp(String email) => sendOtp(email);

  /// Calls Vercel Serverless Function: POST /api/verify-otp
  Future<OtpVerificationResult> verifyOtp(
    String email,
    String enteredCode,
  ) async {
    final cleanEmail = email.trim().toLowerCase();
    final code = enteredCode.trim();

    if (code.length != 6) {
      return const OtpVerificationResult(
        isValid: false,
        errorMessage: 'Please enter the complete 6-digit verification code.',
      );
    }

    final baseUrl = AppConfig.otpApiUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$baseUrl/verify-otp');

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': cleanEmail, 'otp': code}),
          )
          .timeout(const Duration(seconds: 15));

      final data = _parseResponseBody(response.body);

      if (response.statusCode == 200) {
        return const OtpVerificationResult(isValid: true);
      }

      if (response.statusCode == 401) {
        return OtpVerificationResult(
          isValid: false,
          errorMessage:
              data['error'] as String? ?? 'Incorrect verification code.',
        );
      }

      if (response.statusCode == 403) {
        return OtpVerificationResult(
          isValid: false,
          errorMessage: data['error'] as String? ??
              'Maximum attempts exceeded. Please request a new verification code.',
        );
      }

      if (response.statusCode == 400) {
        return OtpVerificationResult(
          isValid: false,
          errorMessage: data['error'] as String? ??
              'Verification code has expired. Please request a new one.',
        );
      }

      return OtpVerificationResult(
        isValid: false,
        errorMessage: data['error'] as String? ??
            'Verification failed (Status ${response.statusCode}).',
      );
    } catch (e) {
      return OtpVerificationResult(
        isValid: false,
        errorMessage: 'Network error connecting to verification service: $e',
      );
    }
  }

  /// Backward-compatible alias
  Future<OtpVerificationResult> verifyEmailOtp(
    String email,
    String enteredCode,
  ) =>
      verifyOtp(email, enteredCode);

  Map<String, dynamic> _parseResponseBody(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
