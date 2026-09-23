import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:skip/core/localization/app_locale.dart';
import 'package:skip/core/localization/locale_provider.dart';
import 'package:skip/core/settings/sfx_provider.dart';
import 'package:skip/core/theme/app_themes.dart';
import 'package:skip/features/coin_flip/coin_flip_screen.dart';

void main() {
  Future<void> pumpCoinFlip(
    WidgetTester tester,
    AppLocale locale, {
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        // Keyed by locale so re-pumping builds a fresh LocaleProvider.
        key: ValueKey(locale),
        providers: [
          ChangeNotifierProvider(
            create: (_) => LocaleProvider(initial: locale),
          ),
          ChangeNotifierProvider(create: (_) => SfxProvider()),
        ],
        child: MaterialApp(
          theme: theme ?? AppThemes.minimal,
          home: const CoinFlipScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the coin has a localized screen-reader label', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpCoinFlip(tester, AppLocale.en);
    expect(find.bySemanticsLabel('Flip the coin'), findsOneWidget);

    await pumpCoinFlip(tester, AppLocale.it);
    expect(find.bySemanticsLabel('Lancia la moneta'), findsOneWidget);
    semantics.dispose();
  });

  for (final theme in [AppThemes.minimal, AppThemes.y2k]) {
    final name = theme.extension<SkipThemeExtension>()!.isY2K
        ? 'y2k'
        : 'minimal';
    testWidgets('fits a landscape phone, mid-flip too ($name)', (tester) async {
      // iPhone 16 in landscape (iOS QA check 10.3).
      tester.view.physicalSize = const Size(2556, 1179);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await pumpCoinFlip(tester, AppLocale.de, theme: theme);
      expect(tester.takeException(), isNull);

      await tester.tap(find.bySemanticsLabel('Münze werfen'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      // Past the flip, result reveal and confetti (which never "settles").
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull);
    });
  }
}
