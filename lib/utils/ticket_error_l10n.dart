import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

import 'l10n_extension.dart';

// friendly error message for tickets
String ticketErrorMessage(BuildContext context, Object error) {
  final l10n = context.l10n;
  final errStr = error.toString().toLowerCase();

  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return l10n.ticketSubmitPermissionDenied;
    }
    if (error.code == 'unavailable' ||
        error.code == 'deadline-exceeded' ||
        error.code == 'network-request-failed') {
      return l10n.authErrNetwork;
    }
  }

  if (errStr.contains('permission-denied') ||
      errStr.contains('permission_denied')) {
    return l10n.ticketSubmitPermissionDenied;
  }

  if (errStr.contains('network') ||
      errStr.contains('socket') ||
      errStr.contains('timeout') ||
      errStr.contains('unavailable') ||
      errStr.contains('connection')) {
    return l10n.authErrNetwork;
  }

  return l10n.ticketSubmitErrorGeneral;
}

// friendly error message for posting job requests
String jobPostErrorMessage(BuildContext context, Object error) {
  final l10n = context.l10n;
  final errStr = error.toString().toLowerCase();

  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return l10n.jobPostPermissionDenied;
    }
    if (error.code == 'unavailable' ||
        error.code == 'deadline-exceeded' ||
        error.code == 'network-request-failed') {
      return l10n.authErrNetwork;
    }
  }

  if (errStr.contains('permission-denied') ||
      errStr.contains('permission_denied')) {
    return l10n.jobPostPermissionDenied;
  }

  if (errStr.contains('network') ||
      errStr.contains('socket') ||
      errStr.contains('timeout') ||
      errStr.contains('unavailable') ||
      errStr.contains('connection')) {
    return l10n.authErrNetwork;
  }

  return l10n.jobPostErrorGeneral;
}
