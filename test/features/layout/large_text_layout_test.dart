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
import 'package:skip/features/home/item_detail_screen.dart';
import 'package:skip/features/insights/insights_screen.dart';
import 'package:skip/features/item_entry/item_entry_screen.dart';
import 'package:skip/features/settings/settings_screen.dart';

import '../../test_helpers/widget_test_env.dart';

/// German (the longest strings) at large system text sizes: 2x on an
/// Android-sized phone (the Android QA run's checks 7.7 and 10.4) and 3x —
/// roughly iOS's largest accessibility size — on an iPhone 16 (iOS QA
/// check 10.4).
const _cases = [
  (scale: 2.0, size: Size(1080, 2340), dpr: 2.625),
  (scale: 3.0, size: Size(1179, 2556), dpr: 3.0),
];

void main() {
  setUpAll(() => setUpWidgetTestEnvironment());
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    required SkipAesthetic aesthetic,
    required ({double scale, Size size, double dpr}) textCase,
    ItemsProvider? itemsProvider,
  }) async {
    tester.view.physicalSize = textCase.size;
    tester.view.devicePixelRatio = textCase.dpr;
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
              ).copyWith(textScaler: TextScaler.linear(textCase.scale)),
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

  for (final textCase in _cases) {
    for (final aesthetic in SkipAesthetic.values) {
      group('German at ${textCase.scale}x text, ${aesthetic.name}', () {
        testWidgets('Settings lays out without overflow', (tester) async {
          await pumpScreen(
            tester,
            const SettingsScreen(),
            aesthetic: aesthetic,
            textCase: textCase,
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
            textCase: textCase,
            itemsProvider: await seededItems(),
          );
          expect(tester.takeException(), isNull);
        });

        testWidgets('Item entry lays out without overflow', (tester) async {
          await pumpScreen(
            tester,
            const ItemEntryScreen(),
            aesthetic: aesthetic,
            textCase: textCase,
          );
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
            textCase: textCase,
            itemsProvider: await seededItems(),
          );
          expect(tester.takeException(), isNull);
        });

        testWidgets('Item detail (qty > 1) lays out without overflow', (
          tester,
        ) async {
          final items = await seededItems();
          final item = items.items.firstWhere((i) => i.quantity > 1);
          await pumpScreen(
            tester,
            ItemDetailScreen(item: item),
            aesthetic: aesthetic,
            textCase: textCase,
            itemsProvider: items,
          );
          final scrollable = find.byType(Scrollable).first;
          await tester.drag(scrollable, const Offset(0, -2000));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      });
    }
  }
}
