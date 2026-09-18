import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class NavItem {
  final IconData icon;
  final String label;
  const NavItem(this.icon, this.label);
}

class AppBottomNav extends StatelessWidget {
  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const AppBottomNav(
      {super.key, required this.items, required this.currentIndex, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -2))
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final active = i == currentIndex;
            final color =
                active ? AppColors.primary : AppColors.onSurfaceVariant;
            return InkWell(
              onTap: () => onTap?.call(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(items[i].icon, color: color, size: 24),
                    const SizedBox(height: 2),
                    Text(items[i].label,
                        style: TextStyle(color: color, fontSize: 11)),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
