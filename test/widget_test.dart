import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skip/core/localization/app_locale.dart';
import 'package:skip/core/localization/locale_provider.dart';
import 'package:skip/core/theme/theme_provider.dart';
import 'package:skip/main.dart';

import 'test_helpers/widget_test_env.dart';

void main() {
  setUpAll(() => setUpWidgetTestEnvironment());

  testWidgets(
    'SkipApp shows the minimal logo by default and switches to Skip! on toggle',
    (tester) async {
      final themeProvider = ThemeProvider();
      final itemsProvider = buildTestItemsProvider();

      await tester.pumpWidget(
        SkipApp(
          themeProviderOverride: themeProvider,
          itemsProviderOverride: itemsProvider,
        ),
      );
      await tester.pumpAndSettle();

      Image logoImage() => tester.widget<Image>(find.byType(Image));
      String logoAssetKey() => (logoImage().image as AssetImage).assetName;

      expect(logoAssetKey(), 'assets/images/logo_minimal.png');
      expect(logoImage().semanticLabel, 'Skip!');

      themeProvider.toggle();
      await tester.pumpAndSettle();

      expect(logoAssetKey(), 'assets/images/logo_y2k.png');
      expect(logoImage().semanticLabel, 'Skip!');
    },
  );

  testWidgets('framework strings follow the app language, live', (
    tester,
  ) async {
    final localeProvider = LocaleProvider(initial: AppLocale.it);
    await tester.pumpWidget(
      SkipApp(
        itemsProviderOverride: buildTestItemsProvider(),
        localeProviderOverride: localeProvider,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Impostazioni'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Indietro'), findsOneWidget);

    localeProvider.setLocale(AppLocale.de);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Zurück'), findsOneWidget);
  });
}
