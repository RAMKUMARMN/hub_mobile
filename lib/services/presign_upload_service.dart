import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/media_item.dart';

/// Raised when obtaining a presigned URL or uploading to it fails.
class PresignUploadException implements Exception {
  final String message;
  final int? statusCode;

  const PresignUploadException(this.message, {this.statusCode});

  @override
  String toString() =>
      statusCode == null ? message : '$message (HTTP $statusCode)';
}

/// A single presigned part of a multipart upload.
typedef MultipartPart = ({int partNumber, String url});

/// The backend's handling of an upload request.
typedef _PresignPlan = ({
  String mode,
  String? uploadId,
  String? key,
  String? singleUrl,
  List<MultipartPart> parts,

  /// Exact `x-amz-tagging` string the backend signed the URL for, if any.
  String? signedTagging,
});

/// Uploads a file to S3 (and deletes objects) through a backend that issues
/// **presigned URLs**.
///
/// The app never holds AWS credentials: it asks the backend (an AWS Lambda
/// Function URL) for short-lived presigned URLs, then PUTs the file bytes
/// straight to S3. Has no Flutter UI dependencies, so it also runs from the
/// background sync isolate.
///
/// Small files use a single presigned PUT. Files larger than
/// [multipartThreshold] are uploaded with S3 **multipart upload**: the backend
/// hands back one presigned URL per part, each part is PUT independently, and
/// the upload is finalised with a complete call.
///
/// Deletion ([deleteObject]) is also routed through the backend, which issues
/// the `DeleteObject` call to S3 on the app's behalf.
class PresignUploadService {
  PresignUploadService({
    required this.endpoint,
    this.multipartThreshold = defaultMultipartThreshold,
    this.partSize = defaultPartSize,
  });

  /// Lambda Function URL that returns presigned URLs for the given file.
  final String endpoint;

  /// Files strictly larger than this many bytes use multipart upload.
  final int multipartThreshold;

  /// Target size of each multipart part. S3 requires every part except the
  /// last to be at least [_minPartSize] bytes.
  final int partSize;

  /// Default cutoff above which multipart upload is used (100 MiB).
  static const int defaultMultipartThreshold = 100 * 1024 * 1024;

  /// Default target part size (10 MiB).
  static const int defaultPartSize = 10 * 1024 * 1024;

  /// S3 minimum size for every part except the last (5 MiB).
  static const int _minPartSize = 5 * 1024 * 1024;

  /// S3 maximum number of parts in a single multipart upload.
  static const int _maxParts = 10000;

  /// Requests presigned URL(s) for [fileName] and uploads [file].
  ///
  /// [mediaTypeTag] is sent to the backend as `mediaType` so it can set S3
  /// object tags / metadata. If omitted, it is derived from [contentType]
  /// via [MediaType.fromMimeType].
  ///
  /// [tags] is sent to the backend as a JSON object (so the presigned URL
  /// signature covers `x-amz-tagging`) and is also URL-encoded into the
  /// `x-amz-tagging` header on the direct S3 PUT. Defaults to
  /// `MediaType=<mediaTypeTag>` + `Environment=Production`.
  ///
  /// [metadata] is attached on the direct S3 PUT as `x-amz-meta-<key>`
  /// headers (lower-cased keys).
  ///
  /// Returns the object key stored in S3.
  Future<String> upload({
    required File file,
    required String fileName,
    String? contentType,
    String? storageClass,
    String? mediaTypeTag,
    Map<String, String>? tags,
    Map<String, String>? metadata,
  }) async {
    final length = await file.length();
    if (length == 0) {
      throw const PresignUploadException('Refusing to upload an empty file.');
    }

    final mime = (contentType == null || contentType.isEmpty)
        ? MediaType.defaultMimeType
        : contentType;
    final tag = mediaTypeTag ?? MediaType.fromMimeType(mime).tag;
    final effectiveTags =
        tags ?? {'MediaType': tag, 'Environment': 'Production'};

    if (length <= multipartThreshold) {
      return _uploadSingle(
        file: file,
        fileName: fileName,
        contentType: mime,
        length: length,
        storageClass: storageClass,
        mediaTypeTag: tag,
        tags: effectiveTags,
        metadata: metadata,
      );
    }

    return _uploadMultipart(
      file: file,
      fileName: fileName,
      contentType: mime,
      length: length,
      storageClass: storageClass,
      mediaTypeTag: tag,
      tags: effectiveTags,
      metadata: metadata,
    );
  }

  /// Deletes the S3 object at [objectKey] via the backend.
  ///
  /// The backend issues the `DeleteObject` call to S3 and replies `200`; the
  /// response body is intentionally ignored. Throws [PresignUploadException] if
  /// the backend does not confirm the deletion.
  ///
  /// Contract:
  ///   POST {endpoint}
  ///   {"action": "DELETE", "objectKey": "<key>"}
  ///   -> 200 {"message": "Object deleted successfully", "objectKey": "<key>"}
  Future<void> deleteObject({required String objectKey}) async {
    if (objectKey.isEmpty) {
      throw const PresignUploadException('Missing object key for delete.');
    }
    await _postJson({'action': 'DELETE', 'objectKey': objectKey});
  }

  // ── Single-part path ──

  /// Asks the backend for one presigned PUT URL and uploads the whole file.
  Future<String> _uploadSingle({
    required File file,
    required String fileName,
    required String contentType,
    required int length,
    String? storageClass,
    String? mediaTypeTag,
    Map<String, String>? tags,
    Map<String, String>? metadata,
  }) async {
    final plan = await _requestPresign({
      'action': 'SINGLE',
      'fileName': fileName,
      if (contentType.isNotEmpty) 'mimeType': contentType,
      if (storageClass != null) 'storageClass': storageClass,
      if (mediaTypeTag != null) 'mediaType': mediaTypeTag,
      if (tags != null && tags.isNotEmpty) 'tags': tags,
      if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
    });
    final url = plan.singleUrl;
    if (url == null || url.isEmpty) {
      throw const PresignUploadException(
        'Presign response did not include an upload URL.',
      );
    }
    await _put(
      file: file,
      url: url,
      contentType: contentType,
      amzTagging: _signedTagging(plan),
      metadata: metadata,
    );
    return plan.key ?? _keyFromUrl(url);
  }

  /// The `x-amz-tagging` string to attach, or `null` when the backend did
  /// not sign the presigned URL for that header (attaching it unsigned
  /// makes S3 reject the request with SignatureDoesNotMatch).
  static String? _signedTagging(_PresignPlan plan) =>
      (plan.signedTagging != null && plan.signedTagging!.isNotEmpty)
          ? plan.signedTagging
          : null;

  // ── Multipart path ──

  /// Uploads [file] in parts and finalises the S3 multipart upload.
  Future<String> _uploadMultipart({
    required File file,
    required String fileName,
    required String contentType,
    required int length,
    String? storageClass,
    String? mediaTypeTag,
    Map<String, String>? tags,
    Map<String, String>? metadata,
  }) async {
    final size = _computePartSize(length);
    final totalParts = (length + size - 1) ~/ size;

    final plan = await _requestPresign({
      'action': 'MULTIPART_INITIATE',
      'fileName': fileName,
      if (contentType.isNotEmpty) 'mimeType': contentType,
      'size': length,
      'totalParts': totalParts,
      if (storageClass != null) 'storageClass': storageClass,
      if (mediaTypeTag != null) 'mediaType': mediaTypeTag,
      if (tags != null && tags.isNotEmpty) 'tags': tags,
      if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
    });

    // The backend may still answer with a single URL (e.g. a lower limit);
    // honour it rather than failing the upload.
    if (plan.mode != 'MULTIPART' || plan.parts.isEmpty) {
      final url = plan.singleUrl ?? plan.parts.firstOrNull?.url;
      if (url == null || url.isEmpty) {
        throw const PresignUploadException(
          'Multipart initiate response did not include any part URLs.',
        );
      }
      await _put(
        file: file,
        url: url,
        contentType: contentType,
        amzTagging: _signedTagging(plan),
        metadata: metadata,
      );
      return plan.key ?? _keyFromUrl(url);
    }

    final uploadId = plan.uploadId;
    final key = plan.key;
    if (uploadId == null || uploadId.isEmpty || key == null || key.isEmpty) {
      throw const PresignUploadException(
        'Multipart initiate response was missing uploadId/objectKey.',
      );
    }

    final parts = List<MultipartPart>.of(plan.parts)
      ..sort((a, b) => a.partNumber.compareTo(b.partNumber));

    final completed = <Map<String, Object>>[];
    for (final part in parts) {
      final start = (part.partNumber - 1) * size;
      final end = start + size > length ? length : start + size;
      // Object tags are set at multipart initiation (the backend passes
      // `Tagging` to CreateMultipartUpload); per-part PUTs must NOT carry
      // x-amz-tagging or S3 rejects the signature.
      final etag = await _put(
        file: file,
        url: part.url,
        contentType: contentType,
        start: start,
        end: end,
      );
      // S3's complete call expects `PartNumber`/`ETag` (case-sensitive).
      completed.add({'PartNumber': part.partNumber, 'ETag': etag});
    }

    await _requestPresign({
      'action': 'MULTIPART_COMPLETE',
      'uploadId': uploadId,
      'objectKey': key,
      'parts': completed,
    });
    return key;
  }

  /// Picks a part size that stays within S3's part-count limit and never drops
  /// below the 5 MiB minimum.
  int _computePartSize(int length) {
    var size = partSize < _minPartSize ? _minPartSize : partSize;
    final minForMaxParts = (length + _maxParts - 1) ~/ _maxParts;
    if (minForMaxParts > size) size = minForMaxParts;
    return size;
  }

  /// Calls the backend and parses its upload plan (single URL or multipart).
  ///
  /// Contract (the presign Lambda Function URL):
  ///   Single:
  ///     POST {endpoint}
  ///     {"action": "SINGLE", "fileName": "<name>", "mimeType": "<mime>",
  ///      "mediaType": "Photo", "tags": {"MediaType": "Photo",
  ///      "Environment": "Production"}}
  ///     -> 200 {"mode": "SINGLE", "presignedUrl": "<url>", "objectKey": "<key>",
  ///             "taggingString": "MediaType=Photo&Environment=Production"}
  ///     (`taggingString` is the exact x-amz-tagging value the URL was
  ///      signed for and must be echoed back as the header)
  ///   Multipart initiate:
  ///     POST {endpoint}
  ///     {"action": "MULTIPART_INITIATE", "fileName": "...", "mimeType": "...",
  ///      "mediaType": "...", "tags": {...},
  ///      "size": <bytes>, "totalParts": <n>}
  ///     -> 200 {"mode": "MULTIPART", "uploadId": "...", "objectKey": "...",
  ///             "parts": [{"partNumber": 1, "url": "..."}, ...]}
  ///   Multipart complete:
  ///     POST {endpoint}
  ///     {"action": "MULTIPART_COMPLETE", "uploadId": "...",
  ///      "objectKey": "...", "parts": [{"PartNumber": 1, "ETag": "..."}, ...]}
  Future<_PresignPlan> _requestPresign(Map<String, Object?> payload) async {
    return _parsePlan(await _postJson(payload));
  }

  /// POSTs [payload] as JSON to the backend and returns the decoded body.
  ///
  /// Shared by the upload presign calls and [deleteObject]. Throws
  /// [PresignUploadException] on a non-2xx status or invalid JSON.
  Future<Map<String, dynamic>> _postJson(Map<String, Object?> payload) async {
    final uri = Uri.parse(endpoint);
    final payloadBytes = utf8.encode(jsonEncode(payload));

    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.contentType = ContentType.json;
      request.contentLength = payloadBytes.length;
      request.add(payloadBytes);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw PresignUploadException(
          'Presign request failed'
          '${body.isEmpty ? '' : ': ${_extractError(body)}'}',
          statusCode: response.statusCode,
        );
      }

      if (body.trim().isEmpty) return const {};
      try {
        return jsonDecode(body) as Map<String, dynamic>;
      } catch (_) {
        throw const PresignUploadException(
          'Presign response was not valid JSON.',
        );
      }
    } finally {
      client.close(force: true);
    }
  }

  static _PresignPlan _parsePlan(Map<String, dynamic> json) {
    final mode = (json['mode'] as String?)?.toUpperCase() ?? 'SINGLE';

    final singleUrl = _firstString(
      json,
      const ['url', 'uploadUrl', 'uploadURL', 'presignedUrl'],
    );

    final rawParts = json['parts'];
    final parts = <MultipartPart>[];
    if (rawParts is List) {
      for (final entry in rawParts) {
        if (entry is! Map) continue;
        final partNumber =
            _firstInt(entry, const ['partNumber', 'PartNumber', 'number']);
        final url =
            _firstString(entry, const ['url', 'uploadUrl', 'presignedUrl']);
        if (partNumber != null && url != null) {
          parts.add((partNumber: partNumber, url: url));
        }
      }
    }

    final key = _firstString(
          json,
          const ['key', 'Key', 'objectKey', 'fileName'],
        ) ??
        (singleUrl != null ? _keyFromUrl(singleUrl) : null);

    // The exact x-amz-tagging string the backend signed the URL for, if any.
    // It must be echoed back verbatim on the PUT (case/value sensitive).
    final signedTagging = _firstString(
        json, const ['taggingString', 'signedTagging', 'xAmzTagging']);

    return (
      mode: mode,
      uploadId: _firstString(json, const ['uploadId', 'UploadId']),
      key: key,
      singleUrl: singleUrl,
      parts: parts,
      signedTagging: signedTagging,
    );
  }

  /// PUTs bytes to a presigned URL and returns the response `ETag` (empty for
  /// single uploads, which have no per-part ETag to report).
  Future<String> _put({
    required File file,
    required String url,
    required String contentType,
    int? start,
    int? end,
    String? amzTagging,
    Map<String, String>? metadata,
  }) async {
    final Uri uri = Uri.parse(url);
    final http.Request request = http.Request('PUT', uri);

    // 1. Content-Type Header — always set to the exact mimeType.
    request.headers['content-type'] = contentType;

    // 2. Object tags → URL-encoded "MediaType=Photo&Environment=Production"
    //    attached as x-amz-tagging BEFORE the request is sent.
    //    Only provided when the presigned URL was signed for this header;
    //    an unsigned x-amz-tagging makes S3 return SignatureDoesNotMatch.
    if (amzTagging != null && amzTagging.isNotEmpty) {
      request.headers['x-amz-tagging'] = amzTagging;
    }

    // 3. Custom metadata → x-amz-meta-<key> (keys lower-cased).
    //    The presigner typically hoists metadata into the URL query string
    //    (x-amz-meta-...=...&...). In that case S3 rejects the request with
    //    "headers present which were not signed" if we ALSO send them as
    //    headers, so only attach them when the URL does not already carry
    //    them (i.e. the backend signed them as headers instead).
    final metaInQuery = uri.queryParameters.keys
        .any((k) => k.toLowerCase().startsWith('x-amz-meta-'));
    if (!metaInQuery && metadata != null && metadata.isNotEmpty) {
      metadata.forEach((key, value) {
        final k = key.trim().toLowerCase();
        final v = value.trim();
        if (k.isEmpty || v.isEmpty) return;
        request.headers['x-amz-meta-$k'] = v;
      });
    }

    // 4. Attach body and send.
    final List<int> bodyBytes;
    if (start != null && end != null) {
      // Read the specific byte range for a multipart part upload.
      final raf = await file.open();
      try {
        await raf.setPosition(start);
        bodyBytes = await raf.read(end - start);
      } finally {
        await raf.close();
      }
    } else {
      bodyBytes = await file.readAsBytes();
    }

    request.bodyBytes = bodyBytes;

    final http.StreamedResponse streamedResponse = await request.send();
    final http.Response response =
        await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PresignUploadException(
        'S3 upload failed'
        '${response.body.isEmpty ? '' : ': ${_extractError(response.body)}'}',
        statusCode: response.statusCode,
      );
    }

    // Return ETag from response headers (needed by multipart complete).
    return response.headers['etag'] ?? '';
  }

  static String? _firstString(Map json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  static int? _firstInt(Map json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  /// Derives the object key from a presigned URL's path (used when the backend
  /// does not return it explicitly).
  static String _keyFromUrl(String url) {
    final path = Uri.parse(url).path;
    return Uri.decodeComponent(path.startsWith('/') ? path.substring(1) : path);
  }

  /// Pulls the human-readable reason out of an XML or JSON error response.
  static String _extractError(String body) {
    final msg = RegExp(r'<Message>([^<]+)</Message>', caseSensitive: false)
        .firstMatch(body);
    if (msg != null) return msg.group(1)!;
    final code =
        RegExp(r'<Code>([^<]+)</Code>', caseSensitive: false).firstMatch(body);
    if (code != null) return code.group(1)!;
    final jsonMsg = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(body);
    return jsonMsg?.group(1) ?? body;
  }
}
