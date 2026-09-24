import 'package:cloud_firestore/cloud_firestore.dart';
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
  final String id;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String timeAgo;
  final String detail;
  final String tagLabel;
  final DateTime? timestamp;

  const DispatchEvent({
    this.id = '',
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.timeAgo,
    required this.detail,
    required this.tagLabel,
    this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'detail': detail,
      'tagLabel': tagLabel,
      'timeAgo': timeAgo,
      'iconKey': _iconToKey(icon),
      'colorValue': iconColor.toARGB32(),
      'timestamp': timestamp != null
          ? Timestamp.fromDate(timestamp!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory DispatchEvent.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final ts = parseDate(map['timestamp']);
    String calcTimeAgo(DateTime? dt, String fallback) {
      if (dt == null) return fallback;
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    }

    final iconKey = map['iconKey'] as String? ?? '';
    final colorVal = map['colorValue'] as int? ?? 0xFF00685F;

    return DispatchEvent(
      id: id,
      icon: _keyToIcon(iconKey),
      iconColor: Color(colorVal),
      title: map['title'] as String? ?? '',
      timeAgo: calcTimeAgo(ts, map['timeAgo'] as String? ?? 'Just now'),
      detail: map['detail'] as String? ?? '',
      tagLabel: map['tagLabel'] as String? ?? '',
      timestamp: ts,
    );
  }

  static String _iconToKey(IconData icon) {
    if (icon == Icons.payments) return 'payments';
    if (icon == Icons.bolt) return 'bolt';
    if (icon == Icons.badge) return 'badge';
    if (icon == Icons.ac_unit) return 'ac_unit';
    if (icon == Icons.plumbing) return 'plumbing';
    return 'bolt';
  }

  static IconData _keyToIcon(String key) {
    switch (key) {
      case 'payments':
        return Icons.payments;
      case 'bolt':
        return Icons.bolt;
      case 'badge':
        return Icons.badge;
      case 'ac_unit':
        return Icons.ac_unit;
      case 'plumbing':
        return Icons.plumbing;
      default:
        return Icons.bolt;
    }
  }
}

class DistrictLoad {
  final String id;
  final String name;
  final double percent;
  final String loadLabel;
  final String detail;

  const DistrictLoad({
    this.id = '',
    required this.name,
    required this.percent,
    required this.loadLabel,
    required this.detail,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'percent': percent,
      'loadLabel': loadLabel,
      'detail': detail,
    };
  }

  factory DistrictLoad.fromMap(String id, Map<String, dynamic> map) {
    return DistrictLoad(
      id: id,
      name: map['name'] as String? ?? '',
      percent: (map['percent'] as num?)?.toDouble() ?? 0.5,
      loadLabel: map['loadLabel'] as String? ?? 'Normal',
      detail: map['detail'] as String? ?? '',
    );
  }
}

class VerificationQueueItem {
  final String id;
  final String providerId;
  final String fileKey;
  final String status;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;

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
    this.id = '',
    this.providerId = '',
    this.fileKey = '',
    this.status = 'pending',
    this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    required this.name,
    this.timeAgo = 'Just now',
    required this.trade,
    this.tradeIcon = Icons.engineering,
    required this.location,
    required this.nicNumber,
    this.docNote = 'Front + Back Uploaded',
    this.matchPercent = 95,
    this.flagged = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'providerId': providerId,
      'fileKey': fileKey,
      'status': status,
      if (submittedAt != null) 'submittedAt': Timestamp.fromDate(submittedAt!),
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      'name': name,
      'trade': trade,
      'location': location,
      'nicNumber': nicNumber,
      'docNote': docNote,
      'matchPercent': matchPercent,
      'flagged': flagged,
    };
  }

  factory VerificationQueueItem.fromMap(String id, Map<String, dynamic> map) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    final submitted = parseDate(map['submittedAt']);
    String calcTimeAgo(DateTime? dt) {
      if (dt == null) return map['timeAgo'] as String? ?? 'Just now';
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    }

    IconData resolveTradeIcon(String tradeStr) {
      final lower = tradeStr.toLowerCase();
      if (lower.contains('electr')) return Icons.bolt;
      if (lower.contains('plumb')) return Icons.plumbing;
      if (lower.contains('ac') || lower.contains('hvac') || lower.contains('cool')) return Icons.ac_unit;
      if (lower.contains('carpent')) return Icons.carpenter;
      return Icons.engineering;
    }

    return VerificationQueueItem(
      id: id,
      providerId: map['providerId'] as String? ?? '',
      fileKey: map['fileKey'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      submittedAt: submitted,
      reviewedAt: parseDate(map['reviewedAt']),
      reviewedBy: map['reviewedBy'] as String?,
      name: map['name'] as String? ?? 'Artisan',
      timeAgo: calcTimeAgo(submitted),
      trade: map['trade'] as String? ?? 'Technician',
      tradeIcon: resolveTradeIcon(map['trade'] as String? ?? ''),
      location: map['location'] as String? ?? 'Sri Lanka',
      nicNumber: map['nicNumber'] as String? ?? 'Pending NIC',
      docNote: map['docNote'] as String? ?? 'NIC front + back',
      matchPercent: (map['matchPercent'] as num?)?.toInt() ?? 95,
      flagged: map['flagged'] as bool? ?? false,
    );
  }
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
  final String id;
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
  final String iconKey;

  const CategoryRow({
    this.id = '',
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
    this.iconKey = '',
  });

  Map<String, dynamic> toMap() => {
        'label': name,
        'name': name,
        'description': description,
        'registered': registered,
        'onlineNow': onlineNow,
        'baseFee': baseFee,
        'hourlyCap': hourlyCap,
        'districts': districts,
        'districtsOff': districtsOff,
        'surge': surge,
        'status': status,
        'iconKey': iconKey.isNotEmpty ? iconKey : _iconToKey(icon),
      };

  factory CategoryRow.fromMap(String id, Map<String, dynamic> map) {
    final key = map['iconKey'] as String? ?? '';
    return CategoryRow(
      id: id,
      icon: _keyToIcon(key),
      name: map['name'] ?? map['label'] ?? '',
      description: map['description'] ?? '',
      registered: map['registered'] ?? '0 Registered',
      onlineNow: map['onlineNow'] ?? '0 Online Now',
      baseFee: map['baseFee'] ?? 'LKR 1,500',
      hourlyCap: map['hourlyCap'] ?? 'LKR 1,000 /hr',
      districts: List<String>.from(map['districts'] ?? ['Colombo', 'Gampaha']),
      districtsOff: List<String>.from(map['districtsOff'] ?? []),
      surge: map['surge'] ?? '1.0x Normal',
      status: map['status'] ?? 'Active',
      iconKey: key,
    );
  }

  static IconData _keyToIcon(String key) {
    switch (key) {
      case 'electrical_services':
      case 'electric_bolt':
        return Icons.electrical_services;
      case 'plumbing':
        return Icons.plumbing;
      case 'hvac':
      case 'ac_unit':
        return Icons.hvac;
      case 'carpenter':
        return Icons.carpenter;
      case 'format_paint':
        return Icons.format_paint;
      case 'microwave':
      case 'car_repair':
        return Icons.microwave;
      default:
        return Icons.handyman;
    }
  }

  static String _iconToKey(IconData icon) {
    if (icon == Icons.electrical_services || icon == Icons.bolt) {
      return 'electrical_services';
    }
    if (icon == Icons.plumbing) return 'plumbing';
    if (icon == Icons.hvac || icon == Icons.ac_unit) return 'hvac';
    if (icon == Icons.carpenter) return 'carpenter';
    if (icon == Icons.format_paint) return 'format_paint';
    if (icon == Icons.microwave) return 'microwave';
    return 'handyman';
  }
}

class ExpansionDistrict {
  final String id;
  final String hubName;
  final double readiness;
  final String location;
  final String description;
  final String signups;
  final String preregistrations;
  final String ctaLabel;
  final IconData ctaIcon;

  const ExpansionDistrict({
    this.id = '',
    required this.hubName,
    required this.readiness,
    required this.location,
    required this.description,
    required this.signups,
    required this.preregistrations,
    required this.ctaLabel,
    required this.ctaIcon,
  });

  Map<String, dynamic> toMap() => {
        'hubName': hubName,
        'readiness': readiness,
        'location': location,
        'description': description,
        'signups': signups,
        'preregistrations': preregistrations,
        'ctaLabel': ctaLabel,
      };

  factory ExpansionDistrict.fromMap(String id, Map<String, dynamic> map) {
    return ExpansionDistrict(
      id: id,
      hubName: map['hubName'] ?? map['name'] ?? '',
      readiness:
          ((map['readiness'] ?? map['percent'] ?? 0.5) as num).toDouble(),
      location: map['location'] ?? map['detail'] ?? '',
      description: map['description'] ?? 'Target expansion corridor.',
      signups: map['signups'] ?? '500+ users',
      preregistrations: map['preregistrations'] ?? '20+ vetted',
      ctaLabel: map['ctaLabel'] ?? 'Review Hub',
      ctaIcon: Icons.rocket_launch,
    );
  }
}
