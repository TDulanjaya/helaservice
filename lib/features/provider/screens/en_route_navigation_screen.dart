import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/slide_to_confirm.dart';
import '../../../shared/widgets/outline_button.dart';

class EnRouteNavigationScreen extends StatelessWidget {
  const EnRouteNavigationScreen({super.key});

  void _showDelayReasons(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Expanded(
                  child: Text('Report En-Route Delay',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16))),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close)),
            ]),
            const Text(
                'Select a reason to adjust the customer ETA by +10 mins:',
                style:
                    TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: const [
              _DelayChip('🚗 Heavy Traffic'),
              _DelayChip('🌧️ Monsoon Rain'),
              _DelayChip('🚧 Road Detour'),
              _DelayChip('⛽ Refueling Stop'),
            ]),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('En Route Navigation'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(999)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.home, size: 13, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text("Niroshan's Home",
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 170,
                color: AppColors.surfaceLow,
                child: Stack(children: [
                  Positioned(
                    top: 12,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 8)
                          ]),
                      child: Row(children: [
                        const Icon(Icons.turn_left,
                            color: AppColors.primary, size: 26),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('In 350m',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.onSurfaceVariant)),
                              Text('Turn Left onto Havelock Rd',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('1.8 km',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w700)),
                            Text('6 mins',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.onSurfaceVariant)),
                          ],
                        ),
                      ]),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.navigation, size: 14),
                      label: const Text('Google Maps / Waze',
                          style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999))),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.surfaceLowest,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04), blurRadius: 10)
                  ]),
              child: Column(
                children: [
                  Row(children: [
                    const CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.surfaceHigh,
                        child: Icon(Icons.person,
                            color: AppColors.onSurfaceVariant)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Row(children: [
                            Text('Niroshan Jayawardena',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            SizedBox(width: 4),
                            Icon(Icons.verified,
                                size: 13, color: AppColors.primary)
                          ]),
                          Row(children: [
                            Icon(Icons.location_on,
                                size: 12, color: AppColors.onSurfaceVariant),
                            SizedBox(width: 3),
                            Text('Havelock Town, Colombo 05',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.onSurfaceVariant))
                          ]),
                        ],
                      ),
                    ),
                    IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.chat, color: AppColors.primary)),
                    IconButton(
                        onPressed: () {},
                        icon:
                            const Icon(Icons.phone, color: AppColors.primary)),
                  ]),
                  const Divider(height: 20),
                  Row(children: const [
                    Icon(Icons.vpn_key,
                        size: 16, color: AppColors.secondaryContainer),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text.rich(TextSpan(children: [
                        TextSpan(
                            text: 'Entry Instructions: ',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12)),
                        TextSpan(
                            text:
                                'Security gate code #4102. Gatekeeper informed. Tap intercom at Villa 4.',
                            style: TextStyle(fontSize: 12)),
                      ])),
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(16)),
              child: Row(children: const [
                Icon(Icons.payments, color: AppColors.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Direct Pay at Site — Cash or LankaQR Accepted',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12)),
                    ],
                  ),
                ),
                Text('LKR 2,200+',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ]),
            ),
            const SizedBox(height: 18),
            SlideToConfirm(
              label: 'Slide to Confirm Arrival',
              onConfirmed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Customer notified of your arrival')),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text('Customer will be notified of your immediate arrival',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.onSurfaceVariant)),
            ),
            const SizedBox(height: 14),
            AppOutlineButton(
              label: 'Report Traffic / Delay',
              icon: Icons.warning,
              color: AppColors.error,
              onPressed: () => _showDelayReasons(context),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text('GPS Active (High Precision)',
                  style: TextStyle(fontSize: 11, color: AppColors.outline)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DelayChip extends StatelessWidget {
  final String label;
  const _DelayChip(this.label);
  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: () => Navigator.pop(context),
      backgroundColor: AppColors.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}
