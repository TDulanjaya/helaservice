import 'package:flutter/material.dart';

enum AppRole { customer, provider, admin }

class RoleProvider extends ChangeNotifier {
  AppRole _role = AppRole.customer;

  AppRole get role => _role;

  void setRole(AppRole role) {
    _role = role;
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
