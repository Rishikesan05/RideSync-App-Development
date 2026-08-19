import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ridesync/core/widgets/bottom_nav_bar.dart';
import 'package:ridesync/core/widgets/confirm_exit_dialog.dart';
import 'package:ridesync/features/passenger/presentation/providers/booking_provider.dart';
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
      final newIndex = args['index'] as int;
      if (newIndex >= 0 && newIndex < _screens.length) {
        _onTabSelected(newIndex);
      }
    }
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) {
      // Tapping the currently active tab again (e.g. Booking tab)
      if (index == 1) {
        context.read<BookingProvider>().resetBookingFlow();
      }
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _handlePopScope(bool didPop, dynamic result) async {
    if (didPop) return;

    if (_currentIndex != 0) {
      // Return to Home screen first
      setState(() {
        _currentIndex = 0;
      });
      return;
    }

    // On Home screen: prompt before exiting app
    final shouldExit = await showConfirmExitDialog(
      context,
      title: 'Exit RideSync?',
      message: 'Are you sure you want to exit the app?',
      confirmLabel: 'Exit App',
      cancelLabel: 'Stay',
      isDestructive: true,
      icon: Icons.exit_to_app_rounded,
    );

    if (shouldExit && mounted) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _handlePopScope,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onTabSelected,
        ),
      ),
    );
  }
}
