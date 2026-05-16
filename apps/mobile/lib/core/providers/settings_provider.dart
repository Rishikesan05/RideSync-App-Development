import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  String _selectedLanguage = 'English';
  bool _isNotificationsEnabled = true;

  ThemeMode get themeMode => _themeMode;
  String get selectedLanguage => _selectedLanguage;
  bool get isNotificationsEnabled => _isNotificationsEnabled;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setLanguage(String lang) {
    _selectedLanguage = lang;
    notifyListeners();
  }

  void toggleNotifications(bool value) {
    _isNotificationsEnabled = value;
    notifyListeners();
  }
}

