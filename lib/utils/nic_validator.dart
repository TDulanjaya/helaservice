import 'dart:io';
import '../l10n/app_localizations.dart';

class NicValidator {
  NicValidator._();

  static final RegExp _nicRegex = RegExp(r'^(\d{9}[VX]|\d{12})$');

  /// Trims spaces and turns lowercase 'v'/'x' into uppercase 'V'/'X'.
  static String cleanNic(String? input) {
    if (input == null) return '';
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '';
    final lastChar = trimmed[trimmed.length - 1];
    if (lastChar == 'v' || lastChar == 'x') {
      return '${trimmed.substring(0, trimmed.length - 1)}${lastChar.toUpperCase()}';
    }
    return trimmed;
  }

  /// Valid formats:
  /// - Old: 9 digits + V or X (e.g. 123456789V)
  /// - New: 12 digits (e.g. 200012345678)
  /// Case-insensitive for v/x (cleaned before checking).
  static bool isValidNic(String? input) {
    if (input == null) return false;
    final cleaned = cleanNic(input);
    return _nicRegex.hasMatch(cleaned);
  }

  /// Returns translated error string if invalid, or null if valid.
  static String? validateNic(String? input, AppLocalizations l10n,
      {bool isRequired = true}) {
    if (input == null || input.trim().isEmpty) {
      return isRequired ? l10n.enterNicError : null;
    }
    final cleaned = cleanNic(input);
    if (!_nicRegex.hasMatch(cleaned)) {
      return l10n.invalidNicFormatError;
    }
    return null;
  }

  /// Maps errors on provider registration/NIC upload to friendly user messages:
  /// - private_storage_not_configured / 5xx → “We couldn’t upload your NIC right now. Please try again later.”
  /// - network error → authErrNetwork
  /// - email_otp_required → “Please verify your email first.”
  /// - anything else → “Couldn’t complete your profile. Please try again.”
  static String mapProfileError(Object? error, AppLocalizations l10n) {
    if (error == null) {
      return l10n.profileCompletionError;
    }

    final errStr = error.toString().toLowerCase();

    // 1. private_storage_not_configured / 5xx
    if (errStr.contains('private_storage_not_configured') ||
        errStr.contains('500') ||
        errStr.contains('502') ||
        errStr.contains('503') ||
        errStr.contains('504') ||
        errStr.contains('5xx')) {
      return l10n.nicUploadErrorRetry;
    }

    // 2. email_otp_required
    if (errStr.contains('email_otp_required') ||
        errStr.contains('email otp verification is required')) {
      return l10n.emailOtpRequiredError;
    }

    // 3. network error
    if (error is SocketException ||
        errStr.contains('socketexception') ||
        errStr.contains('clientexception') ||
        errStr.contains('timeoutexception') ||
        errStr.contains('handshakeexception') ||
        errStr.contains('failed host lookup') ||
        errStr.contains('network error') ||
        errStr.contains('network') ||
        errStr.contains('connection refused') ||
        errStr.contains('connection closed') ||
        errStr.contains('connection abort') ||
        errStr.contains('offline') ||
        errStr.contains('timed out') ||
        errStr.contains('timeout') ||
        errStr.contains('unavailable')) {
      return l10n.authErrNetwork;
    }

    // 4. anything else
    return l10n.profileCompletionError;
  }
}
