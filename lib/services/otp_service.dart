import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../constants/app_config.dart';

class OtpException implements Exception {
  final String code;
  final int? retryAfter;
  const OtpException(this.code, {this.retryAfter});

  @override
  String toString() => code;
}

class OtpCooldownException implements OtpException {
  @override
  final String code = 'cooldown';
  @override
  final int retryAfter;
  final String message;
  const OtpCooldownException({
    required this.retryAfter,
    this.message = 'cooldown',
  });

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
      final statusCode = response.statusCode;
      final serverCode = (data['code'] as String? ?? '').trim();

      // log server code and status for debugging (no tokens)
      debugPrint('[OtpService.sendOtp] status=$statusCode code=$serverCode');

      if (statusCode == 200) {
        _lastSentAt = DateTime.now();
        return;
      }

      if (statusCode == 429) {
        final retryAfter = (data['retryAfter'] as num?)?.toInt() ?? 60;
        _lastSentAt = DateTime.now();
        if (serverCode == 'cooldown' || data.containsKey('retryAfter')) {
          throw OtpCooldownException(retryAfter: retryAfter);
        }
        throw OtpException(
          serverCode.isNotEmpty ? serverCode : 'rate_limited_ip',
          retryAfter: retryAfter,
        );
      }

      if (serverCode.isNotEmpty) {
        throw OtpException(serverCode);
      }

      if (statusCode == 400) {
        throw const OtpException('invalid_request');
      }

      if (statusCode == 401 || statusCode == 403) {
        throw const OtpException('not_admin');
      }

      if (statusCode >= 500) {
        throw const OtpException('server_error');
      }

      throw const OtpException('unknown');
    } on TimeoutException {
      debugPrint('[OtpService.sendOtp] error=timeout');
      throw const OtpException('timeout');
    } on OtpException {
      rethrow;
    } catch (e) {
      debugPrint('[OtpService.sendOtp] error=network_error');
      throw const OtpException('network_error');
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
      final statusCode = response.statusCode;
      final serverCode = (data['code'] as String? ?? '').trim();
      final attemptsRemaining = (data['attemptsRemaining'] as num?)?.toInt();

      // log server code and status for debugging (no tokens)
      debugPrint('[OtpService.verifyOtp] status=$statusCode code=$serverCode');

      if (statusCode == 200) {
        // refresh claims on user
        await user?.getIdToken(true);
        return const OtpVerificationResult(isValid: true);
      }

      // match by server code
      if (serverCode.isNotEmpty) {
        return OtpVerificationResult(
          isValid: false,
          errorCode: serverCode,
          attemptsRemaining: attemptsRemaining,
        );
      }

      // fallback if server did not send a code field
      if (statusCode == 400) {
        return const OtpVerificationResult(
          isValid: false,
          errorCode: 'otp_expired',
        );
      }

      if (statusCode == 401 || statusCode == 403) {
        return OtpVerificationResult(
          isValid: false,
          errorCode: 'otp_incorrect',
          attemptsRemaining: attemptsRemaining,
        );
      }

      if (statusCode >= 500) {
        return const OtpVerificationResult(
          isValid: false,
          errorCode: 'server_error',
        );
      }

      return const OtpVerificationResult(
        isValid: false,
        errorCode: 'unknown',
      );
    } on TimeoutException {
      debugPrint('[OtpService.verifyOtp] error=timeout');
      return const OtpVerificationResult(
        isValid: false,
        errorCode: 'timeout',
      );
    } catch (e) {
      debugPrint('[OtpService.verifyOtp] error=network_error');
      return const OtpVerificationResult(
        isValid: false,
        errorCode: 'network_error',
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
