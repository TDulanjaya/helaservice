import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class HeroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool showAmberGlow;
  final double radius;

  const HeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.showAmberGlow = true,
    this.radius = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final bg = context.themeHeroSurface;
    final border = context.themeHeroBorder;

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: border, width: 1.0),
        ),
        child: Stack(
          children: [
            if (showAmberGlow)
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(
                      alpha: context.isDark ? 0.18 : 0.25,
                    ),
                  ),
                ),
              ),
            child,
          ],
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: card,
        ),
      );
    }

    return card;
  }
}
