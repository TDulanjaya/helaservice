import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class AdminStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? trailingBadge;
  final String subtitle;

  const AdminStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trailingBadge,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              if (trailingBadge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
                  child: Text(trailingBadge!, style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ]),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 10.5, color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
