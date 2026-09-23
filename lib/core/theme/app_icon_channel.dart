import 'dart:io';

import 'package:flutter/services.dart';

/// Bridges to the native alternate-icon API so the home screen icon can
/// follow the active [SkipAesthetic]. On iOS this uses
/// `UIApplication.setAlternateIconName`; on Android it toggles between two
/// `activity-alias` entries in the manifest. No-op on other platforms, where
/// alternate app icons aren't supported.
class AppIconChannel {
  static const _channel = MethodChannel('skip/app_icon');

  /// [iconName] must match a `CFBundleAlternateIcons` key in Info.plist
  /// (also used on Android to pick between the launcher activity-aliases),
  /// or be `null` to switch back to the primary icon.
  static Future<void> setAlternateIconName(String? iconName) async {
    if (!Platform.isIOS && !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('setAlternateIconName', {
        'iconName': iconName,
      });
    } on PlatformException {
      // Icon switching is a cosmetic nicety; ignore failures (e.g. the user
      // dismissing the system confirmation prompt).
    }
  }
}
