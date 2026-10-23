import 'package:cixiohub_mobile/services/upload_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('upload completion text', () {
    test('singular', () {
      expect(UploadNotifier.titleForSuccess(1), 'Upload complete');
      expect(
        UploadNotifier.bodyForSuccess(1),
        '1 file was uploaded to the cloud.',
      );
    });

    test('plural', () {
      expect(UploadNotifier.titleForSuccess(3), 'Uploads complete');
      expect(
        UploadNotifier.bodyForSuccess(3),
        '3 files were uploaded to the cloud.',
      );
    });
  });

  group('upload failure text', () {
    test('singular without error', () {
      expect(UploadNotifier.titleForFailure(1), 'Upload failed');
      expect(
        UploadNotifier.bodyForFailure(1, null),
        '1 file could not be uploaded. It will retry automatically.',
      );
    });

    test('plural includes the first line of the error', () {
      final body = UploadNotifier.bodyForFailure(
        2,
        'S3 upload failed: AccessDenied\nmore detail',
      );
      expect(UploadNotifier.titleForFailure(2), 'Uploads failed');
      expect(body, contains('2 files could not be uploaded.'));
      expect(body, contains('S3 upload failed: AccessDenied'));
      expect(body, isNot(contains('more detail')));
    });

    test('truncates very long error lines', () {
      final body = UploadNotifier.bodyForFailure(1, 'x' * 300);
      expect(body, contains('...'));
      expect(body.length, lessThan(220));
    });
  });

  test('zero count posts nothing', () {
    expect(UploadNotifier.uploadCompleted(count: 0), completes);
    expect(UploadNotifier.uploadFailed(count: 0), completes);
  });

  group('delete text', () {
    test('success names the file', () {
      expect(
        UploadNotifier.bodyForDelete('a1b2.mp4'),
        '"a1b2.mp4" was deleted.',
      );
    });

    test('failure without error', () {
      expect(
        UploadNotifier.bodyForDeleteFailure('a1b2.mp4', null),
        '"a1b2.mp4" could not be deleted.',
      );
    });

    test('failure includes the first line of the error', () {
      final body = UploadNotifier.bodyForDeleteFailure(
        'a1b2.mp4',
        'Access denied\nstack trace',
      );
      expect(body, contains('Access denied'));
      expect(body, isNot(contains('stack trace')));
    });

    test('posting methods complete (plugin failures are swallowed)', () {
      expect(UploadNotifier.mediaDeleted(fileName: 'a.mp4'), completes);
      expect(
        UploadNotifier.mediaDeleteFailed(fileName: 'a.mp4', error: 'nope'),
        completes,
      );
    });
  });
}
