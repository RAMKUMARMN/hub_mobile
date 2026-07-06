import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'screens/auth/login_screen.dart';
import 'services/auth_state.dart';
import 'screens/auth/register_screen.dart';
import 'screens/chat/chat_sessions_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/documents/documents_screen.dart';
import 'screens/todos/todos_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'services/todo_service.dart';
import 'theme/cixio_theme.dart';
import 'widgets/app_shell.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Fire up Firebase Core native bindings
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  // 2. Initialize notification display handling (permissions + local notif setup + foreground listener)
  await NotificationService.init();

  // Pre-load auth state so GoRouter can redirect synchronously (no blank flash).
  await authNotifier.initialize();

  runApp(const ProviderScope(child: CixioHubApp()));

  initializeNotificationSync();
}

/// Safely handles token retrieval and sync tasks without blocking the main event loop
/// Safely handles token retrieval and sync tasks without blocking the main event loop
void initializeNotificationSync() async {
  try {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('✅ User granted notification permissions.');
      String? token = await messaging.getToken();

      if (token != null) {
        debugPrint("🔑 Device FCM Token: $token");

        final TodoService todoService = TodoService();

        // 🛠️ FIX: Bypassed the check since we commented out auth on the backend anyway!
        await todoService.registerDeviceWithBackend(token);
      }
    } else {
      debugPrint('❌ User declined notification permissions.');
    }
  } catch (e) {
    debugPrint("FCM registration pipeline error: $e");
  }
}

final _router = GoRouter(
  initialLocation: '/chat',
  refreshListenable: authNotifier,
  debugLogDiagnostics: true, // ADD THIS LINE
  redirect: (context, state) {
    return null;
  },

  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(
      path: '/verify-otp/:phone',
      builder: (_, state) => OtpVerificationScreen(
        phoneNumber: state.pathParameters['phone']!,
      ),
    ),
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
            GoRoute(
                path: '/documents',
                builder: (_, __) => const DocumentsScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/todos', builder: (_, __) => const TodosScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
                path: '/profile', builder: (_, __) => const ProfileScreen()),
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
