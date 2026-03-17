import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/registration_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/auth/driver_registration/registration_flow.dart';
import 'screens/auth/passenger_signup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/booking/booking_screen.dart';
import 'screens/live/live_screen.dart';
import 'screens/finder/finder_screen.dart';
import 'screens/account/account_screen.dart';
import 'screens/operator/operator_navigation_hub.dart';
import 'screens/auth/passenger_auth_choice_screen.dart';
import 'screens/auth/operator_auth_choice_screen.dart';
import 'widgets/bottom_nav_bar.dart';

// Entry point and Theme configuration for RideSync
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RegistrationProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const RideSyncApp(),
    ),
  );
}

class RideSyncApp extends StatelessWidget {
  const RideSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          title: 'RideSync',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
          debugShowCheckedModeBanner: false,
          initialRoute: '/splash',
          routes: {
            '/splash': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/role-selection': (context) => const RoleSelectionScreen(),
            '/main': (context) => const PassengerNavigationHub(),
            '/operator-main': (context) => const BusOperatorNavigationHub(),
            '/driver-registration': (context) => const DriverRegistrationFlow(),
            '/passenger-signup': (context) => const PassengerSignupScreen(),
            '/passenger-auth-choice': (context) => const PassengerAuthChoiceScreen(),
            '/operator-auth-choice': (context) => const OperatorAuthChoiceScreen(),
          },
        );
      },
    );
  }
}

// Persistent Navigation Hub for Passengers
class PassengerNavigationHub extends StatefulWidget {
  const PassengerNavigationHub({super.key});

  @override
  State<PassengerNavigationHub> createState() => _PassengerNavigationHubState();
}

class _PassengerNavigationHubState extends State<PassengerNavigationHub> {
  int _currentIndex = 0;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('index')) {
        _currentIndex = args['index'] as int;
      }
      _initialized = true;
    }
  }

  late final List<Widget> _screens = [
    const HomeScreen(),
    BookingScreen(onBack: () => setState(() => _currentIndex = 0)),
    LiveScreen(onBack: () => setState(() => _currentIndex = 0)),
    FinderScreen(onBack: () => setState(() => _currentIndex = 0)),
    const AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
