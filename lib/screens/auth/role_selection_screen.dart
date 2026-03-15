import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';

// Role selection between Commuter and Bus Operator
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        title: const Text('Choose Your Role'),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppStyles.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you an Operator or a User?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 32),
            _roleCard(
              context,
              'Commuter',
              'Book rides and track buses in real-time',
              Icons.directions_walk,
              isDark,
              () {
                Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).setRole('Commuter');
                Navigator.pushNamed(context, '/passenger-signup');
              },
            ),
            const SizedBox(height: 20),
            _roleCard(
              context,
              'Bus Operator',
              'Manage your fleet and optimize routes',
              Icons.directions_bus,
              isDark,
              () {
                Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).setRole('Operator');
                Navigator.pushNamed(context, '/driver-registration');
              },
            ),
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
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: Border.all(
            color: isDark
                ? Colors.white12
                : AppColors.primaryNavy.withValues(alpha: 0.1),
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: isDark
                  ? Colors.white10
                  : AppColors.primaryNavy.withValues(alpha: 0.1),
              child: Icon(
                icon,
                color: isDark ? Colors.white : AppColors.primaryNavy,
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
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? Colors.white70 : AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }
}
