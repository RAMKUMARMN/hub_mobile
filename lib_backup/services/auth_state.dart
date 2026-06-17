import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global auth-state notifier.
///
/// Initialized once in [main] so GoRouter can do a synchronous redirect
/// (no blank-screen flash while awaiting SharedPreferences).
///
/// Call [onLogin] after saving tokens and [onLogout] after clearing them.
final authNotifier = _AuthNotifier();

class _AuthNotifier extends ChangeNotifier {
  bool _loggedIn = false;

  bool get isLoggedIn => _loggedIn;

  /// Call once in [main] before [runApp] to pre-load the stored token.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _loggedIn = prefs.getString('access_token') != null;
    // No notifyListeners here — runApp hasn't been called yet.
  }

  /// Call after a successful login / registration + token save.
  void onLogin() {
    if (_loggedIn) return;
    _loggedIn = true;
    notifyListeners();
  }

  /// Call after logout or token-refresh failure.
  void onLogout() {
    if (!_loggedIn) return;
    _loggedIn = false;
    notifyListeners();
  }
}
