import 'package:flutter/material.dart';
import 'package:ridesync/core/widgets/bottom_nav_bar.dart';
import 'package:ridesync/features/passenger/presentation/screens/home_screen.dart';
import 'package:ridesync/features/passenger/presentation/screens/booking_screen.dart';
import 'package:ridesync/features/passenger/presentation/screens/live_screen.dart';
import 'package:ridesync/features/passenger/presentation/screens/finder_screen.dart';
import 'package:ridesync/features/passenger/presentation/screens/account_screen.dart';

class PassengerNavigationHub extends StatefulWidget {
  const PassengerNavigationHub({super.key});

  @override
  State<PassengerNavigationHub> createState() => _PassengerNavigationHubState();
}

class _PassengerNavigationHubState extends State<PassengerNavigationHub> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const BookingScreen(),
    const LiveScreen(),
    const RouteFinderScreen(),
    const AccountScreen(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Handle index argument if passed via navigation
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('index')) {
      _currentIndex = args['index'] as int;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
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
