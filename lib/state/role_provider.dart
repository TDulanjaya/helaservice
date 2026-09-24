import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

enum AppRole { customer, provider, admin }

class RoleProvider extends ChangeNotifier {
  AppRole _role = AppRole.customer;
  UserProfile? _currentUser;
  bool _isLoading = false;

  AppRole get role => _role;
  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  bool get isProfileCompleted => _currentUser?.isProfileComplete ?? false;

  void setRole(AppRole role) {
    _role = role;
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(role: role);
    }
    notifyListeners();
  }

  void setUser(UserProfile user) {
    _currentUser = user;
    if (user.role != null) {
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
      if (saved.role != null) {
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
        return 'Admin';
    }
  }
}
