import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/firestore_paths.dart';

Future<void> seedInitialDataIfEmpty() async {
  try {
    final db = FirebaseFirestore.instance;
    final catSnap =
        await db.collection(FirestorePaths.categories).limit(1).get();
    if (catSnap.docs.isEmpty) {
      await seedInitialData();
    }
  } catch (e) {
    // ignore: avoid_print
    print('seedInitialDataIfEmpty notice: $e');
  }
}

Future<void> seedInitialData() async {
  final db = FirebaseFirestore.instance;

  final categories = <String, Map<String, dynamic>>{
    'ac_repair': {
      'name': 'AC Repair',
      'label': 'AC Repair',
      'iconKey': 'ac_unit',
      'code': 'AC-01',
      'basePrice': 'LKR 2,500',
      'activeProviders': 24,
      'growth': '+12%',
      'isLive': true,
    },
    'electrician': {
      'name': 'Electrician',
      'label': 'Electrician',
      'iconKey': 'electric_bolt',
      'code': 'EL-02',
      'basePrice': 'LKR 1,500',
      'activeProviders': 42,
      'growth': '+8%',
      'isLive': true,
    },
    'plumber': {
      'name': 'Plumber',
      'label': 'Plumber',
      'iconKey': 'plumbing',
      'code': 'PL-03',
      'basePrice': 'LKR 1,800',
      'activeProviders': 31,
      'growth': '+15%',
      'isLive': true,
    },
    'mechanic': {
      'name': 'Mechanic',
      'label': 'Mechanic',
      'iconKey': 'car_repair',
      'code': 'MC-04',
      'basePrice': 'LKR 2,000',
      'activeProviders': 18,
      'growth': '+4%',
      'isLive': true,
    },
    'carpentry': {
      'name': 'Carpentry',
      'label': 'Carpentry',
      'iconKey': 'carpenter',
      'code': 'CP-05',
      'basePrice': 'LKR 1,600',
      'activeProviders': 15,
      'growth': '+6%',
      'isLive': true,
    },
    'cleaning': {
      'name': 'Cleaning',
      'label': 'Cleaning',
      'iconKey': 'cleaning_services',
      'code': 'CL-06',
      'basePrice': 'LKR 1,200',
      'activeProviders': 38,
      'growth': '+19%',
      'isLive': true,
    },
  };

  for (final entry in categories.entries) {
    await db.collection(FirestorePaths.categories).doc(entry.key).set(entry.value);
  }

  final technicians = <String, Map<String, dynamic>>{
    'kasun': {
      'name': 'Kasun Perera',
      'initials': 'KP',
      'avatarColor': 0xFF00685F,
      'title': 'Master Electrician & Senior Plumber',
      'nicVerified': true,
      'online': true,
      'rating': 4.9,
      'reviewCount': 142,
      'etaLabel': 'Instant (8 min)',
      'baseRateLkr': 1500,
      'responseTimeLabel': 'Usually responds in 5 mins',
      'jobsCount': 142,
      'yearsExperience': '10+ Yrs',
      'onTimePercent': '99.2%',
      'hourlyRateLkr': 1200,
      'emergencyRateLkr': 1800,
      'about':
          '10+ years certified domestic electrical & plumbing specialist '
              'across Colombo & Gampaha. Fluent in Sinhala & English. NVQ '
              'Level 4 certified with extensive expertise in full apartment '
              'rewiring, leak detection, pump installations, and inverter '
              'AC systems.',
      'languages': 'Sinhala & English',
      'serviceArea': 'Colombo 01-15 & Gampaha',
      'certification': 'NVQ-4 Certified',
      'recentWork': [
        {'title': 'Breaker Panel', 'location': 'Nugegoda'},
        {'title': 'Pipe Repair', 'location': 'Rajagiriya'},
        {'title': 'AC Overhaul', 'location': 'Kollupitiya'},
      ],
      'reviews': [
        {
          'reviewerName': 'Dilrukshi Samaranayake',
          'initials': 'DS',
          'location': 'Havelock Town',
          'timeAgo': '2 days ago',
          'rating': 5.0,
          'comment':
              'Bandara solved our main breaker trip within 30 minutes of '
                  'arrival. Very courteous, brought his own shoe covers, and '
                  'explained the fuse load clearly. Excellent work!',
        },
        {
          'reviewerName': 'Jonathan Wijeyesinghe',
          'initials': 'JW',
          'location': 'Mount Lavinia',
          'timeAgo': '1 week ago',
          'rating': 5.0,
          'comment':
              'Fixed an urgent water valve leak under the kitchen sink on a '
                  'Sunday morning. Super fast response and completely '
                  'transparent about spare part pricing.',
        },
      ],
    },
    'priyantha': {
      'name': 'Priyantha Jayasuriya',
      'initials': 'PJ',
      'avatarColor': 0xFF855300,
      'title': 'Certified Commercial Plumber',
      'nicVerified': true,
      'online': true,
      'rating': 4.8,
      'reviewCount': 94,
      'etaLabel': '15 mins away',
      'baseRateLkr': 1200,
      'responseTimeLabel': 'Usually responds in 10 mins',
      'jobsCount': 94,
      'yearsExperience': '8 Yrs',
      'onTimePercent': '97.5%',
      'hourlyRateLkr': 1000,
      'emergencyRateLkr': 1600,
      'about':
          'Commercial-grade plumber covering leak detection, pump installs '
              'and bathroom fit-outs across greater Colombo.',
      'languages': 'Sinhala & English',
      'serviceArea': 'Colombo & Dehiwala',
      'certification': 'NVQ-3 Certified',
      'recentWork': [
        {'title': 'Pump Install', 'location': 'Dehiwala'},
        {'title': 'Leak Repair', 'location': 'Wellawatte'},
      ],
      'reviews': [],
    },
    'dilani': {
      'name': 'Dilani Fernando',
      'initials': 'DF',
      'avatarColor': 0xFF924628,
      'title': 'Inverter AC & Cooling Specialist',
      'nicVerified': true,
      'online': true,
      'rating': 5.0,
      'reviewCount': 62,
      'etaLabel': '20 mins away',
      'baseRateLkr': 1800,
      'responseTimeLabel': 'Usually responds in 8 mins',
      'jobsCount': 62,
      'yearsExperience': '6 Yrs',
      'onTimePercent': '99.0%',
      'hourlyRateLkr': 1400,
      'emergencyRateLkr': 2000,
      'about':
          'Inverter and split-AC specialist — servicing, gas refills and '
              'full unit installs for homes and small offices.',
      'languages': 'Sinhala, English & Tamil',
      'serviceArea': 'Colombo 03-07',
      'certification': 'HVAC Certified',
      'recentWork': [
        {'title': 'AC Gas Refill', 'location': 'Bambalapitiya'},
      ],
      'reviews': [],
    },
  };

  for (final entry in technicians.entries) {
    await db.collection(FirestorePaths.technicians).doc(entry.key).set(entry.value);
  }

  final dispatchEvents = <String, Map<String, dynamic>>{
    'dispatch_1': {
      'title': 'Kasun Perera — Completed Job #HL-89421',
      'detail': 'in Colombo 03.',
      'tagLabel': 'LKR 3,700 LankaQR Settled',
      'timeAgo': '2m ago',
      'iconKey': 'payments',
      'colorValue': 0xFF00685F,
      'timestamp': FieldValue.serverTimestamp(),
    },
    'dispatch_2': {
      'title': 'Urgent Water Pump Breakdown',
      'detail':
          'Havelock Road, Col 05. Auto-assigned to Pradeep Bandara (Plumber).',
      'tagLabel': 'En Route (ETA 8m)',
      'timeAgo': '6m ago',
      'iconKey': 'bolt',
      'colorValue': 0xFF855300,
      'timestamp': FieldValue.serverTimestamp(),
    },
    'dispatch_3': {
      'title': 'Dilshan Gamage — NIC Submitted',
      'detail':
          'Submitted Smart NIC & Grama Niladhari certificate for Kurunegala district.',
      'tagLabel': 'Manual Verification Queue',
      'timeAgo': '14m ago',
      'iconKey': 'badge',
      'colorValue': 0xFF00685F,
      'timestamp': FieldValue.serverTimestamp(),
    },
    'dispatch_4': {
      'title': 'AC Service Scheduled',
      'detail':
          'Peradeniya, Kandy. Assigned to technician team with R32 manifold.',
      'tagLabel': 'Scheduled 2:30 PM',
      'timeAgo': '21m ago',
      'iconKey': 'ac_unit',
      'colorValue': 0xFF79747E,
      'timestamp': FieldValue.serverTimestamp(),
    },
  };

  for (final entry in dispatchEvents.entries) {
    await db.collection(FirestorePaths.dispatchEvents).doc(entry.key).set(entry.value);
  }

  final districtStats = <String, Map<String, dynamic>>{
    'colombo': {
      'name': 'Colombo Metro',
      'hubName': 'Colombo Metro Hub',
      'percent': 0.88,
      'readiness': 0.88,
      'loadLabel': 'High Demand',
      'detail': '218/240 active dispatch threshold',
      'location': 'Western Province',
      'description': 'Primary operational hub with high dispatch density.',
      'signups': '12.4k users',
      'preregistrations': '340+ technicians',
      'ctaLabel': 'Manage Fleet',
    },
    'gampaha': {
      'name': 'Gampaha District',
      'hubName': 'Gampaha Industrial Hub',
      'percent': 0.79,
      'readiness': 0.79,
      'loadLabel': 'Moderate',
      'detail': '86/110 active slots allocated',
      'location': 'Western Province North',
      'description': 'Rapid industrial & residential servicing expansion.',
      'signups': '8.2k users',
      'preregistrations': '180+ technicians',
      'ctaLabel': 'Review Hub',
    },
    'kandy': {
      'name': 'Kandy Urban',
      'hubName': 'Central Hills Hub',
      'percent': 0.62,
      'readiness': 0.62,
      'loadLabel': 'Normal',
      'detail': '74/120 active slots',
      'location': 'Central Province',
      'description': 'Urban core and surrounding estate service coverage.',
      'signups': '5.6k users',
      'preregistrations': '95+ technicians',
      'ctaLabel': 'Launch Zone',
    },
    'galle': {
      'name': 'Galle & Coastal',
      'hubName': 'Southern Coastal Corridor',
      'percent': 0.45,
      'readiness': 0.45,
      'loadLabel': 'Optimal',
      'detail': '50/110 active slots available',
      'location': 'Southern Province',
      'description': 'Hospitality and residential technician availability.',
      'signups': '4.1k users',
      'preregistrations': '70+ technicians',
      'ctaLabel': 'Expand Capacity',
    },
  };

  for (final entry in districtStats.entries) {
    await db.collection(FirestorePaths.districtStats).doc(entry.key).set(entry.value);
  }

  final bookings = <String, Map<String, dynamic>>{
    'booking_demo_1': {
      'customerId': 'g_cust_101',
      'providerId': 'kasun',
      'status': 'confirmed',
      'createdAt': FieldValue.serverTimestamp(),
      'time': 'Today, 2:30 PM',
      'relativeTime': 'In 45 mins',
      'title': 'Emergency Circuit Breaker Trip',
      'estRate': 'LKR 2,500',
      'customerName': 'Amara Wickramasinghe',
      'customerInitials': 'AW',
      'location': 'Havelock Road, Col 05',
      'distance': '2.4 km away',
    },
    'booking_demo_2': {
      'customerId': 'g_cust_101',
      'providerId': 'kasun',
      'status': 'completed',
      'createdAt': FieldValue.serverTimestamp(),
      'time': 'Yesterday, 10:00 AM',
      'relativeTime': 'Yesterday',
      'title': 'Bathroom Water Valve Leak Fix',
      'estRate': 'LKR 3,200',
      'customerName': 'Amara Wickramasinghe',
      'customerInitials': 'AW',
      'location': 'Havelock Road, Col 05',
      'distance': '2.4 km away',
    },
  };

  for (final entry in bookings.entries) {
    await db.collection(FirestorePaths.bookings).doc(entry.key).set(entry.value);
  }

  final verificationQueue = <String, Map<String, dynamic>>{
    'vk_dilshan': {
      'providerId': 'p_dilshan_99',
      'name': 'Dilshan Gamage',
      'trade': 'Plumbing Specialist',
      'location': 'Kurunegala District',
      'nicNumber': '199234510098',
      'docNote': 'Smart NIC + Grama Niladhari',
      'matchPercent': 98,
      'flagged': false,
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
    },
    'vk_chathura': {
      'providerId': 'p_chathura_02',
      'name': 'Chathura Alwis',
      'trade': 'HVAC & Inverter AC',
      'location': 'Gampaha Metro',
      'nicNumber': '198711200451',
      'docNote': 'NIC Front/Back Match Pending',
      'matchPercent': 82,
      'flagged': true,
      'status': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
    },
  };

  for (final entry in verificationQueue.entries) {
    await db.collection(FirestorePaths.verificationQueue).doc(entry.key).set(entry.value);
  }
}

