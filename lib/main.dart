// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/auth_provider.dart';
import 'providers/app_state.dart';
import 'providers/theme_provider.dart';
import 'providers/workspace_provider.dart';
import 'providers/ai_provider.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/permission_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/workspace/workspace_screen.dart';
import 'screens/ai/ai_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/notifications/notification_screen.dart';
import 'screens/support/help_screen.dart';
import 'screens/support/privacy_screen.dart';
import 'themes/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/local/notification_service.dart';
import 'services/navigation/navigation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: "assets/app.env");
  } catch (e) {
    debugPrint("Failed to load .env file: $e");
  }
  try {
    final apiKey = dotenv.env['FIREBASE_API_KEY'];
    final appId = dotenv.env['FIREBASE_APP_ID'];
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'];
    final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'];

    if (apiKey != null && appId != null && projectId != null) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: apiKey,
          appId: appId,
          messagingSenderId: messagingSenderId ?? '',
          projectId: projectId,
          authDomain: '$projectId.firebaseapp.com',
          storageBucket: '$projectId.firebasestorage.app',
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }
  runApp(const SmartHubApp());
}

class SmartHubApp extends StatelessWidget {
  const SmartHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // No dependencies - create first
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => WorkspaceProvider()),
        ChangeNotifierProvider(create: (_) => AIProvider()),
        
        // Depends on AppState, WorkspaceProvider, and AIProvider - create last
        ChangeNotifierProvider(
          create: (context) {
            final authProvider = AuthProvider();
            final appState = Provider.of<AppState>(context, listen: false);
            final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
            final aiProvider = Provider.of<AIProvider>(context, listen: false);
            authProvider.setAppState(appState);
            authProvider.setWorkspaceProvider(workspaceProvider);
            authProvider.setAIProvider(aiProvider);
            return authProvider;
          },
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorKey: NavigationService.navigatorKey,
            title: "SmartHub",
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.currentTheme,
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
              '/workspace': (context) => const WorkspaceScreen(),
              '/ai': (context) => const AIScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/calendar': (context) => const CalendarScreen(),
              '/help': (context) => const HelpScreen(),
              '/privacy': (context) => const PrivacyScreen(),
              '/notifications': (context) => const NotificationScreen(),
              '/permission': (context) => const PermissionScreen(),
            },
          );
        },
      ),
    );
  }
}