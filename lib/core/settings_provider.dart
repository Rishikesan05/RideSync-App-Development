import 'package:flutter/material.dart';

// Manages App-wide settings like Theme, Language, and Notifications
class SettingsProvider with ChangeNotifier {
  bool _isNotificationsEnabled = true;
  String _selectedLanguage = 'English';
  ThemeMode _themeMode = ThemeMode.system;

  bool get isNotificationsEnabled => _isNotificationsEnabled;
  String get selectedLanguage => _selectedLanguage;
  ThemeMode get themeMode => _themeMode;

  void toggleNotifications(bool value) {
    _isNotificationsEnabled = value;
    notifyListeners();
  }

  void setLanguage(String language) {
    _selectedLanguage = language;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
