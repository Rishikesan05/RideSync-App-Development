import 'package:flutter/material.dart';
import 'package:ridesync/modules/auth/user_model.dart';

// Manages User Role and Session state
class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isGuest = false;
  UserModel? _user;
  UserRole _currentRole = UserRole.passenger;

  bool get isAuthenticated => _isAuthenticated;
  bool get isGuest => _isGuest;
  UserModel? get user => _user;
  UserRole get currentRole => _currentRole;

  // Set the role during onboarding (before auth)
  void selectRole(UserRole role) {
    _currentRole = role;
    _isGuest = false;
    notifyListeners();
  }

  // Guest Flow
  void continueAsGuest() {
    _isAuthenticated = false;
    _isGuest = true;
    _user = null;
    _currentRole = UserRole.guest;
    notifyListeners();
  }

  // Passenger Login
  void loginAsPassenger(String email, String password) {
    // Mock authentication
    _isAuthenticated = true;
    _isGuest = false;
    _currentRole = UserRole.passenger;
    _user = UserModel(
      id: 'p1',
      name: 'Sarah Passenger',
      email: email,
      role: 'Passenger',
      joinYear: 2024,
      totalRides: 12,
      rating: 4.9,
      loyaltyPoints: 350,
    );
    notifyListeners();
  }

  // Operator Login
  void loginAsOperator(String email, String password) {
    // Mock authentication
    _isAuthenticated = true;
    _isGuest = false;
    _currentRole = UserRole.operator;
    _user = UserModel(
      id: 'o1',
      name: 'Marcus Thompson',
      email: email,
      role: 'Operator',
      joinYear: 2023,
      totalRides: 450,
      rating: 4.8,
      loyaltyPoints: 1250,
    );
    notifyListeners();
  }

  // Complete Operator Registration
  void completeOperatorRegistration() {
    _isAuthenticated = true;
    _isGuest = false;
    _currentRole = UserRole.operator;
    _user = UserModel(
      id: 'o_new',
      name: 'New Operator',
      email: 'operator@ridesync.com',
      role: 'Operator',
      joinYear: 2024,
      totalRides: 0,
      rating: 5.0,
      loyaltyPoints: 0,
    );
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    _isGuest = false;
    _user = null;
    _currentRole = UserRole.passenger; // Reset to default role for next session
    notifyListeners();
  }
}




