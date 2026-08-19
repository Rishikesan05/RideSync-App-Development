import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ridesync/features/auth/presentation/screens/user_model.dart';
import 'package:ridesync/core/services/fcm_service.dart';


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
  // Guard against Firebase firing authStateChanges multiple times for the same UID
  String? _lastProcessedUid;

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
    final incomingUid = firebaseUser?.uid;

    // Skip duplicate events for the same UID to prevent multiple Firestore reads
    // and repeated notifyListeners() calls that cause flickering UI rebuilds.
    if (incomingUid == _lastProcessedUid && _isInitialized) return;
    _lastProcessedUid = incomingUid;

    debugPrint('Auth State Changed: $incomingUid');
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

          String profileCollection = roleStr == 'operator' ? 'operators' : 'passengers';
          DocumentSnapshot profileDoc = await _firestore.collection(profileCollection).doc(firebaseUser.uid).get();
          Map<String, dynamic> profileData = {};
          if (profileDoc.exists && profileDoc.data() != null) {
            profileData = profileDoc.data() as Map<String, dynamic>;
          }

          _status = data['status'] ?? 'pending_review';
          if (roleStr == 'operator' && profileData['status'] != null) {
            _status = profileData['status'];
          }

          // Fetch real total rides/trips count from the appropriate collection.
          // – Passengers: count their bookings in 'bookings'
          // – Operators:  count completed schedules in 'schedules'
          int userRides = data['totalRides'] ?? 0;
          if (userRides == 0) {
            try {
              if (roleStr == 'operator') {
                final operatorIdStr = profileData['operatorId'] ?? data['operatorId'] ?? '';
                if (operatorIdStr.isNotEmpty) {
                  // Use operatorId string (e.g. RSOP26-007) to match schedules
                  final countSnap = await _firestore
                      .collection('schedules')
                      .where('operatorId', isEqualTo: operatorIdStr)
                      .where('status', isEqualTo: 'completed')
                      .get();
                  userRides = countSnap.docs.length;
                } else {
                  // Fallback: try matching by uid directly
                  final countSnap = await _firestore
                      .collection('schedules')
                      .where('operatorUid', isEqualTo: firebaseUser.uid)
                      .where('status', isEqualTo: 'completed')
                      .get();
                  userRides = countSnap.docs.length;
                }
              } else {
                final countSnap = await _firestore
                    .collection('bookings')
                    .where('passengerId', isEqualTo: firebaseUser.uid)
                    .get();
                userRides = countSnap.docs.length;
              }
            } catch (_) {}
          }

          _user = UserModel(
            id: firebaseUser.uid,
            name: profileData['displayName'] ?? data['displayName'] ?? data['name'] ?? firebaseUser.displayName ?? 'Passenger User',
            email: firebaseUser.email ?? profileData['email'] ?? data['email'] ?? '',
            phone: profileData['phone'] ?? data['phone'] ?? firebaseUser.phoneNumber ?? '',
            role: roleStr == 'operator' ? 'Operator' : 'Passenger',
            operatorType: profileData['operatorType'] ?? data['operatorType'],
            operatorId: profileData['operatorId'] ?? data['operatorId'],
            joinYear: 2024,
            totalRides: userRides,
            rating: (data['rating'] ?? 5.0).toDouble(),
            loyaltyPoints: data['loyaltyPoints'] ?? (userRides * 10),
          );
          _isAuthenticated = true;
          _isGuest = false;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_guest', false);
        } else {
          debugPrint('User doc does not exist yet for ${firebaseUser.uid}');
          // If auth exists but doc doesn't, we still set a fallback user
          _user = UserModel(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? 'Passenger User',
            email: firebaseUser.email ?? '',
            phone: firebaseUser.phoneNumber ?? '',
            role: 'Passenger',
            joinYear: 2024,
            totalRides: 0,
            rating: 5.0,
            loyaltyPoints: 0,
          );
          _isAuthenticated = true; 
          _isGuest = false;
        }
      } catch (e) {
        debugPrint('Error fetching user data: $e');
        _isAuthenticated = true; // Fallback: allow entry even if Firestore fetch fails temporarily
      }
    }
    _isInitialized = true;

    // Save FCM token so this device can receive push notifications.
    if (_user != null && _user!.id.isNotEmpty) {
      final role = _currentRole == UserRole.operator ? 'operator' : 'passenger';
      FcmService.instance.saveTokenForUser(_user!.id, role: role);
    }

    notifyListeners();
  }

  /// Updates passenger personal details in both /users/{uid} and /passengers/{uid} in Firestore
  Future<void> updatePassengerProfile({
    required String name,
    required String phone,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('No user is currently logged in.');

    await _firestore.collection('users').doc(currentUser.uid).set({
      'displayName': name,
      'name': name,
      'phone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _firestore.collection('passengers').doc(currentUser.uid).set({
      'displayName': name,
      'phone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    try {
      await currentUser.updateDisplayName(name);
    } catch (_) {}

    if (_user != null) {
      _user = _user!.copyWith(name: name, phone: phone);
      notifyListeners();
    }
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

  /// Returns the current user's Firebase ID token for backend API calls.
  /// Returns null if no user is signed in.
  Future<String?> getIdToken() async {
    try {
      return await _auth.currentUser?.getIdToken();
    } catch (e) {
      debugPrint('Error getting ID token: $e');
      return null;
    }
  }

  // Used to manually refresh user document and listeners
  Future<void> refreshUser() async {
    if (_auth.currentUser != null) {
      _lastProcessedUid = null; // Clear guard to force a fresh Firestore read
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
    _lastProcessedUid = null; // Reset so the next sign-in event is always processed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest', false);
    notifyListeners();
  }
}

