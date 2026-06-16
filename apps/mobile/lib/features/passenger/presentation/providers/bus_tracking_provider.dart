import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Holds the latest parsed GPS snapshot from RTDB for one bus.
class BusLocation {
  final double lat;
  final double lng;
  final double speed; // km/h
  final double heading; // degrees
  final int timestamp; // server epoch ms

  const BusLocation({
    required this.lat,
    required this.lng,
    required this.speed,
    required this.heading,
    required this.timestamp,
  });

  LatLng get latLng => LatLng(lat, lng);

  /// True when the last GPS update is older than 30 seconds.
  bool get isStale =>
      DateTime.now().millisecondsSinceEpoch - timestamp > 30000;

  factory BusLocation.fromMap(Map<dynamic, dynamic> data) {
    return BusLocation(
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      speed: (data['speed'] as num? ?? 0).toDouble(),
      heading: (data['heading'] as num? ?? 0).toDouble(),
      timestamp: (data['timestamp'] as num? ?? 0).toInt(),
    );
  }
}

/// Holds the latest trip status from RTDB for one schedule.
class TripStatus {
  final String status;
  final String? currentStop;
  final int? etaMs; // epoch ms
  final int? delayMinutes;

  const TripStatus({
    required this.status,
    this.currentStop,
    this.etaMs,
    this.delayMinutes,
  });

  /// ETA as a human-readable "HH:MM AM/PM" string.
  String get etaFormatted {
    if (etaMs == null) return '--:--';
    final dt = DateTime.fromMillisecondsSinceEpoch(etaMs!);
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final amPm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $amPm';
  }

  factory TripStatus.fromMap(Map<dynamic, dynamic> data) {
    return TripStatus(
      status: (data['status'] as String?) ?? 'unknown',
      currentStop: data['currentStop'] as String?,
      etaMs: (data['eta'] as num?)?.toInt(),
      delayMinutes: (data['delayMinutes'] as num?)?.toInt(),
    );
  }
}

/// Subscribes to live bus GPS and trip status from Firebase Realtime Database
/// and exposes the data to the passenger-side UI via [ChangeNotifier].
///
/// Usage:
///   1. Call [startTracking(busId, scheduleId)] when the passenger's journey starts.
///   2. Watch [busLocation] and [tripStatus] in your widget.
///   3. Call [stopTracking] (or let [dispose] handle it) when done.
class BusTrackingProvider extends ChangeNotifier {
  BusLocation? _busLocation;
  TripStatus? _tripStatus;
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<DatabaseEvent>? _locationSub;
  StreamSubscription<DatabaseEvent>? _statusSub;

  BusLocation? get busLocation => _busLocation;
  TripStatus? get tripStatus => _tripStatus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// True when the most recent GPS ping is older than 30 seconds.
  bool get isStale => _busLocation?.isStale ?? false;

  /// Whether we currently have live data (not stale, not null).
  bool get hasLiveData => _busLocation != null && !isStale;

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Start listening to RTDB for [busId] location and [scheduleId] trip status.
  void startTracking(String busId, String scheduleId) {
    stopTracking(); // Cancel any previous subscriptions

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // 1. Subscribe to live GPS location
    _locationSub = FirebaseDatabase.instance
        .ref('busLocations/$busId')
        .onValue
        .listen(
      (event) {
        if (event.snapshot.value == null) {
          // Operator hasn't started broadcasting yet
          _busLocation = null;
        } else {
          try {
            final raw = Map<dynamic, dynamic>.from(
              event.snapshot.value as Map,
            );
            _busLocation = BusLocation.fromMap(raw);
          } catch (e) {
            debugPrint('[BusTrackingProvider] Parse error (location): $e');
          }
        }
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = 'Live tracking unavailable: $e';
        _isLoading = false;
        debugPrint('[BusTrackingProvider] Location stream error: $e');
        notifyListeners();
      },
    );

    // 2. Subscribe to trip status (ETA, current stop, delay)
    _statusSub = FirebaseDatabase.instance
        .ref('tripStatus/$scheduleId')
        .onValue
        .listen(
      (event) {
        if (event.snapshot.value != null) {
          try {
            final raw = Map<dynamic, dynamic>.from(
              event.snapshot.value as Map,
            );
            _tripStatus = TripStatus.fromMap(raw);
          } catch (e) {
            debugPrint('[BusTrackingProvider] Parse error (status): $e');
          }
        }
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[BusTrackingProvider] Status stream error: $e');
      },
    );
  }

  /// Cancel all RTDB subscriptions.
  void stopTracking() {
    _locationSub?.cancel();
    _statusSub?.cancel();
    _locationSub = null;
    _statusSub = null;
    _busLocation = null;
    _tripStatus = null;
    _isLoading = false;
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
