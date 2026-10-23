import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';
import '../models/media_item.dart';
import 'background_sync.dart';
import 'media_store.dart';
import 'media_uploader.dart';
import 'presign_upload_service.dart';
import 'upload_notifier.dart';

/// Owns the whole voice / camera capture pipeline:
///
///  1. Capture (voice via `record`, photo/video via the native camera through
///     `image_picker`).
///  2. Persist the original file in the phone's local app storage and record it
///     in a durable queue ([MediaStore]).
///  3. Upload to S3 in the background, retrying automatically every
///     [syncInterval] and whenever the app returns to the foreground.
///
/// Exposed as a [ChangeNotifier] singleton so screens can rebuild on progress.
class MediaService extends ChangeNotifier with WidgetsBindingObserver {
  MediaService._();

  static final MediaService instance = MediaService._();

  /// Retry cadence for files that have not made it to S3 yet.
  static const Duration syncInterval = Duration(minutes: 2);

  final AudioRecorder _recorder = AudioRecorder();
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  MediaStore? _store;
  Timer? _syncTimer;

  bool _initialized = false;
  bool _isSyncing = false;
  bool _isRecording = false;
  String? _recordingPath;
  String? _lastError;

  /// Latest app lifecycle state; starts as foreground so a delete before the
  /// first lifecycle callback still behaves correctly.
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  bool get isInitialized => _initialized;
  bool get isSyncing => _isSyncing;
  bool get isRecording => _isRecording;
  bool get uploadConfigured => AppConfig.hasUploadUrl;
  String? get lastError => _lastError;

  /// Whether the app is currently in the foreground.
  bool get _isInForeground => _lifecycle == AppLifecycleState.resumed;

  List<MediaItem> get items => _store?.items ?? const [];

  int get pendingCount => items.where((e) => e.needsUpload).length;
  int get uploadedCount => items.where((e) => e.isUploaded).length;

  /// Loads the persisted queue, primes the local media folder and starts the
  /// periodic retry timer. Safe to call more than once.
  Future<void> init() async {
    if (_initialized) return;

    _store = await MediaStore.openDefault();

    WidgetsBinding.instance.addObserver(this);
    _syncTimer = Timer.periodic(syncInterval, (_) => syncNow());

    _initialized = true;
    notifyListeners();

    // Keep retrying even when the app is backgrounded/closed.
    unawaited(BackgroundUploadSync.registerPeriodic());

    // Best-effort catch-up for anything left over from a previous run.
    unawaited(syncNow());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    if (state == AppLifecycleState.resumed) {
      unawaited(syncNow());
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _recorder.dispose();
    super.dispose();
  }

  // ── Voice recording ──

  /// Starts recording to a file inside the local media folder.
  ///
  /// Returns `false` when microphone access is denied.
  Future<bool> startRecording() async {
    if (_isRecording) return true;

    // `record` triggers the native microphone permission prompt itself.
    if (!await _recorder.hasPermission()) {
      _lastError = 'Microphone permission denied.';
      notifyListeners();
      return false;
    }

    final path = '${_store!.mediaDirectoryPath}/${_uuid.v4()}.m4a';
    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );
      _recordingPath = path;
      _isRecording = true;
      _lastError = null;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Could not start recording: $e';
      notifyListeners();
      return false;
    }
  }

  /// Stops recording and queues the clip for upload. Returns the queued item.
  Future<MediaItem?> stopRecording() async {
    if (!_isRecording) return null;
    _isRecording = false;

    final path = await _recorder.stop() ?? _recordingPath;
    _recordingPath = null;
    notifyListeners();

    if (path == null) return null;
    final file = File(path);
    if (!await file.exists() || await file.length() == 0) {
      await file.delete().catchError((_) => file);
      return null;
    }
    return _enqueue(file, MediaType.voice, 'audio/mp4');
  }

  /// Stops and discards the current recording.
  Future<void> cancelRecording() async {
    if (!_isRecording) return;
    _isRecording = false;
    final path = await _recorder.stop() ?? _recordingPath;
    _recordingPath = null;
    notifyListeners();
    if (path != null) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }

  // ── Camera capture ──

  /// Opens the camera and captures a photo. Returns the queued item, or null
  /// if the user cancelled / permission was denied.
  Future<MediaItem?> capturePhoto() async {
    try {
      final shot = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (shot == null) return null;
      return await _enqueue(File(shot.path), MediaType.photo, 'image/jpeg');
    } catch (e) {
      _lastError = 'Camera error: $e';
      notifyListeners();
      return null;
    }
  }

  /// Opens the camera and records a video. Returns the queued item, or null if
  /// the user cancelled / permission was denied.
  ///
  /// No `maxDuration` is set, so recording runs until the user stops it (or the
  /// camera app's own storage limits are reached).
  Future<MediaItem?> captureVideo() async {
    try {
      final clip = await _picker.pickVideo(source: ImageSource.camera);
      if (clip == null) return null;
      return await _enqueue(File(clip.path), MediaType.video, 'video/mp4');
    } catch (e) {
      _lastError = 'Camera error: $e';
      notifyListeners();
      return null;
    }
  }

  // ── Local persistence + upload queue ──

  /// Copies [source] into the durable local media folder and queues it.
  ///
  /// The original is always written to the phone first; the S3 upload is kicked
  /// off in the background and never blocks this call.
  Future<MediaItem?> _enqueue(
    File source,
    MediaType type,
    String mimeType,
  ) async {
    if (_store == null) return null;

    final mediaDirPath = _store!.mediaDirectoryPath;
    final id = _uuid.v4();
    final ext = _extensionFor(source.path, type);
    final dest = File('$mediaDirPath/$id$ext');

    try {
      // The recorder already writes into the media dir; avoid a pointless copy.
      if (source.absolute.path != dest.absolute.path) {
        await source.copy(dest.path);
        // Clean up the transient capture file if it was written by the recorder.
        if (source.absolute.path.startsWith(mediaDirPath)) {
          await source.delete().catchError((_) => source);
        }
      }
    } catch (e) {
      _lastError = 'Could not save file locally: $e';
      notifyListeners();
      return null;
    }

    final item = MediaItem(
      id: id,
      type: type,
      localPath: dest.path,
      fileName: '$id$ext',
      mimeType: mimeType,
      sizeBytes: await dest.length(),
      createdAt: DateTime.now().toUtc().toIso8601String(),
    );

    await _store!.upsert(item);
    _lastError = null;
    notifyListeners();

    // Fire-and-forget upload; the OS-level task keeps retrying if this fails.
    unawaited(syncNow());
    unawaited(BackgroundUploadSync.triggerNow());
    return item;
  }

  /// Attempts to upload every item still needing S3. Serialized so overlapping
  /// triggers (capture, timer, app-resume) never race.
  Future<void> syncNow() async {
    if (!_initialized || _isSyncing || _store == null) return;
    _isSyncing = true;
    notifyListeners();
    try {
      await MediaUploader(_store!).syncPending(onChanged: notifyListeners);
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Deletes an item: its S3 object (if uploaded) and its local file.
  ///
  /// The S3 object is deleted **first** through the presign Lambda; the local
  /// file and queue entry are only removed once the backend confirms (HTTP
  /// 200), so a failed remote delete never silently orphans the object. Throws
  /// [PresignUploadException] if the remote delete fails.
  ///
  /// If the app is backgrounded when the delete finishes, a device notification
  /// reports the outcome (there is no snackbar to show then).
  Future<void> delete(String id) async {
    final item = _store?.byId(id);
    if (item == null) return;

    final s3Key = item.s3Key;
    final hasRemote =
        s3Key != null && s3Key.isNotEmpty && AppConfig.hasUploadUrl;

    if (hasRemote) {
      try {
        await PresignUploadService(endpoint: AppConfig.awsUploadUrl)
            .deleteObject(objectKey: s3Key);
      } catch (e) {
        if (!_isInForeground) {
          unawaited(UploadNotifier.mediaDeleteFailed(
            fileName: item.fileName,
            error: e.toString(),
          ));
        }
        rethrow;
      }
    }

    await _store!.delete(id);
    final file = File(item.localPath);
    if (await file.exists()) {
      await file.delete().catchError((_) => file);
    }
    notifyListeners();

    if (!_isInForeground) {
      unawaited(UploadNotifier.mediaDeleted(fileName: item.fileName));
    }
  }

  // ── Helpers ──

  String _extensionFor(String path, MediaType type) {
    final dot = path.lastIndexOf('.');
    if (dot != -1 && dot < path.length - 1) {
      final ext = path.substring(dot).toLowerCase();
      if (ext.length <= 6 && !ext.contains('/')) return ext;
    }
    switch (type) {
      case MediaType.voice:
        return '.m4a';
      case MediaType.video:
        return '.mp4';
      case MediaType.photo:
        return '.jpg';
    }
  }
}
