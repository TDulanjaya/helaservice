import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PillBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color background;
  final Color foreground;
  final double fontSize;

  const PillBadge({
    super.key,
    required this.label,
    this.icon,
    this.background = AppColors.surfaceContainer,
    this.foreground = AppColors.onSurfaceVariant,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 3, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
                color: foreground,
                fontSize: fontSize,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
