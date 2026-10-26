import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../constants/firestore_paths.dart';
import '../features/customer/screens/post_job_request_screen.dart';

class ErrorReporter {
  ErrorReporter._();
  static final ErrorReporter instance = ErrorReporter._();

  static String? _cachedAppVersion;

  static Future<String> getAppVersion() async {
    if (_cachedAppVersion != null) return _cachedAppVersion!;
    try {
      final info = await PackageInfo.fromPlatform();
      _cachedAppVersion = '${info.version}+${info.buildNumber}';
    } catch (_) {
      _cachedAppVersion = '1.0.0';
    }
    return _cachedAppVersion!;
  }

  static String formatDebugDetails(dynamic error) {
    if (error == null) return '';
    if (error is FirebaseException) {
      final code = error.code;
      final msg = error.message;
      return '[${error.runtimeType}] code: $code${msg != null ? ' - $msg' : ''}';
    }
    if (error is MediaUploadException) {
      return '[MediaUploadException] status: ${error.statusCode ?? 'unknown'} - ${error.message}';
    }
    return '[${error.runtimeType}]: $error';
  }

  static String sanitizeMessage(String input) {
    var s = input.trim();
    // hide tokens
    s = s.replaceAll(RegExp(r'Bearer\s+[A-Za-z0-9\-._~+/]+=*', caseSensitive: false), '[TOKEN]');
    // hide emails
    s = s.replaceAll(RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'), '[EMAIL]');
    // hide phone numbers
    s = s.replaceAll(RegExp(r'(\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}'), '[PHONE]');
    // keep it short
    if (s.length > 300) {
      s = s.substring(0, 300);
    }
    return s;
  }

  static int _sessionReportCount = 0;
  static const int _maxSessionReports = 20;
  static final Map<String, DateTime> _recentReports = {};
  static const Duration _duplicateWindow = Duration(seconds: 60);

  static Future<void> report({
    required String screen,
    required String action,
    required dynamic error,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return;
      }

      final errorType = error.runtimeType.toString();
      String code = '';
      String rawMsg = error.toString();

      if (error is FirebaseException) {
        code = error.code;
        rawMsg = error.message ?? error.toString();
      } else if (error is MediaUploadException) {
        code = error.statusCode?.toString() ?? '';
        rawMsg = error.message;
      }

      final key = '$screen:$action:$code';
      final now = DateTime.now();

      // skip dupes within 60s
      final lastReported = _recentReports[key];
      if (lastReported != null && now.difference(lastReported) < _duplicateWindow) {
        return;
      }

      // max 20 per session
      if (_sessionReportCount >= _maxSessionReports) {
        return;
      }

      _recentReports[key] = now;
      _sessionReportCount++;

      // clean old cache entries
      _recentReports.removeWhere((_, time) => now.difference(time) > _duplicateWindow);

      final cleanMessage = sanitizeMessage(rawMsg);
      final version = await getAppVersion();
      final platform = defaultTargetPlatform.name;

      final data = <String, dynamic>{
        'screen': screen.length > 100 ? screen.substring(0, 100) : screen,
        'action': action.length > 100 ? action.substring(0, 100) : action,
        'errorType': errorType.length > 100 ? errorType.substring(0, 100) : errorType,
        'code': code.length > 100 ? code.substring(0, 100) : code,
        'message': cleanMessage,
        'appVersion': version.length > 50 ? version.substring(0, 50) : version,
        'platform': platform.length > 50 ? platform.substring(0, 50) : platform,
        'uid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      };

      unawaited(
        FirebaseFirestore.instance
            .collection(FirestorePaths.clientErrors)
            .add(data)
            .then((_) {})
            .catchError((e) {
          debugPrint('[ErrorReporter] write clientErrors error: $e');
        }),
      );
    } catch (e) {
      debugPrint('[ErrorReporter] report error: $e');
    }
  }
}
