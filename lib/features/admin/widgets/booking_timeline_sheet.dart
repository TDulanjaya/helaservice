import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/booking_timeline_event.dart';
import '../../../repositories/booking_repository.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/l10n_extension.dart';

// sheet displaying chronological booking timeline
class BookingTimelineSheet extends StatelessWidget {
  final String bookingId;
  final String bookingTitle;

  const BookingTimelineSheet({
    super.key,
    required this.bookingId,
    required this.bookingTitle,
  });

  static void show(BuildContext context, {required String bookingId, required String bookingTitle}) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BookingTimelineSheet(
        bookingId: bookingId,
        bookingTitle: bookingTitle,
      ),
    );
  }

  void _exportTimelineCsv(BuildContext context, List<BookingTimelineEvent> events) {
    if (events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noEntriesToExport)),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('Event ID,Action,Title,Description,Actor Role,Actor UID,Timestamp');

    for (final e in events) {
      final tsStr = e.timestamp != null
          ? DateFormat('yyyy-MM-dd HH:mm:ss').format(e.timestamp!)
          : '';
      final desc = e.description.replaceAll('"', '""');
      final title = e.title.replaceAll('"', '""');
      buffer.writeln('"${e.id}","${e.action}","$title","$desc","${e.actorRole}","${e.actorUid}","$tsStr"');
    }

    // copy to clipboard or show modal with csv preview
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.exportCsv),
        content: SingleChildScrollView(
          child: SelectableText(
            buffer.toString(),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n.close),
          ),
        ],
      ),
    );
  }

  IconData _iconForAction(String action) {
    switch (action) {
      case 'created':
        return Icons.add_circle_outline_rounded;
      case 'accepted':
        return Icons.check_circle_outline_rounded;
      case 'declined':
        return Icons.cancel_outlined;
      case 'en_route':
        return Icons.directions_car_rounded;
      case 'arrived':
        return Icons.location_on_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'payment_confirmed':
        return Icons.payments_rounded;
      case 'payment_disputed':
        return Icons.warning_amber_rounded;
      case 'cancelled':
        return Icons.highlight_off_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  Color _colorForAction(String action) {
    switch (action) {
      case 'created':
        return AppColors.info;
      case 'accepted':
      case 'completed':
      case 'payment_confirmed':
        return AppColors.success;
      case 'en_route':
      case 'arrived':
        return AppColors.primary;
      case 'payment_disputed':
      case 'declined':
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: StreamBuilder<List<BookingTimelineEvent>>(
        stream: BookingRepository().streamTimelineEvents(bookingId),
        builder: (context, snapshot) {
          final events = snapshot.data ?? [];
          return Column(
            children: [
              const SizedBox(height: 12),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.timeline_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.bookingTimelineTitle,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: context.themeTextPrimary,
                            ),
                          ),
                          if (bookingTitle.isNotEmpty)
                            Text(
                              bookingTitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.themeTextSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _exportTimelineCsv(context, events),
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: Text(context.l10n.exportCsv),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : events.isEmpty
                        ? Center(
                            child: Text(
                              context.l10n.noTimelineEvents,
                              style: TextStyle(color: context.themeTextSecondary),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: events.length,
                            itemBuilder: (context, index) {
                              final event = events[index];
                              final isLast = index == events.length - 1;
                              final color = _colorForAction(event.action);
                              final icon = _iconForAction(event.action);
                              final timeStr = event.timestamp != null
                                  ? DateFormat('MMM d, hh:mm a').format(event.timestamp!)
                                  : '';

                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.15),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: color, width: 1.5),
                                          ),
                                          child: Icon(icon, color: color, size: 16),
                                        ),
                                        if (!isLast)
                                          Expanded(
                                            child: Container(
                                              width: 2,
                                              color: context.themeBorder,
                                              margin: const EdgeInsets.symmetric(vertical: 4),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.only(bottom: 20),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    event.title,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w700,
                                                      color: context.themeTextPrimary,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  timeStr,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: context.themeTextSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              event.description,
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                color: context.themeTextSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: context.themeSurfaceLow,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: context.themeBorder),
                                              ),
                                              child: Text(
                                                event.actorRole.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.5,
                                                  color: context.themeTextSecondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}
