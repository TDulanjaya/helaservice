import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/job_status.dart';

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
  final double? agreedPrice;
  final String? cancellationReason;
  final String? cancelledBy;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final String bookingType;
  final DateTime? scheduledDate;
  final String? scheduledSlot;

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
    this.agreedPrice,
    this.cancellationReason,
    this.cancelledBy,
    this.createdAt,
    this.completedAt,
    this.bookingType = 'asap',
    this.scheduledDate,
    this.scheduledSlot,
  }) : _legacyPhotoUrls = photoUrls;

  List<String> get photoUrls =>
      photos.isNotEmpty ? photos.map((p) => p.url).toList() : _legacyPhotoUrls;

  String? get videoUrl => video?.url;

  bool get isExpired =>
      status == JobRequestStatus.open &&
      createdAt != null &&
      DateTime.now().difference(createdAt!).inDays >= 7;

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
        if (selectedProviderId != null) 'selectedProviderId': selectedProviderId,
        if (acceptedQuoteId != null) 'acceptedQuoteId': acceptedQuoteId,
        if (agreedPrice != null) 'agreedPrice': agreedPrice,
        if (cancellationReason != null) 'cancellationReason': cancellationReason,
        if (cancelledBy != null) 'cancelledBy': cancelledBy,
        if (completedAt != null)
          'completedAt': Timestamp.fromDate(completedAt!),
        'bookingType': bookingType,
        if (scheduledDate != null)
          'scheduledDate': Timestamp.fromDate(scheduledDate!),
        if (scheduledSlot != null) 'scheduledSlot': scheduledSlot,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  factory JobRequest.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['createdAt'];
    final cat = map['completedAt'];
    final sdt = map['scheduledDate'];
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
      parsedVideo = JobVideoItem.fromMap(Map<String, dynamic>.from(map['video'] as Map));
    }

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
      landmark: map['landmark'] as String?,
      status: map['status'] ?? JobRequestStatus.open,
      quoteCount: map['quoteCount'] ?? 0,
      selectedProviderId: map['selectedProviderId'],
      acceptedQuoteId: map['acceptedQuoteId'],
      agreedPrice: (map['agreedPrice'] as num?)?.toDouble(),
      cancellationReason: map['cancellationReason'],
      cancelledBy: map['cancelledBy'],
      createdAt: resolvedCreatedAt,
      completedAt: cat is Timestamp ? cat.toDate() : null,
      bookingType: map['bookingType']?.toString() ?? 'asap',
      scheduledDate: sdt is Timestamp ? sdt.toDate() : null,
      scheduledSlot: map['scheduledSlot'] as String?,
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
    double? agreedPrice,
    String? cancellationReason,
    String? cancelledBy,
    DateTime? createdAt,
    DateTime? completedAt,
    String? bookingType,
    DateTime? scheduledDate,
    String? scheduledSlot,
  }) {
    return JobRequest(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
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
      agreedPrice: agreedPrice ?? this.agreedPrice,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      bookingType: bookingType ?? this.bookingType,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledSlot: scheduledSlot ?? this.scheduledSlot,
    );
  }
}

