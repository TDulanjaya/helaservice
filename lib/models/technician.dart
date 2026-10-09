import 'package:flutter/material.dart';
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
  final List<RecentWork> recentWork;
  final List<Review> reviews;
  final bool isBanned;
  final String? banReason;
  final bool isVerified;
  final String status;
  final bool emergencyAvailable;
  final double serviceRadiusKm;
  final Map<String, WorkingDaySchedule> workingHours;

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
    required this.about,
    required this.languages,
    required this.serviceArea,
    this.phone = '',
    required this.certification,
    required this.recentWork,
    required this.reviews,
    this.isBanned = false,
    this.banReason,
    this.isVerified = false,
    this.status = '',
    this.emergencyAvailable = true,
    this.serviceRadiusKm = 25.0,
    this.workingHours = const {},
  });

  factory Technician.placeholder({
    required String id,
    required String name,
    String phone = '',
    String title = 'Service Provider',
    String category = '',
    String serviceArea = '',
    double? rating = 5.0,
  }) =>
      Technician(
        id: id,
        name: name,
        initials: name.isNotEmpty ? name[0].toUpperCase() : 'P',
        avatarColor: const Color(0xFF1B6B93),
        title: title,
        category: category,
        nicVerified: true,
        online: true,
        rating: rating,
        reviewCount: 1,
        etaLabel: '20 mins',
        baseRateLkr: 2000,
        responseTimeLabel: '< 15 mins',
        jobsCount: 1,
        yearsExperience: '3 yrs',
        onTimePercent: '100%',
        hourlyRateLkr: 2000,
        emergencyRateLkr: 3000,
        about: '',
        languages: 'English, Sinhala',
        serviceArea: serviceArea,
        phone: phone,
        certification: 'Verified Artisan',
        recentWork: const [],
        reviews: const [],
        isVerified: true,
        serviceRadiusKm: 25.0,
        workingHours: WorkingDaySchedule.defaultWeek(),
      );

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
      final startMins = startParts[0] * 60 + (startParts.length > 1 ? startParts[1] : 0);
      final endMins = endParts[0] * 60 + (endParts.length > 1 ? endParts[1] : 0);
      final currentMins = now.hour * 60 + now.minute;
      return currentMins >= startMins && currentMins <= endMins;
    } catch (_) {
      return true;
    }
  }

  Map<String, dynamic> toMap() => {
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
        'hourlyRateLkr': hourlyRateLkr,
        'emergencyRateLkr': emergencyRateLkr,
        'about': about,
        'languages': languages,
        'serviceArea': serviceArea,
        'phone': phone,
        'certification': certification,
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
      about: map['about'] ?? '',
      languages: map['languages'] ?? '',
      serviceArea: map['serviceArea'] ?? '',
      phone: map['phone'] ?? '',
      certification: map['certification'] ?? '',
      isBanned: (map['isBanned'] == true) || (map['banned'] == true),
      banReason: map['banReason'] as String?,
      isVerified: map['isVerified'] == true,
      status: (map['status'] as String?) ?? '',
      emergencyAvailable: map['emergencyAvailable'] ?? true,
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
