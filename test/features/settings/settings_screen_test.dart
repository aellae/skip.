import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skip/core/localization/app_locale.dart';
import 'package:skip/core/localization/locale_provider.dart';
import 'package:skip/core/theme/theme_provider.dart';
import 'package:skip/core/utils/currency_formatter.dart';
import 'package:skip/data/items_provider.dart';
import 'package:skip/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';

import '../../test_helpers/widget_test_env.dart';

void main() {
  setUpAll(() => setUpWidgetTestEnvironment());
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpSettings(
    WidgetTester tester, {
    required ThemeProvider themeProvider,
    required ItemsProvider itemsProvider,
    LocaleProvider? localeProvider,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: itemsProvider),
          ChangeNotifierProvider.value(
            value: localeProvider ?? LocaleProvider(),
          ),
        ],
        child: Consumer<ThemeProvider>(
          builder: (context, provider, _) => MaterialApp(
            theme: provider.themeData,
            home: const SettingsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows resisted count and average saved from live data', (
    tester,
  ) async {
    final itemsProvider = buildTestItemsProvider();
    await itemsProvider.addItem(price: 30, imagePath: 'a.jpg', isSaved: true);
    await itemsProvider.addItem(price: 10, imagePath: 'b.jpg', isSaved: true);
    await itemsProvider.addItem(price: 5, imagePath: 'c.jpg', isSaved: false);

    await pumpSettings(
      tester,
      themeProvider: ThemeProvider(),
      itemsProvider: itemsProvider,
    );

    expect(find.text('2'), findsOneWidget);
    expect(find.text(formatCurrency(20)), findsOneWidget);
  });

  testWidgets('tapping SKIP! switches the active aesthetic', (tester) async {
    final themeProvider = ThemeProvider();
    await pumpSettings(
      tester,
      themeProvider: themeProvider,
      itemsProvider: buildTestItemsProvider(),
    );

    expect(themeProvider.isY2K, isFalse);

    await tester.tap(find.text('SKIP!'));
    await tester.pumpAndSettle();

    expect(themeProvider.isY2K, isTrue);
  });

  testWidgets('tapping skip. switches back to the minimal aesthetic', (
    tester,
  ) async {
    final themeProvider = ThemeProvider(initial: SkipAesthetic.y2k);
    await pumpSettings(
      tester,
      themeProvider: themeProvider,
      itemsProvider: buildTestItemsProvider(),
    );

    await tester.tap(find.text('skip.'));
    await tester.pumpAndSettle();

    expect(themeProvider.isY2K, isFalse);
  });

  testWidgets('shows the Data section with export/import backup actions', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      themeProvider: ThemeProvider(),
      itemsProvider: buildTestItemsProvider(),
    );

    expect(find.text('Data'), findsOneWidget);
    expect(find.text('Export backup'), findsOneWidget);
    expect(find.text('Import backup'), findsOneWidget);
  });

  testWidgets('tapping Italiano switches the app to Italian', (tester) async {
    final localeProvider = LocaleProvider();
    await pumpSettings(
      tester,
      themeProvider: ThemeProvider(),
      itemsProvider: buildTestItemsProvider(),
      localeProvider: localeProvider,
    );

    expect(localeProvider.isItalian, isFalse);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Italiano'));
    await tester.pumpAndSettle();

    expect(localeProvider.isItalian, isTrue);
    expect(find.text('Impostazioni'), findsOneWidget);
    expect(find.text('Aesthetic'), findsNothing);
    expect(find.text('Estetica'), findsOneWidget);
  });

  testWidgets('tapping English switches back to English', (tester) async {
    final localeProvider = LocaleProvider(initial: AppLocale.it);
    await pumpSettings(
      tester,
      themeProvider: ThemeProvider(),
      itemsProvider: buildTestItemsProvider(),
      localeProvider: localeProvider,
    );

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(localeProvider.isItalian, isFalse);
    expect(find.text('Settings'), findsOneWidget);
  });
}
