class AppConfig {
  /// Hardcoded to your actual Windows laptop IP on the Tailscale network
  static const String apiBaseUrl = 'http://100.111.106.78:8000';

  static const String notifyBaseUrl = 'http://100.111.106.78:8001';

  static const String apiVersion = '/api/v1';
  static String get apiUrl => '$apiBaseUrl$apiVersion';
  static String get notifyUrl => '$notifyBaseUrl$apiVersion';
}
