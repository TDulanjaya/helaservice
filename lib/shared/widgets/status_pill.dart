import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/l10n_extension.dart';
import '../../constants/job_status.dart';

enum StatusPillType {
  online,
  pending,
  confirmed,
  enRoute,
  inProgress,
  completed,
  cancelled,
  declined,
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

  const StatusPill.online({super.key, this.label})
      : type = StatusPillType.online,
        showDot = true,
        customBackground = null,
        customForeground = null;

  const StatusPill.pending({super.key, this.label})
      : type = StatusPillType.pending,
        showDot = false,
        customBackground = null,
        customForeground = null;

  const StatusPill.confirmed({super.key, this.label})
      : type = StatusPillType.confirmed,
        showDot = false,
        customBackground = null,
        customForeground = null;

  const StatusPill.enRoute({super.key, this.label})
      : type = StatusPillType.enRoute,
        showDot = true,
        customBackground = null,
        customForeground = null;

  const StatusPill.inProgress({super.key, this.label})
      : type = StatusPillType.inProgress,
        showDot = false,
        customBackground = null,
        customForeground = null;

  const StatusPill.completed({super.key, this.label})
      : type = StatusPillType.completed,
        showDot = false,
        customBackground = null,
        customForeground = null;

  const StatusPill.cancelled({super.key, this.label})
      : type = StatusPillType.cancelled,
        showDot = false,
        customBackground = null,
        customForeground = null;

  const StatusPill.declined({super.key, this.label})
      : type = StatusPillType.declined,
        showDot = false,
        customBackground = null,
        customForeground = null;

  const StatusPill.offline({super.key, this.label})
      : type = StatusPillType.offline,
        showDot = true,
        customBackground = null,
        customForeground = null;

  const StatusPill.you({super.key, this.label})
      : type = StatusPillType.you,
        showDot = false,
        customBackground = null,
        customForeground = null;

  factory StatusPill.fromStatus(String status, {String? customLabel}) {
    switch (status) {
      case JobStatus.pending:
      case JobRequestStatus.pendingProvider:
        return StatusPill.pending(label: customLabel);
      case JobStatus.confirmed:
      case JobRequestStatus.assigned:
        return StatusPill.confirmed(label: customLabel);
      case JobStatus.enRoute:
        return StatusPill.enRoute(label: customLabel);
      case JobStatus.inProgress:
        return StatusPill.inProgress(label: customLabel);
      case JobStatus.completed:
        return StatusPill.completed(label: customLabel);
      case JobStatus.cancelled:
        return StatusPill.cancelled(label: customLabel);
      case JobStatus.declined:
        return StatusPill.declined(label: customLabel);
      default:
        return StatusPill.pending(label: customLabel ?? status);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String text = label ?? '';

    switch (type) {
      case StatusPillType.online:
        bg = context.themeSuccessTint;
        fg = context.themeSuccess;
        text = label ?? context.l10n.online;
        break;
      case StatusPillType.pending:
        bg = context.themeAmberTint;
        fg = context.themeAmberText;
        text = label ?? context.l10n.statusPending;
        break;
      case StatusPillType.confirmed:
        bg = AppColors.primary.withValues(alpha: 0.12);
        fg = AppColors.primary;
        text = label ?? context.l10n.statusConfirmed;
        break;
      case StatusPillType.enRoute:
        bg = const Color(0xFF3B82F6).withValues(alpha: 0.14);
        fg = const Color(0xFF2563EB);
        text = label ?? context.l10n.statusEnRoute;
        break;
      case StatusPillType.inProgress:
        bg = context.themeInfoTint;
        fg = context.themeInfo;
        text = label ?? context.l10n.statusInProgress;
        break;
      case StatusPillType.completed:
        bg = context.themeSuccessTint;
        fg = context.themeSuccess;
        text = label ?? context.l10n.statusCompleted;
        break;
      case StatusPillType.cancelled:
        bg = context.themeDangerTint;
        fg = context.themeDanger;
        text = label ?? context.l10n.statusCancelled;
        break;
      case StatusPillType.declined:
        bg = context.themeDangerTint;
        fg = context.themeDanger;
        text = label ?? context.l10n.statusDeclined;
        break;
      case StatusPillType.offline:
        bg = context.themeSoft;
        fg = context.themeMuted;
        text = label ?? context.l10n.offline;
        break;
      case StatusPillType.you:
        bg = context.isDark ? Colors.white : AppColors.ink;
        fg = context.isDark ? AppColors.ink : Colors.white;
        text = label ?? context.l10n.you;
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
