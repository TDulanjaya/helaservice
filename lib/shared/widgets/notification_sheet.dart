import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart' as pv;

import '../../models/app_notification.dart';
import '../../repositories/booking_repository.dart';
import '../../services/notification_service.dart';
import '../../state/role_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/l10n_extension.dart';
import '../widgets/app_card.dart';
import '../screens/conversations_inbox_screen.dart';
import '../../features/customer/screens/live_tracking_screen.dart';
import '../../features/customer/screens/job_quotes_screen.dart';
import '../../features/provider/screens/en_route_navigation_screen.dart';

// bottom sheet for alerts and notifications
class NotificationSheet extends StatelessWidget {
  const NotificationSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NotificationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleProvider = pv.Provider.of<RoleProvider>(context);
    final user = roleProvider.currentUser;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? (user?.id ?? '');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // drag handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.themeBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),

            // header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.notifications_active_outlined,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        context.l10n.proNotificationsTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () async {
                      if (uid.isNotEmpty) {
                        await NotificationService.instance.markAllAsRead(uid);
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.l10n.proMarkAllRead),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    child: Text(
                      context.l10n.proMarkAllRead,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 16),

            // notification list stream
            Expanded(
              child: StreamBuilder<List<AppNotification>>(
                stream:
                    NotificationService.instance.streamUserNotifications(uid),
                builder: (context, snapshot) {
                  final notifications = snapshot.data ?? [];

                  if (notifications.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 48,
                              color: context.themeTextSecondary
                                  .withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              context.l10n.proNoNotifications,
                              style: TextStyle(
                                color: context.themeTextSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      return _NotificationCard(
                        notification: item,
                        currentUid: uid,
                        isProvider: roleProvider.role == AppRole.provider,
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

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final String currentUid;
  final bool isProvider;

  const _NotificationCard({
    required this.notification,
    required this.currentUid,
    required this.isProvider,
  });

  IconData _iconForType(String type) {
    switch (type) {
      case 'quote_received':
      case 'quote_accepted':
        return Icons.local_offer_outlined;
      case 'provider_en_route':
        return Icons.directions_car_outlined;
      case 'provider_arrived':
        return Icons.location_on_outlined;
      case 'job_completed':
        return Icons.check_circle_outline;
      case 'payment_recorded':
        return Icons.payments_outlined;
      case 'new_chat_message':
        return Icons.chat_bubble_outline;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'quote_accepted':
      case 'job_completed':
      case 'payment_recorded':
        return const Color(0xFF22C55E);
      case 'provider_en_route':
      case 'provider_arrived':
        return AppColors.primary;
      case 'new_chat_message':
        return const Color(0xFF3B82F6);
      default:
        return AppColors.primary;
    }
  }

  String _formatTime(DateTime? date, BuildContext context) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return context.l10n.timeJustNow;
    if (diff.inMinutes < 60) return context.l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return context.l10n.timeHoursAgo(diff.inHours);
    return context.l10n.timeDaysAgo(diff.inDays);
  }

  Future<void> _handleTap(BuildContext context) async {
    // mark item as read
    if (!notification.isRead) {
      await NotificationService.instance
          .markAsRead(currentUid, notification.id);
    }

    if (!context.mounted) return;
    Navigator.pop(context);

    // navigate based on target data
    if (notification.bookingId != null && notification.bookingId!.isNotEmpty) {
      final bookingSnap =
          await BookingRepository().getBookingById(notification.bookingId!);
      if (bookingSnap != null && context.mounted) {
        if (isProvider) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EnRouteNavigationScreen(booking: bookingSnap),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LiveTrackingScreen(booking: bookingSnap),
            ),
          );
        }
        return;
      }
    }

    if (!context.mounted) return;

    if (notification.jobRequestId != null &&
        notification.jobRequestId!.isNotEmpty &&
        !isProvider) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => JobQuotesScreen(
            requestId: notification.jobRequestId!,
            jobTitle: notification.title,
          ),
        ),
      );
      return;
    }

    if (notification.chatRoomId != null ||
        notification.eventType == 'new_chat_message') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ConversationsInboxScreen(),
        ),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(notification.eventType);
    final icon = _iconForType(notification.eventType);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.error),
      ),
      onDismissed: (_) {
        NotificationService.instance
            .deleteNotification(currentUid, notification.id);
      },
      child: AppCard(
        onTap: () => _handleTap(context),
        padding: const EdgeInsets.all(14),
        borderColor: !notification.isRead
            ? color.withValues(alpha: 0.4)
            : context.themeBorder,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                            fontSize: 13.5,
                            color: context.themeInk,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!notification.isRead) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.themeTextSecondary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (notification.createdAt != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(notification.createdAt, context),
                      style: TextStyle(
                        fontSize: 10.5,
                        color: context.themeMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
