import 'package:flutter/material.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/core/widgets/custom_button.dart';

class OperatorAuthChoiceScreen extends StatelessWidget {
  const OperatorAuthChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : AppColors.primaryNavy,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryNavy.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.directions_bus_filled_outlined,
                size: 80,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Bus Operator',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Access your fleet dashboard or register as a new operator to join our network.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : AppColors.textLight,
              ),
            ),
            const SizedBox(height: 48),
            CustomButton(
              label: 'Operator Login',
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
            ),
            const SizedBox(height: 16),
            CustomButton(
              label: 'Register Fleet',
              color: AppColors.primaryOrange,
              onPressed: () {
                Navigator.pushNamed(context, '/driver-registration');
              },
            ),
          ],
        ),
      ),
    );
  }
}





