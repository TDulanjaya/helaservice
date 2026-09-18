import 'package:flutter/material.dart';
import 'models/technician.dart';
import 'models/category_item.dart';
import 'models/booking.dart';
import 'models/review.dart';

class MockData {
  MockData._();

  static const categories = [
    CategoryItem(label: 'AC Repair', icon: Icons.ac_unit),
    CategoryItem(label: 'Electrician', icon: Icons.electric_bolt),
    CategoryItem(label: 'Plumber', icon: Icons.plumbing),
    CategoryItem(label: 'Mechanic', icon: Icons.car_repair),
    CategoryItem(label: 'Carpentry', icon: Icons.carpenter),
    CategoryItem(label: 'Cleaning', icon: Icons.cleaning_services),
  ];

  static final Technician kasun = Technician(
    id: 'kasun',
    name: 'Kasun Perera',
    initials: 'KP',
    avatarColor: const Color(0xFF00685F),
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
    about:
        '10+ years certified domestic electrical & plumbing specialist across '
        'Colombo & Gampaha. Fluent in Sinhala & English. NVQ Level 4 certified '
        'with extensive expertise in full apartment rewiring, leak detection, '
        'pump installations, and inverter AC systems.',
    languages: 'Sinhala & English',
    serviceArea: 'Colombo 01-15 & Gampaha',
    certification: 'NVQ-4 Certified',
    recentWork: const [
      RecentWork(title: 'Breaker Panel', location: 'Nugegoda'),
      RecentWork(title: 'Pipe Repair', location: 'Rajagiriya'),
      RecentWork(title: 'AC Overhaul', location: 'Kollupitiya'),
    ],
    reviews: const [
      Review(
        reviewerName: 'Dilrukshi Samaranayake',
        initials: 'DS',
        location: 'Havelock Town',
        timeAgo: '2 days ago',
        rating: 5,
        comment:
            'Bandara solved our main breaker trip within 30 minutes of arrival. '
            'Very courteous, brought his own shoe covers, and explained the '
            'fuse load clearly. Excellent work!',
      ),
      Review(
        reviewerName: 'Jonathan Wijeyesinghe',
        initials: 'JW',
        location: 'Mount Lavinia',
        timeAgo: '1 week ago',
        rating: 5,
        comment: 'Fixed an urgent water valve leak under the kitchen sink on a '
            'Sunday morning. Super fast response and completely transparent '
            'about spare part pricing.',
      ),
    ],
  );

  static final Technician priyantha = Technician(
    id: 'priyantha',
    name: 'Priyantha Jayasuriya',
    initials: 'PJ',
    avatarColor: const Color(0xFF855300),
    title: 'Certified Commercial Plumber',
    nicVerified: true,
    online: true,
    rating: 4.8,
    reviewCount: 94,
    etaLabel: '15 mins away',
    baseRateLkr: 1200,
    responseTimeLabel: 'Usually responds in 10 mins',
    jobsCount: 94,
    yearsExperience: '8 Yrs',
    onTimePercent: '97.5%',
    hourlyRateLkr: 1000,
    emergencyRateLkr: 1600,
    about:
        'Commercial-grade plumber covering leak detection, pump installs and '
        'bathroom fit-outs across greater Colombo.',
    languages: 'Sinhala & English',
    serviceArea: 'Colombo & Dehiwala',
    certification: 'NVQ-3 Certified',
    recentWork: const [
      RecentWork(title: 'Pump Install', location: 'Dehiwala'),
      RecentWork(title: 'Leak Repair', location: 'Wellawatte'),
    ],
    reviews: const [],
  );

  static final Technician dilani = Technician(
    id: 'dilani',
    name: 'Dilani Fernando',
    initials: 'DF',
    avatarColor: const Color(0xFF924628),
    title: 'Inverter AC & Cooling Specialist',
    nicVerified: true,
    online: true,
    rating: 5.0,
    reviewCount: 62,
    etaLabel: '20 mins away',
    baseRateLkr: 1800,
    responseTimeLabel: 'Usually responds in 8 mins',
    jobsCount: 62,
    yearsExperience: '6 Yrs',
    onTimePercent: '99.0%',
    hourlyRateLkr: 1400,
    emergencyRateLkr: 2000,
    about: 'Inverter and split-AC specialist — servicing, gas refills and full '
        'unit installs for homes and small offices.',
    languages: 'Sinhala, English & Tamil',
    serviceArea: 'Colombo 03-07',
    certification: 'HVAC Certified',
    recentWork: const [
      RecentWork(title: 'AC Gas Refill', location: 'Bambalapitiya'),
    ],
    reviews: const [],
  );

  static List<Technician> get technicians => [kasun, priyantha, dilani];

  static const bookings = [
    Booking(
      time: '2:30 PM',
      relativeTime: 'In 45 mins',
      title: 'Breaker Panel Tripping',
      estRate: 'LKR 3,500',
      customerName: 'Dr. Ruwan Wickramasinghe',
      customerInitials: 'RW',
      location: 'Flower Road, Colombo 07',
      distance: '3.1 km',
    ),
    Booking(
      time: '4:45 PM',
      relativeTime: '',
      title: 'Inverter AC Diagnostic',
      estRate: 'LKR 2,500',
      customerName: 'Ayesha Senanayake',
      customerInitials: 'AS',
      location: 'Marine Drive, Colombo 03',
      distance: '1.2 km',
    ),
  ];
}
