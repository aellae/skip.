import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_currency.dart';

/// Manages which pricing currency is active, independent of [LocaleProvider]
/// — persisted to on-device [SharedPreferences] so it survives app
/// restarts, same as the display language.
class CurrencyProvider extends ChangeNotifier {
  static const _prefsKey = 'skip_currency';

  AppCurrency _currency;

  CurrencyProvider({AppCurrency initial = AppCurrency.usd})
    : _currency = initial;

  AppCurrency get currency => _currency;

  /// Loads a previously persisted currency, if any. Call once during app
  /// startup, before the first frame, so there's no flash of the default
  /// currency before the saved one takes over.
  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code == null) return;
    final saved = AppCurrency.fromCode(code);
    if (saved != _currency) {
      _currency = saved;
      notifyListeners();
    }
  }

  Future<void> setCurrency(AppCurrency currency) async {
    if (_currency == currency) return;
    _currency = currency;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, currency.code);
  }
}
