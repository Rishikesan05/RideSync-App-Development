import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class LiveJourneyProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _hasActiveBooking = false;
  bool _hasJourneyStarted = false;
  Map<String, dynamic>? _activeBooking;
  Map<String, dynamic>? _activeSchedule;
  
  StreamSubscription? _bookingSub;
  StreamSubscription? _scheduleSub;

  bool get isLoading => _isLoading;
  bool get hasActiveBooking => _hasActiveBooking;
  bool get hasJourneyStarted => _hasJourneyStarted;
  Map<String, dynamic>? get activeBooking => _activeBooking;
  Map<String, dynamic>? get activeSchedule => _activeSchedule;

  String? get routeName => _activeBooking?['routeName'] ?? _activeSchedule?['routeName'];
  String? get origin => _activeBooking?['origin'] ?? _activeSchedule?['startingPoint'];
  String? get destination => _activeBooking?['destination'];
  String? get busPlateNumber => _activeBooking?['plateNumber'] ?? _activeSchedule?['busPlateNumber'];
  List<dynamic> get seats => (_activeBooking?['seats'] as List<dynamic>?) ?? [];
  double get balanceDue => (_activeBooking?['balanceDue'] as num? ?? 0.0).toDouble();
  double get totalFare => (_activeBooking?['totalFare'] as num? ?? 0.0).toDouble();

  void initialize(String? userId) {
    _bookingSub?.cancel();
    _scheduleSub?.cancel();
    
    _hasActiveBooking = false;
    _hasJourneyStarted = false;
    _activeBooking = null;
    _activeSchedule = null;

    if (userId == null) {
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    // Listen for bookings for this user using single-field query (no composite index required)
    _bookingSub = FirebaseFirestore.instance
        .collection('bookings')
        .where('passengerId', isEqualTo: userId)
        .snapshots()
        .listen((bookingSnap) async {
      if (bookingSnap.docs.isEmpty) {
        _hasActiveBooking = false;
        _hasJourneyStarted = false;
        _activeBooking = null;
        _activeSchedule = null;
        _isLoading = false;
        _scheduleSub?.cancel();
        notifyListeners();
        return;
      }

      // Filter active (non-cancelled, non-completed) bookings with a linked bus/schedule
      final allBookings = bookingSnap.docs
          .map((d) {
            final data = d.data();
            data['id'] = d.id;
            return data;
          })
          .where((b) =>
              b['status'] != 'cancelled' &&
              b['status'] != 'completed' &&
              (b['busId'] != null || b['scheduleId'] != null))
          .toList();

      if (allBookings.isEmpty) {
        _hasActiveBooking = false;
        _hasJourneyStarted = false;
        _activeBooking = null;
        _activeSchedule = null;
        _isLoading = false;
        _scheduleSub?.cancel();
        notifyListeners();
        return;
      }

      // Sort newest bookings first
      allBookings.sort((a, b) {
        final timeA = a['departureTime'] ?? a['timestamp'];
        final timeB = b['departureTime'] ?? b['timestamp'];
        if (timeA == null || timeB == null) return 0;
        return timeB.toString().compareTo(timeA.toString());
      });

      // Find the active in-transit trip first, or the first upcoming non-completed trip
      Map<String, dynamic>? selectedBooking;
      for (final b in allBookings) {
        final schedId = b['scheduleId'] as String?;
        if (schedId != null) {
          try {
            final sDoc = await FirebaseFirestore.instance
                .collection('schedules')
                .doc(schedId)
                .get();
            if (sDoc.exists) {
              final sStatus = sDoc.data()?['status'] as String?;
              if (sStatus == 'in-transit' || sStatus == 'started') {
                selectedBooking = b;
                break; // Found active in-transit trip!
              } else if (sStatus != 'completed' && sStatus != 'cancelled') {
                selectedBooking ??= b; // Found valid upcoming trip
              }
            }
          } catch (_) {}
        } else if (b['busId'] != null) {
          selectedBooking ??= b;
        }
      }

      if (selectedBooking == null) {
        _hasActiveBooking = false;
        _hasJourneyStarted = false;
        _activeBooking = null;
        _activeSchedule = null;
        _isLoading = false;
        _scheduleSub?.cancel();
        notifyListeners();
        return;
      }

      _activeBooking = selectedBooking;
      final scheduleId = selectedBooking['scheduleId'] as String?;
      final busId = selectedBooking['busId'] as String?;

      if (scheduleId == null) {
        _hasActiveBooking = busId != null && busId.isNotEmpty;
        _hasJourneyStarted = false;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Listen to the associated schedule real-time stream to detect operator Start / End Journey
      _scheduleSub?.cancel();
      _scheduleSub = FirebaseFirestore.instance
          .collection('schedules')
          .doc(scheduleId)
          .snapshots()
          .listen((scheduleSnap) {
        if (!scheduleSnap.exists) {
          _hasActiveBooking = false;
          _hasJourneyStarted = false;
          _activeSchedule = null;
          _isLoading = false;
          notifyListeners();
          return;
        }

        final scheduleData = scheduleSnap.data()!;
        final status = scheduleData['status'] as String?;

        if (status == 'completed' || status == 'cancelled') {
          // Journey finished or cancelled by operator — remove card from home screen
          _hasActiveBooking = false;
          _hasJourneyStarted = false;
          _activeSchedule = null;
        } else if (status == 'in-transit' || status == 'started') {
          // Operator tapped "Start Journey" — show LIVE TRACKING / IN TRANSIT
          _hasActiveBooking = true;
          _hasJourneyStarted = true;
          _activeSchedule = scheduleData;
        } else {
          // Scheduled / Confirmed trip — show UPCOMING
          _hasActiveBooking = true;
          _hasJourneyStarted = false;
          _activeSchedule = scheduleData;
        }

        _isLoading = false;
        notifyListeners();
      });
    }, onError: (e) {
      debugPrint('[LiveJourneyProvider] Error listening to bookings: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _bookingSub?.cancel();
    _scheduleSub?.cancel();
    super.dispose();
  }
}
