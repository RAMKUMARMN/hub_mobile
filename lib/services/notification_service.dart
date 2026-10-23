import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 1. TOP-LEVEL BACKGROUND HANDLER
// Must be outside all classes and marked with @pragma
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Background message received: ${message.messageId}");
  print("Silent Data Received: ${message.data}");
}

class NotificationService {
  // 2. LAZY GETTERS (Prevents early instantiation before Firebase.initializeApp())
  static FirebaseMessaging get _firebaseMessaging => FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize({
    required Function(RemoteMessage message) onForegroundMessage,
    required Function(RemoteMessage message) onNotificationClicked,
  }) async {
    // Request user permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Create Notification Channel for Android
    const AndroidNotificationChannel vibrationChannel =
        AndroidNotificationChannel(
      'vibration_channel_v3',
      'Vibration Notifications V3',
      description: 'Shows banners with sound and physical vibration.',
      importance: Importance.high,
      enableVibration: true,
    );

    final androidPlugin = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(vibrationChannel);

    // Initialize Local Notifications Plugin
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotificationsPlugin.initialize(settings: 
      initializationSettings, // Fixed parameter passing
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle foreground notification banner taps here if needed
      },
    );

    // Handle FOREGROUND messages (App is active on screen)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground message received!");

      // Notify UI
      onForegroundMessage(message);

      // Display native heads-up banner
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _localNotificationsPlugin.show(id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              vibrationChannel.id,
              vibrationChannel.name,
              channelDescription: vibrationChannel.description,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    // Handle BACKGROUND notification taps (App running in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notification tapped from background!");
      onNotificationClicked(message);
    });

    // Handle TERMINATED state taps (App launched from dead state)
    // Bounded: this platform call never completes when the app was not
    // launched from a notification (notably the iOS simulator).
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage()
        .timeout(const Duration(seconds: 2));
    if (initialMessage != null) {
      print("App launched from terminated state via notification!");
      onNotificationClicked(initialMessage);
    }
  }

  // Get device token safely
  static Future<String?> getDeviceToken() async {
    try {
      NotificationSettings settings =
          await _firebaseMessaging.getNotificationSettings();
      debugPrint("Permission status: ${settings.authorizationStatus}");

      // Allow if status is authorized OR provisional (Android default)
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint("User denied notification permissions.");
        return null;
      }

      final token = await _firebaseMessaging.getToken();
      if (token == null) {
        debugPrint("getToken() returned null — check google-services.json "
            "matches applicationId and Google Play Services is present.");
        return null;
      }

      debugPrint("==================================================");
      debugPrint("Device Token for AWS SNS: $token");
      debugPrint("==================================================");

      // Token can rotate — re-log so the backend always has the current one.
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        debugPrint("==================================================");
        debugPrint("Device Token refreshed: $newToken");
        debugPrint("==================================================");
      });

      return token;
    } catch (e, stack) {
      debugPrint("Error getting FCM device token: $e");
      debugPrint("$stack");
    }
    return null;
  }
}