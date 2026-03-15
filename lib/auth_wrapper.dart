import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'main.dart';
import 'screens/auth/login_screen.dart';

// Logic to redirect based on Login status and User Role
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // If authenticated, show main dashboard navigation
    if (authProvider.isAuthenticated) {
      return const MainNavigationHub();
    } else {
      // Otherwise, redirect to login screen
      return const LoginScreen();
    }
  }
}
