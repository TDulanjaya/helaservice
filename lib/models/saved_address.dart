import 'package:cloud_firestore/cloud_firestore.dart';

class SavedAddress {
  final String id;
  final String label;
  final double latitude;
  final double longitude;
  final String address;
  final String? landmark;
  final double? accuracyMeters;
  final String? houseNo;
  final String? street;
  final String? city;
  final String? directions;
  final String? note;
  final DateTime? createdAt;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.landmark,
    this.accuracyMeters,
    this.houseNo,
    this.street,
    this.city,
    this.directions,
    this.note,
    this.createdAt,
  });

  // effective note for provider (falls back to landmark / directions)
  String? get effectiveNote {
    if (note != null && note!.trim().isNotEmpty) return note!.trim();
    final parts = [
      if (landmark != null && landmark!.trim().isNotEmpty) landmark!.trim(),
      if (directions != null && directions!.trim().isNotEmpty)
        directions!.trim(),
    ];
    return parts.isNotEmpty ? parts.join(' · ') : null;
  }

  Map<String, dynamic> toMap() => {
        'label': label,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        if (effectiveNote != null) 'note': effectiveNote,
        if (effectiveNote != null) 'landmark': effectiveNote,
        if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
        if (houseNo != null && houseNo!.isNotEmpty) 'houseNo': houseNo,
        if (street != null && street!.isNotEmpty) 'street': street,
        if (city != null && city!.isNotEmpty) 'city': city,
        if (directions != null && directions!.isNotEmpty)
          'directions': directions,
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

    final noteRaw = data['note'] as String?;
    final landmarkRaw = data['landmark'] as String?;
    final directionsRaw = data['directions'] as String?;
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

    return SavedAddress(
      id: doc.id,
      label: data['label'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      address: data['address'] as String? ?? '',
      landmark: landmarkRaw,
      accuracyMeters: (data['accuracyMeters'] as num?)?.toDouble(),
      houseNo: data['houseNo'] as String?,
      street: data['street'] as String?,
      city: data['city'] as String?,
      directions: directionsRaw,
      note: resolvedNote,
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
    double? accuracyMeters,
    String? houseNo,
    String? street,
    String? city,
    String? directions,
    String? note,
    DateTime? createdAt,
  }) {
    return SavedAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      landmark: landmark ?? this.landmark,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      houseNo: houseNo ?? this.houseNo,
      street: street ?? this.street,
      city: city ?? this.city,
      directions: directions ?? this.directions,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
