import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'location_utils.dart';

class CustomerHomeLocation {
  final double latitude;
  final double longitude;
  final String shortArea;

  double get lat => latitude;
  double get lng => longitude;

  const CustomerHomeLocation({
    required this.latitude,
    required this.longitude,
    required this.shortArea,
  });

  Map<String, dynamic> toMap() => {
        'lat': latitude,
        'lng': longitude,
        'shortArea': shortArea,
      };

  factory CustomerHomeLocation.fromMap(Map<String, dynamic> map) =>
      CustomerHomeLocation(
        latitude: (map['lat'] as num?)?.toDouble() ?? 0.0,
        longitude: (map['lng'] as num?)?.toDouble() ?? 0.0,
        shortArea: (map['shortArea'] as String?) ?? '',
      );
}

class RecentPlace {
  final String id;
  final String title;
  final String address;
  final double latitude;
  final double longitude;

  RecentPlace({
    String? id,
    required this.title,
    required this.address,
    required this.latitude,
    required this.longitude,
  }) : id = (id != null && id.isNotEmpty)
            ? id
            : '${latitude.toStringAsFixed(4)}_${longitude.toStringAsFixed(4)}';

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'address': address,
        'lat': latitude,
        'lng': longitude,
      };

  factory RecentPlace.fromMap(Map<String, dynamic> map) => RecentPlace(
        id: (map['id'] as String?) ?? '',
        title: (map['title'] as String?) ?? '',
        address: (map['address'] as String?) ?? '',
        latitude: (map['lat'] as num?)?.toDouble() ?? 0.0,
        longitude: (map['lng'] as num?)?.toDouble() ?? 0.0,
      );
}

class CustomerLocationPrefs {
  CustomerLocationPrefs._();

  static const String _keyHomeLat = 'home_customer_lat';
  static const String _keyHomeLng = 'home_customer_lng';
  static const String _keyHomeArea = 'home_customer_area';
  static const String _keyAskedHomeLocation = 'home_customer_asked_location';
  static const String _keyRecentPlaces = 'recent_customer_places_json';

  // load saved home location from phone only
  static Future<CustomerHomeLocation?> getHomeLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_keyHomeLat);
    final lng = prefs.getDouble(_keyHomeLng);
    final area = prefs.getString(_keyHomeArea);
    if (lat != null && lng != null && area != null && area.isNotEmpty) {
      return CustomerHomeLocation(
        latitude: lat,
        longitude: lng,
        shortArea: area,
      );
    }
    return null;
  }

  // save home location on phone only
  static Future<void> setHomeLocation(CustomerHomeLocation loc) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyHomeLat, loc.latitude);
    await prefs.setDouble(_keyHomeLng, loc.longitude);
    await prefs.setString(_keyHomeArea, loc.shortArea);
    await prefs.setBool(_keyAskedHomeLocation, true);
  }

  static Future<void> saveHomeLocation({
    required double lat,
    required double lng,
    required String shortArea,
  }) async {
    await setHomeLocation(
      CustomerHomeLocation(
        latitude: lat,
        longitude: lng,
        shortArea: shortArea,
      ),
    );
  }

  // clear saved home location
  static Future<void> clearHomeLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHomeLat);
    await prefs.remove(_keyHomeLng);
    await prefs.remove(_keyHomeArea);
  }

  // check if user was prompted on first open
  static Future<bool> hasPromptedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAskedHomeLocation) ?? false;
  }

  static Future<bool> hasAskedHomeLocation() => hasPromptedLocation();

  // mark first prompt as seen
  static Future<void> markPromptedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAskedHomeLocation, true);
  }

  static Future<void> setAskedHomeLocation() => markPromptedLocation();

  // load recent places from phone storage
  static Future<List<RecentPlace>> getRecentPlaces() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyRecentPlaces);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = json.decode(raw) as List<dynamic>;
      return list
          .map((item) => RecentPlace.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // add recent place, de-duplicate within 100m, keep max 5, phone only
  static Future<void> addRecentPlace(RecentPlace location) async {
    final existing = await getRecentPlaces();
    final filtered = <RecentPlace>[];

    // clean place without private details
    final clean = RecentPlace(
      id: location.id,
      title: location.title,
      address: location.address,
      latitude: location.latitude,
      longitude: location.longitude,
    );

    filtered.add(clean);

    for (final place in existing) {
      final distM = LocationUtils.calculateDistanceKm(
            clean.latitude,
            clean.longitude,
            place.latitude,
            place.longitude,
          ) *
          1000.0;
      if (distM >= 100.0 &&
          clean.address.trim().toLowerCase() !=
              place.address.trim().toLowerCase()) {
        filtered.add(place);
      }
      if (filtered.length >= 5) break;
    }

    final raw = json.encode(filtered.map((loc) => loc.toMap()).toList());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRecentPlaces, raw);
  }

  // remove a recent place entry by ID
  static Future<void> removeRecentPlace(String id) async {
    final existing = await getRecentPlaces();
    existing.removeWhere((p) => p.id == id);

    final raw = json.encode(existing.map((loc) => loc.toMap()).toList());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRecentPlaces, raw);
  }

  // remove a recent place entry by index
  static Future<void> removeRecentPlaceAt(int index) async {
    final existing = await getRecentPlaces();
    if (index < 0 || index >= existing.length) return;
    existing.removeAt(index);

    final raw = json.encode(existing.map((loc) => loc.toMap()).toList());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRecentPlaces, raw);
  }
}
