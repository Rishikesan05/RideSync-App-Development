import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onBack;
  final String? backRoute;

  const PlaceholderScreen({
    super.key,
    required this.title,
    this.message = 'We are working hard to bring this feature to you soon!',
    this.onBack,
    this.backRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: false,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.padding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.construction,
                size: 80,
                color: AppColors.primaryOrange,
              ),
              const SizedBox(height: 24),
              Text(
                'Coming Soon',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: onBack ?? () {
                    if (backRoute != null) {
                      Navigator.pushReplacementNamed(context, backRoute!);
                    } else {
                      // Role-aware default navigation
                      final auth = context.read<AuthProvider>();
                      final role = auth.currentRole;
                      
                      if (role == UserRole.operator) {
                        Navigator.pushReplacementNamed(context, '/operator-main');
                      } else {
                        Navigator.pushReplacementNamed(context, '/main');
                      }
                    }
                  },
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
