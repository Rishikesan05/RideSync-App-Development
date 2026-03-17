import 'package:flutter/material.dart';
import '../placeholder_screen.dart';

// Real-time tracking map screen
class LiveScreen extends StatelessWidget {
  final VoidCallback? onBack;
  const LiveScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Live Tracking',
      onBack: onBack,
    );
  }
}
