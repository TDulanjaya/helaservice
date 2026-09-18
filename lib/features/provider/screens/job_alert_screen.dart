import 'dart:async';
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/outline_button.dart';
import 'en_route_navigation_screen.dart';

class JobAlertScreen extends StatefulWidget {
  const JobAlertScreen({super.key});

  @override
  State<JobAlertScreen> createState() => _JobAlertScreenState();
}

class _JobAlertScreenState extends State<JobAlertScreen> {
  int _secondsLeft = 38;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) {
        t.cancel();
        if (mounted) Navigator.of(context).pop();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.onSurface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(children: [
                const Icon(Icons.handyman, color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                const Text('EXPRESS DISPATCH ROUTE',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 11, letterSpacing: 1)),
                const Spacer(),
                const Icon(Icons.volume_up, color: Colors.white70, size: 14),
                Text(' Auto-passes in $_secondsLeft s',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 11)),
              ]),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: AppColors.surfaceLowest,
                    borderRadius: BorderRadius.circular(24)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: const [
                          Icon(Icons.bolt, color: AppColors.secondaryContainer),
                          SizedBox(width: 6),
                          Text('New Job Request',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                        ]),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: AppColors.errorContainer,
                              borderRadius: BorderRadius.circular(999)),
                          child: const Text('URGENT',
                              style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppColors.primary, width: 3)),
                      child: Text('$_secondsLeft\nsec',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 14),
                    Row(children: const [
                      Icon(Icons.plumbing, size: 16, color: AppColors.primary),
                      SizedBox(width: 6),
                      Expanded(
                          child: Text('Plumbing & Water Pump Breakdown',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                    ]),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: AppColors.surfaceLow,
                          borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Guaranteed Base Payout',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.onSurfaceVariant)),
                              Text('LKR 2,200',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17)),
                            ],
                          ),
                          Text('Direct Settlement\nParts via LankaQR / Cash',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(children: const [
                      CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.surfaceHigh,
                          child: Icon(Icons.person, size: 16)),
                      SizedBox(width: 8),
                      Expanded(
                          child: Text('Niroshan Jayawardena',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      Icon(Icons.star,
                          size: 14, color: AppColors.secondaryContainer),
                      Text(' 4.9 (14 jobs)', style: TextStyle(fontSize: 11)),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: const [
                      Icon(Icons.navigation,
                          size: 14, color: AppColors.onSurfaceVariant),
                      SizedBox(width: 4),
                      Text('2.4 km',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                    Row(children: const [
                      Icon(Icons.location_on,
                          size: 14, color: AppColors.onSurfaceVariant),
                      SizedBox(width: 4),
                      Expanded(
                          child: Text('No. 42/B, Havelock Road, Colombo 05',
                              style: TextStyle(fontSize: 12))),
                    ]),
                    Row(children: const [
                      Icon(Icons.two_wheeler,
                          size: 14, color: AppColors.onSurfaceVariant),
                      SizedBox(width: 4),
                      Expanded(
                          child: Text(
                              '~8 mins ride via baseline road • Low traffic',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.onSurfaceVariant))),
                    ]),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: AppColors.errorContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(14)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Row(children: [
                            Icon(Icons.warning,
                                size: 14, color: AppColors.error),
                            SizedBox(width: 4),
                            Text('Reported Issue',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12))
                          ]),
                          SizedBox(height: 4),
                          Text(
                              '"Water pump won\'t turn on and overhead tank is overflowing. Urgent repair needed before 1:00 PM."',
                              style: TextStyle(
                                  fontSize: 12, fontStyle: FontStyle.italic)),
                          SizedBox(height: 6),
                          Row(children: [
                            Icon(Icons.photo_camera, size: 14),
                            SizedBox(width: 4),
                            Text('1 photo attached — tap to view',
                                style: TextStyle(fontSize: 11))
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Accept Job ($_secondsLeft s)',
                trailingIcon: Icons.check_circle,
                onPressed: () {
                  _timer?.cancel();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (_) => const EnRouteNavigationScreen()),
                  );
                },
              ),
              const SizedBox(height: 10),
              AppOutlineButton(
                label: 'Pass to Next Available Artisan',
                icon: Icons.cancel,
                color: Colors.white,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 10),
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.security, size: 12, color: Colors.white54),
                SizedBox(width: 4),
                Text('Pull over safely before confirming arrival navigation',
                    style: TextStyle(color: Colors.white54, fontSize: 10)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
