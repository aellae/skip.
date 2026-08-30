import 'package:flutter/material.dart';

import 'app_themes.dart';

enum SkipAesthetic { minimal, y2k }

/// Manages which of the two SKIP aesthetics is active and notifies
/// listeners so the whole app rebuilds with the new [ThemeData].
class ThemeProvider extends ChangeNotifier {
  SkipAesthetic _aesthetic;

  ThemeProvider({SkipAesthetic initial = SkipAesthetic.minimal})
    : _aesthetic = initial;

  SkipAesthetic get aesthetic => _aesthetic;

  bool get isY2K => _aesthetic == SkipAesthetic.y2k;

  ThemeData get themeData => switch (_aesthetic) {
    SkipAesthetic.minimal => AppThemes.minimal,
    SkipAesthetic.y2k => AppThemes.y2k,
  };

  void setAesthetic(SkipAesthetic aesthetic) {
    if (_aesthetic == aesthetic) return;
    _aesthetic = aesthetic;
    notifyListeners();
  }

  void toggle() {
    setAesthetic(isY2K ? SkipAesthetic.minimal : SkipAesthetic.y2k);
  }
}
