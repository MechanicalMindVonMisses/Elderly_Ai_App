import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  late SharedPreferences _prefs;
  bool _isDarkMode = false;
  bool _isLargeFont = true; // Default to true as per original design
  bool _initialized = false;

  bool get isDarkMode => _isDarkMode;
  bool get isLargeFont => _isLargeFont;
  bool get initialized => _initialized;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool('is_dark_mode') ?? false;
    _isLargeFont = _prefs.getBool('is_large_font') ?? true;
    _initialized = true;
    notifyListeners();
  }

  Future<void> toggleTheme(bool value) async {
    _isDarkMode = value;
    await _prefs.setBool('is_dark_mode', value);
    notifyListeners();
  }

  Future<void> toggleFont(bool value) async {
    _isLargeFont = value;
    await _prefs.setBool('is_large_font', value);
    notifyListeners();
  }
}
