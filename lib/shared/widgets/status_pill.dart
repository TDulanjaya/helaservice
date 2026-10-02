import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum StatusPillType {
  online,
  pending,
  inProgress,
  completed,
  cancelled,
  offline,
  you,
  custom,
}

class StatusPill extends StatelessWidget {
  final String? label;
  final StatusPillType type;
  final bool showDot;
  final Color? customBackground;
  final Color? customForeground;

  const StatusPill({
    super.key,
    this.label,
    required this.type,
    this.showDot = false,
    this.customBackground,
    this.customForeground,
  });

  const StatusPill.online({super.key, this.label = 'Online'})
      : type = StatusPillType.online,
        showDot = true,
        customBackground = null,
        customForeground = null;

  const StatusPill.pending({super.key, this.label = 'Pending'})
      : type = StatusPillType.pending,
        showDot = false,
        customBackground = null,
        customForeground = null;

  const StatusPill.inProgress({super.key, this.label = 'In Progress'})
      : type = StatusPillType.inProgress,
        showDot = false,
        customBackground = null,
        customForeground = null;

  const StatusPill.completed({super.key, this.label = 'Completed'})
      : type = StatusPillType.completed,
        showDot = false,
        customBackground = null,
        customForeground = null;

  const StatusPill.cancelled({super.key, this.label = 'Cancelled'})
      : type = StatusPillType.cancelled,
        showDot = false,
        customBackground = null,
        customForeground = null;

  const StatusPill.offline({super.key, this.label = 'Offline'})
      : type = StatusPillType.offline,
        showDot = true,
        customBackground = null,
        customForeground = null;

  const StatusPill.you({super.key, this.label = 'You'})
      : type = StatusPillType.you,
        showDot = false,
        customBackground = null,
        customForeground = null;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String text = label ?? '';

    switch (type) {
      case StatusPillType.online:
        bg = context.themeSuccessTint;
        fg = context.themeSuccess;
        text = label ?? 'Online';
        break;
      case StatusPillType.pending:
        bg = context.themeAmberTint;
        fg = context.themeAmberText;
        text = label ?? 'Pending';
        break;
      case StatusPillType.inProgress:
        bg = context.themeInfoTint;
        fg = context.themeInfo;
        text = label ?? 'In Progress';
        break;
      case StatusPillType.completed:
        bg = context.themeSuccessTint;
        fg = context.themeSuccess;
        text = label ?? 'Completed';
        break;
      case StatusPillType.cancelled:
        bg = context.themeDangerTint;
        fg = context.themeDanger;
        text = label ?? 'Cancelled';
        break;
      case StatusPillType.offline:
        bg = context.themeSoft;
        fg = context.themeMuted;
        text = label ?? 'Offline';
        break;
      case StatusPillType.you:
        bg = context.isDark ? Colors.white : AppColors.ink;
        fg = context.isDark ? AppColors.ink : Colors.white;
        text = label ?? 'You';
        break;
      case StatusPillType.custom:
        bg = customBackground ?? context.themeSoft;
        fg = customForeground ?? context.themeInk;
        break;
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: fg,
                shape: BoxShape.circle,
              ),
            ),
          ],
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
