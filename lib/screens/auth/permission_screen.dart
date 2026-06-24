// lib/screens/auth/permission_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../services/local/notification_service.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _notificationsGranted = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isChecking = true);
    
    // Use NotificationService to check permissions
    final service = NotificationService();
    final enabled = await service.areNotificationsEnabled();
    
    setState(() {
      _notificationsGranted = enabled;
      _isChecking = false;
    });
  }

  Future<void> _requestPermissions() async {
    // For Android 13+, the permission dialog appears automatically
    // when we try to show a notification or create a channel
    // We'll just test by showing a test notification
    
    final plugin = FlutterLocalNotificationsPlugin();
    
    // Initialize the plugin if needed
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await plugin.initialize(settings);
    
    // Try to show a test notification - this will trigger permission request on Android 13+
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await plugin.show(
      999,
      'Notification Permission',
      'You have enabled notifications!',
      details,
    );
    
    // Wait a bit and check again
    await Future.delayed(const Duration(seconds: 1));
    await _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.notifications_active, size: 80, color: Color(0xFF0BD1FA)),
              const SizedBox(height: 24),
              const Text(
                'Enable Notifications',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Get reminders for your tasks, deadlines, and important updates',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              if (_isChecking)
                const CircularProgressIndicator()
              else if (_notificationsGranted)
                Column(
                  children: [
                    const Icon(Icons.check_circle, size: 48, color: Colors.green),
                    const SizedBox(height: 16),
                    const Text(
                      'Notifications Enabled!',
                      style: TextStyle(color: Colors.green, fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0BD1FA),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: const Text('Continue'),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _requestPermissions,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0BD1FA),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: const Text('Allow Notifications'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                      child: const Text('Skip for now'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}