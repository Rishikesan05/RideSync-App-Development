import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/features/auth/presentation/screens/auth_provider.dart';
import 'package:ridesync/features/auth/presentation/screens/user_model.dart';

/// Redesigned "Choose Your Experience" screen
/// Passenger → goes straight to passenger auth (login+signup combined)
/// Operator  → goes straight to operator auth (login+register combined)
/// Guest     → bypasses auth entirely
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight * 0.06),

              // Logo + branding
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/images/logo.jpeg',
                      height: 40,
                      width: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.directions_bus, color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'RideSync',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                ],
              ),

              SizedBox(height: screenHeight * 0.05),

              Text(
                'Who are\nyou today?',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Choose your role to get started.',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white54 : AppColors.textLight,
                ),
              ),

              SizedBox(height: screenHeight * 0.05),

              // Passenger Card
              _RoleCard(
                title: 'Passenger',
                subtitle: 'Book rides & track your bus in real-time',
                icon: Icons.person_pin_circle_rounded,
                accentColor: AppColors.primaryOrange,
                badgeLabel: 'TRAVELLER',
                isDark: isDark,
                onTap: () {
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  auth.selectRole(UserRole.passenger);
                  Navigator.pushNamed(context, '/passenger-auth-choice');
                },
              ),

              const SizedBox(height: 16),

              // Operator Card
              _RoleCard(
                title: 'Bus Operator',
                subtitle: 'Manage your fleet & track earnings',
                icon: Icons.directions_bus_filled_rounded,
                accentColor: const Color(0xFF3B82F6),
                badgeLabel: 'OPERATOR',
                isDark: isDark,
                onTap: () {
                  final auth = Provider.of<AuthProvider>(context, listen: false);
                  auth.selectRole(UserRole.operator);
                  Navigator.pushNamed(context, '/operator-auth-choice');
                },
              ),

              const Spacer(),

              // Guest link
              Center(
                child: TextButton(
                  onPressed: () {
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    auth.continueAsGuest();
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/main', (route) => false);
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'Just exploring? ',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : AppColors.textLight,
                        fontSize: 14,
                      ),
                      children: const [
                        TextSpan(
                          text: 'Continue as Guest',
                          style: TextStyle(
                            color: AppColors.primaryOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String badgeLabel;
  final bool isDark;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.badgeLabel,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accentColor, size: 30),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeLabel,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isDark ? Colors.white24 : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
