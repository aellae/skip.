import 'dart:io';

import 'package:home_widget/home_widget.dart';

import '../localization/app_currency.dart';
import '../localization/app_strings.dart';
import '../theme/theme_provider.dart';
import '../utils/motto_picker.dart';

/// Bridges this-month saved/spent totals into the home-screen widget on iOS
/// (`SkipWidget`, see ios/SkipWidget/SkipWidget.swift, via the shared App
/// Group `group.com.skip.finance`) and Android (`SkipHomeWidgetProvider`, see
/// android/app/src/main/kotlin/com/skip/finance/SkipHomeWidgetProvider.kt,
/// via the `home_widget` plugin's own SharedPreferences file). No-op on any
/// other platform, where this widget doesn't exist.
class HomeWidgetService {
  static const _appGroupId = 'group.com.skip.finance';
  static const _iOSWidgetName = 'SkipWidget';
  static const _iOSMottoWidgetName = 'SkipMottoWidget';
  static const _androidWidgetName = 'SkipHomeWidgetProvider';

  static Future<void> update({
    required double savedThisMonth,
    required double spentThisMonth,
    required AppCurrency currency,
    required SkipAesthetic aesthetic,
    required AppStrings strings,
  }) async {
    if (!Platform.isIOS && !Platform.isAndroid) return;
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
      await HomeWidget.saveWidgetData<double>('saved', savedThisMonth);
      await HomeWidget.saveWidgetData<double>('spent', spentThisMonth);
      await HomeWidget.saveWidgetData<String>('currencyCode', currency.code);
      await HomeWidget.saveWidgetData<String>('aesthetic', aesthetic.name);
      // The native widgets can't read AppStrings, so they get the active
      // language's copy pre-translated, and in the active aesthetic's voice
      // (calm for "Skip!", sassy for "Skip!"). Mottos travel newline-joined;
      // the widget picks one per day so it rotates without the app being
      // opened. Mottos are typeset first (non-breaking spaces) so they wrap
      // cleanly in every language on the native side too.
      final isY2k = aesthetic == SkipAesthetic.y2k;
      await HomeWidget.saveWidgetData<String>('savedLabel', strings.saved);
      await HomeWidget.saveWidgetData<String>('spentLabel', strings.spent);
      await HomeWidget.saveWidgetData<String>(
        'mottos',
        (isY2k ? strings.mottosY2k : strings.mottosMinimal)
            .map(typesetMotto)
            .join('\n'),
      );
      await HomeWidget.saveWidgetData<String>(
        'mottoEmpty',
        typesetMotto(
          isY2k ? strings.widgetMottoEmptyY2k : strings.widgetMottoEmptyMinimal,
        ),
      );
      await HomeWidget.updateWidget(
        iOSName: _iOSWidgetName,
        androidName: _androidWidgetName,
      );
      if (Platform.isIOS) {
        // The lock-screen motto widget is a separate kind, so it needs its
        // own reload to pick up a new language or aesthetic.
        await HomeWidget.updateWidget(iOSName: _iOSMottoWidgetName);
      }
    } catch (_) {
      // Widget refresh is a nicety; ignore failures (e.g. running on a
      // simulator/emulator without the widget added to the home screen yet).
    }
  }
}
