import Flutter
import UIKit
import TerraiOS

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register Terra's background delivery so Apple Health updates keep syncing
    // to the Terra webhook after the first connection. Must run before the app
    // finishes launching (it schedules the BGTask identifier declared in
    // Info.plist: co.tryterra.data.post.request).
    Terra.setUpBackgroundDelivery()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
