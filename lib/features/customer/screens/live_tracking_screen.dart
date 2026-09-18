import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../data/models/technician.dart';
import '../../../shared/widgets/pill_badge.dart';
import '../../../shared/widgets/outline_button.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import 'rating_completion_screen.dart';

class LiveTrackingScreen extends StatelessWidget {
  final Technician technician;
  const LiveTrackingScreen({super.key, required this.technician});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
                child: PillBadge(label: 'Colombo 03', icon: Icons.location_on)),
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
                height: 190,
                color: AppColors.surfaceLow,
                child: Stack(children: [
                  const Positioned(
                      top: 14,
                      left: 14,
                      child: PillBadge(
                          label: 'Technician on the way • Live GPS',
                          background: Colors.white,
                          foreground: AppColors.primary)),
                  Positioned(
                    top: 60,
                    left: 40,
                    child: Column(children: const [
                      Icon(Icons.two_wheeler,
                          color: AppColors.primary, size: 28),
                      Text('38 km/h',
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  const Positioned(
                      bottom: 40,
                      right: 50,
                      child: Icon(Icons.home,
                          color: AppColors.onSurface, size: 30)),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Column(children: const [
                      _RoundIconButton(icon: Icons.my_location),
                      SizedBox(height: 8),
                      _RoundIconButton(icon: Icons.layers),
                    ]),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppColors.surfaceLowest,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04), blurRadius: 10)
                  ]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: const [
                    Icon(Icons.timer, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Estimated Arrival',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.onSurfaceVariant)),
                        Text('Arriving in 11 mins',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ]),
                  Row(children: const [
                    Icon(Icons.navigation,
                        size: 16, color: AppColors.onSurfaceVariant),
                    SizedBox(width: 4),
                    Text('2.1 km',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ]),
                ],
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
                    CircleAvatar(
                        radius: 24,
                        backgroundColor: technician.avatarColor,
                        child: Text(technician.initials,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            const Icon(Icons.star,
                                size: 14, color: AppColors.secondaryContainer),
                            Text(' ${technician.rating}  ',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 12)),
                            Expanded(
                                child: Text(technician.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis)),
                          ]),
                          Row(children: const [
                            Icon(Icons.verified,
                                size: 12, color: AppColors.primary),
                            SizedBox(width: 3),
                            Text('Master Electrician • 642 Jobs',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.onSurfaceVariant)),
                          ]),
                          Row(children: const [
                            Icon(Icons.motorcycle,
                                size: 12, color: AppColors.onSurfaceVariant),
                            SizedBox(width: 3),
                            Text('WP BDF-8821 (Bajaj Pulsar)',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.onSurfaceVariant)),
                          ]),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: AppOutlineButton(
                            label: 'Call Tech',
                            icon: Icons.call,
                            onPressed: () {})),
                    const SizedBox(width: 10),
                    Expanded(
                        child: AppOutlineButton(
                            label: 'Chat (2)',
                            icon: Icons.chat,
                            onPressed: () {})),
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
              child: Row(children: [
                const Icon(Icons.payments, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Direct Pay at Site (Cash / LankaQR)',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      Text(
                          'LKR 2,400 standard inspection fee. No hidden platform charges.',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                  child: AppOutlineButton(
                      label: 'Cancel Request',
                      icon: Icons.cancel,
                      color: AppColors.error,
                      onPressed: () => Navigator.of(context).pop())),
              const SizedBox(width: 10),
              Expanded(
                  child: AppOutlineButton(
                      label: 'Share Trip',
                      icon: Icons.share_location,
                      onPressed: () {})),
            ]),
            const SizedBox(height: 14),
            AppOutlineButton(
              label: 'Simulate: Job Finished',
              icon: Icons.check_circle,
              color: AppColors.primary,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) =>
                        RatingCompletionScreen(technician: technician)),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        items: const [
          NavItem(Icons.explore, 'Explore'),
          NavItem(Icons.calendar_month, 'Bookings'),
          NavItem(Icons.near_me, 'Tracking'),
          NavItem(Icons.person, 'Profile'),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  const _RoundIconButton({required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration:
          const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: Icon(icon, size: 16, color: AppColors.onSurface),
    );
  }
}
