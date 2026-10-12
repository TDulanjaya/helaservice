import 'package:cloud_firestore/cloud_firestore.dart';

class SavedAddress {
  final String id;
  final String label;
  final double latitude;
  final double longitude;
  final String address;
  final String? landmark;
  final DateTime? createdAt;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.landmark,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'label': label,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        if (landmark != null && landmark!.isNotEmpty) 'landmark': landmark,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  factory SavedAddress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime? created;
    final rawCreated = data['createdAt'];
    if (rawCreated is Timestamp) {
      created = rawCreated.toDate();
    } else if (rawCreated is String) {
      created = DateTime.tryParse(rawCreated);
    }

    return SavedAddress(
      id: doc.id,
      label: data['label'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      address: data['address'] as String? ?? '',
      landmark: data['landmark'] as String?,
      createdAt: created,
    );
  }

  SavedAddress copyWith({
    String? id,
    String? label,
    double? latitude,
    double? longitude,
    String? address,
    String? landmark,
    DateTime? createdAt,
  }) {
    return SavedAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      landmark: landmark ?? this.landmark,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
