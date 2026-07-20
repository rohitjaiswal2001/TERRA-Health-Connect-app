import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // NOTE: Terra background delivery is deliberately NOT enabled.
    // This app captures Apple Health history only when the member taps the
    // sync button — nothing runs or is observed in the background. If you ever
    // want continuous background sync, re-add `import TerraiOS` and call
    // `Terra.setUpBackgroundDelivery()` here, and restore the
    // BGTaskSchedulerPermittedIdentifiers + UIBackgroundModes keys in Info.plist.

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
