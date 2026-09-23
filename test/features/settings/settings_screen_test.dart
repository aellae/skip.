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
    CurrencyProvider? currencyProvider,
    SfxProvider? sfxProvider,
    WageProvider? wageProvider,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: themeProvider),
          ChangeNotifierProvider.value(value: itemsProvider),
          ChangeNotifierProvider.value(
            value: localeProvider ?? LocaleProvider(),
          ),
          ChangeNotifierProvider.value(
            value: currencyProvider ?? CurrencyProvider(),
          ),
          ChangeNotifierProvider.value(value: sfxProvider ?? SfxProvider()),
          ChangeNotifierProvider.value(value: wageProvider ?? WageProvider()),
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

    await tester.scrollUntilVisible(find.text(formatCurrency(20)), 200);
    expect(find.text('2'), findsOneWidget);
    expect(find.text(formatCurrency(20)), findsOneWidget);
  });

  testWidgets('tapping Baddie Y2K switches the active aesthetic', (tester) async {
    final themeProvider = ThemeProvider();
    await pumpSettings(
      tester,
      themeProvider: themeProvider,
      itemsProvider: buildTestItemsProvider(),
    );

    expect(themeProvider.isY2K, isFalse);

    await tester.tap(find.text('Baddie Y2K'));
    await tester.pumpAndSettle();

    expect(themeProvider.isY2K, isTrue);
  });

  testWidgets('tapping Quiet Luxury switches back to the minimal aesthetic', (
    tester,
  ) async {
    final themeProvider = ThemeProvider(initial: SkipAesthetic.y2k);
    await pumpSettings(
      tester,
      themeProvider: themeProvider,
      itemsProvider: buildTestItemsProvider(),
    );

    await tester.tap(find.text('Quiet Luxury'));
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

    await tester.scrollUntilVisible(find.text('Data'), 200);
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

  testWidgets('tapping Privacy Policy opens the privacy policy screen', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      themeProvider: ThemeProvider(),
      itemsProvider: buildTestItemsProvider(),
    );

    await tester.scrollUntilVisible(find.text('Privacy Policy'), 200);
    await tester.ensureVisible(find.text('Privacy Policy'));
    await tester.pumpAndSettle();
    expect(find.text('Legal'), findsOneWidget);
    await tester.tap(find.text('Privacy Policy'));
    await tester.pumpAndSettle();

    expect(find.text('Read the full policy'), findsOneWidget);
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

  testWidgets('tapping Euro switches the active currency', (tester) async {
    final currencyProvider = CurrencyProvider();
    await pumpSettings(
      tester,
      themeProvider: ThemeProvider(),
      itemsProvider: buildTestItemsProvider(),
      currencyProvider: currencyProvider,
    );

    expect(currencyProvider.currency, AppCurrency.usd);

    await tester.tap(find.text('Euro'));
    await tester.pumpAndSettle();

    expect(currencyProvider.currency, AppCurrency.eur);
  });

  testWidgets(
    'currency stays independent of language — switching to Italian keeps USD selected',
    (tester) async {
      final localeProvider = LocaleProvider();
      final currencyProvider = CurrencyProvider();
      await pumpSettings(
        tester,
        themeProvider: ThemeProvider(),
        itemsProvider: buildTestItemsProvider(),
        localeProvider: localeProvider,
        currencyProvider: currencyProvider,
      );

      await tester.tap(find.text('Italiano'));
      await tester.pumpAndSettle();

      expect(localeProvider.isItalian, isTrue);
      expect(currencyProvider.currency, AppCurrency.usd);
      expect(find.text('Dollaro USA'), findsOneWidget);
    },
  );

  testWidgets('toggling the sound switch mutes/unmutes and persists it', (
    tester,
  ) async {
    final sfxProvider = SfxProvider();
    await pumpSettings(
      tester,
      themeProvider: ThemeProvider(),
      itemsProvider: buildTestItemsProvider(),
      sfxProvider: sfxProvider,
    );

    await tester.scrollUntilVisible(find.byType(Switch), 200);
    expect(sfxProvider.enabled, isTrue);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(sfxProvider.enabled, isFalse);
  });

  testWidgets('shows "Not set" for the hourly wage until one is configured', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      themeProvider: ThemeProvider(),
      itemsProvider: buildTestItemsProvider(),
    );

    await tester.scrollUntilVisible(find.text('Hourly wage'), 200);
    expect(find.text('Not set — prices shown as-is'), findsOneWidget);
  });

  testWidgets('setting an hourly wage persists it and updates the summary', (
    tester,
  ) async {
    final wageProvider = WageProvider();
    await pumpSettings(
      tester,
      themeProvider: ThemeProvider(),
      itemsProvider: buildTestItemsProvider(),
      wageProvider: wageProvider,
    );

    await tester.scrollUntilVisible(find.text('Hourly wage'), 200);
    await tester.tap(find.text('Hourly wage'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '20');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(wageProvider.hourlyWage, 20);
    expect(find.text('\$20.00 / hr'), findsOneWidget);
  });

  testWidgets('removing a set hourly wage clears it', (tester) async {
    final wageProvider = WageProvider(initial: 20);
    await pumpSettings(
      tester,
      themeProvider: ThemeProvider(),
      itemsProvider: buildTestItemsProvider(),
      wageProvider: wageProvider,
    );

    await tester.scrollUntilVisible(find.text('Hourly wage'), 200);
    await tester.tap(find.text('Hourly wage'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(wageProvider.hourlyWage, isNull);
  });

  testWidgets('tapping Trash opens the trash screen', (tester) async {
    await pumpSettings(
      tester,
      themeProvider: ThemeProvider(),
      itemsProvider: buildTestItemsProvider(),
    );

    await tester.scrollUntilVisible(find.text('Trash'), 200);
    await tester.ensureVisible(find.text('Trash'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trash'));
    await tester.pumpAndSettle();

    expect(find.text('Trash is empty.'), findsOneWidget);
  });
}
