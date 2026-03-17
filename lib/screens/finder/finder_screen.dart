import 'package:flutter/material.dart';
import '../placeholder_screen.dart';

// Route finder and fare display screen
class FinderScreen extends StatelessWidget {
  final VoidCallback? onBack;
  const FinderScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Route Finder',
      onBack: onBack,
    );
  }
}
