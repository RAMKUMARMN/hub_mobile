import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'aws_sns_sms_service.dart';

/// Result of an SMS send attempt, so the UI can report success or failure.
class SmsResult {
  final bool success;
  final String message;

  const SmsResult.success(this.message) : success = true;
  const SmsResult.failure(this.message) : success = false;
}

/// Sends a test SMS through the AWS SNS SMS sandbox.
///
/// The destination number is never typed by hand: it is resolved from the
/// account's sandbox (see [resolveSandboxNumber]) or, failing that, from the
/// phone number registered on the logged-in user.
class SmsService {
  SmsService({AwsSnsSmsService? sns}) : _override = sns;

  final AwsSnsSmsService? _override;

  AwsSnsSmsService get _sns => _override ?? AwsSnsSmsService(
        accessKeyId: AppConfig.awsAccessKeyId,
        secretAccessKey: AppConfig.awsSecretAccessKey,
        sessionToken:
            AppConfig.awsSessionToken.isEmpty ? null : AppConfig.awsSessionToken,
        region: AppConfig.awsSnsRegion,
      );

  bool get _configured => _override != null || AppConfig.hasAwsCredentials;

  /// Picks the destination number to send to.
  ///
  /// Prefers the logged-in user's number when it is verified in the sandbox;
  /// otherwise falls back to the single verified sandbox number. Returns null
  /// when nothing usable is registered.
  Future<({String phone, String source})?> resolveSandboxNumber({
    String? userPhone,
  }) async {
    final numbers = await _sns.listSandboxPhoneNumbers();
    final verified =
        numbers.where((n) => n.isVerified).map((n) => n.phoneNumber).toList();

    if (verified.isEmpty) {
      final pending =
          numbers.where((n) => !n.isVerified).map((n) => n.phoneNumber).toList();
      if (pending.isNotEmpty) {
        throw SnsException(
          'Sandbox has ${pending.length} number(s) still pending verification: '
          '${pending.join(', ')}. Verify them in the AWS console first.',
        );
      }
      throw const SnsException(
        'No destination numbers are registered in the SNS sandbox. '
        'Add and verify one in the AWS console first.',
      );
    }

    final candidate = (userPhone ?? '').trim();
    if (candidate.isNotEmpty && verified.contains(candidate)) {
      return (phone: candidate, source: 'your registered number');
    }
    if (verified.length == 1) {
      return (phone: verified.single, source: 'the sandbox number');
    }
    // Multiple verified numbers and no match on the user's profile — pick the
    // first rather than prompting, per the "no manual entry" requirement.
    return (phone: verified.first, source: 'the first sandbox number');
  }

  /// Sends [message] to [phone] via SNS.
  Future<SmsResult> sendSms({
    required String phone,
    required String message,
  }) async {
    if (!_configured) {
      return const SmsResult.failure(
        'AWS credentials not configured. Rebuild with '
        '--dart-define=AWS_ACCESS_KEY_ID=... --dart-define=AWS_SECRET_ACCESS_KEY=...',
      );
    }
    if (phone.trim().isEmpty) {
      return const SmsResult.failure('No destination phone number resolved.');
    }

    try {
      final messageId = await _sns.publishSms(
        phoneNumber: phone.trim(),
        message: message,
      );
      return SmsResult.success('SMS sent to $phone. MessageId: $messageId');
    } on SnsException catch (e) {
      return SmsResult.failure(e.toString());
    } on DioException catch (e) {
      return SmsResult.failure('Connection failed: ${e.message}');
    } catch (e) {
      return SmsResult.failure('Unexpected error: $e');
    }
  }
}

/// Legacy helper kept for the previous Twilio-style flow.
Future<SmsResult> triggerSmsNotification({
  required String userPhoneNumber,
  required String textMessage,
}) async {
  final dio = Dio();
  const url = 'http://localhost:3000/api/send-sms';

  try {
    final response = await dio.post(
      url,
      data: {'phoneNumber': userPhoneNumber, 'message': textMessage},
    );
    if (response.statusCode == 200) {
      return SmsResult.success('SMS sent. MessageId: ${response.data['messageId']}');
    }
    return SmsResult.failure(
        'Server returned ${response.statusCode} - ${response.data}');
  } on DioException catch (e) {
    if (e.response != null) {
      return SmsResult.failure(
          'Backend error ${e.response?.statusCode} - ${e.response?.data}');
    }
    return SmsResult.failure(
        'Connection failed. Is the SMS server running? ${e.message}');
  }
}