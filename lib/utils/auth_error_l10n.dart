import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/widgets.dart';

import '../services/auth_service.dart';
import '../services/otp_service.dart';
import 'l10n_extension.dart';

// map otp server error codes to localized messages
String mapOtpErrorCode(
  BuildContext context,
  String? code, {
  int? attemptsRemaining,
}) {
  final l10n = context.l10n;
  final normalized = (code ?? '').trim().toLowerCase();

  switch (normalized) {
    case 'otp_required':
    case 'otp_code_incomplete':
    case 'empty_otp':
      return l10n.enterOtp;

    case 'invalid_purpose':
    case 'invalid_request':
      return l10n.invalidRequest;

    case 'otp_no_session':
      return l10n.otpNoSession;

    case 'otp_expired':
      return l10n.otpExpiredResend;

    case 'otp_max_attempts':
      return l10n.otpMaxAttemptsResend;

    case 'otp_incorrect':
      if (attemptsRemaining != null && attemptsRemaining > 0) {
        return l10n.otpIncorrectTriesLeft(attemptsRemaining);
      }
      return l10n.codeIncorrect;

    case 'rate_limited_ip':
    case 'rate_limited_uid':
    case 'cooldown':
    case 'too_many_requests':
      return l10n.authErrTooManyRequests;

    case 'login_otp_required':
      return l10n.loginOtpRequired;

    case 'network_error':
    case 'otp_network_error':
    case 'network':
      return l10n.authErrNetwork;

    case 'timeout':
      return l10n.requestTimeout;

    case 'not_admin':
      return l10n.unauthorizedAdminAccess;

    case 'no_email':
      return l10n.authErrInvalidEmail;

    default:
      return l10n.somethingWentWrong;
  }
}

// helper to map any error caught in otp flows to localized message
String mapOtpError(BuildContext context, Object error) {
  if (error is OtpException) {
    return mapOtpErrorCode(context, error.code);
  }
  return authErrorMessage(context, error);
}

// auth error translations
String authErrorMessage(BuildContext context, Object error) {
  final l10n = context.l10n;

  if (error is OtpException) {
    return mapOtpErrorCode(context, error.code);
  }

  if (error is AuthFlowException) {
    switch (error.code) {
      case AuthFlowException.googleNoAccount:
        return l10n.googleNoAccountMessage;
      case AuthFlowException.network:
        return l10n.authErrNetwork;
    }
  }

  if (error is fb.FirebaseAuthException) {
    switch (error.code) {
      case 'user-not-found':
        return l10n.authErrUserNotFound;
      case 'wrong-password':
      case 'invalid-credential':
        return l10n.authErrWrongCredentials;
      case 'email-already-in-use':
        return l10n.authErrEmailInUse;
      case 'weak-password':
        return l10n.authErrWeakPassword;
      case 'invalid-email':
        return l10n.authErrInvalidEmail;
      case 'user-disabled':
        return l10n.authErrUserDisabled;
      case 'too-many-requests':
        return l10n.authErrTooManyRequests;
      case 'network-request-failed':
        return l10n.authErrNetwork;
      case 'ERROR_ABORTED_BY_USER':
        return l10n.authErrSignInCancelled;
    }
  }

  // service fallback
  final readable = AuthService.getReadableAuthError(error);

  // match known exceptions
  switch (readable) {
    case 'user-not-found':
    case 'No account found with this email. Please check your spelling or register.':
      return l10n.authErrUserNotFound;
    case 'wrong-password':
    case 'invalid-credential':
    case 'Incorrect password or email. Please check your credentials.':
      return l10n.authErrWrongCredentials;
    case 'email-already-in-use':
    case 'An account already exists with this email address.':
      return l10n.authErrEmailInUse;
    case 'weak-password':
    case 'The password is too weak. Please use at least 6 characters.':
      return l10n.authErrWeakPassword;
    case 'invalid-email':
    case 'Please enter a valid email address.':
      return l10n.authErrInvalidEmail;
    case 'user-disabled':
    case 'This account has been disabled. Please contact support.':
      return l10n.authErrUserDisabled;
    case 'too-many-requests':
    case 'Too many attempts. Please wait a moment before trying again.':
      return l10n.authErrTooManyRequests;
    case 'network-request-failed':
    case 'Network connection issue. Please check your internet connection.':
      return l10n.authErrNetwork;
    case 'ERROR_ABORTED_BY_USER':
    case 'Sign-in cancelled by user.':
      return l10n.authErrSignInCancelled;
    case 'Firebase user data is not available.':
      return l10n.authErrUserDataUnavailable;
    case 'User is already registered as an administrator.':
      return l10n.authErrAlreadyAdmin;
  }

  // Google Sign-In PlatformException / ApiException patterns
  if (readable.contains('ApiException: 10') ||
      readable.contains('DEVELOPER_ERROR')) {
    return l10n.somethingWentWrong;
  }
  if (readable.contains('12501') ||
      readable.contains('sign_in_canceled') ||
      readable.contains('ERROR_ABORTED_BY_USER')) {
    return l10n.authErrSignInCancelled;
  }
  if (readable.contains('ApiException: 7') ||
      readable.contains('NETWORK_ERROR')) {
    return l10n.authErrNetwork;
  }
  if (readable.contains('Valid API key required') ||
      readable.contains('Server misconfigured')) {
    return l10n.somethingWentWrong;
  }

  const authFailedPrefix = 'Authentication failed for ';
  if (readable.startsWith(authFailedPrefix)) {
    return l10n.authErrAuthenticationFailed(
        readable.substring(authFailedPrefix.length));
  }

  const regFailedPrefix = 'Registration failed for ';
  if (readable.startsWith(regFailedPrefix)) {
    return l10n
        .authErrRegistrationFailed(readable.substring(regFailedPrefix.length));
  }

  final noUserMatch = RegExp(
    r'^No registered user found with email "(.*)"\. The person must first register an account in the app before they can be promoted to an administrator\.$',
  ).firstMatch(readable);
  if (noUserMatch != null) {
    return l10n.authErrNoRegisteredUser(noUserMatch.group(1) ?? '');
  }

  debugPrint('[authErrorMessage] unmapped error: $error');
  return l10n.somethingWentWrong;
}
