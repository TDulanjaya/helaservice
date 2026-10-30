import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../utils/provider_location_helper.dart';
import '../utils/provider_pricing_helper.dart';
import 'review.dart';

class RecentWork {
  final String title;
  final String location;
  const RecentWork({required this.title, required this.location});

  Map<String, dynamic> toMap() => {'title': title, 'location': location};

  factory RecentWork.fromMap(Map<String, dynamic> map) => RecentWork(
        title: map['title'] ?? '',
        location: map['location'] ?? '',
      );
}

class WorkingDaySchedule {
  final bool enabled;
  final String start;
  final String end;

  const WorkingDaySchedule({
    this.enabled = true,
    this.start = '08:00',
    this.end = '18:00',
  });

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'start': start,
        'end': end,
      };

  factory WorkingDaySchedule.fromMap(Map<String, dynamic> map) =>
      WorkingDaySchedule(
        enabled: map['enabled'] ?? true,
        start: map['start'] ?? '08:00',
        end: map['end'] ?? '18:00',
      );

  static Map<String, WorkingDaySchedule> defaultWeek() => {
        'monday': const WorkingDaySchedule(),
        'tuesday': const WorkingDaySchedule(),
        'wednesday': const WorkingDaySchedule(),
        'thursday': const WorkingDaySchedule(),
        'friday': const WorkingDaySchedule(),
        'saturday': const WorkingDaySchedule(),
        'sunday': const WorkingDaySchedule(enabled: false),
      };
}

// technician model representation
class Technician {
  final String id;
  final String name;
  final String initials;
  final Color avatarColor;
  final String title;
  final String category;
  final bool nicVerified;
  final bool online;
  final double? rating;
  final int reviewCount;
  final String etaLabel;
  final int baseRateLkr;
  final String responseTimeLabel;
  final int jobsCount;
  final String yearsExperience;
  final String onTimePercent;
  final int hourlyRateLkr;
  final int emergencyRateLkr;
  final String about;
  final String languages;
  final String serviceArea;
  final String phone;
  final String certification;
  final bool hasApprovedCertificates;
  final List<String> certificateTitles;
  final List<RecentWork> recentWork;
  final List<Review> reviews;
  final bool isBanned;
  final String? banReason;
  final bool isVerified;
  final String status;
  final bool emergencyAvailable;
  final double serviceRadiusKm;
  final Map<String, WorkingDaySchedule> workingHours;
  final int? dailyRateLkr;
  final int? perKmRateLkr;
  final int? visitFeeLkr;
  final List<String>? pricingModes;
  final double? latitude;
  final double? longitude;
  final double? baseLat;
  final double? baseLng;
  final String? baseAddress;
  final String? baseArea;
  final double? currentLat;
  final double? currentLng;
  final DateTime? currentLocationAt;
  final DateTime? baseLocationUpdatedAt;

  List<String> get resolvedPricingModes =>
      ProviderPricingHelper.resolvePricingModes(
        pricingModes: pricingModes,
        hourlyRateLkr: hourlyRateLkr,
        dailyRateLkr: dailyRateLkr,
        baseRateLkr: baseRateLkr,
        visitFeeLkr: visitFeeLkr,
        perKmRateLkr: perKmRateLkr,
      );

  bool hasPricingMode(String mode) => resolvedPricingModes.contains(mode);

  int get effectiveVisitFeeLkr =>
      ProviderPricingHelper.resolveVisitFee(this);

  // active location based on online state
  EffectiveProviderLocation get effectiveLocation =>
      getEffectiveProviderLocation(this);

  const Technician({
    required this.id,
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.title,
    this.category = '',
    required this.nicVerified,
    required this.online,
    this.rating,
    required this.reviewCount,
    required this.etaLabel,
    required this.baseRateLkr,
    required this.responseTimeLabel,
    required this.jobsCount,
    required this.yearsExperience,
    required this.onTimePercent,
    required this.hourlyRateLkr,
    required this.emergencyRateLkr,
    this.dailyRateLkr,
    this.perKmRateLkr,
    this.visitFeeLkr,
    this.pricingModes,
    this.latitude,
    this.longitude,
    this.baseLat,
    this.baseLng,
    this.baseAddress,
    this.baseArea,
    this.currentLat,
    this.currentLng,
    this.currentLocationAt,
    this.baseLocationUpdatedAt,
    required this.about,
    required this.languages,
    required this.serviceArea,
    this.phone = '',
    required this.certification,
    this.hasApprovedCertificates = false,
    this.certificateTitles = const [],
    required this.recentWork,
    required this.reviews,
    this.isBanned = false,
    this.banReason,
    this.isVerified = false,
    this.status = '',
    this.emergencyAvailable = false,
    this.serviceRadiusKm = 25.0,
    this.workingHours = const {},
  });

  factory Technician.placeholder({
    required String id,
    required String name,
    String phone = '',
    String title = '',
    String category = '',
    String serviceArea = '',
    double? rating,
    double? latitude,
    double? longitude,
    double? baseLat,
    double? baseLng,
    String? baseAddress,
    double? currentLat,
    double? currentLng,
    DateTime? currentLocationAt,
    DateTime? baseLocationUpdatedAt,
  }) =>
      Technician(
        id: id,
        name: name,
        initials: name.isNotEmpty ? name[0].toUpperCase() : 'P',
        avatarColor: const Color(0xFF1B6B93),
        title: title,
        category: category,
        nicVerified: false,
        online: false,
        rating: null,
        reviewCount: 0,
        etaLabel: '',
        baseRateLkr: 0,
        responseTimeLabel: '',
        jobsCount: 0,
        yearsExperience: '',
        onTimePercent: '',
        hourlyRateLkr: 0,
        emergencyRateLkr: 0,
        latitude: latitude ?? baseLat,
        longitude: longitude ?? baseLng,
        baseLat: baseLat ?? latitude,
        baseLng: baseLng ?? longitude,
        baseAddress: baseAddress,
        currentLat: currentLat,
        currentLng: currentLng,
        currentLocationAt: currentLocationAt,
        baseLocationUpdatedAt: baseLocationUpdatedAt,
        about: '',
        languages: '',
        serviceArea: serviceArea,
        phone: phone,
        certification: '',
        recentWork: const [],
        reviews: const [],
        isVerified: false,
        serviceRadiusKm: 25.0,
        workingHours: WorkingDaySchedule.defaultWeek(),
      );

  Technician copyWith({
    String? id,
    String? name,
    String? initials,
    Color? avatarColor,
    String? title,
    String? category,
    bool? nicVerified,
    bool? online,
    double? rating,
    int? reviewCount,
    String? etaLabel,
    int? baseRateLkr,
    String? responseTimeLabel,
    int? jobsCount,
    String? yearsExperience,
    String? onTimePercent,
    int? hourlyRateLkr,
    int? emergencyRateLkr,
    int? dailyRateLkr,
    int? perKmRateLkr,
    int? visitFeeLkr,
    List<String>? pricingModes,
    double? latitude,
    double? longitude,
    double? baseLat,
    double? baseLng,
    String? baseAddress,
    String? baseArea,
    double? currentLat,
    double? currentLng,
    DateTime? currentLocationAt,
    DateTime? baseLocationUpdatedAt,
    String? about,
    String? languages,
    String? serviceArea,
    String? phone,
    String? certification,
    List<RecentWork>? recentWork,
    List<Review>? reviews,
    bool? isBanned,
    String? banReason,
    bool? isVerified,
    String? status,
    bool? emergencyAvailable,
    double? serviceRadiusKm,
    Map<String, WorkingDaySchedule>? workingHours,
  }) {
    return Technician(
      id: id ?? this.id,
      name: name ?? this.name,
      initials: initials ?? this.initials,
      avatarColor: avatarColor ?? this.avatarColor,
      title: title ?? this.title,
      category: category ?? this.category,
      nicVerified: nicVerified ?? this.nicVerified,
      online: online ?? this.online,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      etaLabel: etaLabel ?? this.etaLabel,
      baseRateLkr: baseRateLkr ?? this.baseRateLkr,
      responseTimeLabel: responseTimeLabel ?? this.responseTimeLabel,
      jobsCount: jobsCount ?? this.jobsCount,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      onTimePercent: onTimePercent ?? this.onTimePercent,
      hourlyRateLkr: hourlyRateLkr ?? this.hourlyRateLkr,
      emergencyRateLkr: emergencyRateLkr ?? this.emergencyRateLkr,
      dailyRateLkr: dailyRateLkr ?? this.dailyRateLkr,
      perKmRateLkr: perKmRateLkr ?? this.perKmRateLkr,
      visitFeeLkr: visitFeeLkr ?? this.visitFeeLkr,
      pricingModes: pricingModes ?? this.pricingModes,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      baseLat: baseLat ?? this.baseLat,
      baseLng: baseLng ?? this.baseLng,
      baseAddress: baseAddress ?? this.baseAddress,
      baseArea: baseArea ?? this.baseArea,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      currentLocationAt: currentLocationAt ?? this.currentLocationAt,
      baseLocationUpdatedAt:
          baseLocationUpdatedAt ?? this.baseLocationUpdatedAt,
      about: about ?? this.about,
      languages: languages ?? this.languages,
      serviceArea: serviceArea ?? this.serviceArea,
      phone: phone ?? this.phone,
      certification: certification ?? this.certification,
      recentWork: recentWork ?? this.recentWork,
      reviews: reviews ?? this.reviews,
      isBanned: isBanned ?? this.isBanned,
      banReason: banReason ?? this.banReason,
      isVerified: isVerified ?? this.isVerified,
      status: status ?? this.status,
      emergencyAvailable: emergencyAvailable ?? this.emergencyAvailable,
      serviceRadiusKm: serviceRadiusKm ?? this.serviceRadiusKm,
      workingHours: workingHours ?? this.workingHours,
    );
  }

  bool get isApproved {
    if (isBanned) return false;
    final s = status.trim().toLowerCase();
    if (s == 'rejected' || s == 'suspended' || s == 'pending') return false;
    return nicVerified || isVerified;
  }

  // check if technician is a new provider with fewer than three reviews
  bool get isNewProvider => rating == null || reviewCount < 3;

  // check if technician is currently within open working hours
  bool get isAvailableNow {
    if (isBanned || !online) return false;
    if (workingHours.isEmpty) return true;

    final now = DateTime.now();
    final dayKeys = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    final todayKey = dayKeys[now.weekday - 1];
    final todaySchedule = workingHours[todayKey];
    if (todaySchedule == null || !todaySchedule.enabled) return false;

    try {
      final startParts = todaySchedule.start.split(':').map(int.parse).toList();
      final endParts = todaySchedule.end.split(':').map(int.parse).toList();
      final startMins =
          startParts[0] * 60 + (startParts.length > 1 ? startParts[1] : 0);
      final endMins =
          endParts[0] * 60 + (endParts.length > 1 ? endParts[1] : 0);
      final currentMins = now.hour * 60 + now.minute;
      return currentMins >= startMins && currentMins <= endMins;
    } catch (_) {
      return true;
    }
  }

  Map<String, dynamic> toMap() {
    final effectiveBaseLat = baseLat ?? latitude;
    final effectiveBaseLng = baseLng ?? longitude;

    return {
      'name': name,
      'initials': initials,
      'avatarColor': avatarColor.toARGB32(),
      'title': title,
      'category': category,
      'nicVerified': nicVerified,
      'online': online,
      'rating': rating,
      'reviewCount': reviewCount,
      'etaLabel': etaLabel,
      'baseRateLkr': baseRateLkr,
      'responseTimeLabel': responseTimeLabel,
      'jobsCount': jobsCount,
      'yearsExperience': yearsExperience,
      'onTimePercent': onTimePercent,
      if (hourlyRateLkr > 0) 'hourlyRateLkr': hourlyRateLkr,
      'emergencyRateLkr': emergencyRateLkr,
      if (pricingModes != null) 'pricingModes': pricingModes,
      if (dailyRateLkr != null && dailyRateLkr! > 0)
        'dailyRateLkr': dailyRateLkr,
      if (perKmRateLkr != null && perKmRateLkr! > 0)
        'perKmRateLkr': perKmRateLkr,
      if (visitFeeLkr != null && visitFeeLkr! > 0) 'visitFeeLkr': visitFeeLkr,
      // round to 2 decimals for privacy
      if (effectiveBaseLat != null)
        'baseLat': roundToTwoDecimals(effectiveBaseLat),
      if (effectiveBaseLng != null)
        'baseLng': roundToTwoDecimals(effectiveBaseLng),
      if (baseAddress != null) 'baseAddress': baseAddress,
      if (baseArea != null && baseArea!.trim().isNotEmpty)
        'baseArea': baseArea!.trim(),
      if (currentLat != null) 'currentLat': roundToTwoDecimals(currentLat!),
      if (currentLng != null) 'currentLng': roundToTwoDecimals(currentLng!),
      if (currentLocationAt != null)
        'currentLocationAt': Timestamp.fromDate(currentLocationAt!),
      if (effectiveBaseLat != null)
        'latitude': roundToTwoDecimals(effectiveBaseLat),
      if (effectiveBaseLng != null)
        'longitude': roundToTwoDecimals(effectiveBaseLng),
      'about': about,
      'languages': languages,
      'serviceArea': serviceArea,
      'phone': phone,
      'certification': certification,
      'hasApprovedCertificates': hasApprovedCertificates,
      if (certificateTitles.isNotEmpty) 'certificateTitles': certificateTitles,
      'isBanned': isBanned,
      if (banReason != null) 'banReason': banReason,
      'isVerified': isVerified,
      'status': status,
      'emergencyAvailable': emergencyAvailable,
      'serviceRadiusKm': serviceRadiusKm,
      'workingHours': workingHours.map((k, v) => MapEntry(k, v.toMap())),
      'recentWork': recentWork.map((w) => w.toMap()).toList(),
      'reviews': reviews.map((r) => r.toMap()).toList(),
    };
  }

  factory Technician.fromMap(String id, Map<String, dynamic> map) {
    Map<String, WorkingDaySchedule> parsedWorkingHours = {};
    if (map['workingHours'] is Map) {
      final rawMap = map['workingHours'] as Map;
      rawMap.forEach((k, v) {
        if (v is Map) {
          parsedWorkingHours[k.toString()] =
              WorkingDaySchedule.fromMap(Map<String, dynamic>.from(v));
        }
      });
    }

    final parsedBaseLat = (map['baseLat'] as num?)?.toDouble() ??
        (map['latitude'] as num?)?.toDouble() ??
        (map['lat'] as num?)?.toDouble();
    final parsedBaseLng = (map['baseLng'] as num?)?.toDouble() ??
        (map['longitude'] as num?)?.toDouble() ??
        (map['lng'] as num?)?.toDouble();
    final parsedCurrentLat = (map['currentLat'] as num?)?.toDouble();
    final parsedCurrentLng = (map['currentLng'] as num?)?.toDouble();
    final parsedCurrentLocationAt = (map['currentLocationAt'] is Timestamp)
        ? (map['currentLocationAt'] as Timestamp).toDate()
        : null;
    final parsedBaseLocationUpdatedAt =
        (map['baseLocationUpdatedAt'] is Timestamp)
            ? (map['baseLocationUpdatedAt'] as Timestamp).toDate()
            : null;

    return Technician(
      id: id,
      name: map['name'] ?? '',
      initials: map['initials'] ?? '',
      avatarColor: Color((map['avatarColor'] ?? 0xFFD6900F) as int),
      title: map['title'] ?? '',
      category: map['category'] ?? map['serviceCategory'] ?? '',
      nicVerified: map['nicVerified'] ?? false,
      online: map['online'] ?? false,
      rating: (map['rating'] as num?)?.toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      etaLabel: map['etaLabel'] ?? '',
      baseRateLkr: map['baseRateLkr'] ?? 0,
      responseTimeLabel: map['responseTimeLabel'] ?? '',
      jobsCount: map['jobsCount'] ?? 0,
      yearsExperience: map['yearsExperience'] ?? '',
      onTimePercent: map['onTimePercent'] ?? '',
      hourlyRateLkr: map['hourlyRateLkr'] ?? 0,
      emergencyRateLkr: map['emergencyRateLkr'] ?? 0,
      dailyRateLkr: (map['dailyRateLkr'] as num?)?.toInt(),
      perKmRateLkr: (map['perKmRateLkr'] as num?)?.toInt(),
      visitFeeLkr: (map['visitFeeLkr'] as num?)?.toInt(),
      pricingModes:
          (map['pricingModes'] as List?)?.map((e) => e.toString()).toList(),
      latitude: parsedBaseLat,
      longitude: parsedBaseLng,
      baseLat: parsedBaseLat,
      baseLng: parsedBaseLng,
      baseAddress: map['baseAddress'] as String?,
      baseArea: map['baseArea'] as String?,
      currentLat: parsedCurrentLat,
      currentLng: parsedCurrentLng,
      currentLocationAt: parsedCurrentLocationAt,
      baseLocationUpdatedAt: parsedBaseLocationUpdatedAt,
      about: map['about'] ?? '',
      languages: map['languages'] ?? '',
      serviceArea: map['serviceArea'] ?? '',
      phone: map['phone'] ?? '',
      certification: map['certification'] ?? '',
      hasApprovedCertificates: map['hasApprovedCertificates'] == true,
      certificateTitles: (map['certificateTitles'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isBanned: (map['isBanned'] == true) || (map['banned'] == true),
      banReason: map['banReason'] as String?,
      isVerified: map['isVerified'] == true,
      status: (map['status'] as String?) ?? '',
      emergencyAvailable: map['emergencyAvailable'] ?? false,
      serviceRadiusKm: (map['serviceRadiusKm'] as num?)?.toDouble() ?? 25.0,
      workingHours: parsedWorkingHours.isNotEmpty
          ? parsedWorkingHours
          : WorkingDaySchedule.defaultWeek(),
      recentWork: ((map['recentWork'] as List?) ?? [])
          .map((w) => RecentWork.fromMap(Map<String, dynamic>.from(w as Map)))
          .toList(),
      reviews: ((map['reviews'] as List?) ?? [])
          .map((r) => Review.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList(),
    );
  }
}
