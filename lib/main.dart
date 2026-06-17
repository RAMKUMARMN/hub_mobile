// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'dart:convert';
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
import 'services/local/notification_service.dart';

/// Migration function to convert old Reminder data to new Task format
Future<void> _migrateData() async {
  final prefs = await SharedPreferences.getInstance();
  final migrated = prefs.getBool('data_migrated_v2') ?? false;
  
  if (migrated) return;
  
  debugPrint('Running data migration v2...');
  
  try {
    // Check for old Reminder items and convert to Tasks with reminders
    final allItemsJson = prefs.getString('all_workspace_items');
    if (allItemsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(allItemsJson);
      bool changes = false;
      
      decoded.forEach((workspaceId, itemsJson) {
        final items = itemsJson as List;
        for (var i = 0; i < items.length; i++) {
          final item = items[i];
          // If it's a reminder (has reminderTime field), convert to task
          if (item.containsKey('reminderTime')) {
            final convertedTask = {
              'id': item['id'],
              'workspaceId': item['workspaceId'],
              'title': item['title'],
              'subtitle': item['subtitle'],
              'icon': item['icon'],
              'description': '',
              'priority': 1,  // medium
              'status': item['isCompleted'] == true ? 2 : 0,  // completed or pending
              'dueDate': null,
              'reminderAt': item['reminderTime'],
              'reminderEnabled': true,
              'reminderCompleted': item['isCompleted'] ?? false,
              'createdAt': item['createdAt'],
              'updatedAt': item['updatedAt'],
            };
            items[i] = convertedTask;
            changes = true;
            debugPrint('Migrated reminder: ${item['title']}');
          }
        }
      });
      
      if (changes) {
        await prefs.setString('all_workspace_items', jsonEncode(decoded));
        debugPrint('Migration completed successfully!');
      } else {
        debugPrint('No reminders found to migrate.');
      }
    }
    
    // Mark migration as complete
    await prefs.setBool('data_migrated_v2', true);
  } catch (e) {
    debugPrint('Migration error: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  print('✅ Firebase initialized');
  
  // Check current Firebase user (using alias)
  final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
  print('Current Firebase user: ${firebaseUser?.email ?? "none"}');
  
  // Initialize notifications
  await NotificationService().initialize();
  
  // Run migration
  await _migrateData();
  
  runApp(const CixioHubApp());
}

class CixioHubApp extends StatelessWidget {
  const CixioHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(
          create: (context) {
            final authProvider = AuthProvider();
            final appState = Provider.of<AppState>(context, listen: false);
            final workspaceProvider = Provider.of<WorkspaceProvider>(context, listen: false);
            authProvider.setAppState(appState);
            authProvider.setWorkspaceProvider(workspaceProvider); 
            authProvider.setAppState(appState);
            return authProvider;
          },
        ),
        ChangeNotifierProvider(create: (_) => WorkspaceProvider()),
        ChangeNotifierProvider(create: (_) => AIProvider()),
      ],
      child: const SmartHubApp(),
    );
  }
}

class SmartHubApp extends StatelessWidget {
  const SmartHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
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
  }
}