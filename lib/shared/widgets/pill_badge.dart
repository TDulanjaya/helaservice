import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PillBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? background;
  final Color? foreground;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry? padding;

  const PillBadge({
    super.key,
    required this.label,
    this.icon,
    this.background,
    this.foreground,
    this.fontSize = 12,
    this.fontWeight = FontWeight.w700,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final bg = background ?? context.themeSoft;
    final fg = foreground ?? context.themeInk;

    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: fontSize,
              fontWeight: fontWeight,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

