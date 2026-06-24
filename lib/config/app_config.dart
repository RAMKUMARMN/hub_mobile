// lib/config/app_config.dart
class AppConfig {
  // Change this to your computer's IP when testing on physical device
  // For emulator: 10.0.2.2:8000
  // For same computer: localhost:8000
  // For physical device: Your computer's IP (e.g., 192.168.1.100:8000)
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.86.255.19:8000',  // Change this to your backend URL// For emulator (Android Virtual Device): defaultValue: 'http://10.0.2.2:8000', defaultValue: 'http://192.168.1.100:8000',  // Find your IP with 'ipconfig',defaultValue: 'http://localhost:8000',
  );
  
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