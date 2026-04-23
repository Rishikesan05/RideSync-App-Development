import 'package:flutter/material.dart';

// State management for seat selection and fares
class BookingProvider with ChangeNotifier {
  int _selectedSeat = -1;
  double _fare = 0.0;

  int get selectedSeat => _selectedSeat;
  double get fare => _fare;

  void selectSeat(int seatIndex) {
    _selectedSeat = seatIndex;
    notifyListeners();
  }

  void updateFare(double newFare) {
    _fare = newFare;
    notifyListeners();
  }
}
