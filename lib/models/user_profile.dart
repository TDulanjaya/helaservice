import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../state/role_provider.dart';
import 'admin_user.dart';

class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? photoStatus; // pending or approved or rejected
  final AppRole? role;
  final String? initialRole;
  final bool isProfileComplete;
  final String? phone;
  final String? district;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? nic;
  final String? nicFrontKey;
  final String? nicBackKey;
  final List<String> certificationUrls;
  final String? certificationsStatus; // pending or approved or rejected
  final String? serviceCategory;
  final AdminRole? adminRole;
  final List<AdminPermission>? permissions;
  final String? preferredLanguage;
  final bool isBanned;
  final String? banReason;
  final bool isVerified;
  final bool emailOtpVerified;
  final int? dailyRateLkr;
  final int? hourlyRateLkr;
  final int? perKmRateLkr;
  final int? visitFeeLkr;

  String? get nicFrontUrl => nicFrontKey;
  String? get nicBackUrl => nicBackKey;

  const UserProfile({
    required this.id,
    this.email = '',
    this.displayName = '',
    this.photoUrl,
    this.photoStatus,
    this.role,
    this.initialRole,
    this.isProfileComplete = false,
    this.phone,
    this.district,
    this.address,
    this.latitude,
    this.longitude,
    this.nic,
    String? nicFrontKey,
    String? nicBackKey,
    String? nicFrontUrl,
    String? nicBackUrl,
    this.certificationUrls = const [],
    this.certificationsStatus,
    this.serviceCategory,
    this.adminRole,
    this.permissions,
    this.preferredLanguage,
    this.isBanned = false,
    this.banReason,
    this.isVerified = false,
    this.emailOtpVerified = false,
    this.dailyRateLkr,
    this.hourlyRateLkr,
    this.perKmRateLkr,
    this.visitFeeLkr,
  }) : nicFrontKey = nicFrontKey ?? nicFrontUrl,
       nicBackKey = nicBackKey ?? nicBackUrl;

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
        ? phone
        : (user.email != null && user.email!.isNotEmpty
            ? user.email!.split('@').first
            : '');

    return UserProfile(
      id: user.uid,
      email: user.email ?? '',
      displayName: (user.displayName != null && user.displayName!.isNotEmpty)
          ? user.displayName!
          : fallbackName,
      photoUrl: null,
      phone: phone,
      role: role,
      initialRole: role != null
          ? (role == AppRole.provider ? 'provider' : 'customer')
          : null,
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
    String? initialRole,
    bool? isProfileComplete,
    String? phone,
    String? district,
    String? address,
    double? latitude,
    double? longitude,
    String? nic,
    String? nicFrontKey,
    String? nicBackKey,
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
    bool? isVerified,
    bool? emailOtpVerified,
    int? dailyRateLkr,
    int? hourlyRateLkr,
    int? perKmRateLkr,
    int? visitFeeLkr,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      photoStatus: photoStatus ?? this.photoStatus,
      role: role ?? this.role,
      initialRole: initialRole ?? this.initialRole,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      phone: phone ?? this.phone,
      district: district ?? this.district,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      nic: nic ?? this.nic,
      nicFrontKey: nicFrontKey ?? nicFrontUrl ?? this.nicFrontKey,
      nicBackKey: nicBackKey ?? nicBackUrl ?? this.nicBackKey,
      certificationUrls: certificationUrls ?? this.certificationUrls,
      certificationsStatus: certificationsStatus ?? this.certificationsStatus,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      adminRole: adminRole ?? this.adminRole,
      permissions: permissions ?? this.permissions,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      isBanned: isBanned ?? this.isBanned,
      banReason: banReason ?? this.banReason,
      isVerified: isVerified ?? this.isVerified,
      emailOtpVerified: emailOtpVerified ?? this.emailOtpVerified,
      dailyRateLkr: dailyRateLkr ?? this.dailyRateLkr,
      hourlyRateLkr: hourlyRateLkr ?? this.hourlyRateLkr,
      perKmRateLkr: perKmRateLkr ?? this.perKmRateLkr,
      visitFeeLkr: visitFeeLkr ?? this.visitFeeLkr,
    );
  }

  Map<String, dynamic> toMap() {
    // customer and provider only
    final safeRole = role == AppRole.admin ? null : role?.name;

    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (photoStatus != null) 'photoStatus': photoStatus,
      if (safeRole != null) 'role': safeRole,
      if (initialRole != null) 'initialRole': initialRole,
      'isProfileComplete': isProfileComplete,
      'phone': phone,
      'district': district,
      'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (certificationUrls.isNotEmpty) 'certificationUrls': certificationUrls,
      if (certificationsStatus != null) 'certificationsStatus': certificationsStatus,
      'serviceCategory': serviceCategory,
      if (preferredLanguage != null) 'preferredLanguage': preferredLanguage,
      'isBanned': isBanned,
      'banned': isBanned,
      if (banReason != null) 'banReason': banReason,
      'isVerified': isVerified,
      if (dailyRateLkr != null) 'dailyRateLkr': dailyRateLkr,
      if (hourlyRateLkr != null) 'hourlyRateLkr': hourlyRateLkr,
      if (perKmRateLkr != null) 'perKmRateLkr': perKmRateLkr,
      if (visitFeeLkr != null) 'visitFeeLkr': visitFeeLkr,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, {String? documentId}) {
    AppRole? parsedRole;
    final rawRole = map['role']?.toString().toLowerCase();
    if (rawRole == 'provider' || rawRole == 'technician') {
      parsedRole = AppRole.provider;
    } else if (rawRole == 'customer') {
      parsedRole = AppRole.customer;
    } else if (map['role'] != null) {
      parsedRole = AppRole.customer;
    }

    AdminRole? parsedAdminRole;

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
      initialRole: map['initialRole']?.toString(),
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
      nicFrontKey: map['nicFrontKey'] ?? map['nicFrontUrl'],
      nicBackKey: map['nicBackKey'] ?? map['nicBackUrl'],
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
      isVerified: (map['isVerified'] == true) || (map['nicVerified'] == true),
      emailOtpVerified: map['emailOtpVerified'] == true,
      dailyRateLkr: (map['dailyRateLkr'] as num?)?.toInt(),
      hourlyRateLkr: (map['hourlyRateLkr'] as num?)?.toInt(),
      perKmRateLkr: (map['perKmRateLkr'] as num?)?.toInt(),
      visitFeeLkr: (map['visitFeeLkr'] as num?)?.toInt(),
    );
  }
}
