import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AppOutlineButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? borderColor;
  final Color? backgroundColor;
  final bool expand;
  final bool small;

  const AppOutlineButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color,
    this.borderColor,
    this.backgroundColor,
    this.expand = true,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? context.themeInk;
    final height = small ? 40.0 : 54.0;
    final radius = small ? 12.0 : 16.0;

    final button = SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: effectiveColor,
          backgroundColor: backgroundColor ?? Colors.transparent,
          side: BorderSide(
            color: borderColor ?? context.themeBorder,
            width: 1.5,
          ),
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: small ? 14 : 20,
            vertical: 0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: small ? 16 : 18, color: effectiveColor),
              SizedBox(width: small ? 6 : 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: small ? 13.0 : 14.5,
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
