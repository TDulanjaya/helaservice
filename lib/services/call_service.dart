import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/l10n_extension.dart';
import '../utils/map_launcher.dart';

class CallLog {
  final String id;
  final String callerUid;
  final String calleeUid;
  final String calleeRole;
  final String bookingId;
  final DateTime? startedAt;
  final String outcome;
  final String postCallStatus;
  final DateTime? resolvedAt;

  const CallLog({
    this.id = '',
    required this.callerUid,
    this.calleeUid = '',
    this.calleeRole = 'provider',
    this.bookingId = '',
    this.startedAt,
    this.outcome = 'initiated',
    this.postCallStatus = 'pending',
    this.resolvedAt,
  });

  Map<String, dynamic> toMap() => {
        'callerUid': callerUid,
        'calleeUid': calleeUid,
        'calleeRole': calleeRole,
        'bookingId': bookingId,
        'startedAt': startedAt != null
            ? Timestamp.fromDate(startedAt!)
            : FieldValue.serverTimestamp(),
        'outcome': outcome,
        'postCallStatus': postCallStatus,
        if (resolvedAt != null) 'resolvedAt': Timestamp.fromDate(resolvedAt!),
      };

  factory CallLog.fromMap(String id, Map<String, dynamic> map) {
    final sat = map['startedAt'];
    final rat = map['resolvedAt'];
    return CallLog(
      id: id,
      callerUid: map['callerUid'] ?? '',
      calleeUid: map['calleeUid'] ?? '',
      calleeRole: map['calleeRole'] ?? 'provider',
      bookingId: map['bookingId'] ?? '',
      startedAt: sat is Timestamp ? sat.toDate() : null,
      outcome: map['outcome'] ?? 'initiated',
      postCallStatus: map['postCallStatus'] ?? 'pending',
      resolvedAt: rat is Timestamp ? rat.toDate() : null,
    );
  }
}

class CallService {
  CallService._();
  static final CallService instance = CallService._();

  final _col = FirebaseFirestore.instance.collection('callLogs');

  // initiate phone call with audit log and follow up outcome prompt
  Future<void> startCall({
    required BuildContext context,
    required String calleePhone,
    required String calleeName,
    String? bookingId,
    String? calleeUid,
    String? calleeRole,
  }) async {
    final callerUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    String? logId;

    if (callerUid.isNotEmpty) {
      try {
        final docRef = _col.doc();
        logId = docRef.id;
        await docRef.set({
          'callerUid': callerUid,
          'calleeUid': calleeUid ?? '',
          'calleeRole': calleeRole ?? 'provider',
          'bookingId': bookingId ?? '',
          'startedAt': FieldValue.serverTimestamp(),
          'outcome': 'initiated',
          'postCallStatus': 'pending',
        });
      } catch (e) {
        debugPrint('[CallService] Could not write call log doc: $e');
      }
    }

    // open phone dialer
    await MapLauncher.openPhoneCall(calleePhone);

    // show follow up outcome prompt
    if (context.mounted && logId != null) {
      _showPostCallOutcomeSheet(
        context: context,
        logId: logId,
        calleeName: calleeName,
      );
    }
  }

  void _showPostCallOutcomeSheet({
    required BuildContext context,
    required String logId,
    required String calleeName,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: ctx.themeSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ctx.themeBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.phone_in_talk, color: AppColors.primary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.didYouReachPerson(calleeName),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildOutcomeButton(
                context: ctx,
                label: context.l10n.callOutcomeAnswered,
                icon: Icons.check_circle_outline,
                color: AppColors.success,
                onTap: () => _resolveCall(ctx, logId, 'connected'),
              ),
              const SizedBox(height: 8),
              _buildOutcomeButton(
                context: ctx,
                label: context.l10n.callOutcomeNoAnswer,
                icon: Icons.phone_missed,
                color: AppColors.warning,
                onTap: () => _resolveCall(ctx, logId, 'no_answer'),
              ),
              const SizedBox(height: 8),
              _buildOutcomeButton(
                context: ctx,
                label: context.l10n.callOutcomeWrongNumber,
                icon: Icons.error_outline,
                color: AppColors.error,
                onTap: () => _resolveCall(ctx, logId, 'wrong_number'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutcomeButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: context.themeTextPrimary,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _resolveCall(BuildContext context, String logId, String outcome) async {
    Navigator.pop(context);
    try {
      await _col.doc(logId).update({
        'outcome': outcome,
        'postCallStatus': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[CallService] Could not resolve call outcome: $e');
    }
  }

  Stream<List<CallLog>> streamAllCallLogs() {
    return _col.orderBy('startedAt', descending: true).limit(100).snapshots().map(
          (snap) => snap.docs.map((d) => CallLog.fromMap(d.id, d.data())).toList(),
        );
  }
}
