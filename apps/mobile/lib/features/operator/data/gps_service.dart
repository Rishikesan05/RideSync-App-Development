import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Low-level service that reads the device GPS and writes the location to
/// Firebase Realtime Database under `busLocations/{busId}`.
///
/// This class is pure Dart — it has no widget or BuildContext dependencies,
/// making it easy to unit-test and safe to call from a background isolate.
class GpsService {
  GpsService._();
  static final GpsService instance = GpsService._();

  // ── Adaptive intervals ──────────────────────────────────────────────────────
  static const int _fastIntervalSec = 3;  // When bus is moving  (≥ 5 km/h)
  static const int _slowIntervalSec = 10; // When bus is idle     (< 5 km/h)
  static const double _movingThresholdMps = 1.39; // 5 km/h in m/s

  Timer? _locationTimer;
  int _currentInterval = _fastIntervalSec;
  String? _activeBusId;
  bool _isBroadcasting = false;
  void Function(double speedKmh)? _onSpeedUpdate;

  bool get isBroadcasting => _isBroadcasting;
  String? get activeBusId => _activeBusId;

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Requests location permissions (foreground + background) and returns true
  /// if permission was granted. Call this before [startBroadcasting].
  Future<bool> requestPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('[GpsService] Location permissions permanently denied.');
      return false;
    }

    // On Android 10+ we must separately ask for background location
    if (permission == LocationPermission.whileInUse) {
      // Prompt for "Allow all the time" so broadcasting works when screen is off
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Starts the adaptive GPS broadcasting loop. The [busId] is the Firestore
  /// document ID of the bus assigned to this operator.
  ///
  /// Calling this while already broadcasting stops the old loop first.
  void startBroadcasting(String busId, {void Function(double speedKmh)? onSpeedUpdate}) {
    stopBroadcasting();
    _activeBusId = busId;
    _isBroadcasting = true;
    _currentInterval = _fastIntervalSec;
    _onSpeedUpdate = onSpeedUpdate;
    debugPrint('[GpsService] Broadcasting started for bus: $busId');
    _scheduleNext();
  }

  /// Stops GPS broadcasting and removes the stale node from RTDB so passengers
  /// see a clean "signal lost" state rather than frozen coordinates.
  Future<void> stopBroadcasting() async {
    _locationTimer?.cancel();
    _locationTimer = null;
    _isBroadcasting = false;
    _onSpeedUpdate = null;

    if (_activeBusId != null) {
      try {
        await FirebaseDatabase.instance
            .ref('busLocations/$_activeBusId')
            .remove();
        debugPrint('[GpsService] RTDB node removed for bus: $_activeBusId');
      } catch (e) {
        debugPrint('[GpsService] Failed to remove RTDB node: $e');
      }
      _activeBusId = null;
    }
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  void _scheduleNext() {
    if (!_isBroadcasting) return;

    _locationTimer = Timer(Duration(seconds: _currentInterval), () async {
      if (!_isBroadcasting) return;
      await _writeLocation();
      _scheduleNext();
    });
  }

  Future<void> _writeLocation() async {
    try {
      final Position pos = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          // Android-specific: keep the GPS hardware awake even when idle
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationText: 'RideSync is broadcasting your bus location.',
            notificationTitle: 'Bus GPS Active',
            enableWakeLock: true,
          ),
        ),
      );

      final double speedKmh = pos.speed * 3.6; // m/s → km/h
      final bool isMoving = pos.speed >= _movingThresholdMps;

      // Adapt interval on the fly
      final int nextInterval = isMoving ? _fastIntervalSec : _slowIntervalSec;
      if (nextInterval != _currentInterval) {
        _currentInterval = nextInterval;
        debugPrint('[GpsService] Adaptive interval: ${_currentInterval}s (speed: ${speedKmh.toStringAsFixed(1)} km/h)');
      }

      // Notify speed to provider callback
      _onSpeedUpdate?.call(speedKmh);

      // Write to RTDB
      await FirebaseDatabase.instance
          .ref('busLocations/$_activeBusId')
          .set({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'speed': double.parse(speedKmh.toStringAsFixed(1)),
        'heading': pos.heading,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('[GpsService] GPS write error: $e');
      // Non-fatal — keep the loop alive; next tick may recover
    }
  }
}
