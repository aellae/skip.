import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/localization/app_currency.dart';
import 'core/localization/app_locale.dart';
import 'core/localization/currency_provider.dart';
import 'core/localization/locale_provider.dart';
import 'core/theme/theme_provider.dart';
import 'data/items_provider.dart';
import 'features/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localeProvider = LocaleProvider();
  // Awaited before runApp so the persisted language is already active on
  // the very first frame — no flash of the default language.
  await localeProvider.loadSaved();
  // Currency is independent of language once set, but a euro-speaking
  // locale's first-ever launch (no persisted currency yet) should still
  // default to euros rather than dollars.
  final currencyProvider = CurrencyProvider(
    initial: localeProvider.locale == AppLocale.en
        ? AppCurrency.usd
        : AppCurrency.eur,
  );
  await currencyProvider.loadSaved();
  runApp(
    SkipApp(
      localeProviderOverride: localeProvider,
      currencyProviderOverride: currencyProvider,
    ),
  );
}

class SkipApp extends StatelessWidget {
  /// Overridable only by tests, so a widget test can supply a ThemeProvider
  /// / ItemsProvider / LocaleProvider / CurrencyProvider backed by fakes
  /// instead of the real platform channels.
  final ThemeProvider? themeProviderOverride;
  final ItemsProvider? itemsProviderOverride;
  final LocaleProvider? localeProviderOverride;
  final CurrencyProvider? currencyProviderOverride;

  const SkipApp({
    super.key,
    this.themeProviderOverride,
    this.itemsProviderOverride,
    this.localeProviderOverride,
    this.currencyProviderOverride,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => themeProviderOverride ?? ThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => itemsProviderOverride ?? ItemsProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => localeProviderOverride ?? LocaleProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => currencyProviderOverride ?? CurrencyProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'SKIP',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            builder: (context, child) => AnimatedTheme(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
              data: themeProvider.themeData,
              child: child!,
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
