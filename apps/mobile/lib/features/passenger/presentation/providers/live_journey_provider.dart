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

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    // Listen for confirmed bookings for today or upcoming
    _bookingSub = FirebaseFirestore.instance
        .collection('bookings')
        .where('passengerId', isEqualTo: userId)
        .where('status', isEqualTo: 'confirmed')
        .where('departureTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('departureTime')
        .limit(1)
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

      _hasActiveBooking = true;
      final bookingData = bookingSnap.docs.first.data();
      final scheduleId = bookingData['scheduleId'];

      if (scheduleId == null) {
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
        if (!scheduleSnap.exists) return;
        
        final scheduleData = scheduleSnap.data()!;
        final status = scheduleData['status'] as String?;
        
        // "journey started" happens when operator/admin updates status to in-transit
        _hasJourneyStarted = (status == 'in-transit' || status == 'started' || status == 'active');
        
        _isLoading = false;
        notifyListeners();
      });
    }, onError: (e) {
      debugPrint('Error listening to bookings: $e');
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
