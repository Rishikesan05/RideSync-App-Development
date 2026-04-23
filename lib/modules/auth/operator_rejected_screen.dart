import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridesync/modules/auth/auth_provider.dart';
import 'package:ridesync/core/widgets/custom_button.dart';
import 'package:ridesync/core/constants.dart';

class OperatorRejectedScreen extends StatelessWidget {
  const OperatorRejectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        title: const Text('Application Rejected'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppStyles.padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cancel_outlined,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 32),
            Text(
              'Application Rejected',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Unfortunately, your application to become a Bus Operator has been rejected. Please contact support for more details or to appeal the decision.',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : AppColors.textLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            CustomButton(
              label: 'Contact Support',
              onPressed: () {
                // Future Support routing
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
