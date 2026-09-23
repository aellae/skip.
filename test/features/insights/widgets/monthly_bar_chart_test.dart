import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skip/core/localization/app_currency.dart';
import 'package:skip/core/localization/app_locale.dart';
import 'package:skip/core/theme/app_themes.dart';
import 'package:skip/core/theme/theme_provider.dart';
import 'package:skip/data/models/monthly_total.dart';
import 'package:skip/features/insights/widgets/monthly_bar_chart.dart';

/// Every axis label must get the full width its text needs — the iOS QA
/// run (check 8.5) saw `3,0k…` in place of `3,0k €`.
void main() {
  final totals = [
    for (var m = 4; m <= 9; m++)
      MonthlyTotal(year: 2026, month: m, saved: 2900, spent: 1200),
  ];

  Future<void> pumpChart(
    WidgetTester tester, {
    required AppLocale locale,
    required AppCurrency currency,
    required SkipAesthetic aesthetic,
    double textScale = 1,
    double height = 260,
    double width = 393,
  }) async {
    tester.view.physicalSize = Size(width * 3, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: aesthetic == SkipAesthetic.y2k
            ? AppThemes.y2k
            : AppThemes.minimal,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: height,
              child: MonthlyBarChart(
                monthlyTotals: totals,
                currency: currency,
                locale: locale,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void expectNoClippedLabels(WidgetTester tester) {
    final paragraphs = tester.renderObjectList<RenderParagraph>(
      find.descendant(
        of: find.byType(MonthlyBarChart),
        matching: find.byType(RichText),
      ),
    );
    expect(paragraphs, isNotEmpty);
    for (final paragraph in paragraphs) {
      final needed = paragraph.getMaxIntrinsicWidth(double.infinity);
      expect(
        paragraph.size.width,
        greaterThanOrEqualTo(needed - 0.5),
        reason: '"${paragraph.text.toPlainText()}" is clipped',
      );
    }
  }

  for (final aesthetic in SkipAesthetic.values) {
    for (final currency in AppCurrency.values) {
      for (final locale in AppLocale.values) {
        testWidgets(
          'labels fit: ${aesthetic.name}, ${currency.name}, ${locale.name}',
          (tester) async {
            await pumpChart(
              tester,
              locale: locale,
              currency: currency,
              aesthetic: aesthetic,
            );
            expectNoClippedLabels(tester);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('the y-axis leaves the plot most of the width at 3x text', (
    tester,
  ) async {
    await pumpChart(
      tester,
      locale: AppLocale.de,
      currency: AppCurrency.eur,
      aesthetic: SkipAesthetic.minimal,
      textScale: 3,
    );
    expectNoClippedLabels(tester);
    final chartWidth = tester.getSize(find.byType(MonthlyBarChart)).width;
    final label = tester.getRect(find.text('2,0k €'));
    expect(label.right, lessThanOrEqualTo(16 + chartWidth * 0.25));
    expect(tester.takeException(), isNull);
  });

  testWidgets('y-axis labels never overlap at large text', (tester) async {
    // Insights' chart height, at iOS's largest accessibility size. Wider
    // than a phone because the test font's square glyphs are far wider
    // than real ones: this keeps the labels about as tall as on device.
    await pumpChart(
      tester,
      locale: AppLocale.de,
      currency: AppCurrency.eur,
      aesthetic: SkipAesthetic.y2k,
      textScale: 3.5,
      height: 250,
      width: 900,
    );
    final rects =
        tester
            .widgetList<Text>(find.textContaining('€'))
            .map((t) => tester.getRect(find.text(t.data!)))
            .toList()
          ..sort((a, b) => a.top.compareTo(b.top));
    expect(rects.length, greaterThanOrEqualTo(2));
    for (var i = 1; i < rects.length; i++) {
      expect(rects[i].top, greaterThanOrEqualTo(rects[i - 1].bottom));
    }
    expect(tester.takeException(), isNull);
  });
}
