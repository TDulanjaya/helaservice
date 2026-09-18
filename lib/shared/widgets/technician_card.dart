import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../data/models/technician.dart';
import 'pill_badge.dart';

class TechnicianCard extends StatelessWidget {
  final Technician technician;
  final VoidCallback onTap;

  const TechnicianCard(
      {super.key, required this.technician, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: technician.avatarColor,
                      child: Text(technician.initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                    if (technician.online)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                              color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.check,
                              size: 11, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(technician.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          PillBadge(
                            label:
                                '${technician.rating} (${technician.reviewCount})',
                            icon: Icons.star,
                            background: AppColors.surfaceContainer,
                            foreground: AppColors.onSurface,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(technician.title,
                          style: const TextStyle(
                              color: AppColors.onSurfaceVariant, fontSize: 13)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (technician.nicVerified)
                            const PillBadge(
                              label: 'NIC Verified',
                              icon: Icons.verified_user,
                              background: AppColors.surfaceHigh,
                              foreground: AppColors.primary,
                            ),
                          PillBadge(
                              label: technician.etaLabel, icon: Icons.schedule),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Initial Inspection Rate',
                        style: TextStyle(
                            color: AppColors.onSurfaceVariant, fontSize: 11)),
                    Text('LKR ${technician.baseRateLkr}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 17)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.bolt, size: 18),
                  label: const Text('Quick Book'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
