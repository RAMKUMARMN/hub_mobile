import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global settings notifier — persists theme and notification preferences.
final settingsNotifier = _SettingsNotifier();

class _SettingsNotifier extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _notificationsEnabled = true;

  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;

  static const _keyTheme = 'settings_theme_mode';
  static const _keyNotifications = 'settings_notifications_enabled';

  /// Call once in [main] before [runApp] to restore persisted preferences.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_keyTheme);
    if (themeIndex != null && themeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeIndex];
    }
    _notificationsEnabled = prefs.getBool(_keyNotifications) ?? true;
    // No notifyListeners — runApp hasn't been called yet.
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTheme, mode.index);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    if (_notificationsEnabled == enabled) return;
    _notificationsEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotifications, enabled);
  }
}
