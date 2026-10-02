import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
class AdminStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? trailingBadge;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final String subtitle;

  const AdminStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trailingBadge,
    this.badgeColor,
    this.badgeTextColor,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    Color bgBadge;
    Color fgBadge;

    if (badgeColor != null) {
      bgBadge = badgeColor!;
      fgBadge = badgeTextColor ?? AppColors.primary;
    } else if (trailingBadge != null) {
      final b = trailingBadge!.toLowerCase();
      if (b.contains('req') || b.contains('pending') || b.contains('flag')) {
        bgBadge = context.themeDangerTint;
        fgBadge = context.themeDanger;
      } else if (b.contains('active') || b.contains('live') || b.contains('online')) {
        bgBadge = context.themeInfoTint;
        fgBadge = context.themeInfo;
      } else {
        bgBadge = context.themeAmberTint;
        fgBadge = context.themeAmberText;
      }
    } else {
      bgBadge = Colors.transparent;
      fgBadge = Colors.transparent;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.themeBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: context.themeTextSecondary),
              const Spacer(),
              if (trailingBadge != null && trailingBadge!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: bgBadge,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    trailingBadge!,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: fgBadge,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: context.themeTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: context.themeTextPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: context.themeTextSecondary,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
