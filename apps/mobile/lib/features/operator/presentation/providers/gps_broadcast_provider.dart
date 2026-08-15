import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ridesync/features/operator/data/gps_service.dart';

/// Provider that exposes GPS broadcast state to the Operator UI.
///
/// Widgets watch this provider to:
///   • Show/hide the "BROADCASTING GPS" badge on the active trip card.
///   • Display the live speed value.
///   • Enable/disable the Start / End Journey buttons.
class GpsBroadcastProvider extends ChangeNotifier {
  final GpsService _service = GpsService.instance;

  bool _hasPermission = false;
  String? _errorMessage;
  double _currentSpeed = 0.0; // km/h — updated by GpsService

  bool get isBroadcasting => _service.isBroadcasting;
  String? get activeBusId => _service.activeBusId;
  bool get hasPermission => _hasPermission;
  String? get errorMessage => _errorMessage;
  double get currentSpeed => _currentSpeed;

  GpsBroadcastProvider() {
    _checkPermissions();
  }

  // ── Permissions ─────────────────────────────────────────────────────────────

  Future<void> _checkPermissions() async {
    _hasPermission = await _service.requestPermissions();
    notifyListeners();
  }

  /// Call this when the user taps "Start Journey" after the co-operator check.
  /// Returns true if broadcasting was started successfully.
  Future<bool> startBroadcasting(String busId) async {
    _errorMessage = null;

    // Force-refresh the Firebase Auth ID token so that the latest custom claims
    // (set by admin approval) are included in the JWT. Without this, RTDB
    // security rules that check auth.token.role may reject writes.
    try {
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
      debugPrint('[GpsBroadcastProvider] Firebase token refreshed.');
    } catch (e) {
      debugPrint('[GpsBroadcastProvider] Token refresh failed (non-fatal): $e');
    }

    // Request permissions if not yet granted
    if (!_hasPermission) {
      _hasPermission = await _service.requestPermissions();
    }

    if (!_hasPermission) {
      // Check if it's a location service issue vs permission issue
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        _errorMessage =
            'GPS is turned off on your device. Please enable Location Services in Settings to broadcast.';
      } else {
        _errorMessage =
            'Location permission is required to broadcast GPS. Please enable it in Settings.';
      }
      notifyListeners();
      return false;
    }

    try {
      _service.startBroadcasting(busId, onSpeedUpdate: (double speedKmh) {
        _currentSpeed = speedKmh;
        notifyListeners();
      });
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to start GPS: $e';
      debugPrint('[GpsBroadcastProvider] Error: $e');
      notifyListeners();
      return false;
    }
  }

  /// Call this when the operator taps "End Trip".
  Future<void> stopBroadcasting() async {
    await _service.stopBroadcasting();
    _currentSpeed = 0.0;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Gracefully stop if widget tree is destroyed mid-trip
    _service.stopBroadcasting();
    super.dispose();
  }
}
