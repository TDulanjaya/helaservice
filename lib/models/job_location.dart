class JobLocation {
  final double latitude;
  final double longitude;
  final String address;
  final String? landmark;
  final String? label;

  const JobLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.landmark,
    this.label,
  });

  Map<String, dynamic> toMap() => {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        if (landmark != null && landmark!.isNotEmpty) 'landmark': landmark,
        if (label != null && label!.isNotEmpty) 'label': label,
      };

  factory JobLocation.fromMap(Map<String, dynamic> map) {
    return JobLocation(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      address: map['address'] as String? ?? '',
      landmark: map['landmark'] as String?,
      label: map['label'] as String?,
    );
  }
}
