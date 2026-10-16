import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final ValueChanged<int>? onChanged;
  final Color? color;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.onChanged,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;
    final inactiveColor =
        context.isDark ? const Color(0xFF3A4048) : const Color(0xFFD4CEBF);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.round();
        final star = Icon(
          filled ? Icons.star_rounded : Icons.star_rounded,
          size: size,
          color: filled ? activeColor : inactiveColor,
        );
        if (onChanged == null) return star;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged!(i + 1),
          child: star,
        );
      }),
    );
  }
}
