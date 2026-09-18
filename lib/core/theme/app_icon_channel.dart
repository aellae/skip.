import 'dart:io';

import 'package:flutter/services.dart';

/// Bridges to the native iOS alternate-icon API so the home screen icon can
/// follow the active [SkipAesthetic]. No-op on platforms other than iOS,
/// where alternate app icons aren't supported.
class AppIconChannel {
  static const _channel = MethodChannel('skip/app_icon');

  /// [iconName] must match a `CFBundleAlternateIcons` key in Info.plist, or
  /// be `null` to switch back to the primary icon.
  static Future<void> setAlternateIconName(String? iconName) async {
    if (!Platform.isIOS) return;
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
