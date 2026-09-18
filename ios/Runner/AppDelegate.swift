import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static let appIconChannelName = "skip/app_icon"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: AppDelegate.appIconChannelName,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "setAlternateIconName" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard UIApplication.shared.supportsAlternateIcons else {
        result(nil)
        return
      }
      let args = call.arguments as? [String: Any]
      let iconName = args?["iconName"] as? String
      // Re-setting the same name still triggers the OS confirmation prompt,
      // so skip the call entirely when it wouldn't change anything.
      if UIApplication.shared.alternateIconName == iconName {
        result(nil)
        return
      }
      UIApplication.shared.setAlternateIconName(iconName) { error in
        if let error = error {
          result(
            FlutterError(
              code: "SET_ALTERNATE_ICON_FAILED",
              message: error.localizedDescription,
              details: nil
            )
          )
        } else {
          result(nil)
        }
      }
    }
  }
}
