import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PillBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? background;
  final Color? foreground;
  final double fontSize;

  const PillBadge({
    super.key,
    required this.label,
    this.icon,
    this.background,
    this.foreground,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final bg = background ?? context.themeSurfaceContainer;
    final fg = foreground ?? context.themeTextSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 3, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
                color: fg,
                fontSize: fontSize,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
