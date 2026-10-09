import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_config.dart';

class OtpVerificationResult {
  final bool isValid;
  final String? errorMessage;
  final String? customToken;

  const OtpVerificationResult({
    required this.isValid,
    this.errorMessage,
    this.customToken,
  });
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

  // send verification code to email
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
            headers: {
              'Content-Type': 'application/json',
              'x-helaservice-key': AppConfig.apiSecretKey,
            },
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

  // backwards compatibility alias
  Future<void> sendEmailOtp(String email) => sendOtp(email);

  // verify submitted code
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
            headers: {
              'Content-Type': 'application/json',
              'x-helaservice-key': AppConfig.apiSecretKey,
            },
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

  // send sms otp
  Future<void> sendSmsOtp(String phone) async {
    final cleanPhone = phone.trim();

    if (_lastSentAt != null && remainingCooldownSeconds > 0) {
      throw Exception(
        'Please wait $remainingCooldownSeconds seconds before requesting a new code.',
      );
    }

    final baseUrl = AppConfig.otpApiUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$baseUrl/send-sms-otp');

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-helaservice-key': AppConfig.apiSecretKey,
            },
            body: jsonEncode({'phone': cleanPhone}),
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
            'Too many requests. Please wait before requesting another code.';
        throw Exception(errorMsg);
      }

      throw Exception(
        data['error'] as String? ??
            'Failed to send SMS code (Error ${response.statusCode}).',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('sms otp send error: $e');
      }
      rethrow;
    }
  }

  // verify sms otp
  Future<OtpVerificationResult> verifySmsOtp(
    String phone,
    String enteredCode,
  ) async {
    final cleanPhone = phone.trim();
    final code = enteredCode.trim();

    if (code.length != 6) {
      return const OtpVerificationResult(
        isValid: false,
        errorMessage: 'Please enter the complete 6-digit verification code.',
      );
    }

    final baseUrl = AppConfig.otpApiUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$baseUrl/verify-sms-otp');

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-helaservice-key': AppConfig.apiSecretKey,
            },
            body: jsonEncode({'phone': cleanPhone, 'otp': code}),
          )
          .timeout(const Duration(seconds: 15));

      final data = _parseResponseBody(response.body);

      if (response.statusCode == 200) {
        return OtpVerificationResult(
          isValid: true,
          customToken: data['customToken'] as String?,
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

  // backwards compatibility alias
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
