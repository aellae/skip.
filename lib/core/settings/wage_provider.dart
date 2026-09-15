import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user's optional hourly wage, used to reframe prices as hours of work.
/// `null` means the feature is off — nothing renders until a user opts in
/// by setting a wage. Persisted to on-device [SharedPreferences], same
/// two-phase load as [LocaleProvider]/[CurrencyProvider].
class WageProvider extends ChangeNotifier {
  static const _prefsKey = 'skip_hourly_wage';

  double? _hourlyWage;

  WageProvider({double? initial}) : _hourlyWage = initial;

  double? get hourlyWage => _hourlyWage;

  /// Loads a previously persisted wage, if any. Call once during app
  /// startup, before the first frame, so there's no flash of the unset
  /// state before the saved one takes over.
  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_prefsKey);
    if (saved == _hourlyWage) return;
    _hourlyWage = saved;
    notifyListeners();
  }

  /// Sets the hourly wage, or clears it (pass `null`) to turn the feature
  /// back off.
  Future<void> setHourlyWage(double? hourlyWage) async {
    if (_hourlyWage == hourlyWage) return;
    _hourlyWage = hourlyWage;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (hourlyWage == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setDouble(_prefsKey, hourlyWage);
    }
  }
}
