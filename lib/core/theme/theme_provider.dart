import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_icon_channel.dart';
import 'app_themes.dart';

enum SkipAesthetic { minimal, y2k }

/// Alternate-icon name (matches the `CFBundleAlternateIcons` key in
/// Info.plist) to switch to for each aesthetic; `null` means the primary
/// (minimal) icon.
String? _alternateIconNameFor(SkipAesthetic aesthetic) => switch (aesthetic) {
  SkipAesthetic.minimal => null,
  SkipAesthetic.y2k => 'AppIcon-Y2K',
};

/// Manages which of the two SKIP aesthetics is active and notifies
/// listeners so the whole app rebuilds with the new [ThemeData]. The choice
/// is persisted to on-device [SharedPreferences] so it survives app
/// restarts.
class ThemeProvider extends ChangeNotifier {
  static const _prefsKey = 'skip_aesthetic';

  SkipAesthetic _aesthetic;

  ThemeProvider({SkipAesthetic initial = SkipAesthetic.minimal})
    : _aesthetic = initial;

  SkipAesthetic get aesthetic => _aesthetic;

  bool get isY2K => _aesthetic == SkipAesthetic.y2k;

  ThemeData get themeData => switch (_aesthetic) {
    SkipAesthetic.minimal => AppThemes.minimal,
    SkipAesthetic.y2k => AppThemes.y2k,
  };

  /// Loads a previously persisted aesthetic, if any. Call once during app
  /// startup, before the first frame, so there's no flash of the default
  /// aesthetic before the saved one takes over.
  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_prefsKey);
    if (name == null) return;
    final saved = SkipAesthetic.values.where((a) => a.name == name).firstOrNull;
    if (saved != null && saved != _aesthetic) {
      _aesthetic = saved;
      notifyListeners();
    }
    // Keep the home screen icon in sync even if a previous icon switch
    // never completed (e.g. the user dismissed the system prompt).
    AppIconChannel.setAlternateIconName(_alternateIconNameFor(_aesthetic));
  }

  void setAesthetic(SkipAesthetic aesthetic) {
    if (_aesthetic == aesthetic) return;
    _aesthetic = aesthetic;
    notifyListeners();
    _save(aesthetic);
    AppIconChannel.setAlternateIconName(_alternateIconNameFor(aesthetic));
  }

  void toggle() {
    setAesthetic(isY2K ? SkipAesthetic.minimal : SkipAesthetic.y2k);
  }

  Future<void> _save(SkipAesthetic aesthetic) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, aesthetic.name);
  }
}
