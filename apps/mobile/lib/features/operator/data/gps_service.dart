import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ridesync/core/constants.dart';

/// Low-level service that reads the device GPS and writes the location to
/// Firebase Realtime Database under `busLocations/{busId}`.
///
/// This class is pure Dart — it has no widget or BuildContext dependencies,
/// making it easy to unit-test and safe to call from a background isolate.
///
/// ## Fix (2026-07-12) — live-gps-error-fix branch
/// The previous implementation used a manual one-shot [Timer] chain:
///   `Timer → _writeLocation() → _scheduleNext() → Timer → …`
/// This meant that if [_writeLocation] threw (even though caught), the chain
/// continued, but any blocking await inside [_writeLocation] could delay the
/// next tick unpredictably. More critically, the timer was never restarted if
/// [startBroadcasting] was called while the RTDB write was still in flight.
///
/// The fix replaces the timer chain with [Geolocator.getPositionStream], which
/// delivers position events at the OS level. Application-level RTDB write
/// errors are now handled inside [_onPosition] and **never** interrupt the
/// stream, guaranteeing continuous location sharing for the full journey.
///
/// ## Fix (2026-08-17) — gps-fixing-2.0 branch
/// Added `scheduleId`, `routeId`, and `isBroadcasting` to the RTDB payload so
/// that the admin portal and Cloud Function can read these without an extra
/// Firestore round-trip. Also sets `isBroadcasting: false` before removing
/// the node, so the admin portal can cleanly distinguish "stopped" from
/// "no signal".
class GpsService {
  GpsService._();
  static final GpsService instance = GpsService._();

  // ── Adaptive thresholds ──────────────────────────────────────────────────────
  static const int _fastIntervalMs = 2000;  // When bus is moving (≥ 5 km/h)
  static const double _movingThresholdMps = 1.39; // 5 km/h in m/s

  StreamSubscription<Position>? _positionSub;
  String? _activeBusId;
  String? _activeScheduleId;
  String? _activeRouteId;
  bool _isBroadcasting = false;
  void Function(double speedKmh)? _onSpeedUpdate;

  bool get isBroadcasting => _isBroadcasting;
  String? get activeBusId => _activeBusId;

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Requests location permissions (foreground + background) and returns true
  /// if permission was granted. Call this before [startBroadcasting].
  Future<bool> requestPermissions() async {
    // Check if location services (GPS) are enabled on the device
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[GpsService] Location services are disabled.');
      // Try to open device location settings for the user
      await Geolocator.openLocationSettings();
      // Re-check after returning from settings
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[GpsService] Location services still disabled after settings prompt.');
        return false;
      }
    }

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

  /// Starts continuous GPS broadcasting via [Geolocator.getPositionStream].
  ///
  /// [busId]      — Firestore document ID of the assigned bus.
  /// [scheduleId] — Active schedule ID; written to RTDB for Cloud Functions.
  /// [routeId]    — Route ID; written to RTDB for Cloud Functions.
  ///
  /// Calling this while already broadcasting stops the old stream first.
  /// Starts continuous GPS broadcasting via [Geolocator.getPositionStream].
  ///
  /// [busId]      — Firestore document ID or plate number of the assigned bus.
  /// [scheduleId] — Active schedule ID; written to RTDB for Cloud Functions.
  /// [routeId]    — Route ID; written to RTDB for Cloud Functions.
  ///
  /// Calling this while already broadcasting stops the old stream first.
  void startBroadcasting(
    String busId, {
    String? scheduleId,
    String? routeId,
    void Function(double speedKmh)? onSpeedUpdate,
  }) {
    // Cancel any existing stream before opening a new one
    stopBroadcasting();

    _activeBusId = busId;
    _activeScheduleId = scheduleId;
    _activeRouteId = routeId;
    _isBroadcasting = true;
    _onSpeedUpdate = onSpeedUpdate;
    debugPrint('[GpsService] Broadcasting started for bus: $busId | schedule: $scheduleId');

    final db = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: AppConstants.rtdbUrl,
    );

    // Setup onDisconnect presence hook so that if network drops or app is terminated,
    // the bus location node is automatically marked offline on the RTDB server side.
    try {
      final busRef = db.ref('busLocations/$_activeBusId');
      busRef.onDisconnect().update({
        'isBroadcasting': false,
        'status': 'OFFLINE',
        'disconnectedAt': ServerValue.timestamp,
      }).catchError((e) {
        debugPrint('[GpsService] RTDB onDisconnect registration warning: $e');
      });
    } catch (e) {
      debugPrint('[GpsService] Failed to register onDisconnect hook: $e');
    }

    // Configure throttled location settings:
    // - distanceFilter: 5 meters (reduces battery drain and stops redundant stationary writes)
    // - ForegroundNotificationConfig for Android background isolate survival
    LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        intervalDuration: const Duration(milliseconds: _fastIntervalMs),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: 'RideSync is broadcasting your bus location.',
          notificationTitle: 'Bus GPS Active',
          enableWakeLock: true,
        ),
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );
    }

    _positionSub = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen(
          _onPosition,
          onError: (Object e) {
            debugPrint('[GpsService] Position stream error: $e');
            // Stream errors are non-fatal — the subscription stays alive and
            // will recover on the next OS-level position update.
          },
          cancelOnError: false, // ← CRITICAL: keep stream alive despite errors
        );
  }

  /// Stops GPS broadcasting, cleans up onDisconnect hooks, and marks `isBroadcasting: false`
  /// on RTDB so passengers see a clean "signal lost" state rather than frozen coordinates,
  /// then removes the node cleanly.
  Future<void> stopBroadcasting() async {
    await _positionSub?.cancel();
    _positionSub = null;
    _isBroadcasting = false;
    _onSpeedUpdate = null;

    if (_activeBusId != null) {
      final busIdToRemove = _activeBusId!;
      _activeBusId = null;
      _activeScheduleId = null;
      _activeRouteId = null;

      try {
        final db = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: AppConstants.rtdbUrl,
        );
        final busRef = db.ref('busLocations/$busIdToRemove');
        // Cancel the onDisconnect hook since this is a clean shutdown
        await busRef.onDisconnect().cancel().catchError((_) {});
        // Mark as not broadcasting BEFORE removing
        await busRef.update({'isBroadcasting': false, 'status': 'STOPPED'});
        await busRef.remove();
        debugPrint('[GpsService] RTDB node cleanly removed for bus: $busIdToRemove');
      } catch (e) {
        debugPrint('[GpsService] Failed to remove RTDB node cleanly: $e');
      }
    }
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  /// Called on every position update from [Geolocator.getPositionStream].
  /// RTDB write errors are caught and logged — they never cancel the stream.
  void _onPosition(Position pos) {
    if (!_isBroadcasting || _activeBusId == null) return;

    final double speedKmh = pos.speed * 3.6; // m/s → km/h
    final bool isMoving = pos.speed >= _movingThresholdMps;

    debugPrint(
      '[GpsService] Position update | '
      'speed: ${speedKmh.toStringAsFixed(1)} km/h | '
      'moving: $isMoving',
    );

    // Notify speed to provider callback
    _onSpeedUpdate?.call(speedKmh);

    // Build the RTDB payload — includes scheduleId, routeId, isBroadcasting
    // so the Cloud Function and admin portal don't need an extra Firestore read.
    final Map<String, dynamic> payload = {
      'lat': pos.latitude,
      'lng': pos.longitude,
      'speed': double.parse(speedKmh.toStringAsFixed(1)),
      'heading': pos.heading,
      'isMoving': isMoving,
      'isBroadcasting': true,
      'timestamp': ServerValue.timestamp,
    };

    if (_activeScheduleId != null) payload['scheduleId'] = _activeScheduleId!;
    if (_activeRouteId != null) payload['routeId'] = _activeRouteId!;

    // Write to RTDB — fire-and-forget; errors are logged but never rethrown
    FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: AppConstants.rtdbUrl,
    )
        .ref('busLocations/$_activeBusId')
        .set(payload)
        .catchError((Object e) {
          debugPrint('[GpsService] RTDB write error: $e');
          // Non-fatal — stream continues; next position update will retry
        });
  }
}
