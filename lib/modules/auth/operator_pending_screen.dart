import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridesync/modules/auth/auth_provider.dart';
import 'package:ridesync/core/widgets/custom_button.dart';
import 'package:ridesync/core/constants.dart';

class OperatorPendingScreen extends StatelessWidget {
  const OperatorPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        title: const Text('Review Pending'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppStyles.padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
              size: 80,
              color: AppColors.primaryOrange,
            ),
            const SizedBox(height: 32),
            Text(
              'Application Under Review',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Your registration documents are currently being reviewed by our administration team. You will be notified once your account is approved.',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            CustomButton(
              label: 'Refresh Status',
              onPressed: () async {
                await Provider.of<AuthProvider>(context, listen: false).refreshUser();
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                await Provider.of<AuthProvider>(context, listen: false).logout();
              },
              child: Text(
                 'Logout',
                 style: TextStyle(color: isDark ? Colors.white70 : AppColors.textLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
