class AppConfig {
  /// Backend API base URL.
  /// iOS Simulator shares the Mac's network stack → localhost works.
  /// Android Emulator: use http://10.0.2.2:8090
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8090',
  );

  static const String notifyBaseUrl = String.fromEnvironment(
    'NOTIFY_BASE_URL',
    defaultValue: 'http://localhost:8001',
  );

  static const String apiVersion = '/api/v1';
  static String get apiUrl => '$apiBaseUrl$apiVersion';
  static String get notifyUrl => '$notifyBaseUrl$apiVersion';
}
