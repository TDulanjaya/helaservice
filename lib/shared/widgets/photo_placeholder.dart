import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PhotoPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final double iconSize;

  const PhotoPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceLow,
      child: Icon(
        Icons.broken_image,
        size: iconSize,
        color: AppColors.outline,
      ),
    );
  }
}
