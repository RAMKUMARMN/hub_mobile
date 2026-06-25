import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/auth/login_screen.dart';
import 'services/auth_state.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';
import 'screens/auth/register_screen.dart';
import 'screens/chat/chat_sessions_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/documents/documents_screen.dart';
import 'screens/todos/todos_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'theme/cixio_theme.dart';
import 'widgets/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  // Pre-load auth state so GoRouter can redirect synchronously (no blank flash).
  await authNotifier.initialize();
  // Pre-load settings so the correct theme is applied on first frame.
  await settingsNotifier.initialize();
  // Initialize notifications respecting persisted preferences
  await notificationService.initialize();
  runApp(const CixioHubApp());
}

final _router = GoRouter(
  initialLocation: '/chat',
  // Synchronous redirect — no async SharedPreferences read on every navigation.
  refreshListenable: authNotifier,
  redirect: (context, state) {
    final isAuthRoute = state.matchedLocation.startsWith('/login') ||
        state.matchedLocation.startsWith('/register');
    if (!authNotifier.isLoggedIn && !isAuthRoute) return '/login';
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
    // Settings — outside shell so it gets full screen with back navigation
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
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
    return ListenableBuilder(
      listenable: settingsNotifier,
      builder: (context, _) => MaterialApp.router(
        title: 'CixioHub',
        debugShowCheckedModeBanner: false,
        theme: CixioTheme.light,
        darkTheme: CixioTheme.dark,
        themeMode: settingsNotifier.themeMode,
        routerConfig: _router,
      ),
    );
  }
}
