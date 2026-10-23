import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Thrown when AWS rejects a request or the SMS sandbox is not usable.
class SnsException implements Exception {
  final String message;
  final int? statusCode;

  const SnsException(this.message, {this.statusCode});

  @override
  String toString() => statusCode == null
      ? 'SNS error: $message'
      : 'SNS error $statusCode: $message';
}

/// A destination number registered in the account's SMS sandbox.
class SandboxNumber {
  final String phoneNumber;

  /// 'Verified' or 'Pending'.
  final String status;

  const SandboxNumber(this.phoneNumber, this.status);

  bool get isVerified => status.toLowerCase() == 'verified';

  @override
  String toString() => '$phoneNumber ($status)';
}

/// Minimal AWS SigV4 + SNS client, scoped to the two operations the SMS
/// sandbox test needs: listing verified destination numbers, and publishing.
///
/// Credentials are injected at build time (see AppConfig), never hardcoded.
class AwsSnsSmsService {
  AwsSnsSmsService({
    required this.accessKeyId,
    required this.secretAccessKey,
    required this.region,
    this.sessionToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String accessKeyId;
  final String secretAccessKey;
  final String region;
  final String? sessionToken;
  final http.Client _client;

  static const _service = 'sns';
  static const _apiVersion = '2010-03-31';

  Uri get _endpoint => Uri.parse('https://sns.$region.amazonaws.com/');

  /// Lists every destination number in the SMS sandbox, verified or pending.
  Future<List<SandboxNumber>> listSandboxPhoneNumbers() async {
    final xml = await _call({'Action': 'ListSMSSandboxPhoneNumbers'});

    // Scope to the <PhoneNumbers> container so the result list is parsed even
    // though sibling elements (e.g. NextToken) share the same names.
    final container = RegExp(
      r'<PhoneNumbers>(.*?)</PhoneNumbers>',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(xml);
    final scope = container?.group(1) ?? xml;

    final numbers = <SandboxNumber>[];
    final memberRe = RegExp(
      r'<PhoneNumber>([^<]+)</PhoneNumber>\s*(?:<Status>([^<]*)</Status>)?',
      caseSensitive: false,
    );
    for (final m in memberRe.allMatches(scope)) {
      numbers.add(SandboxNumber(
        _unescape(m.group(1)!.trim()),
        _unescape((m.group(2) ?? '').trim()),
      ));
    }
    return numbers;
  }

  /// Publishes [message] as a transactional SMS to [phoneNumber].
  ///
  /// In the sandbox AWS prefixes the delivered text with a notice, and the
  /// destination must already be verified.
  Future<String> publishSms({
    required String phoneNumber,
    required String message,
  }) async {
    final xml = await _call({
      'Action': 'Publish',
      'Message': message,
      'MessageAttributes.entry.1.Name': 'SMSType',
      'MessageAttributes.entry.1.Value.DataType': 'String',
      'MessageAttributes.entry.1.Value.StringValue': 'Transactional',
      'PhoneNumber': phoneNumber,
    });

    final id =
        RegExp(r'<MessageId>([^<]+)</MessageId>', caseSensitive: false)
            .firstMatch(xml);
    if (id == null) {
      throw const SnsException(
        'Publish returned no MessageId',
      );
    }
    return _unescape(id.group(1)!.trim());
  }

  /// POSTs an AWS Query-protocol request with a SigV4 Authorization header and
  /// returns the raw XML response body.
  Future<String> _call(Map<String, String> params) async {
    final now = DateTime.now().toUtc();
    final amzDate =
        '${_pad(now.year, 4)}${_pad(now.month, 2)}${_pad(now.day, 2)}T'
        '${_pad(now.hour, 2)}:${_pad(now.minute, 2)}:${_pad(now.second, 2)}Z';
    final dateStamp = amzDate.substring(0, 8);

    // Query encoding must be deterministic: SigV4 hashes the exact body sent.
    final body = params.entries
        .followedBy([MapEntry('Version', _apiVersion)])
        .map((e) =>
            '${Uri.encodeComponent(e.key)}='
            '${Uri.encodeComponent(e.value)}')
        .join('&');

    final host = _endpoint.host;
    final canonicalHeaders = <String, String>{
      'host': host,
      'x-amz-date': amzDate,
      if (sessionToken != null && sessionToken!.isNotEmpty)
        'x-amz-security-token': sessionToken!,
    };
    final signedHeaders = (canonicalHeaders.keys.toList()..sort()).join(';');
    final canonicalHeaderBlock =
        canonicalHeaders.entries.map((e) => '${e.key}:${e.value}\n').join();

    final canonicalRequest = [
      'POST',
      '/',
      '',
      canonicalHeaderBlock,
      signedHeaders,
      _sha256Hex(body),
    ].join('\n');

    final credentialScope = '$dateStamp/$region/$_service/aws4_request';
    final stringToSign = [
      'AWS4-HMAC-SHA256',
      amzDate,
      credentialScope,
      _sha256Hex(canonicalRequest),
    ].join('\n');

    final signature =
        _hmacHex(_signingKey(dateStamp), stringToSign);

    final res = await _client
        .post(
          _endpoint,
          headers: {
            'Content-Type':
                'application/x-www-form-urlencoded; charset=utf-8',
            'X-Amz-Date': amzDate,
            if (sessionToken != null && sessionToken!.isNotEmpty)
              'X-Amz-Security-Token': sessionToken!,
            'Authorization': 'AWS4-HMAC-SHA256 '
                'Credential=$accessKeyId/$credentialScope, '
                'SignedHeaders=$signedHeaders, Signature=$signature',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode != 200) {
      throw SnsException(
        _extractError(res.body) ?? res.body,
        statusCode: res.statusCode,
      );
    }
    return res.body;
  }

  List<int> _signingKey(String dateStamp) {
    final kDate = _hmac(utf8.encode('AWS4$secretAccessKey'), dateStamp);
    final kRegion = _hmac(kDate, region);
    final kService = _hmac(kRegion, _service);
    return _hmac(kService, 'aws4_request');
  }

  List<int> _hmac(List<int> key, String data) =>
      Hmac(sha256, key).convert(utf8.encode(data)).bytes;

  String _hmacHex(List<int> key, String data) => _hex(_hmac(key, data));

  String _sha256Hex(String data) =>
      sha256.convert(utf8.encode(data)).toString();

  String _hex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  String _pad(int v, int width) => v.toString().padLeft(width, '0');

  /// Pulls the human-readable reason out of an SNS XML error response.
  String? _extractError(String xml) {
    final msg =
        RegExp(r'<Message>([^<]+)</Message>', caseSensitive: false)
            .firstMatch(xml);
    if (msg != null) return _unescape(msg.group(1)!);
    final code =
        RegExp(r'<Code>([^<]+)</Code>', caseSensitive: false).firstMatch(xml);
    return code == null ? null : _unescape(code.group(1)!);
  }

  String _unescape(String s) => s
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");
}