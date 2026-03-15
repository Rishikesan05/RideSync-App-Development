import 'package:flutter/material.dart';
import '../models/user_model.dart';

// Manages User Role and Session state
class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  UserModel? _user;
  String _currentRole = 'Commuter';

  bool get isAuthenticated => _isAuthenticated;
  UserModel? get user => _user;
  String get currentRole => _currentRole;

  void login(UserModel user) {
    _isAuthenticated = true;
    _user = user;
    notifyListeners();
  }

  void loginTest() {
    _isAuthenticated = true;
    _user = UserModel(
      id: '1',
      name: 'Marcus Thompson',
      email: 'marcus@example.com',
      role: 'Commuter',
      joinYear: 2023,
      totalRides: 45,
      rating: 4.8,
      loyaltyPoints: 1250,
    );
    notifyListeners();
  }

  void setRole(String role) {
    _currentRole = role;
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }
}
