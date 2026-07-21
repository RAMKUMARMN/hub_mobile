import 'package:flutter_dotenv/flutter_dotenv.dart';

// lib/config/app_config.dart
class AppConfig {
  // Read from the loaded .env file dynamically, requiring it to be set
  static String get apiBaseUrl {
    final url = dotenv.env['API_BASE_URL'];
    if (url == null || url.trim().isEmpty) {
      throw Exception('❌ Error: API_BASE_URL is missing or empty in your .env file!');
    }
    return url.trim();
  }

  static String get googleClientId => dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
  
  // For different environments
  static bool get isProduction => const bool.fromEnvironment('IS_PRODUCTION', defaultValue: false);
  static bool get isDevelopment => !isProduction;
  
  // API endpoints
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authMe = '/auth/me';
  static const String workspaces = '/workspaces';
  static const String tasks = '/tasks';
  static const String notes = '/notes';
  static const String documents = '/documents';
  static const String aiChat = '/ai/chat';
  static const String aiChats = '/ai/chats';
  static const String aiDailyInsight = '/ai/daily-insight';
  static const String aiWeeklyReport = '/ai/weekly-report';
  static const String search = '/search';
}