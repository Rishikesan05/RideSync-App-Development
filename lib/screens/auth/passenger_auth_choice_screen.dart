import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../widgets/custom_button.dart';

class PassengerAuthChoiceScreen extends StatelessWidget {
  const PassengerAuthChoiceScreen({super.key});

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
                color: AppColors.primaryOrange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_pin_circle_outlined,
                size: 80,
                color: AppColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Passenger Account',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sign in to book rides or create a new account to start your journey with RideSync.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : AppColors.textLight,
              ),
            ),
            const SizedBox(height: 48),
            CustomButton(
              label: 'Login',
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
            ),
            const SizedBox(height: 16),
            CustomButton(
              label: 'Create Account',
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
              textColor: isDark ? Colors.white : AppColors.primaryNavy,
              onPressed: () {
                Navigator.pushNamed(context, '/passenger-signup');
              },
            ),
            // The white button needs a border to be visible on white bg if not dark
            if (!isDark)
              const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Text(
                  'Join our passenger community',
                  style: TextStyle(fontSize: 12, color: AppColors.textLight),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
