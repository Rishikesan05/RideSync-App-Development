import 'package:flutter/material.dart';
import 'package:ridesync/core/constants.dart';
import 'package:ridesync/features/operator/presentation/screens/operator_home_screen.dart';
import 'package:ridesync/features/operator/presentation/screens/operator_profile_screen.dart';
import 'package:ridesync/core/placeholder_screen.dart';

class BusOperatorNavigationHub extends StatefulWidget {
  const BusOperatorNavigationHub({super.key});

  @override
  State<BusOperatorNavigationHub> createState() => _BusOperatorNavigationHubState();
}

class _BusOperatorNavigationHubState extends State<BusOperatorNavigationHub> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    const OperatorHomeScreen(),
    PlaceholderScreen(title: 'My Routes', onBack: () => setState(() => _currentIndex = 0)),
    PlaceholderScreen(title: 'Earnings', onBack: () => setState(() => _currentIndex = 0)),
    PlaceholderScreen(title: 'Fleet', onBack: () => setState(() => _currentIndex = 0)),
    const OperatorProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          selectedItemColor: AppColors.primaryOrange,
          unselectedItemColor: isDark ? Colors.white30 : Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.route_outlined), activeIcon: Icon(Icons.route), label: 'Routes'),
            BottomNavigationBarItem(icon: Icon(Icons.payments_outlined), activeIcon: Icon(Icons.payments), label: 'Earnings'),
            BottomNavigationBarItem(icon: Icon(Icons.directions_bus_outlined), activeIcon: Icon(Icons.directions_bus), label: 'Fleet'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}







