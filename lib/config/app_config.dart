import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Values are resolved in this order:
  //   1. Compile-time define (--dart-define / --dart-define-from-file).
  //   2. The bundled `.env` asset, loaded once at startup (see main.dart).
  //   3. The hard-coded default below.
  //
  // The compile-time constants must stay literal so `String.fromEnvironment`
  // is evaluated by the compiler; the `_resolve` helper picks the winner.
  static const String _apiBaseUrlDefine =
      String.fromEnvironment('API_BASE_URL');
  static const String _notifyBaseUrlDefine =
      String.fromEnvironment('NOTIFY_BASE_URL');
  static const String _awsAccessKeyIdDefine =
      String.fromEnvironment('AWS_ACCESS_KEY_ID');
  static const String _awsSecretAccessKeyDefine =
      String.fromEnvironment('AWS_SECRET_ACCESS_KEY');
  static const String _awsSessionTokenDefine =
      String.fromEnvironment('AWS_SESSION_TOKEN');
  static const String _awsSnsRegionDefine =
      String.fromEnvironment('AWS_SNS_SMS_REGION');
  static const String _awsUploadUrlDefine =
      String.fromEnvironment('AWS_UPLOAD_URL');

  static String _resolve(String define, String envKey, String fallback) {
    if (define.isNotEmpty) return define;
    if (dotenv.isInitialized) {
      final value = dotenv.maybeGet(envKey);
      if (value != null && value.isNotEmpty) return value;
    }
    return fallback;
  }

  /// Backend API base URL.
  /// iOS Simulator shares the Mac's network stack → localhost works.
  /// Android Emulator: use http://10.0.2.2:8090
  static String get apiBaseUrl =>
      _resolve(_apiBaseUrlDefine, 'API_BASE_URL', 'http://localhost:8090');

  static String get notifyBaseUrl =>
      _resolve(_notifyBaseUrlDefine, 'NOTIFY_BASE_URL', 'http://localhost:8001');

  // ── AWS SNS (SMS) ──
  // Injected with --dart-define so credentials never live in source control:
  //   flutter run --dart-define=AWS_ACCESS_KEY_ID=... \
  //               --dart-define=AWS_SECRET_ACCESS_KEY=... \
  //               --dart-define=AWS_SNS_SMS_REGION=ap-south-1
  static String get awsAccessKeyId =>
      _resolve(_awsAccessKeyIdDefine, 'AWS_ACCESS_KEY_ID', '');

  static String get awsSecretAccessKey =>
      _resolve(_awsSecretAccessKeyDefine, 'AWS_SECRET_ACCESS_KEY', '');

  static String get awsSessionToken =>
      _resolve(_awsSessionTokenDefine, 'AWS_SESSION_TOKEN', '');

  static String get awsSnsRegion =>
      _resolve(_awsSnsRegionDefine, 'AWS_SNS_SMS_REGION', 'ap-south-1');

  /// True when SNS credentials were supplied at build time.
  static bool get hasAwsCredentials =>
      awsAccessKeyId.isNotEmpty && awsSecretAccessKey.isNotEmpty;

  // ── Media uploads (Lambda presigned URLs) ──
  // The app asks a Lambda Function URL for a short-lived presigned PUT URL and
  // uploads straight to S3. No AWS credentials ship in the app for uploads.
  // Set it via either:
  //   flutter run --dart-define=AWS_UPLOAD_URL=https://xxxx.lambda-url...
  // or the bundled `.env`:
  //   AWS_UPLOAD_URL=https://xxxx.lambda-url...
  static String get awsUploadUrl =>
      _resolve(_awsUploadUrlDefine, 'AWS_UPLOAD_URL', '');

  /// True when the presign Lambda Function URL was supplied at build time or
  /// via the bundled `.env`.
  static bool get hasUploadUrl => awsUploadUrl.isNotEmpty;

  static const String apiVersion = '/api/v1';
  static String get apiUrl => '$apiBaseUrl$apiVersion';
  static String get notifyUrl => '$notifyBaseUrl$apiVersion';
}
