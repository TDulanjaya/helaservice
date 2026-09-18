import 'package:flutter/material.dart';
import 'review.dart';

class RecentWork {
  final String title;
  final String location;
  const RecentWork({required this.title, required this.location});
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
  final String certification;
  final List<RecentWork> recentWork;
  final List<Review> reviews;

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
    required this.certification,
    required this.recentWork,
    required this.reviews,
  });
}
