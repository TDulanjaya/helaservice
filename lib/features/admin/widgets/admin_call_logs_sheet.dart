import 'package:flutter/material.dart';
import '../../../services/call_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/l10n_extension.dart';

class AdminCallLogsSheet extends StatelessWidget {
  const AdminCallLogsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const AdminCallLogsSheet(),
    );
  }

  Color _getOutcomeColor(String outcome) {
    switch (outcome.toLowerCase()) {
      case 'connected':
        return AppColors.success;
      case 'no_answer':
        return AppColors.warning;
      case 'wrong_number':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  String _getOutcomeLabel(BuildContext context, String outcome) {
    switch (outcome.toLowerCase()) {
      case 'connected':
        return context.l10n.callOutcomeAnswered;
      case 'no_answer':
        return context.l10n.callOutcomeNoAnswer;
      case 'wrong_number':
        return context.l10n.callOutcomeWrongNumber;
      default:
        return outcome;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.themeBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.phone_in_talk, color: AppColors.primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.callLogsTitle,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<CallLog>>(
                stream: CallService.instance.streamAllCallLogs(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final logs = snapshot.data ?? [];
                  if (logs.isEmpty) {
                    return Center(
                      child: Text(
                        context.l10n.noBookingsFound,
                        style: TextStyle(color: context.themeTextSecondary),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final outcomeColor = _getOutcomeColor(log.outcome);
                      final outcomeText = _getOutcomeLabel(context, log.outcome);

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.themeSurfaceLow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: context.themeBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 14, color: context.themeTextSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      log.startedAt != null
                                          ? log.startedAt!.toLocal().toString().substring(0, 16)
                                          : context.l10n.timeJustNow,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.themeTextSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: outcomeColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    outcomeText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: outcomeColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.l10n.callLogCaller,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: context.themeTextSecondary,
                                        ),
                                      ),
                                      Text(
                                        log.callerUid.length > 8
                                            ? '${log.callerUid.substring(0, 8)}...'
                                            : log.callerUid,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.l10n.callLogCallee,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: context.themeTextSecondary,
                                        ),
                                      ),
                                      Text(
                                        '${log.calleeRole} (${log.calleeUid.length > 8 ? log.calleeUid.substring(0, 8) : log.calleeUid})',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (log.bookingId.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Booking: ${log.bookingId}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.themeTextSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
