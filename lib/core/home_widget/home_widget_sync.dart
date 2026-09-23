import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../data/items_provider.dart';
import '../localization/currency_provider.dart';
import '../localization/locale_provider.dart';
import '../theme/theme_provider.dart';
import 'home_widget_service.dart';

/// Keeps the home-screen widget in sync by listening to the providers that
/// can change what it shows — items (totals), currency, aesthetic, and
/// language — and pushing a fresh snapshot via [HomeWidgetService] whenever
/// any of them notify. Wrap the app's root widget (below the [MultiProvider]
/// that supplies [ItemsProvider]/[ThemeProvider]/[CurrencyProvider]/
/// [LocaleProvider]) with this so every screen benefits without wiring the
/// push into each provider method individually.
///
/// Also watches for a new calendar month starting — on app resume and via a
/// timer at the boundary while the app stays open — since "this month"
/// totals change then without any provider having anything to notify.
class HomeWidgetSync extends StatefulWidget {
  final Widget child;

  const HomeWidgetSync({super.key, required this.child});

  @override
  State<HomeWidgetSync> createState() => _HomeWidgetSyncState();
}

class _HomeWidgetSyncState extends State<HomeWidgetSync>
    with WidgetsBindingObserver {
  late final ItemsProvider _items;
  late final ThemeProvider _theme;
  late final CurrencyProvider _currency;
  late final LocaleProvider _locale;
  Timer? _monthTimer;

  @override
  void initState() {
    super.initState();
    _items = context.read<ItemsProvider>();
    _theme = context.read<ThemeProvider>();
    _currency = context.read<CurrencyProvider>();
    _locale = context.read<LocaleProvider>();
    _items.addListener(_sync);
    _theme.addListener(_sync);
    _currency.addListener(_sync);
    _locale.addListener(_sync);
    WidgetsBinding.instance.addObserver(this);
    _scheduleMonthRollover();
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Timers don't fire while suspended, so re-check and re-arm on resume.
    _items.checkMonthRollover();
    _scheduleMonthRollover();
  }

  void _scheduleMonthRollover() {
    _monthTimer?.cancel();
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1);
    // A second of slack so the check lands safely inside the new month.
    _monthTimer = Timer(
      nextMonth.difference(now) + const Duration(seconds: 1),
      () {
        _items.checkMonthRollover();
        _scheduleMonthRollover();
      },
    );
  }

  void _sync() {
    HomeWidgetService.update(
      savedThisMonth: _items.totalSavedThisMonth,
      spentThisMonth: _items.totalSpentThisMonth,
      currency: _currency.currency,
      aesthetic: _theme.aesthetic,
      strings: _locale.strings,
    );
  }

  @override
  void dispose() {
    _monthTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _items.removeListener(_sync);
    _theme.removeListener(_sync);
    _currency.removeListener(_sync);
    _locale.removeListener(_sync);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
