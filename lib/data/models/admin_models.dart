import 'package:flutter/material.dart';

class ArtisanRosterRow {
  final String name;
  final String nic;
  final String trade;
  final IconData tradeIcon;
  final String zone;
  final String status;
  final Color statusColor;
  final String payoutToday;
  final double rating;
  final int reviews;
  final String actionLabel;

  const ArtisanRosterRow({
    required this.name,
    required this.nic,
    required this.trade,
    required this.tradeIcon,
    required this.zone,
    required this.status,
    required this.statusColor,
    required this.payoutToday,
    required this.rating,
    required this.reviews,
    required this.actionLabel,
  });
}

class DispatchEvent {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String timeAgo;
  final String detail;
  final String tagLabel;

  const DispatchEvent({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.timeAgo,
    required this.detail,
    required this.tagLabel,
  });
}

class DistrictLoad {
  final String name;
  final double percent;
  final String loadLabel;
  final String detail;

  const DistrictLoad({
    required this.name,
    required this.percent,
    required this.loadLabel,
    required this.detail,
  });
}

class VerificationQueueItem {
  final String name;
  final String timeAgo;
  final String trade;
  final IconData tradeIcon;
  final String location;
  final String nicNumber;
  final String docNote;
  final int matchPercent;
  final bool flagged;

  const VerificationQueueItem({
    required this.name,
    required this.timeAgo,
    required this.trade,
    required this.tradeIcon,
    required this.location,
    required this.nicNumber,
    required this.docNote,
    required this.matchPercent,
    this.flagged = false,
  });
}

class OcrField {
  final IconData icon;
  final String field;
  final String extracted;
  final String registry;
  final String status;

  const OcrField({
    required this.icon,
    required this.field,
    required this.extracted,
    required this.registry,
    required this.status,
  });
}

class CategoryRow {
  final IconData icon;
  final String name;
  final String description;
  final String registered;
  final String onlineNow;
  final String baseFee;
  final String hourlyCap;
  final List<String> districts;
  final List<String> districtsOff;
  final String surge;
  final String status;

  const CategoryRow({
    required this.icon,
    required this.name,
    required this.description,
    required this.registered,
    required this.onlineNow,
    required this.baseFee,
    required this.hourlyCap,
    required this.districts,
    this.districtsOff = const [],
    required this.surge,
    required this.status,
  });
}

class ExpansionDistrict {
  final String hubName;
  final double readiness;
  final String location;
  final String description;
  final String signups;
  final String preregistrations;
  final String ctaLabel;
  final IconData ctaIcon;

  const ExpansionDistrict({
    required this.hubName,
    required this.readiness,
    required this.location,
    required this.description,
    required this.signups,
    required this.preregistrations,
    required this.ctaLabel,
    required this.ctaIcon,
  });
}
