import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether SKIP's Y2K sound effects play, independent of the active theme —
/// muting stays off even if the user later switches back to Y2K. Persisted
/// to on-device [SharedPreferences], same two-phase load as
/// [LocaleProvider]/[CurrencyProvider].
class SfxProvider extends ChangeNotifier {
  static const _prefsKey = 'skip_sfx_enabled';

  bool _enabled;

  SfxProvider({bool initial = true}) : _enabled = initial;

  bool get enabled => _enabled;

  /// Loads a previously persisted mute choice, if any. Call once during app
  /// startup, before the first frame, so there's no flash of the default
  /// (enabled) state before the saved one takes over.
  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_prefsKey);
    if (saved == null || saved == _enabled) return;
    _enabled = saved;
    notifyListeners();
  }

  Future<void> setEnabled(bool enabled) async {
    if (_enabled == enabled) return;
    _enabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);
  }
}
