import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum IconSquareButtonStyle {
  outline, // border with surface background
  soft, // soft grey tile
  amber, // amber background
  ink, // dark card background
}

class IconSquareButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double? iconSize;
  final double radius;
  final IconSquareButtonStyle style;
  final Color? color;
  final Color? iconColor;
  final String? tooltip;

  const IconSquareButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 44.0,
    this.iconSize,
    this.radius = 14.0,
    this.style = IconSquareButtonStyle.outline,
    this.color,
    this.iconColor,
    this.tooltip,
  });

  const IconSquareButton.small({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 40.0,
    this.iconSize = 18.0,
    this.radius = 12.0,
    this.style = IconSquareButtonStyle.soft,
    this.color,
    this.iconColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide borderSide = BorderSide.none;

    switch (style) {
      case IconSquareButtonStyle.outline:
        bg = color ?? context.themeSurface;
        fg = iconColor ?? context.themeInk;
        borderSide = BorderSide(color: context.themeBorder, width: 1.2);
        break;
      case IconSquareButtonStyle.soft:
        bg = color ?? context.themeSoft;
        fg = iconColor ?? context.themeInk;
        borderSide = BorderSide(
            color: context.themeBorder.withValues(alpha: 0.5), width: 1.0);
        break;
      case IconSquareButtonStyle.amber:
        bg = color ?? AppColors.primary;
        fg = iconColor ?? AppColors.onPrimary;
        break;
      case IconSquareButtonStyle.ink:
        bg = color ?? context.themeHeroSurface;
        fg = iconColor ?? Colors.white;
        borderSide = BorderSide(color: context.themeHeroBorder, width: 1.0);
        break;
    }

    Widget button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: borderSide != BorderSide.none
            ? Border.fromBorderSide(borderSide)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Center(
            child: Icon(
              icon,
              size: iconSize ?? (size * 0.46),
              color: fg,
            ),
          ),
        ),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
