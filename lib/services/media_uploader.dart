import 'dart:async';
import 'dart:io';

import '../config/app_config.dart';
import '../models/media_item.dart';
import 'media_store.dart';
import 'presign_upload_service.dart';
import 'upload_notifier.dart';

/// Uploads queued media **through the presign Lambda**: it fetches a presigned
/// PUT URL from [AppConfig.awsUploadUrl] and uploads straight to S3, so no AWS
/// credentials are needed in the app.
///
/// Deliberately free of Flutter UI dependencies so it can run in the
/// background sync isolate as well as the main app.
class MediaUploader {
  MediaUploader(this.store);

  final MediaStore store;

  /// Uploads everything still pending. Returns the number uploaded.
  ///
  /// Posts a device notification summarising the result: one for files that
  /// completed, and one for files that failed (only on their first-ever
  /// failure, so the 2-minute retry timer does not spam the user).
  Future<int> syncPending({void Function()? onChanged}) async {
    var uploaded = 0;
    var firstTimeFailures = 0;
    String? firstError;

    for (final item in List<MediaItem>.of(store.items)) {
      if (!item.needsUpload) continue;
      final ok = await uploadOne(item);
      if (ok) {
        uploaded++;
      } else {
        final updated = store.byId(item.id);
        // `attempts` is incremented by `uploadOne`; ==1 means this was the
        // first failure, so alert once and stay quiet on later retries.
        if (updated?.attempts == 1) {
          firstTimeFailures++;
          firstError ??= updated?.lastError;
        }
      }
      onChanged?.call();
    }

    if (uploaded > 0) {
      unawaited(UploadNotifier.uploadCompleted(count: uploaded));
    }
    if (firstTimeFailures > 0) {
      unawaited(
        UploadNotifier.uploadFailed(
            count: firstTimeFailures, error: firstError),
      );
    }
    return uploaded;
  }

  /// Uploads a single queued item to S3. Returns `true` on success.
  Future<bool> uploadOne(MediaItem item) async {
    if (!AppConfig.hasUploadUrl) {
      await _fail(
        item,
        'Upload not configured. Provide AWS_UPLOAD_URL (the presign Lambda '
        'Function URL).',
      );
      return false;
    }

    final file = File(item.localPath);
    if (!await file.exists()) {
      await _fail(item, 'Local file missing.');
      return false;
    }

    await store.upsert(item.copyWith(status: UploadStatus.uploading));

    try {
      final service = PresignUploadService(endpoint: AppConfig.awsUploadUrl);
      final key = await service.upload(
        file: file,
        fileName: item.fileName,
        contentType: item.mimeType,
        mediaTypeTag: item.mediaTypeTag,
        tags: {
          'MediaId': item.id,
          'MediaType': item.mediaTypeTag,
          'Environment': 'Production',
        },
        metadata: {
          'media-id': item.id,
          'media-type': item.mediaTypeTag,
          'file-name': item.fileName,
          'created-at': item.createdAt,
        },
      );
      await store.upsert(item.copyWith(
        status: UploadStatus.uploaded,
        attempts: item.attempts + 1,
        s3Key: key,
        clearError: true,
      ));
      return true;
    } catch (e) {
      await _fail(item, e.toString());
      return false;
    }
  }

  Future<void> _fail(MediaItem item, String message) => store.upsert(
        item.copyWith(
          status: UploadStatus.failed,
          attempts: item.attempts + 1,
          lastError: message,
        ),
      );
}
