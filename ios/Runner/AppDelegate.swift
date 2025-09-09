import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let audioMonitoringChannel = FlutterMethodChannel(name: "audio_monitoring",
                                                     binaryMessenger: controller.binaryMessenger)
    let audioMonitoringPlugin = AudioMonitoringPlugin()
    audioMonitoringChannel.setMethodCallHandler(audioMonitoringPlugin.handle)
    
    // GeneratedPluginRegistrant.register(with: self) // <-- TEMP: disable
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
