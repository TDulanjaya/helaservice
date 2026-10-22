import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'session_guard.dart';

// wrapper for backend api calls
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();
  factory ApiClient() => instance;

  // send post request with user token
  Future<http.Response> post({
    required Uri uri,
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    return _sendWithRetry(
      () async {
        final user = FirebaseAuth.instance.currentUser;
        final token = await user?.getIdToken();
        final effectiveHeaders = <String, String>{
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
          ...?headers,
        };
        return http
            .post(uri, headers: effectiveHeaders, body: body)
            .timeout(timeout);
      },
    );
  }

  Future<http.Response> _sendWithRetry(
    Future<http.Response> Function() requestFn,
  ) async {
    var response = await requestFn();

    if (_isLoginOtpRequired(response)) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // refresh token in case claims updated and retry
        await user.getIdToken(true);
        response = await requestFn();

        if (_isLoginOtpRequired(response)) {
          SessionGuard.instance.checkSessionValid();
        }
      }
    }

    return response;
  }

  bool _isLoginOtpRequired(http.Response res) {
    if (res.statusCode != 403) return false;
    try {
      final data = jsonDecode(res.body);
      if (data is Map &&
          (data['error'] == 'login_otp_required' ||
              data['code'] == 'login_otp_required')) {
        return true;
      }
    } catch (_) {
      if (res.body.contains('login_otp_required')) return true;
    }
    return false;
  }
}

