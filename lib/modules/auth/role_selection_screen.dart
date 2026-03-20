import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/modules/auth/auth_provider.dart';
import 'package:ridesync/modules/auth/user_model.dart';

// Upgraded Role selection with Passenger, Bus Operator, and Guest modes
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        title: const Text('Join RideSync'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: isDark ? Colors.white : AppColors.primaryNavy,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Choose Your Experience',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Select the role that fits you best to get started with intelligent commuting.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : AppColors.textLight,
              ),
            ),
            const SizedBox(height: 48),

            // Passenger Card
            _roleCard(
              context,
              'Passenger',
              'Book comfortable rides and track your bus in real-time.',
              Icons.person_pin_circle_outlined,
              isDark,
              AppColors.primaryOrange,
              () {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                auth.selectRole(UserRole.passenger);
                Navigator.pushNamed(context, '/passenger-auth-choice');
              },
            ),

            const SizedBox(height: 24),

            // Bus Operator Card
            _roleCard(
              context,
              'Bus Operator',
              'Manage your fleet, optimize schedules, and track earnings.',
              Icons.directions_bus_filled_outlined,
              isDark,
              AppColors.primaryNavy,
              () {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                auth.selectRole(UserRole.operator);
                Navigator.pushNamed(context, '/operator-auth-choice');
              },
            ),

            const SizedBox(height: 24),

            // Guest Card
            _roleCard(
              context,
              'Guest Entry',
              'Explore routes and schedules without an account.',
              Icons.visibility_outlined,
              isDark,
              Colors.grey,
              () {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                auth.continueAsGuest();
                Navigator.pushNamedAndRemoveUntil(
                    context, '/main', (route) => false);
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _roleCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    bool isDark,
    Color accentColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : AppColors.primaryNavy.withValues(alpha: 0.05),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                color: accentColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}





