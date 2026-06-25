import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'api_service.dart';
import 'settings_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  bool _initialized = false;
  String? _fcmToken;

  /// Initializes Firebase and configures messaging if notifications are enabled
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // If Firebase is already initialized natively or via google-services.json, this will succeed.
      // If not, it may throw, which we gracefully catch to prevent app crashes.
      await Firebase.initializeApp();
      _initialized = true;

      // Respect the user's existing settings preference before doing anything
      if (settingsNotifier.notificationsEnabled) {
        await setupNotifications();
      }
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
    }
  }

  /// Requests permissions and retrieves the token
  Future<void> setupNotifications() async {
    if (!_initialized) return;

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized || 
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        _fcmToken = await _messaging.getToken();
        debugPrint('FCM Token retrieved: $_fcmToken');
        if (_fcmToken != null) {
          await _registerTokenWithBackend(_fcmToken!);
        }
        
        // Listen for token refreshes
        _messaging.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          debugPrint('FCM Token refreshed: $_fcmToken');
          _registerTokenWithBackend(newToken);
        });
      } else {
        debugPrint('User declined or has not accepted notification permissions');
        // Optionally sync this back to settingsNotifier in the future
      }
    } catch (e) {
      debugPrint('Error setting up notifications: $e');
    }
  }

  Future<void> _registerTokenWithBackend(String token) async {
    try {
      await ApiService().dio.put(
        '/auth/profile',
        data: {'device_token': token},
      );
      debugPrint('Successfully registered FCM token with backend.');
    } catch (e) {
      debugPrint('Failed to register FCM token with backend: $e');
    }
  }

  String? get fcmToken => _fcmToken;

  /// Call this when the user toggles the setting in the UI
  Future<void> handleSettingsChange(bool enabled) async {
    if (enabled) {
      await setupNotifications();
    } else {
      // In the future: unregister token from backend or delete instance ID
      _fcmToken = null;
    }
  }
}

final notificationService = NotificationService();
