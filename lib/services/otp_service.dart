import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../constants/app_config.dart';

class OtpCooldownException implements Exception {
  final int retryAfter;
  final String message;
  const OtpCooldownException({required this.retryAfter, required this.message});

  @override
  String toString() => message;
}

class OtpVerificationResult {
  final bool isValid;
  final String? errorMessage;
  final String? errorCode;
  final String? customToken;
  final int? attemptsRemaining;

  const OtpVerificationResult({
    required this.isValid,
    this.errorMessage,
    this.errorCode,
    this.customToken,
    this.attemptsRemaining,
  });
}

class OtpService {
  static final OtpService _instance = OtpService._internal();
  factory OtpService({http.Client? client, FirebaseAuth? auth}) {
    if (client != null || auth != null) {
      return OtpService._withClient(client, auth);
    }
    return _instance;
  }
  OtpService._internal()
      : _client = null,
        _auth = null;
  OtpService._withClient(http.Client? client, FirebaseAuth? auth)
      : _client = client,
        _auth = auth;

  final http.Client? _client;
  final FirebaseAuth? _auth;

  User? get _currentUser {
    try {
      return (_auth ?? FirebaseAuth.instance).currentUser;
    } catch (_) {
      return null;
    }
  }

  DateTime? _lastSentAt;

  int get remainingCooldownSeconds {
    if (_lastSentAt == null) return 0;
    final diff = 60 - DateTime.now().difference(_lastSentAt!).inSeconds;
    return diff > 0 ? diff : 0;
  }

  bool get canResend => remainingCooldownSeconds <= 0;

  // send verification code to email
  Future<void> sendOtp([
    String? email,
    String purpose = 'signup',
    String language = 'en',
  ]) async {
    final user = _currentUser;
    final cleanEmail = (email ?? user?.email ?? '').trim().toLowerCase();

    if (_lastSentAt != null && remainingCooldownSeconds > 0) {
      throw OtpCooldownException(
        retryAfter: remainingCooldownSeconds,
        message:
            'Please wait $remainingCooldownSeconds seconds before requesting a new code.',
      );
    }

    final baseUrl = AppConfig.otpApiUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$baseUrl/send-otp');

    if (AppConfig.apiSecretKey.isEmpty) {
      try {
        await AppConfig.ensureApiSecretKey();
      } catch (_) {}
    }

    final idToken = await user?.getIdToken();

    try {
      final postFuture = _client != null
          ? _client.post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                if (idToken != null && idToken.isNotEmpty)
                  'Authorization': 'Bearer $idToken',
                'x-helaservice-key': AppConfig.apiSecretKey,
              },
              body: jsonEncode({
                'purpose': purpose,
                'language': language,
                if (cleanEmail.isNotEmpty) 'email': cleanEmail,
              }),
            )
          : http.post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                if (idToken != null && idToken.isNotEmpty)
                  'Authorization': 'Bearer $idToken',
                'x-helaservice-key': AppConfig.apiSecretKey,
              },
              body: jsonEncode({
                'purpose': purpose,
                'language': language,
                if (cleanEmail.isNotEmpty) 'email': cleanEmail,
              }),
            );

      final response = await postFuture.timeout(const Duration(seconds: 15));

      final data = _parseResponseBody(response.body);

      if (response.statusCode == 200) {
        _lastSentAt = DateTime.now();
        return;
      }

      if (response.statusCode == 429) {
        final serverCode = (data['code'] as String? ?? '').trim();
        final retryAfter = (data['retryAfter'] as num?)?.toInt() ?? 60;
        final errorMsg = data['error'] as String? ??
            'Too many requests. Please wait before requesting another code.';
        if (serverCode == 'cooldown' || data.containsKey('retryAfter')) {
          _lastSentAt = DateTime.now();
          throw OtpCooldownException(retryAfter: retryAfter, message: errorMsg);
        }
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
        throw Exception(
            errorMsg.isNotEmpty ? errorMsg : 'Authentication failed.');
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

  // alias for older callers
  Future<void> sendEmailOtp(
    String email, {
    String purpose = 'signup',
    String language = 'en',
  }) =>
      sendOtp(email, purpose, language);

  // verify submitted code
  Future<OtpVerificationResult> verifyOtp(
    String param1, [
    String? param2,
    String purpose = 'signup',
  ]) async {
    final code = (param2 ?? param1).trim();
    final cleanEmail = (param2 != null ? param1 : '').trim().toLowerCase();

    if (code.length != 6) {
      return const OtpVerificationResult(
        isValid: false,
        errorCode: 'OTP_CODE_INCOMPLETE',
      );
    }

    final baseUrl = AppConfig.otpApiUrl.replaceAll(RegExp(r'/+$'), '');
    final uri = Uri.parse('$baseUrl/verify-otp');

    if (AppConfig.apiSecretKey.isEmpty) {
      try {
        await AppConfig.ensureApiSecretKey();
      } catch (_) {}
    }

    final user = _currentUser;
    final idToken = await user?.getIdToken();

    try {
      final postFuture = _client != null
          ? _client.post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                if (idToken != null && idToken.isNotEmpty)
                  'Authorization': 'Bearer $idToken',
                'x-helaservice-key': AppConfig.apiSecretKey,
              },
              body: jsonEncode({
                'otp': code,
                'purpose': purpose,
                if (cleanEmail.isNotEmpty) 'email': cleanEmail,
              }),
            )
          : http.post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                if (idToken != null && idToken.isNotEmpty)
                  'Authorization': 'Bearer $idToken',
                'x-helaservice-key': AppConfig.apiSecretKey,
              },
              body: jsonEncode({
                'otp': code,
                'purpose': purpose,
                if (cleanEmail.isNotEmpty) 'email': cleanEmail,
              }),
            );

      final response = await postFuture.timeout(const Duration(seconds: 15));

      final data = _parseResponseBody(response.body);

      if (response.statusCode == 200) {
        // refresh claims on user
        await user?.getIdToken(true);
        return const OtpVerificationResult(isValid: true);
      }

      final serverCode = (data['code'] as String? ?? '').trim();
      final errText = data['error'] as String? ?? '';
      final attemptsRemaining = (data['attemptsRemaining'] as num?)?.toInt();

      // match by server code
      if (serverCode.isNotEmpty) {
        switch (serverCode) {
          case 'otp_no_session':
            return OtpVerificationResult(
              isValid: false,
              errorCode: 'OTP_NO_SESSION',
              errorMessage: errText.isNotEmpty ? errText : null,
            );
          case 'otp_expired':
            return OtpVerificationResult(
              isValid: false,
              errorCode: 'OTP_EXPIRED',
              errorMessage: errText.isNotEmpty ? errText : null,
            );
          case 'otp_incorrect':
            return OtpVerificationResult(
              isValid: false,
              errorCode: 'OTP_INCORRECT',
              errorMessage: errText.isNotEmpty ? errText : null,
              attemptsRemaining: attemptsRemaining,
            );
          case 'otp_max_attempts':
            return OtpVerificationResult(
              isValid: false,
              errorCode: 'OTP_MAX_ATTEMPTS',
              errorMessage: errText.isNotEmpty ? errText : null,
            );
          case 'not_admin':
            return OtpVerificationResult(
              isValid: false,
              errorCode: 'NOT_ADMIN',
              errorMessage: errText.isNotEmpty ? errText : null,
            );
          case 'server_error':
            return const OtpVerificationResult(
              isValid: false,
              errorCode: 'SERVICE_UNAVAILABLE',
              errorMessage:
                  'Service temporarily unavailable. Please try again.',
            );
        }
      }

      // fallback if no code sent
      if (response.statusCode == 400) {
        if (errText.contains('No active verification session')) {
          return OtpVerificationResult(
            isValid: false,
            errorCode: 'OTP_NO_SESSION',
            errorMessage: errText.isNotEmpty ? errText : null,
          );
        }
        return OtpVerificationResult(
          isValid: false,
          errorCode: 'OTP_EXPIRED',
          errorMessage: errText.isNotEmpty ? errText : null,
        );
      }

      if (response.statusCode == 401) {
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
          attemptsRemaining: attemptsRemaining,
        );
      }

      if (response.statusCode == 403) {
        return OtpVerificationResult(
          isValid: false,
          errorCode: 'OTP_MAX_ATTEMPTS',
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

      return OtpVerificationResult(
        isValid: false,
        errorCode: 'OTP_FAILED',
        errorMessage: errText.isNotEmpty ? errText : null,
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

  // alias for older callers
  Future<OtpVerificationResult> verifyEmailOtp(
    String email,
    String enteredCode, {
    String purpose = 'signup',
  }) =>
      verifyOtp(email, enteredCode, purpose);

  Map<String, dynamic> _parseResponseBody(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
