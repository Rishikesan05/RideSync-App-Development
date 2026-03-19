import 'package:flutter/material.dart';
import 'package:ridesync/core/placeholder_screen.dart';

// Seat selection and booking screen with Guest restriction
class BookingScreen extends StatelessWidget {
  final VoidCallback? onBack;
  const BookingScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Book Your Seat',
      onBack: onBack,
    );
  }
}




