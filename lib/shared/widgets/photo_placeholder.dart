import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PhotoPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final double iconSize;
  final BorderRadiusGeometry? borderRadius;

  const PhotoPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.iconSize = 20,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.themeSoft,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder, width: 1),
      ),
      child: Icon(
        Icons.image_outlined,
        size: iconSize,
        color: context.themeMuted.withValues(alpha: 0.6),
      ),
    );
  }
}

