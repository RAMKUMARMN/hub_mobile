import Flutter
import UIKit
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register the periodic media-upload task with BGTaskScheduler *before*
    // Dart schedules it. Without this, iOS aborts the app the first time the
    // periodic task is submitted (no launch handler registered yet).
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "com.cixiohub.cixiohubMobile.mediaUpload"
    )
    // Re-register BGTaskScheduler launch handlers persisted from prior sessions.
    WorkmanagerPlugin.registerLaunchHandlers()
    // Make Flutter plugins available inside the background upload isolate.
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
