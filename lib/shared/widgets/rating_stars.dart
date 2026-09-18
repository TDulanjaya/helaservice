import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final ValueChanged<int>? onChanged;

  const RatingStars(
      {super.key, required this.rating, this.size = 16, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.round();
        final star = Icon(
          filled ? Icons.star : Icons.star_border,
          size: size,
          color: AppColors.secondaryContainer,
        );
        if (onChanged == null) return star;
        return GestureDetector(onTap: () => onChanged!(i + 1), child: star);
      }),
    );
  }
}
