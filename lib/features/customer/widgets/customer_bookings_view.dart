import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../theme/app_theme.dart';
import '../../../models/technician.dart';
import '../../../models/booking.dart';
import '../../../repositories/technician_repository.dart';
import '../../../repositories/booking_repository.dart';
import '../screens/live_tracking_screen.dart';

class CustomerBookingsView extends StatelessWidget {
  final VoidCallback? onTrackPressed;

  const CustomerBookingsView({super.key, this.onTrackPressed});

  @override
  Widget build(BuildContext context) {
    final customerId =
        FirebaseAuth.instance.currentUser?.uid ?? 'g_cust_101';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Bookings',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Booking>>(
          stream: BookingRepository().streamBookingsForCustomer(customerId),
          builder: (context, snapshot) {
            final bookings = snapshot.data ?? [];
            final activeBookings = bookings
                .where((b) => b.status != 'completed' && b.status != 'cancelled')
                .toList();
            final pastBookings = bookings
                .where((b) => b.status == 'completed' || b.status == 'cancelled')
                .toList();

            if (bookings.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_month_outlined,
                        size: 54, color: AppColors.outline),
                    SizedBox(height: 12),
                    Text('No bookings recorded yet',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Browse certified artisans on the Explore tab.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                if (activeBookings.isNotEmpty) ...[
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF008378),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ACTIVE SERVICE VISIT',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF008378),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...activeBookings.map((b) => Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLowest,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    b.status == 'pending'
                                        ? 'Request Dispatched'
                                        : 'Technician En Route',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ),
                                Text(
                                  b.relativeTime.isNotEmpty
                                      ? b.relativeTime
                                      : 'Today',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              b.title.isNotEmpty
                                  ? b.title
                                  : 'Service Diagnostic',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Provider: ${b.customerName.isNotEmpty ? b.customerName : b.providerId}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 16, color: AppColors.outline),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    b.location.isNotEmpty
                                        ? b.location
                                        : 'Colombo, Sri Lanka',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  b.estRate.isNotEmpty
                                      ? b.estRate
                                      : 'LKR 2,500',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: onTrackPressed ??
                                  () async {
                                    final tech = await TechnicianRepository()
                                            .getById(b.providerId) ??
                                        _defaultTech;
                                    if (!context.mounted) return;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => LiveTrackingScreen(
                                          technician: tech,
                                        ),
                                      ),
                                    );
                                  },
                              icon: const Icon(Icons.navigation_outlined,
                                  size: 18),
                              label: const Text('Open Live GPS Tracking'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                minimumSize: const Size(double.infinity, 44),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
                if (pastBookings.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Past Completed Services',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  ...pastBookings.map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PastBookingCard(
                          title: b.title.isNotEmpty ? b.title : 'Service',
                          technician: b.customerName.isNotEmpty
                              ? b.customerName
                              : 'Technician',
                          date: b.time.isNotEmpty ? b.time : 'Completed',
                          amount:
                              b.estRate.isNotEmpty ? b.estRate : 'LKR 2,500',
                          status: b.status,
                          rating: 5,
                        ),
                      )),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PastBookingCard extends StatelessWidget {
  final String title;
  final String technician;
  final String date;
  final String amount;
  final String status;
  final int rating;

  const _PastBookingCard({
    required this.title,
    required this.technician,
    required this.date,
    required this.amount,
    required this.status,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'By $technician • ',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              Row(
                children: List.generate(
                  rating,
                  (index) => const Icon(Icons.star,
                      size: 13, color: Color(0xFFFEA619)),
                ),
              ),
              const Spacer(),
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

const _defaultTech = Technician(
  id: 'kasun',
  name: 'Kasun Perera',
  initials: 'KP',
  avatarColor: Color(0xFF00685F),
  title: 'Master Electrician & Senior Plumber',
  nicVerified: true,
  online: true,
  rating: 4.9,
  reviewCount: 142,
  etaLabel: 'Instant (8 min)',
  baseRateLkr: 1500,
  responseTimeLabel: 'Usually responds in 5 mins',
  jobsCount: 142,
  yearsExperience: '10+ Yrs',
  onTimePercent: '99.2%',
  hourlyRateLkr: 1200,
  emergencyRateLkr: 1800,
  about: '',
  languages: 'Sinhala & English',
  serviceArea: 'Colombo 01-15',
  certification: 'NVQ-4 Certified',
  recentWork: [],
  reviews: [],
);
