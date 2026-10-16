// job location model with coordinates, address, and note
class JobLocation {
  final double latitude;
  final double longitude;
  final String address;
  final String? landmark;
  final String? label;
  final double? accuracyMeters;
  final String? houseNo;
  final String? street;
  final String? city;
  final String? directions;
  final String? note;

  const JobLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.landmark,
    this.label,
    this.accuracyMeters,
    this.houseNo,
    this.street,
    this.city,
    this.directions,
    this.note,
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
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        if (effectiveNote != null) 'note': effectiveNote,
        // legacy compatibility
        if (effectiveNote != null) 'landmark': effectiveNote,
        if (label != null && label!.isNotEmpty) 'label': label,
        if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
        if (houseNo != null && houseNo!.isNotEmpty) 'houseNo': houseNo,
        if (street != null && street!.isNotEmpty) 'street': street,
        if (city != null && city!.isNotEmpty) 'city': city,
        if (directions != null && directions!.isNotEmpty)
          'directions': directions,
      };

  factory JobLocation.fromMap(Map<String, dynamic> map) {
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

    return JobLocation(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      address: map['address'] as String? ?? '',
      landmark: landmarkRaw,
      label: map['label'] as String?,
      accuracyMeters: (map['accuracyMeters'] as num?)?.toDouble(),
      houseNo: map['houseNo'] as String?,
      street: map['street'] as String?,
      city: map['city'] as String?,
      directions: directionsRaw,
      note: resolvedNote,
    );
  }
}
