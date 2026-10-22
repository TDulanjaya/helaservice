import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../constants/firestore_paths.dart';
import '../features/auth/screens/email_otp_screen.dart';
import '../main.dart';

// check if user session is still valid
class SessionGuard {
  SessionGuard._();
  static final SessionGuard instance = SessionGuard._();

  // track if user is currently inside an auth screen
  static int _authScreensOpen = 0;
  static bool get isAuthFlowActive => _authScreensOpen > 0;

  static void enterAuthScreen() {
    _authScreensOpen++;
  }

  static void exitAuthScreen() {
    if (_authScreensOpen > 0) {
      _authScreensOpen--;
    }
  }

  // keep track of sent otps per uid and auth_time so we dont spam emails
  static final Set<String> _sentOtpKeys = <String>{};
  static bool _isChecking = false;
  static bool _isNavigatingToOtp = false;
  static DateTime? _lastResumeTokenRefreshAt;

  // remember that we sent an otp for this user and login
  static void markOtpSent(String uid, int authTime) {
    _sentOtpKeys.add('${uid}_$authTime');
  }

  // see if we already sent one for this user and login
  static bool hasOtpBeenSent(String uid, int authTime) {
    return _sentOtpKeys.contains('${uid}_$authTime');
  }

  // handle firestore permission denied
  static Future<bool> handlePermissionDenied(Object? error) async {
    if (error == null) return false;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || isAuthFlowActive) return false;

    final isPermissionDenied = (error is FirebaseException &&
            error.code == 'permission-denied') ||
        error.toString().contains('permission-denied');
    if (!isPermissionDenied) return false;
    return instance.checkSessionValid();
  }

  // check if device is verified
  Future<bool> checkSessionValid({bool fromResume = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return true;
    if (isAuthFlowActive) return false;
    if (_isChecking || _isNavigatingToOtp) return false;

    // throttle token refresh on resume to at most once every 30s
    if (fromResume) {
      if (_lastResumeTokenRefreshAt != null &&
          DateTime.now().difference(_lastResumeTokenRefreshAt!) <
              const Duration(seconds: 30)) {
        return true;
      }
      _lastResumeTokenRefreshAt = DateTime.now();
    }

    _isChecking = true;
    try {
      // get fresh token from firebase
      await user.getIdToken(true);
      final tokenResult = await user.getIdTokenResult();

      final authTime = tokenResult.authTime?.millisecondsSinceEpoch != null
          ? (tokenResult.authTime!.millisecondsSinceEpoch ~/ 1000)
          : null;
      final rawLoginTimes = tokenResult.claims?['loginOtpTimes'];
      final List<int> loginOtpTimes = (rawLoginTimes is List)
          ? rawLoginTimes.map((e) => (e as num).toInt()).toList()
          : <int>[];

      final isVerified = authTime != null && loginOtpTimes.contains(authTime);
      if (isVerified) {
        return true;
      }

      // device got kicked out, send user to otp
      _redirectToOtpScreen(user, authTime);
      return false;
    } catch (_) {
      return false;
    } finally {
      _isChecking = false;
    }
  }

  void _redirectToOtpScreen(User user, int? authTime) async {
    if (_isNavigatingToOtp || isAuthFlowActive) return;
    _isNavigatingToOtp = true;

    try {
      bool isAdmin = false;
      try {
        final superDoc = await FirebaseFirestore.instance
            .collection('superAdmins')
            .doc(user.uid)
            .get();
        if (superDoc.exists) {
          isAdmin = true;
        } else {
          final adminDoc = await FirebaseFirestore.instance
              .collection(FirestorePaths.admins)
              .doc(user.uid)
              .get();
          if (adminDoc.exists && adminDoc.data()?['status'] == 'active') {
            isAdmin = true;
          }
        }
      } catch (_) {}

      final purpose = isAdmin ? 'admin_login' : 'login';

      final bool sendOnOpen;
      if (authTime != null) {
        if (_sentOtpKeys.contains('${user.uid}_$authTime')) {
          sendOnOpen = false;
        } else {
          _sentOtpKeys.add('${user.uid}_$authTime');
          sendOnOpen = true;
        }
      } else {
        sendOnOpen = true;
      }

      final nav = appNavigatorKey.currentState;
      if (nav != null) {
        nav.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => EmailOtpScreen(
              email: user.email ?? '',
              purpose: purpose,
              sendOnOpen: sendOnOpen,
            ),
          ),
          (route) => false,
        );
      }
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        _isNavigatingToOtp = false;
      });
    }
  }
}

// catch permission errors on firestore streams
extension SessionGuardStreamExtension<T> on Stream<T> {
  Stream<T> withSessionGuard() {
    return transform(
      StreamTransformer<T, T>.fromHandlers(
        handleData: (data, sink) => sink.add(data),
        handleError: (error, stackTrace, sink) {
          SessionGuard.handlePermissionDenied(error);
          sink.addError(error, stackTrace);
        },
        handleDone: (sink) => sink.close(),
      ),
    );
  }
}
