import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../state/role_provider.dart';
import 'admin_user.dart';

class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final AppRole? role;
  final bool isProfileComplete;
  final String? phone;
  final String? district;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? nic;
  final String? nicFrontUrl;
  final String? nicBackUrl;
  final String? serviceCategory;
  final AdminRole? adminRole;
  final List<AdminPermission>? permissions;
  final String? preferredLanguage;

  const UserProfile({
    required this.id,
    this.email = '',
    this.displayName = '',
    this.photoUrl,
    this.role,
    this.isProfileComplete = false,
    this.phone,
    this.district,
    this.address,
    this.latitude,
    this.longitude,
    this.nic,
    this.nicFrontUrl,
    this.nicBackUrl,
    this.serviceCategory,
    this.adminRole,
    this.permissions,
    this.preferredLanguage,
  });

  factory UserProfile.fromFirebaseUser(
    fb.User user, {
    AppRole? role,
    bool isComplete = false,
    AdminRole? adminRole,
    List<AdminPermission>? permissions,
    String? preferredLanguage,
  }) {
    final phone = user.phoneNumber;
    final fallbackName = phone != null && phone.isNotEmpty
        ? 'User ($phone)'
        : (user.email != null && user.email!.isNotEmpty
            ? user.email!.split('@').first
            : 'Hela User');

    return UserProfile(
      id: user.uid,
      email: user.email ?? '',
      displayName: (user.displayName != null && user.displayName!.isNotEmpty)
          ? user.displayName!
          : fallbackName,
      photoUrl: null,
      phone: phone,
      role: role,
      isProfileComplete: isComplete,
      adminRole: adminRole,
      permissions: permissions,
      preferredLanguage: preferredLanguage,
    );
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    AppRole? role,
    bool? isProfileComplete,
    String? phone,
    String? district,
    String? address,
    double? latitude,
    double? longitude,
    String? nic,
    String? nicFrontUrl,
    String? nicBackUrl,
    String? serviceCategory,
    AdminRole? adminRole,
    List<AdminPermission>? permissions,
    String? preferredLanguage,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      phone: phone ?? this.phone,
      district: district ?? this.district,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      nic: nic ?? this.nic,
      nicFrontUrl: nicFrontUrl ?? this.nicFrontUrl,
      nicBackUrl: nicBackUrl ?? this.nicBackUrl,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      adminRole: adminRole ?? this.adminRole,
      permissions: permissions ?? this.permissions,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }

  Map<String, dynamic> toMap() {
    // only customer and provider go in users/
    final safeRole = role == AppRole.admin ? null : role?.name;

    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      if (safeRole != null) 'role': safeRole,
      'isProfileComplete': isProfileComplete,
      'phone': phone,
      'district': district,
      'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'nic': nic,
      if (nicFrontUrl != null) 'nicFrontUrl': nicFrontUrl,
      if (nicBackUrl != null) 'nicBackUrl': nicBackUrl,
      'serviceCategory': serviceCategory,
      if (preferredLanguage != null) 'preferredLanguage': preferredLanguage,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    AppRole? parsedRole;
    if (map['role'] != null) {
      if (map['role'] == 'provider') {
        parsedRole = AppRole.provider;
      } else if (map['role'] == 'customer') {
        parsedRole = AppRole.customer;
      } else {
        // default to customer
        parsedRole = AppRole.customer;
      }
    }

    return UserProfile(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
      role: parsedRole,
      isProfileComplete: map['isProfileComplete'] ?? false,
      phone: map['phone'],
      district: map['district'],
      address: map['address'],
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      nic: map['nic'],
      nicFrontUrl: map['nicFrontUrl'],
      nicBackUrl: map['nicBackUrl'],
      serviceCategory: map['serviceCategory'],
      preferredLanguage: map['preferredLanguage']?.toString(),
    );
  }
}
