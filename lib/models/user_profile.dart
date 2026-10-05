import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../state/role_provider.dart';
import 'admin_user.dart';

class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? photoStatus; // 'pending' | 'approved' | 'rejected'
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
  final List<String> certificationUrls;
  final String? certificationsStatus; // 'pending' | 'approved' | 'rejected'
  final String? serviceCategory;
  final AdminRole? adminRole;
  final List<AdminPermission>? permissions;
  final String? preferredLanguage;
  final bool isBanned;
  final String? banReason;

  const UserProfile({
    required this.id,
    this.email = '',
    this.displayName = '',
    this.photoUrl,
    this.photoStatus,
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
    this.certificationUrls = const [],
    this.certificationsStatus,
    this.serviceCategory,
    this.adminRole,
    this.permissions,
    this.preferredLanguage,
    this.isBanned = false,
    this.banReason,
  });

  bool get isSuperAdmin =>
      adminRole == AdminRole.superAdmin ||
      (role == AppRole.admin && adminRole == AdminRole.superAdmin);

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
      isBanned: false,
      banReason: null,
    );
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? photoStatus,
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
    List<String>? certificationUrls,
    String? certificationsStatus,
    String? serviceCategory,
    AdminRole? adminRole,
    List<AdminPermission>? permissions,
    String? preferredLanguage,
    bool? isBanned,
    String? banReason,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      photoStatus: photoStatus ?? this.photoStatus,
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
      certificationUrls: certificationUrls ?? this.certificationUrls,
      certificationsStatus: certificationsStatus ?? this.certificationsStatus,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      adminRole: adminRole ?? this.adminRole,
      permissions: permissions ?? this.permissions,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      isBanned: isBanned ?? this.isBanned,
      banReason: banReason ?? this.banReason,
    );
  }

  Map<String, dynamic> toMap() {
    // only customer and provider go in users/
    final safeRole = role == AppRole.admin ? null : role?.name;

    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (photoStatus != null) 'photoStatus': photoStatus,
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
      if (certificationUrls.isNotEmpty) 'certificationUrls': certificationUrls,
      if (certificationsStatus != null) 'certificationsStatus': certificationsStatus,
      'serviceCategory': serviceCategory,
      if (preferredLanguage != null) 'preferredLanguage': preferredLanguage,
      'isBanned': isBanned,
      'banned': isBanned,
      if (banReason != null) 'banReason': banReason,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, {String? documentId}) {
    AppRole? parsedRole;
    final rawRole = map['role']?.toString().toLowerCase();
    if (rawRole == 'provider' || rawRole == 'technician') {
      parsedRole = AppRole.provider;
    } else if (rawRole == 'admin' ||
        rawRole == 'super_admin' ||
        rawRole == 'superadmin') {
      parsedRole = AppRole.admin;
    } else if (rawRole == 'customer') {
      parsedRole = AppRole.customer;
    } else if (map['role'] != null) {
      parsedRole = AppRole.customer;
    }

    AdminRole? parsedAdminRole;
    final rawAdminRole = map['adminRole']?.toString();
    if (rawAdminRole != null && rawAdminRole.isNotEmpty) {
      parsedAdminRole = AdminRole.fromKey(rawAdminRole);
    } else if (rawRole == 'super_admin' ||
        rawRole == 'superadmin' ||
        map['isSuperAdmin'] == true) {
      parsedAdminRole = AdminRole.superAdmin;
    }

    final certsRaw = map['certificationUrls'];
    final certList = (certsRaw is List)
        ? certsRaw.map((e) => e.toString()).toList()
        : <String>[];

    final rawId = map['id']?.toString() ?? '';
    final effectiveId = rawId.isNotEmpty ? rawId : (documentId ?? '');

    return UserProfile(
      id: effectiveId,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
      photoStatus: map['photoStatus'],
      role: parsedRole,
      isProfileComplete: map['isProfileComplete'] ?? false,
      phone: map['phone'],
      district: map['district'],
      address: map['address'],
      latitude:
          map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null
          ? (map['longitude'] as num).toDouble()
          : null,
      nic: map['nic'],
      nicFrontUrl: map['nicFrontUrl'],
      nicBackUrl: map['nicBackUrl'],
      certificationUrls: certList,
      certificationsStatus: map['certificationsStatus'],
      serviceCategory: map['serviceCategory'],
      adminRole: parsedAdminRole,
      preferredLanguage: map['preferredLanguage']?.toString(),
      isBanned: map['isBanned'] == true ||
          map['banned'] == true ||
          map['status'] == 'suspended' ||
          map['status'] == 'banned',
      banReason: map['banReason']?.toString(),
    );
  }
}
