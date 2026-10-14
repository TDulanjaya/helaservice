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
      if (diff.inMinutes < 1) return '';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${diff.inDays}d';
    }

    final iconKey = map['iconKey'] as String? ?? '';
    final colorVal = map['colorValue'] as int? ?? 0xFFD6900F;

    return DispatchEvent(
      id: id,
      icon: _keyToIcon(iconKey),
      iconColor: Color(colorVal),
      title: map['title'] as String? ?? '',
      timeAgo: calcTimeAgo(ts, map['timeAgo'] as String? ?? ''),
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
      loadLabel: map['loadLabel'] as String? ?? '',
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
  final String? nicHash;
  final String? rejectionReason;
  final String? rejectionNote;
  final String docNote;
  final int matchPercent;
  final bool flagged;
  final String phone;
  final String preferredLanguage;
  final String? photoUrl;
  final String? nicFrontKey;
  final String? nicBackKey;
  final List<String> certificationUrls;
  final bool photoApproved;
  final bool nicApproved;
  final bool certsApproved;

  String? get nicFrontUrl => nicFrontKey;
  String? get nicBackUrl => nicBackKey;

  bool get hasComputedMatch => matchPercent > 0;

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
    this.nicHash,
    this.rejectionReason,
    this.rejectionNote,
    this.docNote = 'Front + Back Uploaded',
    this.matchPercent = 0,
    this.flagged = false,
    this.phone = '',
    this.preferredLanguage = '',
    this.photoUrl,
    String? nicFrontKey,
    String? nicBackKey,
    String? nicFrontUrl,
    String? nicBackUrl,
    this.certificationUrls = const [],
    this.photoApproved = false,
    this.nicApproved = false,
    this.certsApproved = false,
  })  : nicFrontKey = nicFrontKey ?? nicFrontUrl,
        nicBackKey = nicBackKey ?? nicBackUrl;

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
      if (nicHash != null) 'nicHash': nicHash,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (rejectionNote != null) 'rejectionNote': rejectionNote,
      'docNote': docNote,
      'matchPercent': matchPercent,
      'flagged': flagged,
      if (phone.isNotEmpty) 'phone': phone,
      if (preferredLanguage.isNotEmpty) 'preferredLanguage': preferredLanguage,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (nicFrontKey != null) 'nicFrontKey': nicFrontKey,
      if (nicBackKey != null) 'nicBackKey': nicBackKey,
      if (certificationUrls.isNotEmpty) 'certificationUrls': certificationUrls,
      'photoApproved': photoApproved,
      'nicApproved': nicApproved,
      'certsApproved': certsApproved,
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
      if (dt == null) return map['timeAgo'] as String? ?? '';
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return '';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${diff.inDays}d';
    }

    IconData resolveTradeIcon(String tradeStr) {
      final lower = tradeStr.toLowerCase();
      if (lower.contains('electr')) return Icons.bolt;
      if (lower.contains('plumb')) return Icons.plumbing;
      if (lower.contains('ac') ||
          lower.contains('hvac') ||
          lower.contains('cool')) {
        return Icons.ac_unit;
      }
      if (lower.contains('carpent')) return Icons.carpenter;
      return Icons.engineering;
    }

    final certsRaw = map['certificationUrls'];
    final certList = (certsRaw is List)
        ? certsRaw.map((e) => e.toString()).toList()
        : <String>[];

    final resolvedName = (map['providerName'] as String?)?.isNotEmpty == true
        ? map['providerName'] as String
        : (map['name'] as String? ?? '');

    final resolvedTrade = (map['serviceCategory'] as String?)?.isNotEmpty == true
        ? map['serviceCategory'] as String
        : ((map['category'] as String?)?.isNotEmpty == true
            ? map['category'] as String
            : (map['trade'] as String? ?? ''));

    final resolvedLocation = (map['district'] as String?)?.isNotEmpty == true
        ? map['district'] as String
        : (map['location'] as String? ?? '');

    final resolvedNic = (map['nic'] as String?)?.isNotEmpty == true
        ? map['nic'] as String
        : (map['nicNumber'] as String? ?? '');

    return VerificationQueueItem(
      id: id,
      providerId: map['providerId'] as String? ?? id,
      fileKey: map['fileKey'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      submittedAt: submitted,
      reviewedAt: parseDate(map['reviewedAt']),
      reviewedBy: map['reviewedBy'] as String?,
      name: resolvedName,
      timeAgo: calcTimeAgo(submitted),
      trade: resolvedTrade,
      tradeIcon: resolveTradeIcon(resolvedTrade),
      location: resolvedLocation,
      nicNumber: resolvedNic,
      nicHash: map['nicHash'] as String?,
      rejectionReason: map['rejectionReason'] as String? ?? map['reason'] as String?,
      rejectionNote: map['rejectionNote'] as String? ?? map['note'] as String?,
      docNote: map['docNote'] as String? ?? '',
      matchPercent: (map['matchPercent'] as num?)?.toInt() ?? 0,
      flagged: map['flagged'] as bool? ?? false,
      phone: map['phone'] as String? ?? '',
      preferredLanguage: map['preferredLanguage'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      nicFrontKey: map['nicFrontKey'] as String? ?? map['nicFrontUrl'] as String?,
      nicBackKey: map['nicBackKey'] as String? ?? map['nicBackUrl'] as String?,
      certificationUrls: certList,
      photoApproved: map['photoApproved'] as bool? ?? false,
      nicApproved: map['nicApproved'] as bool? ?? false,
      certsApproved: map['certsApproved'] as bool? ?? false,
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
  final List<String> districts;
  final List<String> districtsOff;
  final String surge;
  final String status;
  final String iconKey;
  final bool isLive;
  final int sortOrder;
  final String code;
  final Map<String, String>? names;

  const CategoryRow({
    this.id = '',
    required this.icon,
    required this.name,
    required this.description,
    required this.registered,
    required this.onlineNow,
    required this.districts,
    this.districtsOff = const [],
    required this.surge,
    required this.status,
    this.iconKey = '',
    this.isLive = true,
    this.sortOrder = 0,
    this.code = '',
    this.names,
  });

  CategoryRow copyWith({
    String? id,
    IconData? icon,
    String? name,
    String? description,
    String? registered,
    String? onlineNow,
    List<String>? districts,
    List<String>? districtsOff,
    String? surge,
    String? status,
    String? iconKey,
    bool? isLive,
    int? sortOrder,
    String? code,
    Map<String, String>? names,
  }) {
    return CategoryRow(
      id: id ?? this.id,
      icon: icon ?? this.icon,
      name: name ?? this.name,
      description: description ?? this.description,
      registered: registered ?? this.registered,
      onlineNow: onlineNow ?? this.onlineNow,
      districts: districts ?? this.districts,
      districtsOff: districtsOff ?? this.districtsOff,
      surge: surge ?? this.surge,
      status: status ?? this.status,
      iconKey: iconKey ?? this.iconKey,
      isLive: isLive ?? this.isLive,
      sortOrder: sortOrder ?? this.sortOrder,
      code: code ?? this.code,
      names: names ?? this.names,
    );
  }

  Map<String, dynamic> toMap() => {
        'label': name,
        'name': name,
        'description': description,
        'registered': registered,
        'onlineNow': onlineNow,
        'districts': districts,
        'districtsOff': districtsOff,
        'surge': surge,
        'status': status,
        'iconKey': iconKey.isNotEmpty ? iconKey : _iconToKey(icon),
        'isLive': isLive,
        'sortOrder': sortOrder,
        'code': code.isNotEmpty ? code : id,
        'names': names ?? {'en': name},
      };

  factory CategoryRow.fromMap(String id, Map<String, dynamic> map) {
    final key = map['iconKey'] as String? ?? '';
    final statusStr = map['status'] as String? ?? 'active';
    final live = map['isLive'] is bool
        ? map['isLive'] as bool
        : (statusStr.toLowerCase() == 'active');

    Map<String, String>? namesMap;
    if (map['names'] is Map) {
      namesMap = (map['names'] as Map).map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
    } else {
      final en = map['name_en'] ?? map['name'];
      final si = map['name_si'];
      final ta = map['name_ta'];
      if (en != null || si != null || ta != null) {
        namesMap = {
          if (en != null) 'en': en.toString(),
          if (si != null) 'si': si.toString(),
          if (ta != null) 'ta': ta.toString(),
        };
      }
    }

    return CategoryRow(
      id: id,
      icon: _keyToIcon(key),
      name: namesMap?['en'] ?? map['name'] ?? map['label'] ?? '',
      description: map['description'] ?? '',
      registered: map['registered'] ?? '0',
      onlineNow: map['onlineNow'] ?? '0',
      districts: List<String>.from(map['districts'] ?? []),
      districtsOff: List<String>.from(map['districtsOff'] ?? []),
      surge: map['surge'] ?? '1.0x',
      status: statusStr,
      iconKey: key,
      isLive: live,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      code: map['code'] as String? ?? id,
      names: namesMap,
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
      description: map['description'] ?? '',
      signups: map['signups'] ?? '',
      preregistrations: map['preregistrations'] ?? '',
      ctaLabel: map['ctaLabel'] ?? '',
      ctaIcon: Icons.rocket_launch,
    );
  }
}
