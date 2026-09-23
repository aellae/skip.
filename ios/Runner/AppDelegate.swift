import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static let appIconChannelName = "skip/app_icon"
  private static let deviceChannelName = "skip/device"

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
      AppDelegate.applyAlternateIcon(iconName, result: result)
    }

    let deviceChannel = FlutterMethodChannel(
      name: AppDelegate.deviceChannelName,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    deviceChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "isCameraAvailable":
        result(UIImagePickerController.isSourceTypeAvailable(.camera))
      case "openAppSettings":
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url)
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static var pendingIconObserver: NSObjectProtocol?
  private static var pendingIconResult: FlutterResult?

  /// iOS rejects `setAlternateIconName` unless the app is active, and the
  /// startup sync runs before `runApp` (while the app is still inactive),
  /// so in that case wait for the app to become active, then apply the
  /// latest requested icon.
  private static func applyAlternateIcon(_ iconName: String?, result: @escaping FlutterResult) {
    if let observer = pendingIconObserver {
      NotificationCenter.default.removeObserver(observer)
      pendingIconObserver = nil
    }
    // A newer request supersedes one still waiting for the app to activate.
    pendingIconResult?(nil)
    pendingIconResult = nil

    guard UIApplication.shared.applicationState == .active else {
      pendingIconResult = result
      pendingIconObserver = NotificationCenter.default.addObserver(
        forName: UIApplication.didBecomeActiveNotification,
        object: nil,
        queue: .main
      ) { _ in
        pendingIconResult = nil
        applyAlternateIcon(iconName, result: result)
      }
      return
    }
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
