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

class Technician {
  final String id;
  final String name;
  final String initials;
  final Color avatarColor;
  final String title;
  final bool nicVerified;
  final bool online;
  final double rating;
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

  const Technician({
    required this.id,
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.title,
    required this.nicVerified,
    required this.online,
    required this.rating,
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
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'initials': initials,
        'avatarColor': avatarColor.toARGB32(),
        'title': title,
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
        'recentWork': recentWork.map((w) => w.toMap()).toList(),
        'reviews': reviews.map((r) => r.toMap()).toList(),
      };

  factory Technician.fromMap(String id, Map<String, dynamic> map) {
    return Technician(
      id: id,
      name: map['name'] ?? '',
      initials: map['initials'] ?? '',
      avatarColor: Color((map['avatarColor'] ?? 0xFFD6900F) as int),
      title: map['title'] ?? '',
      nicVerified: map['nicVerified'] ?? false,
      online: map['online'] ?? false,
      rating: (map['rating'] ?? 0).toDouble(),
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
      recentWork: ((map['recentWork'] as List?) ?? [])
          .map((w) => RecentWork.fromMap(Map<String, dynamic>.from(w as Map)))
          .toList(),
      reviews: ((map['reviews'] as List?) ?? [])
          .map((r) => Review.fromMap(Map<String, dynamic>.from(r as Map)))
          .toList(),
    );
  }
}
