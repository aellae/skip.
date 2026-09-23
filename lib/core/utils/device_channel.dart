import 'dart:io';

import 'package:flutter/services.dart';

/// Bridges to a couple of native device checks the image picker doesn't
/// expose (see AppDelegate.swift). iOS-only: elsewhere the camera is
/// assumed available and there's no app Settings page to open.
class DeviceChannel {
  static const _channel = MethodChannel('skip/device');

  static Future<bool>? _cameraAvailable;

  /// Whether the device has a camera — false e.g. on the iOS Simulator,
  /// where image_picker would otherwise show its own English-only
  /// "Camera not available" alert. Checked once per launch.
  static Future<bool> isCameraAvailable() {
    if (!Platform.isIOS) return Future.value(true);
    return _cameraAvailable ??= _channel
        .invokeMethod<bool>('isCameraAvailable')
        .then((available) => available ?? true)
        .catchError((Object _) => true);
  }

  /// Whether [openAppSettings] can do anything on this platform.
  static bool get canOpenAppSettings => Platform.isIOS;

  /// Opens this app's page in the system Settings app.
  static Future<void> openAppSettings() async {
    if (!canOpenAppSettings) return;
    try {
      await _channel.invokeMethod<void>('openAppSettings');
    } on PlatformException {
      // Nothing more useful to do; the snackbar already said where to go.
    }
  }
}
