import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_config.dart';

class OtpVerificationResult {
  final bool isValid;
  final String? errorMessage;
  final String? errorCode;
  final String? customToken;

  const OtpVerificationResult({
    required this.isValid,
    this.errorMessage,
    this.errorCode,
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

    if (AppConfig.apiSecretKey.isEmpty) {
      await AppConfig.ensureApiSecretKey();
    }

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

      if (response.statusCode == 401 || response.statusCode == 500) {
        final errorMsg = data['error'] as String? ?? '';
        if (errorMsg.contains('Valid API key required') ||
            errorMsg.contains('Server misconfigured') ||
            response.statusCode == 500) {
          throw Exception('Service temporarily unavailable. Please try again.');
        }
        throw Exception(errorMsg.isNotEmpty ? errorMsg : 'Authentication failed.');
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
        errorCode: 'OTP_CODE_INCOMPLETE',
      );
    }

    final baseUrl = AppConfig.otpApiUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$baseUrl/verify-otp');

    if (AppConfig.apiSecretKey.isEmpty) {
      await AppConfig.ensureApiSecretKey();
    }

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
        final errText = data['error'] as String? ?? '';
        if (errText.contains('Valid API key required')) {
          return const OtpVerificationResult(
            isValid: false,
            errorCode: 'SERVICE_UNAVAILABLE',
            errorMessage: 'Service temporarily unavailable. Please try again.',
          );
        }
        return OtpVerificationResult(
          isValid: false,
          errorCode: 'OTP_INCORRECT',
          errorMessage: errText.isNotEmpty ? errText : null,
        );
      }

      if (response.statusCode == 500) {
        return const OtpVerificationResult(
          isValid: false,
          errorCode: 'SERVICE_UNAVAILABLE',
          errorMessage: 'Service temporarily unavailable. Please try again.',
        );
      }

      if (response.statusCode == 403) {
        return OtpVerificationResult(
          isValid: false,
          errorCode: 'OTP_MAX_ATTEMPTS',
          errorMessage: data['error'] as String?,
        );
      }

      if (response.statusCode == 400) {
        return OtpVerificationResult(
          isValid: false,
          errorCode: 'OTP_EXPIRED',
          errorMessage: data['error'] as String?,
        );
      }

      return OtpVerificationResult(
        isValid: false,
        errorCode: 'OTP_FAILED',
        errorMessage: data['error'] as String?,
      );
    } catch (e) {
      return const OtpVerificationResult(
        isValid: false,
        errorCode: 'OTP_NETWORK_ERROR',
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
        errorCode: 'OTP_CODE_INCOMPLETE',
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
        errorCode: 'OTP_FAILED',
        errorMessage: data['error'] as String?,
      );
    } catch (e) {
      return const OtpVerificationResult(
        isValid: false,
        errorCode: 'OTP_NETWORK_ERROR',
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
