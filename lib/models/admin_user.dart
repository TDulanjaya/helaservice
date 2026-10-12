import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum AdminRole {
  superAdmin,
  opsAdmin,
  supportAdmin;

  String get key {
    switch (this) {
      case AdminRole.superAdmin:
        return 'super_admin';
      case AdminRole.opsAdmin:
        return 'ops_admin';
      case AdminRole.supportAdmin:
        return 'support_admin';
    }
  }

  String get label => key;
  String get description => key;

  static AdminRole? fromKey(String? key) {
    switch (key) {
      case 'super_admin':
      case 'superAdmin':
        return AdminRole.superAdmin;
      case 'support_admin':
      case 'supportAdmin':
        return AdminRole.supportAdmin;
      case 'ops_admin':
      case 'opsAdmin':
        return AdminRole.opsAdmin;
      default:
        return null;
    }
  }
}

enum AdminPermission {
  manageAdmins,
  verifyNic,
  manageCategories,
  broadcastAlerts,
  viewFinances,
  manageUsers,
  handleSupport;

  String get key {
    switch (this) {
      case AdminPermission.manageAdmins:
        return 'manage_admins';
      case AdminPermission.verifyNic:
        return 'verify_nic';
      case AdminPermission.manageCategories:
        return 'manage_categories';
      case AdminPermission.broadcastAlerts:
        return 'broadcast_alerts';
      case AdminPermission.viewFinances:
        return 'view_finances';
      case AdminPermission.manageUsers:
        return 'manage_users';
      case AdminPermission.handleSupport:
        return 'handle_support';
    }
  }

  String get label => key;
  String get description => key;

  static AdminPermission? fromKey(String? key) {
    switch (key) {
      case 'manage_admins':
      case 'manageAdmins':
        return AdminPermission.manageAdmins;
      case 'verify_nic':
      case 'verifyNic':
        return AdminPermission.verifyNic;
      case 'manage_categories':
      case 'manageCategories':
        return AdminPermission.manageCategories;
      case 'broadcast_alerts':
      case 'broadcastAlerts':
        return AdminPermission.broadcastAlerts;
      case 'view_finances':
      case 'viewFinances':
        return AdminPermission.viewFinances;
      case 'manage_users':
      case 'manageUsers':
        return AdminPermission.manageUsers;
      case 'handle_support':
      case 'handleSupport':
        return AdminPermission.handleSupport;
      default:
        return null;
    }
  }
}

enum AdminStatus {
  active,
  invited,
  suspended;

  String get key {
    switch (this) {
      case AdminStatus.active:
        return 'active';
      case AdminStatus.invited:
        return 'invited';
      case AdminStatus.suspended:
        return 'suspended';
    }
  }

  String get label => key;

  static AdminStatus fromKey(String? key) {
    switch (key) {
      case 'active':
        return AdminStatus.active;
      case 'invited':
        return AdminStatus.invited;
      case 'suspended':
        return AdminStatus.suspended;
      default:
        return AdminStatus.active;
    }
  }
}

class AdminUser {
  final String id;
  final String email;
  final String displayName;
  final String? phone;
  final AdminRole? role;
  final AdminStatus status;
  final List<AdminPermission> permissions;
  final String? invitedBy;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;

  const AdminUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.phone,
    this.role,
    this.status = AdminStatus.active,
    this.permissions = const [],
    this.invitedBy,
    this.createdAt,
    this.lastActiveAt,
  });

  bool get isSuperAdmin => role == AdminRole.superAdmin;
  bool get isActive => status == AdminStatus.active;
  bool get isInvited => status == AdminStatus.invited;
  bool get isSuspended => status == AdminStatus.suspended;

  bool hasPermission(AdminPermission permission) {
    if (isSuperAdmin) return true;
    return permissions.contains(permission);
  }

  bool get canManageAdmins => hasPermission(AdminPermission.manageAdmins);
  bool get canVerifyNic => hasPermission(AdminPermission.verifyNic);
  bool get canManageCategories => hasPermission(AdminPermission.manageCategories);
  bool get canBroadcastAlerts => hasPermission(AdminPermission.broadcastAlerts);
  bool get canViewFinances => hasPermission(AdminPermission.viewFinances);
  bool get canManageUsers => hasPermission(AdminPermission.manageUsers);
  bool get canHandleSupport => hasPermission(AdminPermission.handleSupport);

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'AD';
    if (parts.length == 1) return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Color get roleColor {
    switch (role) {
      case AdminRole.superAdmin:
        return const Color(0xFFD6900F);
      case AdminRole.opsAdmin:
        return const Color(0xFFD6900F);
      case AdminRole.supportAdmin:
        return const Color(0xFF4A6572);
      case null:
        return const Color(0xFF888888);
    }
  }

  Color get roleBgColor => roleColor.withValues(alpha: 0.12);

  Color get statusColor {
    switch (status) {
      case AdminStatus.active:
        return const Color(0xFF2E7D32);
      case AdminStatus.invited:
        return const Color(0xFFD6900F);
      case AdminStatus.suspended:
        return const Color(0xFFBA1A1A);
    }
  }

  Color get statusBgColor => statusColor.withValues(alpha: 0.12);

  AdminUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? phone,
    AdminRole? role,
    AdminStatus? status,
    List<AdminPermission>? permissions,
    String? invitedBy,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return AdminUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      permissions: permissions ?? this.permissions,
      invitedBy: invitedBy ?? this.invitedBy,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email.trim().toLowerCase(),
      'displayName': displayName.trim(),
      'phone': phone,
      if (role != null) 'role': role!.key,
      'status': status.key,
      'permissions': permissions.map((p) => p.key).toList(),
      if (invitedBy != null) 'invitedBy': invitedBy,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      if (lastActiveAt != null) 'lastActiveAt': Timestamp.fromDate(lastActiveAt!),
    };
  }

  factory AdminUser.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    final rawPermissions = map['permissions'] as List<dynamic>? ?? [];
    final permissions = rawPermissions
        .map((e) => AdminPermission.fromKey(e?.toString()))
        .whereType<AdminPermission>()
        .toList();

    return AdminUser(
      id: id ?? (map['id']?.toString() ?? ''),
      email: map['email']?.toString() ?? '',
      displayName: map['displayName']?.toString() ?? '',
      phone: map['phone']?.toString(),
      role: AdminRole.fromKey(map['role']?.toString()),
      status: AdminStatus.fromKey(map['status']?.toString()),
      permissions: permissions,
      invitedBy: map['invitedBy']?.toString(),
      createdAt: parseDate(map['createdAt']),
      lastActiveAt: parseDate(map['lastActiveAt']),
    );
  }
}
