import '../../../shared/widgets/role_switch_sheet.dart';
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class AdminTopBar extends StatelessWidget {
  const AdminTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLowest,
        border: Border(bottom: BorderSide(color: AppColors.surfaceHighest)),
      ),
      child: Row(
        children: [
          Container(
            width: 260,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 38,
            decoration: BoxDecoration(color: AppColors.surfaceLow, borderRadius: BorderRadius.circular(10)),
            child: Row(children: const [
              Icon(Icons.search, size: 16, color: AppColors.outline),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Search technicians, NIC, jobs...',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: AppColors.outline),
                ),
              ),
            ]),
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(999)),
              child: Row(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.circle, size: 8, color: AppColors.primary),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Island Network: 99.8% Online • Colombo / Kandy / Galle active',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                ),
              ]),
            ),
          ),
          const Spacer(),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: AppColors.onSurfaceVariant)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => showRoleSwitchSheet(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircleAvatar(radius: 16, backgroundColor: AppColors.surfaceHigh, child: Icon(Icons.person, size: 18, color: AppColors.onSurfaceVariant)),
                SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kavinda Perera', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    Text('Operations Lead', style: TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                  ],
                ),
                SizedBox(width: 6),
                Icon(Icons.expand_more, size: 16, color: AppColors.onSurfaceVariant),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
