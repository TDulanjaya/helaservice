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
  });

  Map<String, dynamic> toMap() => {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        if (landmark != null && landmark!.isNotEmpty) 'landmark': landmark,
        if (label != null && label!.isNotEmpty) 'label': label,
        if (accuracyMeters != null) 'accuracyMeters': accuracyMeters,
        if (houseNo != null && houseNo!.isNotEmpty) 'houseNo': houseNo,
        if (street != null && street!.isNotEmpty) 'street': street,
        if (city != null && city!.isNotEmpty) 'city': city,
        if (directions != null && directions!.isNotEmpty) 'directions': directions,
      };

  factory JobLocation.fromMap(Map<String, dynamic> map) {
    return JobLocation(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      address: map['address'] as String? ?? '',
      landmark: map['landmark'] as String?,
      label: map['label'] as String?,
      accuracyMeters: (map['accuracyMeters'] as num?)?.toDouble(),
      houseNo: map['houseNo'] as String?,
      street: map['street'] as String?,
      city: map['city'] as String?,
      directions: map['directions'] as String?,
    );
  }
}
