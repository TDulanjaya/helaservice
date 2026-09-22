import '../../state/role_provider.dart';

class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final AppRole? role;
  final bool isProfileComplete;
  final String? phone;
  final String? district;
  final String? address; // For customers
  final String? nic; // For providers
  final String? serviceCategory; // For providers

  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.role,
    this.isProfileComplete = false,
    this.phone,
    this.district,
    this.address,
    this.nic,
    this.serviceCategory,
  });

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
    String? nic,
    String? serviceCategory,
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
      nic: nic ?? this.nic,
      serviceCategory: serviceCategory ?? this.serviceCategory,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': role?.name,
      'isProfileComplete': isProfileComplete,
      'phone': phone,
      'district': district,
      'address': address,
      'nic': nic,
      'serviceCategory': serviceCategory,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    AppRole? parsedRole;
    if (map['role'] != null) {
      for (final r in AppRole.values) {
        if (r.name == map['role']) {
          parsedRole = r;
          break;
        }
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
      nic: map['nic'],
      serviceCategory: map['serviceCategory'],
    );
  }
}
