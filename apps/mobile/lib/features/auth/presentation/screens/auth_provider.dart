import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ridesync/features/auth/presentation/screens/user_model.dart';

// Manages User Role and Session state
class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isAuthenticated = false;
  bool _isGuest = false;
  UserModel? _user;
  UserRole _currentRole = UserRole.passenger;
  String _status = 'pending_review'; 
  bool _isInitialized = false;

  bool get isAuthenticated => _isAuthenticated;
  bool get isGuest => _isGuest;
  UserModel? get user => _user;
  UserRole get currentRole => _currentRole;
  String get status => _status;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // Check if was previously a guest
    final prefs = await SharedPreferences.getInstance();
    _isGuest = prefs.getBool('is_guest') ?? false;
    if (_isGuest) {
      _currentRole = UserRole.guest;
    }
    
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    debugPrint('Auth State Changed: ${firebaseUser?.uid}');
    if (firebaseUser == null) {
      _isAuthenticated = false;
      _user = null;
      _status = 'pending_review';
    } else {
      try {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (userDoc.exists) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          String roleStr = data['role'] ?? 'passenger';
          _currentRole = roleStr == 'operator' ? UserRole.operator : UserRole.passenger;
          _status = data['status'] ?? 'pending_review';

          String profileCollection = roleStr == 'operator' ? 'operators' : 'passengers';
          DocumentSnapshot profileDoc = await _firestore.collection(profileCollection).doc(firebaseUser.uid).get();
          Map<String, dynamic> profileData = {};
          if (profileDoc.exists && profileDoc.data() != null) {
            profileData = profileDoc.data() as Map<String, dynamic>;
          }

          _user = UserModel(
            id: firebaseUser.uid,
            name: profileData['displayName'] ?? data['displayName'] ?? data['name'] ?? firebaseUser.displayName ?? 'New User',
            email: firebaseUser.email ?? profileData['email'] ?? data['email'] ?? '',
            role: roleStr == 'operator' ? 'Operator' : 'Passenger',
            joinYear: 2024,
            totalRides: data['totalRides'] ?? 0,
            rating: (data['rating'] ?? 5.0).toDouble(),
            loyaltyPoints: data['loyaltyPoints'] ?? 0,
          );
          _isAuthenticated = true;
          _isGuest = false;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_guest', false);
        } else {
          debugPrint('User doc does not exist yet for ${firebaseUser.uid}');
          // If auth exists but doc doesn't, we might still be syncing
          _isAuthenticated = true; 
          _isGuest = false;
        }
      } catch (e) {
        debugPrint('Error fetching user data: $e');
        _isAuthenticated = true; // Fallback: allow entry even if Firestore fetch fails temporarily
      }
    }
    _isInitialized = true;
    notifyListeners();
  }

  // Set the role during onboarding (before auth)
  void selectRole(UserRole role) {
    _currentRole = role;
    _isGuest = false;
    notifyListeners();
  }

  // Guest Flow
  Future<void> continueAsGuest() async {
    _isAuthenticated = false;
    _isGuest = true;
    _user = null;
    _currentRole = UserRole.guest;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest', true);
    notifyListeners();
  }

  // Passenger Email Login
  Future<void> loginAsPassenger(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Passenger Email Signup
  Future<void> signupAsPassengerWithEmail(String name, String email, String password, String phone) async {
    UserCredential cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await _firestore.collection('users').doc(cred.user!.uid).set({
      'role': 'passenger',
      'status': 'approved',
      'displayName': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _firestore.collection('passengers').doc(cred.user!.uid).set({
      'displayName': name,
      'email': email,
      'phone': phone,
    });
    await cred.user!.updateDisplayName(name);
    await refreshUser();
  }

  // Passenger Sync for Phone Auth
  Future<void> syncPhonePassenger(User firebaseUser) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
    if (!doc.exists) {
      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'role': 'passenger',
        'status': 'approved',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('passengers').doc(firebaseUser.uid).set({
        'phone': firebaseUser.phoneNumber ?? '',
        'displayName': 'Passenger ${firebaseUser.phoneNumber?.substring(firebaseUser.phoneNumber!.length - 4) ?? 'User'}',
      });
    }
    // Always refresh state to ensure we move out of "guest" mode
    await _onAuthStateChanged(firebaseUser);
  }

  // Operator Email Login
  Future<void> loginAsOperator(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Change Password (requires recent login)
  Future<void> changePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No user logged in');
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  // Used to manually refresh user document and listeners
  Future<void> refreshUser() async {
    if (_auth.currentUser != null) {
      await _onAuthStateChanged(_auth.currentUser);
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _isAuthenticated = false;
    _isGuest = false;
    _user = null;
    _currentRole = UserRole.passenger;
    _status = 'pending_review';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest', false);
    notifyListeners();
  }
}

