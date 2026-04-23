import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridesync/modules/auth/auth_provider.dart';
import 'package:ridesync/modules/auth/user_model.dart';
import 'package:ridesync/main.dart'; // For PassengerNavigationHub
import 'package:ridesync/modules/operator/screens/operator_navigation_hub.dart';
import 'package:ridesync/modules/auth/role_selection_screen.dart';
import 'package:ridesync/modules/auth/operator_pending_screen.dart';
import 'package:ridesync/modules/auth/operator_rejected_screen.dart';

// Logic to redirect based on Login status, Guest mode, and User Role
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // 1. Check for Guest Mode
    if (authProvider.isGuest) {
      return const PassengerNavigationHub();
    }

    // 2. Check for Authenticated Users
    if (authProvider.isAuthenticated) {
      if (authProvider.currentRole == UserRole.operator) {
        if (authProvider.status == 'approved') {
          return const BusOperatorNavigationHub();
        } else if (authProvider.status == 'rejected') {
          return const OperatorRejectedScreen();
        } else {
          // Default to pending review behavior if not approved or explicitly rejected
          return const OperatorPendingScreen();
        }
      }
      return const PassengerNavigationHub();
    }

    // 3. Unauthenticated/Default: Show Role Selection
    return const RoleSelectionScreen();
  }
}



