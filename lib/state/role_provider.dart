import 'package:flutter/foundation.dart';

enum AppRole { customer, provider }

class RoleProvider extends ChangeNotifier {
  AppRole _role = AppRole.customer;

  AppRole get role => _role;

  void setRole(AppRole role) {
    if (_role == role) return;
    _role = role;
    notifyListeners();
  }
}
