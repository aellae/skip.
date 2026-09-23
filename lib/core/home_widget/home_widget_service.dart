import 'dart:io';

import 'package:home_widget/home_widget.dart';

import '../localization/app_currency.dart';
import '../theme/theme_provider.dart';

/// Bridges this-month saved/spent totals into the home-screen widget on iOS
/// (`SkipWidget`, see ios/SkipWidget/SkipWidget.swift, via the shared App
/// Group `group.com.skip.finance`) and Android (`SkipHomeWidgetProvider`, see
/// android/app/src/main/kotlin/com/skip/finance/SkipHomeWidgetProvider.kt,
/// via the `home_widget` plugin's own SharedPreferences file). No-op on any
/// other platform, where this widget doesn't exist.
class HomeWidgetService {
  static const _appGroupId = 'group.com.skip.finance';
  static const _iOSWidgetName = 'SkipWidget';
  static const _androidWidgetName = 'SkipHomeWidgetProvider';

  static Future<void> update({
    required double savedThisMonth,
    required double spentThisMonth,
    required AppCurrency currency,
    required SkipAesthetic aesthetic,
  }) async {
    if (!Platform.isIOS && !Platform.isAndroid) return;
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
      await HomeWidget.saveWidgetData<double>('saved', savedThisMonth);
      await HomeWidget.saveWidgetData<double>('spent', spentThisMonth);
      await HomeWidget.saveWidgetData<String>('currencyCode', currency.code);
      await HomeWidget.saveWidgetData<String>('aesthetic', aesthetic.name);
      await HomeWidget.updateWidget(
        iOSName: _iOSWidgetName,
        androidName: _androidWidgetName,
      );
    } catch (_) {
      // Widget refresh is a nicety; ignore failures (e.g. running on a
      // simulator/emulator without the widget added to the home screen yet).
    }
  }
}
