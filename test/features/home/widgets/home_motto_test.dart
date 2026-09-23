import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:skip/core/localization/app_locale.dart';
import 'package:skip/core/localization/locale_provider.dart';
import 'package:skip/core/theme/app_themes.dart';
import 'package:skip/features/home/widgets/home_motto.dart';

/// The iOS QA follow-up saw "more choi / ces." at the largest text size:
/// balancing the lines must never split a word.
void main() {
  for (final theme in [AppThemes.minimal, AppThemes.y2k]) {
    for (final locale in AppLocale.values) {
      for (final scale in [1.0, 2.0, 3.0]) {
        final y2k = theme.extension<SkipThemeExtension>()!.isY2K;
        testWidgets('no word is split: ${y2k ? 'y2k' : 'minimal'}, '
            '${locale.name}, ${scale}x', (tester) async {
          tester.view.physicalSize = const Size(1179, 2556);
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            ChangeNotifierProvider(
              create: (_) => LocaleProvider(initial: locale),
              child: MaterialApp(
                theme: theme,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: const Scaffold(
                  body: Padding(
                    padding: EdgeInsets.all(16),
                    child: HomeMotto(),
                  ),
                ),
              ),
            ),
          );

          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(
              of: find.byType(HomeMotto),
              matching: find.byType(RichText),
            ),
          );
          final text = paragraph.text.toPlainText();
          for (final match in RegExp(r'\S+').allMatches(text)) {
            final tops = paragraph
                .getBoxesForSelection(
                  TextSelection(
                    baseOffset: match.start,
                    extentOffset: match.end,
                  ),
                )
                .map((b) => b.top)
                .toSet();
            expect(tops, hasLength(1), reason: '"${match[0]}" is split');
          }
        });
      }
    }
  }
}
