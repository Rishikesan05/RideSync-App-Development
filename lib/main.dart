import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:ridesync/core/firebase_options.dart';
import 'package:ridesync/core/theme.dart';
import 'package:ridesync/modules/auth/auth_provider.dart';
import 'package:ridesync/modules/operator/providers/registration_provider.dart';
import 'package:ridesync/modules/passenger/providers/booking_provider.dart';
import 'package:ridesync/core/settings_provider.dart';
import 'package:ridesync/modules/passenger/screens/splash_screen.dart';
import 'package:ridesync/modules/auth/login_screen.dart';
import 'package:ridesync/modules/auth/role_selection_screen.dart';
import 'package:ridesync/modules/auth/driver_registration/registration_flow.dart';
import 'package:ridesync/modules/auth/passenger_signup_screen.dart';
import 'package:ridesync/modules/passenger/screens/home_screen.dart';
import 'package:ridesync/modules/passenger/screens/booking_screen.dart';
import 'package:ridesync/modules/passenger/screens/live_screen.dart';
import 'package:ridesync/modules/passenger/providers/finder_provider.dart';
import 'package:ridesync/modules/passenger/screens/finder_screen.dart';
import 'package:ridesync/modules/passenger/screens/account_screen.dart';
import 'package:ridesync/modules/operator/screens/operator_navigation_hub.dart';
import 'package:ridesync/modules/auth/passenger_auth_choice_screen.dart';
import 'package:ridesync/modules/auth/operator_auth_choice_screen.dart';
import 'package:ridesync/modules/auth/phone_auth_screen.dart';
import 'package:ridesync/core/widgets/bottom_nav_bar.dart';

// Entry point and Theme configuration for RideSync
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RegistrationProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => FinderProvider()),
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
            '/phone-auth': (context) => const PhoneAuthScreen(),
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
    const RouteFinderScreen(),
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




