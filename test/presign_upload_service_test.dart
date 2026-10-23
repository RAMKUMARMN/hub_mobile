import 'dart:convert';
import 'dart:io';

import 'package:cixiohub_mobile/services/presign_upload_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpServer server;
  late Directory tempDir;

  /// Records the presign actions the backend received, in order.
  late List<String> actions;

  /// Bytes received per uploaded part number.
  late Map<int, int> partSizes;

  /// The `parts` payload sent to the complete call.
  late List<dynamic>? completedParts;

  /// Object keys received by DELETE requests, in order.
  late List<String> deletedKeys;

  /// `x-amz-tagging` header seen on the single-object PUT.
  late String? singlePutTagging;

  /// `x-amz-tagging` header seen on each multipart part PUT.
  late Map<int, String?> partTaggings;

  /// `x-amz-meta-*` header names seen on the single-object PUT.
  late List<String> singlePutMetaHeaders;

  /// Body of the most recent SINGLE presign request.
  late Map<String, dynamic>? lastSinglePayload;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    actions = [];
    partSizes = {};
    completedParts = null;
    deletedKeys = [];
    singlePutTagging = null;
    partTaggings = {};
    singlePutMetaHeaders = [];
    lastSinglePayload = null;
    tempDir = Directory.systemTemp.createTempSync('presign_test');

    server.listen((request) async {
      final path = request.uri.path;
      if (path == '/presign') {
        final payload = jsonDecode(await utf8.decoder.bind(request).join())
            as Map<String, dynamic>;
        final action = payload['action'] as String? ?? 'SINGLE';
        actions.add(action);
        request.response.headers.contentType = ContentType.json;

        if (action == 'MULTIPART_INITIATE') {
          final total = payload['totalParts'] as int;
          request.response.write(jsonEncode({
            'mode': 'MULTIPART',
            'uploadId': 'upload-1',
            'objectKey': 'testing/user1/file.bin',
            'parts': [
              for (var i = 1; i <= total; i++)
                {
                  'partNumber': i,
                  'url': 'http://127.0.0.1:${server.port}/part/$i',
                },
            ],
          }));
        } else if (action == 'MULTIPART_COMPLETE') {
          completedParts = payload['parts'] as List<dynamic>?;
          request.response
              .write(jsonEncode({'message': 'Multipart upload completed'}));
        } else if (action == 'DELETE') {
          final objectKey = payload['objectKey'] as String?;
          if (objectKey != null) deletedKeys.add(objectKey);
          request.response.write(jsonEncode({
            'message': 'Object deleted successfully',
            'objectKey': objectKey ?? '',
          }));
        } else {
          lastSinglePayload = payload;
          // Mirrors the real Lambda: sign x-amz-tagging when tags were sent.
          String? taggingString;
          final tags = payload['tags'];
          if (tags is Map && tags.isNotEmpty) {
            taggingString = tags.entries
                .map((e) =>
                    '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
                .join('&');
          }
          // Mirrors the real Lambda: metadata is hoisted into the URL query.
          final metadata = payload['metadata'];
          final metaQuery = <String, String>{};
          if (metadata is Map) {
            metadata.forEach((k, v) {
              metaQuery['x-amz-meta-$k'] = v.toString();
            });
          }
          final objectUri = Uri.parse(
              'http://127.0.0.1:${server.port}/object')
              .replace(queryParameters: metaQuery.isEmpty ? null : metaQuery);
          request.response.write(jsonEncode({
            'mode': 'SINGLE',
            'presignedUrl': objectUri.toString(),
            'objectKey': 'testing/user1/file.bin',
            if (taggingString != null) 'taggingString': taggingString,
          }));
        }
      } else if (path.startsWith('/part/')) {
        final partNumber = int.parse(request.uri.pathSegments.last);
        partTaggings[partNumber] = request.headers.value('x-amz-tagging');
        var size = 0;
        await for (final chunk in request) {
          size += chunk.length;
        }
        partSizes[partNumber] = size;
        request.response.statusCode = 200;
        request.response.headers.set('ETag', '"etag-$partNumber"');
      } else {
        singlePutTagging = request.headers.value('x-amz-tagging');
        singlePutMetaHeaders = [];
        request.headers.forEach((name, values) {
          if (name.toLowerCase().startsWith('x-amz-meta-')) {
            singlePutMetaHeaders.add(name);
          }
        });
        await request.drain<void>();
        request.response.statusCode = 200;
        request.response.headers.set('ETag', '"single-etag"');
      }
      await request.response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
    tempDir.deleteSync(recursive: true);
  });

  PresignUploadService service(
      {int threshold = 0, int partSize = 5 * 1024 * 1024}) {
    return PresignUploadService(
      endpoint: 'http://127.0.0.1:${server.port}/presign',
      multipartThreshold: threshold,
      partSize: partSize,
    );
  }

  File writeFile(int bytes) {
    final file = File('${tempDir.path}/file.bin')
      ..writeAsBytesSync(List<int>.filled(bytes, 0));
    return file;
  }

  test('large file uploads via multipart and completes', () async {
    const minPart = 5 * 1024 * 1024;
    final file = writeFile(6 * 1024 * 1024);

    final key = await service().upload(
      file: file,
      fileName: 'file.bin',
      contentType: 'application/octet-stream',
    );

    expect(key, 'testing/user1/file.bin');
    expect(actions, ['MULTIPART_INITIATE', 'MULTIPART_COMPLETE']);
    expect(partSizes, {1: minPart, 2: 1024 * 1024});
    expect(completedParts, [
      {'PartNumber': 1, 'ETag': '"etag-1"'},
      {'PartNumber': 2, 'ETag': '"etag-2"'},
    ]);
    // Object tags are set at multipart initiation; part PUTs must not
    // carry an unsigned x-amz-tagging header.
    expect(partTaggings, {1: null, 2: null});
  });

  test('file at or below threshold uses a single PUT', () async {
    final file = writeFile(1024);

    final key = await service(threshold: 10 * 1024 * 1024).upload(
      file: file,
      fileName: 'file.bin',
      contentType: 'application/octet-stream',
    );

    expect(key, 'testing/user1/file.bin');
    expect(actions, ['SINGLE']);
    expect(partSizes, isEmpty);
    // The backend signed the URL for x-amz-tagging (taggingString) and the
    // client must echo that exact header back on the PUT.
    expect(singlePutTagging, 'MediaType=Photo&Environment=Production');
  });

  test('does not attach x-amz-tagging when the backend did not sign it',
      () async {
    // Backend that signs without tagging support (no taggingString).
    final plain = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    plain.listen((request) async {
      await request.drain<void>();
      request.response.statusCode = 200;
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path == '/presign') {
        request.response.write(jsonEncode({
          'mode': 'SINGLE',
          'presignedUrl': 'http://127.0.0.1:${plain.port}/object',
          'objectKey': 'testing/user1/file.bin',
        }));
      } else {
        singlePutTagging = request.headers.value('x-amz-tagging');
        request.response.headers.set('ETag', '"etag"');
      }
      await request.response.close();
    });
    addTearDown(() => plain.close(force: true));

    final file = writeFile(1024);
    final plainService = PresignUploadService(
      endpoint: 'http://127.0.0.1:${plain.port}/presign',
      multipartThreshold: 10 * 1024 * 1024,
    );

    final key = await plainService.upload(
      file: file,
      fileName: 'file.bin',
      contentType: 'application/octet-stream',
    );

    expect(key, 'testing/user1/file.bin');
    expect(singlePutTagging, isNull);
  });

  test('metadata is sent to the backend and not attached as headers',
      () async {
    final file = writeFile(1024);

    final key = await service(threshold: 10 * 1024 * 1024).upload(
      file: file,
      fileName: 'file.bin',
      contentType: 'application/octet-stream',
      metadata: {'media-id': 'abc', 'media-type': 'Photo'},
    );

    expect(key, 'testing/user1/file.bin');
    // Metadata reached the presign payload.
    expect(lastSinglePayload?['metadata'], {
      'media-id': 'abc',
      'media-type': 'Photo',
    });
    // The presigned URL already carries x-amz-meta-* in its query string,
    // so the client must NOT also send them as (unsigned) headers.
    expect(singlePutMetaHeaders, isEmpty);
  });

  test('presign failure surfaces the backend error', () async {
    final failing = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    failing.listen((request) async {
      await request.drain<void>();
      request.response
        ..statusCode = 403
        ..write(
            '<Error><Code>AccessDenied</Code><Message>Nope</Message></Error>');
      await request.response.close();
    });
    addTearDown(() => failing.close(force: true));

    final file = writeFile(1024);
    final failingService = PresignUploadService(
      endpoint: 'http://127.0.0.1:${failing.port}/presign',
      multipartThreshold: 10 * 1024 * 1024,
    );

    expect(
      () => failingService.upload(
        file: file,
        fileName: 'file.bin',
        contentType: 'application/octet-stream',
      ),
      throwsA(
        isA<PresignUploadException>()
            .having((e) => e.statusCode, 'statusCode', 403)
            .having((e) => e.message, 'message', contains('Nope')),
      ),
    );
  });

  group('deleteObject', () {
    test('sends a DELETE action with the object key', () async {
      await service().deleteObject(objectKey: 'testing/user1/file.pdf');

      expect(actions, ['DELETE']);
      expect(deletedKeys, ['testing/user1/file.pdf']);
    });

    test('propagates a backend failure', () async {
      final failing = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      failing.listen((request) async {
        await request.drain<void>();
        request.response
          ..statusCode = 500
          ..write('{"error":"Access denied"}');
        await request.response.close();
      });
      addTearDown(() => failing.close(force: true));

      final failingService = PresignUploadService(
        endpoint: 'http://127.0.0.1:${failing.port}/presign',
      );

      expect(
        () => failingService.deleteObject(objectKey: 'testing/user1/file.pdf'),
        throwsA(
          isA<PresignUploadException>()
              .having((e) => e.statusCode, 'statusCode', 500)
              .having((e) => e.message, 'message', contains('Access denied')),
        ),
      );
    });

    test('requires a non-empty object key', () async {
      expect(
        () => service().deleteObject(objectKey: ''),
        throwsA(isA<PresignUploadException>()),
      );
    });
  });
}
