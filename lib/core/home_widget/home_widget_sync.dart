import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../data/items_provider.dart';
import '../localization/currency_provider.dart';
import '../theme/theme_provider.dart';
import 'home_widget_service.dart';

/// Keeps the iOS home-screen widget's totals in sync by listening to the
/// providers that can change what it shows — items (totals), currency, and
/// aesthetic — and pushing a fresh snapshot via [HomeWidgetService] whenever
/// any of them notify. Wrap the app's root widget (below the [MultiProvider]
/// that supplies [ItemsProvider]/[ThemeProvider]/[CurrencyProvider]) with
/// this so every screen benefits without wiring the push into each provider
/// method individually.
class HomeWidgetSync extends StatefulWidget {
  final Widget child;

  const HomeWidgetSync({super.key, required this.child});

  @override
  State<HomeWidgetSync> createState() => _HomeWidgetSyncState();
}

class _HomeWidgetSyncState extends State<HomeWidgetSync> {
  late final ItemsProvider _items;
  late final ThemeProvider _theme;
  late final CurrencyProvider _currency;

  @override
  void initState() {
    super.initState();
    _items = context.read<ItemsProvider>();
    _theme = context.read<ThemeProvider>();
    _currency = context.read<CurrencyProvider>();
    _items.addListener(_sync);
    _theme.addListener(_sync);
    _currency.addListener(_sync);
    _sync();
  }

  void _sync() {
    HomeWidgetService.update(
      savedThisMonth: _items.totalSavedThisMonth,
      spentThisMonth: _items.totalSpentThisMonth,
      currency: _currency.currency,
      aesthetic: _theme.aesthetic,
    );
  }

  @override
  void dispose() {
    _items.removeListener(_sync);
    _theme.removeListener(_sync);
    _currency.removeListener(_sync);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
