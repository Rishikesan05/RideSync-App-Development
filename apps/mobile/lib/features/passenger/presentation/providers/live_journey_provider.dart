import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class LiveJourneyProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _hasActiveBooking = false;
  bool _hasJourneyStarted = false;
  
  StreamSubscription? _bookingSub;
  StreamSubscription? _scheduleSub;

  bool get isLoading => _isLoading;
  bool get hasActiveBooking => _hasActiveBooking;
  bool get hasJourneyStarted => _hasJourneyStarted;

  void initialize(String? userId) {
    _bookingSub?.cancel();
    _scheduleSub?.cancel();
    
    _hasActiveBooking = false;
    _hasJourneyStarted = false;

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
        .listen((bookingSnap) {
      if (bookingSnap.docs.isEmpty) {
        _hasActiveBooking = false;
        _hasJourneyStarted = false;
        _isLoading = false;
        _scheduleSub?.cancel();
        notifyListeners();
        return;
      }

      // Find the most relevant booking (prefer confirmed/active, or any booking with busId/scheduleId)
      final allDocs = bookingSnap.docs.map((d) => d.data()).toList();
      final activeBooking = allDocs.firstWhere(
        (b) => b['status'] != 'cancelled' && (b['busId'] != null || b['scheduleId'] != null),
        orElse: () => allDocs.first,
      );

      _hasActiveBooking = true;
      final scheduleId = activeBooking['scheduleId'] as String?;
      final busId = activeBooking['busId'] as String?;

      if (scheduleId == null) {
        // Direct busId booking (like in Firestore bookings collection) — allow live tracking immediately
        _hasJourneyStarted = busId != null && busId.isNotEmpty;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Listen to the associated schedule to check if journey started
      _scheduleSub?.cancel();
      _scheduleSub = FirebaseFirestore.instance
          .collection('schedules')
          .doc(scheduleId)
          .snapshots()
          .listen((scheduleSnap) {
        if (!scheduleSnap.exists) {
          // If schedule doc is missing but busId exists on booking, still allow tracking
          _hasJourneyStarted = busId != null && busId.isNotEmpty;
          _isLoading = false;
          notifyListeners();
          return;
        }

        final scheduleData = scheduleSnap.data()!;
        final status = scheduleData['status'] as String?;

        // "journey started" happens when operator/admin updates status to in-transit, or if bus is broadcasting
        _hasJourneyStarted = (status == 'in-transit' || status == 'started' || status == 'active' || status == 'scheduled');

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
