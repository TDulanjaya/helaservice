import 'package:cloud_firestore/cloud_firestore.dart';

class JobRequest {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String title;
  final String description;
  final String category;
  final List<String> photoUrls;
  final double? latitude;
  final double? longitude;
  final String address;
  final String status;
  final int quoteCount;
  final String? selectedProviderId;
  final String? acceptedQuoteId;
  final double? agreedPrice;
  final DateTime? createdAt;

  const JobRequest({
    this.id = '',
    required this.customerId,
    required this.customerName,
    this.customerPhone = '',
    required this.title,
    required this.description,
    required this.category,
    this.photoUrls = const [],
    this.latitude,
    this.longitude,
    this.address = '',
    this.status = 'open',
    this.quoteCount = 0,
    this.selectedProviderId,
    this.acceptedQuoteId,
    this.agreedPrice,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'title': title,
        'description': description,
        'category': category,
        'photoUrls': photoUrls,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'address': address,
        'status': status,
        'quoteCount': quoteCount,
        if (selectedProviderId != null) 'selectedProviderId': selectedProviderId,
        if (acceptedQuoteId != null) 'acceptedQuoteId': acceptedQuoteId,
        if (agreedPrice != null) 'agreedPrice': agreedPrice,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory JobRequest.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['createdAt'];
    return JobRequest(
      id: id,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      address: map['address'] ?? '',
      status: map['status'] ?? 'open',
      quoteCount: map['quoteCount'] ?? 0,
      selectedProviderId: map['selectedProviderId'],
      acceptedQuoteId: map['acceptedQuoteId'],
      agreedPrice: (map['agreedPrice'] as num?)?.toDouble(),
      createdAt: ts is Timestamp ? ts.toDate() : null,
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
    String? address,
    String? status,
    int? quoteCount,
    String? selectedProviderId,
    String? acceptedQuoteId,
    double? agreedPrice,
    DateTime? createdAt,
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
      address: address ?? this.address,
      status: status ?? this.status,
      quoteCount: quoteCount ?? this.quoteCount,
      selectedProviderId: selectedProviderId ?? this.selectedProviderId,
      acceptedQuoteId: acceptedQuoteId ?? this.acceptedQuoteId,
      agreedPrice: agreedPrice ?? this.agreedPrice,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
