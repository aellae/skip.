import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/home_widget/home_widget_sync.dart';
import 'core/localization/app_currency.dart';
import 'core/localization/app_locale.dart';
import 'core/localization/currency_provider.dart';
import 'core/localization/locale_provider.dart';
import 'core/settings/sfx_provider.dart';
import 'core/settings/wage_provider.dart';
import 'core/theme/theme_provider.dart';
import 'data/items_provider.dart';
import 'features/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeProvider = ThemeProvider();
  // Awaited before runApp so the persisted aesthetic is already active on
  // the very first frame — no flash of the default aesthetic.
  await themeProvider.loadSaved();
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
  final sfxProvider = SfxProvider();
  await sfxProvider.loadSaved();
  final wageProvider = WageProvider();
  await wageProvider.loadSaved();
  runApp(
    SkipApp(
      themeProviderOverride: themeProvider,
      localeProviderOverride: localeProvider,
      currencyProviderOverride: currencyProvider,
      sfxProviderOverride: sfxProvider,
      wageProviderOverride: wageProvider,
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
  final SfxProvider? sfxProviderOverride;
  final WageProvider? wageProviderOverride;
  final GlobalKey<NavigatorState>? navigatorKeyOverride;

  const SkipApp({
    super.key,
    this.themeProviderOverride,
    this.itemsProviderOverride,
    this.localeProviderOverride,
    this.currencyProviderOverride,
    this.sfxProviderOverride,
    this.wageProviderOverride,
    this.navigatorKeyOverride,
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
        ChangeNotifierProvider(
          create: (_) => sfxProviderOverride ?? SfxProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => wageProviderOverride ?? WageProvider(),
        ),
      ],
      child: HomeWidgetSync(
        child: Consumer<ThemeProvider>(
          builder: (context, themeProvider, _) {
            return MaterialApp(
              title: 'SKIP',
              debugShowCheckedModeBanner: false,
              navigatorKey: navigatorKeyOverride,
              theme: themeProvider.themeData,
              builder: (context, child) => AnimatedTheme(
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeInOutCubicEmphasized,
                data: themeProvider.themeData,
                child: child!,
              ),
              home: const HomeScreen(),
            );
          },
        ),
      ),
    );
  }
}
