import 'dart:io';
import 'dart:ui' show DartPluginRegistrant;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:workmanager/workmanager.dart';

import 'media_store.dart';
import 'media_uploader.dart';

/// Task name delivered to the background isolate (Android).
const String kMediaUploadTask = 'mediaUploadTask';

/// BGTaskScheduler identifier (iOS) / unique name (Android) for the periodic
/// upload retry. On iOS this must match `BGTaskSchedulerPermittedIdentifiers`
/// in Info.plist.
const String kMediaUploadPeriodicId = 'com.cixiohub.cixiohubMobile.mediaUpload';

/// Unique name for the immediate one-off upload (Android expedited).
const String kMediaUploadNowId = 'com.cixiohub.cixiohubMobile.mediaUploadNow';

/// Entry point run by the OS in a background isolate. Must be top-level.
@pragma('vm:entry-point')
void mediaUploadCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      DartPluginRegistrant.ensureInitialized();
    } catch (_) {
      // Not available on every platform/engine; plugins may still work.
    }
    // The background isolate is separate from the UI isolate, so the `.env`
    // asset must be loaded again here for AppConfig to see the upload URL.
    try {
      await dotenv.load();
    } catch (_) {
      // Fall back to --dart-define values bundled into the binary.
    }
    try {
      final store = await MediaStore.openDefault();
      await MediaUploader(store).syncPending();
      return true;
    } catch (_) {
      // Return success so the OS doesn't hammer retries for transient errors;
      // the periodic task will pick pending items up again next cycle.
      return true;
    }
  });
}

/// Wires up OS-level background upload retries via WorkManager / BGTaskScheduler.
class BackgroundUploadSync {
  BackgroundUploadSync._();

  /// Must be called once from `main()` before scheduling any task.
  static Future<void> initialize() async {
    await Workmanager().initialize(mediaUploadCallbackDispatcher);
  }

  /// Whether the platform can run BGTaskScheduler/WorkManager tasks.
  ///
  /// The iOS Simulator does not support `BGTaskScheduler`; submitting a task
  /// there aborts the app with `_handleSubmissionWithoutRegistrationForTaskRequest`.
  /// Foreground sync (the in-app timer + resume hook) still runs on the simulator.
  static Future<bool> _supportsBackgroundTasks() async {
    if (!Platform.isIOS) return true;
    try {
      final ios = await DeviceInfoPlugin().iosInfo;
      return ios.isPhysicalDevice;
    } catch (_) {
      return false;
    }
  }

  /// Schedules the periodic retry (OS minimum is 15 minutes; iOS is best-effort).
  static Future<void> registerPeriodic() async {
    if (!await _supportsBackgroundTasks()) return;
    try {
      await Workmanager().registerPeriodicTask(
        kMediaUploadPeriodicId,
        kMediaUploadTask,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      );
    } catch (_) {
      // Some platforms/devices reject scheduling; the in-app timer still retries.
    }
  }

  /// Requests an immediate background upload attempt (Android only; iOS one-off
  /// tasks need additional BGTaskScheduler plumbing).
  static Future<void> triggerNow() async {
    if (!Platform.isAndroid) return;
    try {
      await Workmanager().registerOneOffTask(
        kMediaUploadNowId,
        kMediaUploadTask,
        existingWorkPolicy: ExistingWorkPolicy.replace,
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } catch (_) {
      // Ignore — foreground sync already attempted the upload.
    }
  }
}
