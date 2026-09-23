import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skip/core/localization/app_currency.dart';
import 'package:skip/core/localization/app_locale.dart';
import 'package:skip/core/localization/currency_provider.dart';
import 'package:skip/core/localization/locale_provider.dart';
import 'package:skip/core/settings/sfx_provider.dart';
import 'package:skip/core/settings/wage_provider.dart';
import 'package:skip/core/theme/theme_provider.dart';
import 'package:skip/data/items_provider.dart';
import 'package:skip/features/home/home_screen.dart';
import 'package:skip/features/insights/insights_screen.dart';
import 'package:skip/features/item_entry/item_entry_screen.dart';
import 'package:skip/features/settings/settings_screen.dart';

import '../../test_helpers/widget_test_env.dart';

/// German (the longest strings) at 2x system text size — the combination
/// the Android QA run found overflowing (checks 7.7 and 10.4).
void main() {
  setUpAll(() => setUpWidgetTestEnvironment());
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    required SkipAesthetic aesthetic,
    ItemsProvider? itemsProvider,
  }) async {
    // A typical phone portrait viewport.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);

    final items = itemsProvider ?? buildTestItemsProvider();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => ThemeProvider(initial: aesthetic),
          ),
          ChangeNotifierProvider.value(value: items),
          ChangeNotifierProvider(
            create: (_) => LocaleProvider(initial: AppLocale.de),
          ),
          ChangeNotifierProvider(
            create: (_) => CurrencyProvider(initial: AppCurrency.eur),
          ),
          ChangeNotifierProvider(create: (_) => SfxProvider()),
          ChangeNotifierProvider(create: (_) => WageProvider(initial: 20)),
        ],
        child: Consumer<ThemeProvider>(
          builder: (context, theme, _) => MaterialApp(
            theme: theme.themeData,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2.0)),
              child: child!,
            ),
            home: screen,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<ItemsProvider> seededItems() async {
    final items = buildTestItemsProvider();
    await items.addItem(price: 1234.5, quantity: 3, isSaved: true);
    await items.addItem(price: 99.99, isSaved: false);
    return items;
  }

  for (final aesthetic in SkipAesthetic.values) {
    group('German at 2x text, ${aesthetic.name}', () {
      testWidgets('Settings lays out without overflow', (tester) async {
        await pumpScreen(
          tester,
          const SettingsScreen(),
          aesthetic: aesthetic,
          itemsProvider: await seededItems(),
        );
        final scrollable = find.byType(Scrollable).first;
        for (var i = 0; i < 12; i++) {
          await tester.drag(scrollable, const Offset(0, -300));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('Home lays out without overflow', (tester) async {
        await pumpScreen(
          tester,
          const HomeScreen(),
          aesthetic: aesthetic,
          itemsProvider: await seededItems(),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('Item entry lays out without overflow', (tester) async {
        await pumpScreen(tester, const ItemEntryScreen(), aesthetic: aesthetic);
        final scrollable = find.byType(Scrollable).first;
        await tester.drag(scrollable, const Offset(0, -2000));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('Insights lays out without overflow', (tester) async {
        await pumpScreen(
          tester,
          const InsightsScreen(),
          aesthetic: aesthetic,
          itemsProvider: await seededItems(),
        );
        expect(tester.takeException(), isNull);
      });
    });
  }
}
