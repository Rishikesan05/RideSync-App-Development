import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridesync/core/theme.dart';
import 'package:ridesync/features/auth/presentation/screens/auth_provider.dart';
import 'package:ridesync/features/auth/presentation/screens/login_screen.dart';
import 'package:ridesync/features/auth/presentation/screens/passenger_signup_screen.dart';
import 'package:ridesync/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:ridesync/features/passenger/presentation/screens/passenger_navigation_hub.dart';
import 'package:ridesync/features/operator/presentation/screens/operator_navigation_hub.dart';
import 'package:ridesync/features/auth/presentation/screens/passenger_auth_choice_screen.dart';
import 'package:ridesync/features/auth/presentation/screens/operator_auth_choice_screen.dart';
import 'package:ridesync/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:ridesync/features/auth/presentation/screens/driver_registration_screen.dart';

import 'package:ridesync/core/constants.dart';
import 'package:ridesync/core/providers/settings_provider.dart';
import 'package:ridesync/features/auth/presentation/screens/user_model.dart';
import 'package:ridesync/features/passenger/presentation/providers/finder_provider.dart';
import 'package:ridesync/features/passenger/presentation/providers/booking_provider.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (context) => FinderProvider()),
        ChangeNotifierProvider(create: (context) => BookingProvider()),
      ],
      child: const RideSyncApp(),
    ),
  );
}

class RideSyncApp extends StatelessWidget {
  const RideSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RideSync',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/passenger-signup': (context) => const PassengerSignupScreen(),
        '/passenger-auth-choice': (context) => const PassengerAuthChoiceScreen(),
        '/operator-auth-choice': (context) => const OperatorAuthChoiceScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/driver-registration': (context) => const DriverRegistrationScreen(),
        '/main': (context) => const PassengerNavigationHub(),
        '/operator-home': (context) => const BusOperatorNavigationHub(),
        '/splash': (context) => const RoleSelectionScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Show splash/loading while initializing
    if (!authProvider.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryOrange),
        ),
      );
    }

    // Determine target screen
    if (authProvider.isAuthenticated || authProvider.isGuest) {
      if (authProvider.currentRole == UserRole.operator) {
        return const BusOperatorNavigationHub();
      } else {
        return const PassengerNavigationHub();
      }
    }

    // Default to login if not authenticated or guest
    return const LoginScreen();
  }
}
