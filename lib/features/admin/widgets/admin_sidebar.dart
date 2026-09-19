import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class AdminNavEntry {
  final IconData icon;
  final String label;
  final String? badge;
  const AdminNavEntry(this.icon, this.label, {this.badge});
}

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const AdminSidebar({super.key, required this.selectedIndex, required this.onSelect});

  static const entries = [
    AdminNavEntry(Icons.speed, 'Dashboard'),
    AdminNavEntry(Icons.badge, 'Verifications', badge: '7'),
    AdminNavEntry(Icons.map, 'Coverage & Categories'),
    AdminNavEntry(Icons.handyman, 'Artisans'),
    AdminNavEntry(Icons.group, 'Customers'),
    AdminNavEntry(Icons.payments, 'LankaQR & Settlements'),
    AdminNavEntry(Icons.settings, 'Platform Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      color: AppColors.surfaceLowest,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              const CircleAvatar(radius: 16, backgroundColor: AppColors.primary, child: Icon(Icons.handyman, size: 16, color: Colors.white)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('HelaService', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('Ops Portal', style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                ],
              ),
            ]),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text('OPERATIONS CORE', style: TextStyle(fontSize: 10, letterSpacing: 0.8, color: AppColors.outline, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 8),
          ...List.generate(entries.length, (i) {
            final e = entries[i];
            final active = i == selectedIndex;
            return InkWell(
              onTap: () => onSelect(i),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: active ? AppColors.surfaceContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Icon(e.icon, size: 18, color: active ? AppColors.primary : AppColors.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(e.label,
                        style: TextStyle(fontSize: 12.5, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? AppColors.primary : AppColors.onSurface)),
                  ),
                  if (e.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.secondaryContainer, borderRadius: BorderRadius.circular(999)),
                      child: Text(e.badge!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ]),
              ),
            );
          }),
          const Spacer(),
          const Divider(indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: const [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Colombo Central Hub', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    Text('v2.4', style: TextStyle(fontSize: 10, color: AppColors.outline)),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
