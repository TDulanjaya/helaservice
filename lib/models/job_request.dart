import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import '../constants/job_status.dart';
import '../utils/schedule_helpers.dart';

class JobMediaItem {
  final String url;
  final String key;
  const JobMediaItem({required this.url, required this.key});

  Map<String, dynamic> toMap() => {'url': url, 'key': key};

  factory JobMediaItem.fromMap(Map<String, dynamic> map) {
    return JobMediaItem(
      url: map['url']?.toString() ?? '',
      key: map['key']?.toString() ?? '',
    );
  }
}

class JobVideoItem {
  final String url;
  final String key;
  final String? thumbUrl;
  final int? durationSec;

  const JobVideoItem({
    required this.url,
    required this.key,
    this.thumbUrl,
    this.durationSec,
  });

  Map<String, dynamic> toMap() => {
        'url': url,
        'key': key,
        if (thumbUrl != null) 'thumbUrl': thumbUrl,
        if (durationSec != null) 'durationSec': durationSec,
      };

  factory JobVideoItem.fromMap(Map<String, dynamic> map) {
    return JobVideoItem(
      url: map['url']?.toString() ?? '',
      key: map['key']?.toString() ?? '',
      thumbUrl: map['thumbUrl']?.toString(),
      durationSec: (map['durationSec'] as num?)?.toInt(),
    );
  }
}

class JobRequest {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String title;
  final String description;
  final String category;
  final List<JobMediaItem> photos;
  final JobVideoItem? video;
  final List<String> _legacyPhotoUrls;
  final double? latitude;
  final double? longitude;
  final String? district;
  final String address;
  final String? landmark;
  final String status;
  final int quoteCount;
  final String? selectedProviderId;
  final String? acceptedQuoteId;
  final String? bookingId;
  final double? agreedPrice;
  final String? cancellationReason;
  final String? cancelReason;
  final String? cancelledBy;
  final DateTime? cancelledAt;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final DateTime? mediaDeletedAt;
  final bool hiddenByCustomer;
  final DateTime? jobUpdatedAt;
  final DateTime? deletedAt;
  final DateTime? renewedAt;
  final DateTime? mediaWarningSentAt;
  final String? previousStatus;
  final String bookingType;
  final String scheduleMode;
  final DateTime? scheduledDate;
  final DateTime? scheduledStartAt;
  final DateTime? scheduledEndAt;
  final String? scheduledSlot;
  final int? flexibleWindowDays;
  final DateTime? expiresAt;

  // local address details kept private
  final double? accuracyMeters;
  final String? houseNo;
  final String? street;
  final String? city;
  final String? directions;
  final String? note;

  const JobRequest({
    this.id = '',
    required this.customerId,
    required this.customerName,
    this.customerPhone = '',
    required this.title,
    required this.description,
    required this.category,
    this.photos = const [],
    this.video,
    List<String> photoUrls = const [],
    this.latitude,
    this.longitude,
    this.district,
    this.address = '',
    this.landmark,
    this.status = JobRequestStatus.open,
    this.quoteCount = 0,
    this.selectedProviderId,
    this.acceptedQuoteId,
    this.bookingId,
    this.agreedPrice,
    this.cancellationReason,
    this.cancelReason,
    this.cancelledBy,
    this.cancelledAt,
    this.createdAt,
    this.completedAt,
    this.mediaDeletedAt,
    this.hiddenByCustomer = false,
    this.jobUpdatedAt,
    this.deletedAt,
    this.renewedAt,
    this.mediaWarningSentAt,
    this.previousStatus,
    this.bookingType = 'asap',
    this.scheduleMode = 'today',
    this.scheduledDate,
    this.scheduledStartAt,
    this.scheduledEndAt,
    this.scheduledSlot,
    this.flexibleWindowDays,
    this.expiresAt,
    this.accuracyMeters,
    this.houseNo,
    this.street,
    this.city,
    this.directions,
    this.note,
  }) : _legacyPhotoUrls = photoUrls;

  bool get hasQuotes => quoteCount > 0;
  bool get canDelete => quoteCount == 0;
  bool get becameBooking =>
      (bookingId != null && bookingId!.isNotEmpty) ||
      (selectedProviderId != null && selectedProviderId!.isNotEmpty) ||
      (acceptedQuoteId != null && acceptedQuoteId!.isNotEmpty);
  bool get isPhotosRemoved => mediaDeletedAt != null;

  List<String> get photoUrls =>
      photos.isNotEmpty ? photos.map((p) => p.url).toList() : _legacyPhotoUrls;

  String? get videoUrl => video?.url;

  String get effectiveCancelReason => cancelReason ?? cancellationReason ?? '';

  bool get isExpired {
    if (status != JobRequestStatus.open && status != 'pending') {
      return false;
    }
    final exp = expiresAt ??
        ScheduleHelpers.computeLegacyExpiresAt(
          scheduledDate: scheduledDate,
          createdAt: createdAt,
        );
    return DateTime.now().isAfter(exp);
  }

  String scheduleLabel(BuildContext context) {
    return ScheduleHelpers.scheduleLabel(
      scheduleMode: scheduleMode,
      scheduledSlot: scheduledSlot,
      scheduledDate: scheduledDate,
      scheduledStartAt: scheduledStartAt,
      scheduledEndAt: scheduledEndAt,
      flexibleWindowDays: flexibleWindowDays,
      context: context,
    );
  }

  Map<String, dynamic> toMap() => {
        'customerId': customerId,
        'customerName': customerName,
        'title': title,
        'description': description,
        'category': category,
        if (photos.isNotEmpty) 'photos': photos.map((p) => p.toMap()).toList(),
        if (video != null) 'video': video!.toMap(),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (district != null) 'district': district,
        'status': status,
        'quoteCount': quoteCount,
        if (selectedProviderId != null)
          'selectedProviderId': selectedProviderId,
        if (acceptedQuoteId != null) 'acceptedQuoteId': acceptedQuoteId,
        if (bookingId != null) 'bookingId': bookingId,
        if (agreedPrice != null) 'agreedPrice': agreedPrice,
        if (cancelReason != null || cancellationReason != null)
          'cancelReason': cancelReason ?? cancellationReason,
        if (cancelledBy != null) 'cancelledBy': cancelledBy,
        if (cancelledAt != null)
          'cancelledAt': Timestamp.fromDate(cancelledAt!),
        if (completedAt != null)
          'completedAt': Timestamp.fromDate(completedAt!),
        if (mediaDeletedAt != null)
          'mediaDeletedAt': Timestamp.fromDate(mediaDeletedAt!),
        if (hiddenByCustomer) 'hiddenByCustomer': true,
        if (jobUpdatedAt != null)
          'jobUpdatedAt': Timestamp.fromDate(jobUpdatedAt!),
        if (deletedAt != null)
          'deletedAt': Timestamp.fromDate(deletedAt!),
        if (renewedAt != null)
          'renewedAt': Timestamp.fromDate(renewedAt!),
        if (mediaWarningSentAt != null)
          'mediaWarningSentAt': Timestamp.fromDate(mediaWarningSentAt!),
        if (previousStatus != null && previousStatus!.isNotEmpty)
          'previousStatus': previousStatus,
        'bookingType':
            scheduleMode == ScheduleHelpers.modeToday ? 'asap' : 'scheduled',
        'scheduleMode': scheduleMode,
        if (scheduledDate != null)
          'scheduledDate': Timestamp.fromDate(scheduledDate!),
        if (scheduledStartAt != null)
          'scheduledStartAt': Timestamp.fromDate(scheduledStartAt!),
        if (scheduledEndAt != null)
          'scheduledEndAt': Timestamp.fromDate(scheduledEndAt!),
        if (scheduledSlot != null && scheduledSlot!.isNotEmpty)
          'scheduledSlot': scheduledSlot,
        if (flexibleWindowDays != null)
          'flexibleWindowDays': flexibleWindowDays,
        if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  factory JobRequest.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['createdAt'];
    final cat = map['completedAt'];
    final cnat = map['cancelledAt'];
    final sdt = map['scheduledDate'];
    final ssa = map['scheduledStartAt'];
    final sea = map['scheduledEndAt'];
    final exp = map['expiresAt'];
    final mda = map['mediaDeletedAt'];
    final jua = map['jobUpdatedAt'];
    final dat = map['deletedAt'];
    final rnat = map['renewedAt'];
    final mwsa = map['mediaWarningSentAt'];
    final prevStat = map['previousStatus'] as String?;

    DateTime? resolvedCreatedAt;
    if (ts is Timestamp) {
      resolvedCreatedAt = ts.toDate();
    } else if (ts is String) {
      resolvedCreatedAt = DateTime.tryParse(ts);
    }

    List<JobMediaItem> parsedPhotos = [];
    if (map['photos'] is List) {
      parsedPhotos = (map['photos'] as List)
          .whereType<Map>()
          .map((m) => JobMediaItem.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    } else if (map['photoUrls'] is List) {
      parsedPhotos = (map['photoUrls'] as List)
          .map((u) => JobMediaItem(url: u.toString(), key: ''))
          .toList();
    }

    JobVideoItem? parsedVideo;
    if (map['video'] is Map) {
      parsedVideo =
          JobVideoItem.fromMap(Map<String, dynamic>.from(map['video'] as Map));
    }

    final rawMode = map['scheduleMode'] as String? ??
        (map['bookingType'] == 'scheduled'
            ? 'date'
            : (map['bookingType']?.toString() == 'asap' ? 'today' : 'today'));
    final mode = ScheduleHelpers.normalizeMode(rawMode);

    final noteRaw = map['note'] as String?;
    final landmarkRaw = map['landmark'] as String?;
    final directionsRaw = map['directions'] as String?;
    String? resolvedNote = noteRaw?.trim();
    if (resolvedNote == null || resolvedNote.isEmpty) {
      final parts = [
        if (landmarkRaw != null && landmarkRaw.trim().isNotEmpty)
          landmarkRaw.trim(),
        if (directionsRaw != null && directionsRaw.trim().isNotEmpty)
          directionsRaw.trim(),
      ];
      if (parts.isNotEmpty) {
        resolvedNote = parts.join(' · ');
      }
    }

    final scheduledDate = sdt is Timestamp ? sdt.toDate() : null;
    DateTime? resolvedExpiresAt;
    if (exp is Timestamp) {
      resolvedExpiresAt = exp.toDate();
    } else {
      resolvedExpiresAt = ScheduleHelpers.computeLegacyExpiresAt(
        scheduledDate: scheduledDate,
        createdAt: resolvedCreatedAt,
      );
    }

    final reason =
        (map['cancelReason'] ?? map['cancellationReason']) as String?;

    // lock if quote count missing
    final rawQuoteCount = map['quoteCount'];
    final resolvedQuoteCount =
        (rawQuoteCount is num) ? rawQuoteCount.toInt() : 1;

    return JobRequest(
      id: id,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      photos: parsedPhotos,
      video: parsedVideo,
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      district: map['district'] as String?,
      address: map['address'] ?? '',
      landmark: landmarkRaw,
      note: resolvedNote,
      status: map['status'] ?? JobRequestStatus.open,
      quoteCount: resolvedQuoteCount,
      selectedProviderId: map['selectedProviderId'],
      acceptedQuoteId: map['acceptedQuoteId'],
      bookingId: map['bookingId'] as String?,
      agreedPrice: (map['agreedPrice'] as num?)?.toDouble(),
      cancellationReason: reason,
      cancelReason: reason,
      cancelledBy: map['cancelledBy'],
      cancelledAt: cnat is Timestamp ? cnat.toDate() : null,
      createdAt: resolvedCreatedAt,
      completedAt: cat is Timestamp ? cat.toDate() : null,
      mediaDeletedAt: mda is Timestamp ? mda.toDate() : null,
      hiddenByCustomer: map['hiddenByCustomer'] == true,
      jobUpdatedAt: jua is Timestamp ? jua.toDate() : null,
      deletedAt: dat is Timestamp ? dat.toDate() : null,
      renewedAt: rnat is Timestamp ? rnat.toDate() : null,
      mediaWarningSentAt: mwsa is Timestamp ? mwsa.toDate() : null,
      previousStatus: prevStat,
      bookingType: map['bookingType']?.toString() ??
          (mode == 'today' ? 'asap' : 'scheduled'),
      scheduleMode: mode,
      scheduledDate: scheduledDate,
      scheduledStartAt: ssa is Timestamp ? ssa.toDate() : null,
      scheduledEndAt: sea is Timestamp ? sea.toDate() : null,
      scheduledSlot: map['scheduledSlot'] as String?,
      flexibleWindowDays: (map['flexibleWindowDays'] as num?)?.toInt(),
      expiresAt: resolvedExpiresAt,
    );
  }

  JobRequest copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? title,
    String? description,
    String? category,
    List<JobMediaItem>? photos,
    JobVideoItem? video,
    List<String>? photoUrls,
    double? latitude,
    double? longitude,
    String? district,
    String? address,
    String? landmark,
    String? status,
    int? quoteCount,
    String? selectedProviderId,
    String? acceptedQuoteId,
    String? bookingId,
    double? agreedPrice,
    String? cancellationReason,
    String? cancelReason,
    String? cancelledBy,
    DateTime? cancelledAt,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? mediaDeletedAt,
    bool? hiddenByCustomer,
    DateTime? jobUpdatedAt,
    DateTime? deletedAt,
    DateTime? renewedAt,
    DateTime? mediaWarningSentAt,
    String? previousStatus,
    String? bookingType,
    String? scheduleMode,
    DateTime? scheduledDate,
    DateTime? scheduledStartAt,
    DateTime? scheduledEndAt,
    String? scheduledSlot,
    int? flexibleWindowDays,
    DateTime? expiresAt,
    double? accuracyMeters,
    String? houseNo,
    String? street,
    String? city,
    String? directions,
    String? note,
  }) {
    return JobRequest(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      photos: photos ?? this.photos,
      video: video ?? this.video,
      photoUrls: photoUrls ?? this.photoUrls,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      district: district ?? this.district,
      address: address ?? this.address,
      landmark: landmark ?? this.landmark,
      status: status ?? this.status,
      quoteCount: quoteCount ?? this.quoteCount,
      selectedProviderId: selectedProviderId ?? this.selectedProviderId,
      acceptedQuoteId: acceptedQuoteId ?? this.acceptedQuoteId,
      bookingId: bookingId ?? this.bookingId,
      agreedPrice: agreedPrice ?? this.agreedPrice,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelReason: cancelReason ?? this.cancelReason,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      mediaDeletedAt: mediaDeletedAt ?? this.mediaDeletedAt,
      hiddenByCustomer: hiddenByCustomer ?? this.hiddenByCustomer,
      jobUpdatedAt: jobUpdatedAt ?? this.jobUpdatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      renewedAt: renewedAt ?? this.renewedAt,
      mediaWarningSentAt: mediaWarningSentAt ?? this.mediaWarningSentAt,
      previousStatus: previousStatus ?? this.previousStatus,
      bookingType: bookingType ?? this.bookingType,
      scheduleMode: scheduleMode ?? this.scheduleMode,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledStartAt: scheduledStartAt ?? this.scheduledStartAt,
      scheduledEndAt: scheduledEndAt ?? this.scheduledEndAt,
      scheduledSlot: scheduledSlot ?? this.scheduledSlot,
      flexibleWindowDays: flexibleWindowDays ?? this.flexibleWindowDays,
      expiresAt: expiresAt ?? this.expiresAt,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      houseNo: houseNo ?? this.houseNo,
      street: street ?? this.street,
      city: city ?? this.city,
      directions: directions ?? this.directions,
      note: note ?? this.note,
    );
  }
}
