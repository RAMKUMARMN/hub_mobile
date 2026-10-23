import 'dart:async';

import 'package:cixiohub_mobile/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/auth/login_screen.dart';
import 'services/auth_state.dart';
import 'services/background_sync.dart';
import 'screens/auth/register_screen.dart';
import 'screens/chat/chat_sessions_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/documents/documents_screen.dart';
import 'screens/media/media_screen.dart';
import 'screens/todos/todos_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'services/media_service.dart';
import 'theme/cixio_theme.dart';
import 'widgets/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load the bundled `.env` before anything reads AppConfig (API base URL,
  // SNS credentials, the presign upload Lambda URL).
  await _loadEnvironment();
  await Firebase.initializeApp();
  // Pre-load auth state so GoRouter can redirect synchronously (no blank flash).
  await authNotifier.initialize();
  // Register the OS background-upload dispatcher before scheduling any task.
  await BackgroundUploadSync.initialize();
  runApp(const CixioHubApp());
  // Notification setup must never block the first frame.
  unawaited(_initNotifications());
  // Prime the local media queue and start the periodic S3 sync timer.
  unawaited(MediaService.instance.init());
}

Future<void> _loadEnvironment() async {
  try {
    await dotenv.load();
  } catch (e) {
    // Missing/unreadable `.env` is non-fatal: AppConfig falls back to
    // --dart-define values and hard-coded defaults.
    debugPrint('dotenv load failed, using dart-defines/defaults: $e');
  }
}

Future<void> _initNotifications() async {
  try {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await NotificationService.initialize(
      onForegroundMessage: (message) {
        print("Foreground: ${message.notification?.title}");
      },
      onNotificationClicked: (message) {
        print("Clicked: ${message.data}");
      },
    );
    final deviceToken = await NotificationService.getDeviceToken();
    debugPrint('FCM device token at startup: $deviceToken');
  } catch (e) {
    debugPrint('Notification init failed: $e');
  }
}

final _router = GoRouter(
  initialLocation: '/chat',
  // Synchronous redirect — no async SharedPreferences read on every navigation.
  refreshListenable: authNotifier,
  redirect: (context, state) {
    final isAuthRoute = state.matchedLocation.startsWith('/login') ||
        state.matchedLocation.startsWith('/register');
    // if (!authNotifier.isLoggedIn && !isAuthRoute) return '/login';
    if (authNotifier.isLoggedIn && isAuthRoute) return '/chat';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    // Individual chat session — outside shell so it gets full screen (no bottom nav)
    GoRoute(
      path: '/chat/:sessionId',
      builder: (_, state) =>
          ChatScreen(sessionId: state.pathParameters['sessionId']!),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/chat',
              builder: (_, __) => const ChatSessionsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/documents', builder: (_, __) => const DocumentsScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/media', builder: (_, __) => const MediaScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/todos', builder: (_, __) => const TodosScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          ],
        ),
      ],
    ),
  ],
);

class CixioHubApp extends StatelessWidget {
  const CixioHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CixioHub',
      debugShowCheckedModeBanner: false,
      theme: CixioTheme.light,
      routerConfig: _router,
    );
  }
}
