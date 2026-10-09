import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import 'notification_sheet.dart';

// notification bell with unread badge counter
class NotificationBellIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const NotificationBellIcon({
    super.key,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<int>(
      stream: uid.isNotEmpty
          ? NotificationService.instance.streamUnreadCount(uid)
          : Stream.value(0),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: context.themeSurfaceLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.themeBorder),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(
                  unreadCount > 0
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_none_rounded,
                  size: size * 0.5,
                  color: color ?? context.themeTextPrimary,
                ),
                onPressed: () => NotificationSheet.show(context),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    shape: unreadCount < 10 ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius: unreadCount >= 10 ? BorderRadius.circular(10) : null,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
