import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/admin_user.dart';
import '../repositories/user_repository.dart';
import '../services/auth_service.dart';
import '../utils/l10n_extension.dart';

enum AppRole { customer, provider, admin }

class RoleProvider extends ChangeNotifier {
  AppRole _role = AppRole.customer;
  UserProfile? _currentUser;
  AdminUser? _currentAdminUser;
  AppRole? _primaryRole;
  bool _isSuperAdmin = false;
  bool _isLoading = false;
  StreamSubscription<UserProfile?>? _userProfileSub;

  AppRole get role => _role;
  AppRole? get primaryRole => _primaryRole;
  UserProfile? get currentUser => _currentUser;
  AdminUser? get currentAdminUser => _currentAdminUser;
  AdminUser? get currentAdmin => _currentAdminUser;
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
            displayName: _currentUser?.displayName ?? 'SUPER_ADMIN',
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
    if (_primaryRole == AppRole.provider) return true;
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

  bool get isApprovedProvider {
    if (isAuthorizedAdmin) return true;
    if (_currentUser == null) return false;
    final isProviderAccount = _primaryRole == AppRole.provider ||
        _currentUser!.role == AppRole.provider ||
        _currentUser!.isVerified;
    return isProviderAccount && _currentUser!.isVerified;
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
          displayName: fbUser?.displayName ?? 'SUPER_ADMIN',
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
      final adminDoc =
          await FirebaseFirestore.instance.collection('admins').doc(uid).get();
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
    // block unpermitted role switch
    if (role == AppRole.provider && !isAuthorizedAdmin && !isApprovedProvider) {
      return;
    }
    if (role == AppRole.admin && !isAuthorizedAdmin) {
      return;
    }
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
      _primaryRole ??= user.role;
    }
    _listenToUser(user.id);
    notifyListeners();
  }

  void _listenToUser(String uid) {
    if (uid.isEmpty) return;
    _userProfileSub?.cancel();
    _userProfileSub =
        UserRepository().streamUserById(uid).listen((updatedUser) {
      if (updatedUser != null) {
        _currentUser = updatedUser;
        if (updatedUser.role != null && updatedUser.role != AppRole.admin) {
          if (updatedUser.role == AppRole.provider && updatedUser.isVerified) {
            _primaryRole = AppRole.provider;
          }
        }
        notifyListeners();
      }
    });
  }

  Future<UserProfile> completeUserProfile(UserProfile updatedProfile) async {
    _isLoading = true;
    notifyListeners();
    try {
      final saved = await AuthService().saveUserProfile(updatedProfile);
      _currentUser = saved;
      if (saved.role != null && saved.role != AppRole.admin) {
        _role = saved.role!;
        _primaryRole = saved.role;
      }
      return saved;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _userProfileSub?.cancel();
    _userProfileSub = null;
    await AuthService().signOut();
    _currentUser = null;
    _currentAdminUser = null;
    _primaryRole = null;
    _isSuperAdmin = false;
    _role = AppRole.customer;
    notifyListeners();
  }

  // delete current user account
  Future<void> deleteAccount() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _userProfileSub?.cancel();
      _userProfileSub = null;
      await AuthService().deleteAccount();
      _currentUser = null;
      _currentAdminUser = null;
      _primaryRole = null;
      _isSuperAdmin = false;
      _role = AppRole.customer;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _userProfileSub?.cancel();
    super.dispose();
  }

  String roleLabelOf(BuildContext context) {
    switch (_role) {
      case AppRole.customer:
        return context.l10n.roleCustomer;
      case AppRole.provider:
        return context.l10n.roleServiceProvider;
      case AppRole.admin:
        if (isSuperAdmin) return context.l10n.roleSuperAdmin;
        if (_currentAdminUser?.role == AdminRole.supportAdmin) {
          return context.l10n.roleSupportAdmin;
        }
        return context.l10n.roleOperationsAdmin;
    }
  }
}
