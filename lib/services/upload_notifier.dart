import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Posts a **device notification** for media lifecycle events: an upload
/// finishing/failing, and a cloud delete finishing/failing.
///
/// These outcomes are resolved on the client (the app itself talks to the
/// presign Lambda and S3), so no server round-trip is required — this uses the
/// same `flutter_local_notifications` plugin that renders foreground push
/// banners.
///
/// Safe to call from both the UI isolate and the background sync isolate
/// (WorkManager / BGTaskScheduler): initialisation and posting are guarded and
/// errors are swallowed, so a missing permission or plugin can never break an
/// upload or delete.
class UploadNotifier {
  UploadNotifier._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static const String channelId = 'upload_status_channel';
  static const String channelName = 'Upload status';
  static const String channelDescription =
      'Alerts when media uploads to S3 complete or fail.';

  // Fixed ids so a newer result replaces the previous banner instead of
  // stacking duplicates.
  static const int _successId = 9101;
  static const int _failureId = 9102;
  static const int _deleteSuccessId = 9103;
  static const int _deleteFailureId = 9104;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permissions are requested once at app start (NotificationService).
        // Do not re-prompt, and never attempt a UI permission prompt from a
        // background isolate.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(settings: settings);

      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              channelId,
              channelName,
              description: channelDescription,
              importance: Importance.high,
              enableVibration: true,
            ),
          );
    } catch (e) {
      debugPrint('UploadNotifier init skipped: $e');
    }
  }

  /// Notifies that [count] file(s) finished uploading to S3.
  static Future<void> uploadCompleted({required int count}) {
    if (count <= 0) return Future.value();
    return _show(
      id: _successId,
      title: titleForSuccess(count),
      body: bodyForSuccess(count),
    );
  }

  /// Notifies that [count] file(s) failed to upload and will be retried.
  static Future<void> uploadFailed({required int count, String? error}) {
    if (count <= 0) return Future.value();
    return _show(
      id: _failureId,
      title: titleForFailure(count),
      body: bodyForFailure(count, error),
    );
  }

  /// Notifies that [fileName] was deleted.
  ///
  /// Used when a delete completes while the app is backgrounded (in the
  /// foreground the screen already shows a snackbar).
  static Future<void> mediaDeleted({required String fileName}) {
    return _show(
      id: _deleteSuccessId,
      title: 'File deleted',
      body: bodyForDelete(fileName),
    );
  }

  /// Notifies that deleting [fileName] failed.
  static Future<void> mediaDeleteFailed({
    required String fileName,
    String? error,
  }) {
    return _show(
      id: _deleteFailureId,
      title: 'Delete failed',
      body: bodyForDeleteFailure(fileName, error),
    );
  }

  static Future<void> _show({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      await _ensureInitialized();
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('Upload notification skipped: $e');
    }
  }

  // ── Notification text (pure helpers, unit-tested) ──

  static String titleForSuccess(int count) =>
      count == 1 ? 'Upload complete' : 'Uploads complete';

  static String bodyForSuccess(int count) => count == 1
      ? '1 file was uploaded to the cloud.'
      : '$count files were uploaded to the cloud.';

  static String titleForFailure(int count) =>
      count == 1 ? 'Upload failed' : 'Uploads failed';

  static String bodyForFailure(int count, String? error) {
    final base = count == 1
        ? '1 file could not be uploaded.'
        : '$count files could not be uploaded.';
    final detail =
        (error == null || error.trim().isEmpty) ? '' : ' ${_firstLine(error)}';
    return '$base It will retry automatically.$detail';
  }

  static String bodyForDelete(String fileName) => '"$fileName" was deleted.';

  static String bodyForDeleteFailure(String fileName, String? error) {
    final detail =
        (error == null || error.trim().isEmpty) ? '' : ' ${_firstLine(error)}';
    return '"$fileName" could not be deleted.$detail';
  }

  static String _firstLine(String error) {
    final line = error.split('\n').first.trim();
    return line.length > 120 ? '${line.substring(0, 117)}...' : line;
  }
}
