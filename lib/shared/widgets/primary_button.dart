import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum PrimaryButtonVariant {
  amber, // amber button
  dark, // dark button
  secondary, // bordered card button
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expand;
  final bool small;
  final PrimaryButtonVariant variant;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const PrimaryButton({
    super.key,
    required this.label,
    this.leadingIcon,
    this.trailingIcon,
    this.onPressed,
    this.loading = false,
    this.expand = true,
    this.small = false,
    this.variant = PrimaryButtonVariant.amber,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    Color bg;
    Color fg;
    BorderSide borderSide = BorderSide.none;

    switch (variant) {
      case PrimaryButtonVariant.amber:
        bg = backgroundColor ?? AppColors.primary;
        fg = foregroundColor ?? AppColors.onPrimary;
        break;
      case PrimaryButtonVariant.dark:
        bg = backgroundColor ?? (isDark ? Colors.white : AppColors.ink);
        fg = foregroundColor ?? (isDark ? AppColors.ink : Colors.white);
        break;
      case PrimaryButtonVariant.secondary:
        bg = backgroundColor ?? context.themeSurface;
        fg = foregroundColor ?? context.themeInk;
        borderSide = BorderSide(color: context.themeBorder, width: 1.5);
        break;
    }

    final height = small ? 40.0 : 54.0;
    final radius = small ? 12.0 : 16.0;

    final button = ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: bg.withValues(alpha: 0.6),
        disabledForegroundColor: fg.withValues(alpha: 0.6),
        elevation: 0,
        shadowColor: Colors.transparent,
        side: borderSide,
        minimumSize: Size(expand ? double.infinity : 0, height),
        padding: EdgeInsets.symmetric(
          horizontal: small ? 14 : 20,
          vertical: small ? 8 : 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      child: loading
          ? SizedBox(
              width: small ? 18 : 22,
              height: small ? 18 : 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: fg,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leadingIcon != null) ...[
                  Icon(leadingIcon, size: small ? 18 : 20, color: fg),
                  SizedBox(width: small ? 6 : 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontWeight: FontWeight.w700,
                      fontSize: small ? 13.5 : 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (trailingIcon != null) ...[
                  SizedBox(width: small ? 6 : 8),
                  Icon(trailingIcon, size: small ? 18 : 20, color: fg),
                ],
              ],
            ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
