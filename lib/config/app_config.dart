class AppConfig {
  static const String apiBaseUrl = 'http://192.168.1.38:8000';
  static const String notifyBaseUrl = 'http://192.168.1.38:8001';
  static const String apiVersion = '/api/v1';
  static String get apiUrl => '$apiBaseUrl$apiVersion';
  static String get notifyUrl => '$notifyBaseUrl$apiVersion';
}
