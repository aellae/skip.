import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_locale.dart';
import 'app_strings.dart';

/// Manages which display language is active and notifies listeners so the
/// whole app rebuilds with the new [AppStrings]. The choice is persisted to
/// on-device [SharedPreferences] (no network involved) so it survives app
/// restarts.
class LocaleProvider extends ChangeNotifier {
  static const _prefsKey = 'skip_locale';

  AppLocale _locale;

  LocaleProvider({AppLocale initial = AppLocale.en}) : _locale = initial;

  AppLocale get locale => _locale;

  AppStrings get strings => AppStrings(_locale);

  bool get isItalian => _locale == AppLocale.it;

  /// Loads a previously persisted locale, if any. Call once during app
  /// startup, before the first frame, so there's no flash of the default
  /// language before the saved one takes over.
  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code == null) return;
    final saved = AppLocale.fromCode(code);
    if (saved != _locale) {
      _locale = saved;
      notifyListeners();
    }
  }

  Future<void> setLocale(AppLocale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.code);
  }
}
