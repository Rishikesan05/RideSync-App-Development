import 'package:flutter/material.dart';
import 'package:ridesync/core/constants.dart';

// Persistent Navigation Bar for the main application
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      selectedItemColor: AppColors.primaryOrange,
      unselectedItemColor: isDark ? Colors.white38 : AppColors.textLight,
      showUnselectedLabels: true,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book_outlined),
          activeIcon: Icon(Icons.book),
          label: 'Booking',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.live_tv_outlined),
          activeIcon: Icon(Icons.live_tv),
          label: 'Live',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          activeIcon: Icon(Icons.search_rounded),
          label: 'Finder',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Account',
        ),
      ],
    );
  }
}
