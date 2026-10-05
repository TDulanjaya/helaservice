import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/admin_user.dart';
import '../services/auth_service.dart';

enum AppRole { customer, provider, admin }

class RoleProvider extends ChangeNotifier {
  AppRole _role = AppRole.customer;
  UserProfile? _currentUser;
  AdminUser? _currentAdminUser;
  bool _isSuperAdmin = false;
  bool _isLoading = false;

  AppRole get role => _role;
  UserProfile? get currentUser => _currentUser;
  AdminUser? get currentAdminUser => _currentAdminUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  bool get isProfileCompleted => _currentUser?.isProfileComplete ?? false;

  // check admin access
  bool get isAuthorizedAdmin =>
      _isSuperAdmin ||
      (_currentAdminUser != null &&
          _currentAdminUser!.isActive &&
          _currentAdminUser!.role != AdminRole.superAdmin);

  bool get isSuperAdmin => _isSuperAdmin;

  bool hasAdminPermission(AdminPermission permission) {
    if (_isSuperAdmin) return true;
    if (!isAuthorizedAdmin) return false;
    return _currentAdminUser?.hasPermission(permission) ?? false;
  }

  void setSuperAdmin(bool value, {AdminUser? adminUser}) {
    _isSuperAdmin = value;
    if (value) {
      _role = AppRole.admin;
      _currentAdminUser = adminUser ??
          AdminUser(
            id: _currentUser?.id ?? 'super_admin',
            email: _currentUser?.email ?? '',
            displayName: _currentUser?.displayName ?? 'Super Admin',
            role: AdminRole.superAdmin,
            status: AdminStatus.active,
            permissions: AdminPermission.values,
            lastActiveAt: DateTime.now(),
          );
    } else {
      _currentAdminUser = null;
    }
    notifyListeners();
  }

  bool get isRegisteredProvider {
    if (_currentUser?.role == AppRole.provider) return true;
    if (_currentUser?.serviceCategory != null &&
        _currentUser!.serviceCategory!.isNotEmpty) {
      return true;
    }
    if (_currentUser?.nic != null && _currentUser!.nic!.isNotEmpty) {
      return true;
    }
    return false;
  }

  Future<void> refreshAdminStatus() async {
    final fbUser = AuthService().currentFirebaseUser;
    if (fbUser != null) {
      await resolveAdminStatus(fbUser.uid);
      notifyListeners();
    }
  }

  Future<AdminUser?> resolveAdminStatus(String uid) async {
    try {
      // check super admin
      final superDoc = await FirebaseFirestore.instance
          .collection('superAdmins')
          .doc(uid)
          .get();
      if (superDoc.exists) {
        _isSuperAdmin = true;
        final fbUser = AuthService().currentFirebaseUser;
        final admin = AdminUser(
          id: uid,
          email: fbUser?.email ?? '',
          displayName: fbUser?.displayName ?? 'Super Admin',
          role: AdminRole.superAdmin,
          status: AdminStatus.active,
          permissions: AdminPermission.values,
          lastActiveAt: DateTime.now(),
        );
        _currentAdminUser = admin;
        _role = AppRole.admin;
        notifyListeners();
        return admin;
      }

      // check staff admin
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(uid)
          .get();
      if (adminDoc.exists && adminDoc.data() != null) {
        final admin = AdminUser.fromMap(adminDoc.data()!, id: uid);
        // block super admin in staff list
        if (admin.role == AdminRole.superAdmin) {
          _isSuperAdmin = false;
          _currentAdminUser = null;
          return null;
        }
        _isSuperAdmin = false;
        _currentAdminUser = admin;
        if (admin.isActive) {
          _role = AppRole.admin;
        }
        notifyListeners();
        return admin;
      }
    } catch (_) {}

    _isSuperAdmin = false;
    _currentAdminUser = null;
    return null;
  }

  void setRole(AppRole role) {
    _role = role;
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(role: role);
    }
    notifyListeners();
  }

  void setAdminUser(AdminUser? admin) {
    // block super admin in staff list
    if (admin != null && admin.role == AdminRole.superAdmin) {
      _currentAdminUser = null;
      _isSuperAdmin = false;
      notifyListeners();
      return;
    }
    _currentAdminUser = admin;
    _isSuperAdmin = false;
    if (admin != null && admin.isActive) {
      _role = AppRole.admin;
    }
    notifyListeners();
  }

  void setUser(UserProfile user) {
    _currentUser = user;
    if (user.role != null && user.role != AppRole.admin) {
      _role = user.role!;
    }
    notifyListeners();
  }

  Future<UserProfile> completeUserProfile(UserProfile updatedProfile) async {
    _isLoading = true;
    notifyListeners();
    try {
      final saved = await AuthService().saveUserProfile(updatedProfile);
      _currentUser = saved;
      if (saved.role != null && saved.role != AppRole.admin) {
        _role = saved.role!;
      }
      return saved;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await AuthService().signOut();
    _currentUser = null;
    _currentAdminUser = null;
    _isSuperAdmin = false;
    _role = AppRole.customer;
    notifyListeners();
  }

  String get roleLabel {
    switch (_role) {
      case AppRole.customer:
        return 'Customer';
      case AppRole.provider:
        return 'Service Provider';
      case AppRole.admin:
        if (isSuperAdmin) return 'Super Admin';
        if (_currentAdminUser?.role == AdminRole.supportAdmin) {
          return 'Support Admin';
        }
        return 'Operations Admin';
    }
  }
}

