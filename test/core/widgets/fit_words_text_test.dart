import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skip/core/widgets/fit_words_text.dart';

void main() {
  // The test font draws every glyph as a fontSize-wide square, so a word's
  // width is exactly length * fontSize * text scale.
  const style = TextStyle(fontSize: 10);

  Future<RenderParagraph> pumpText(
    WidgetTester tester,
    String text, {
    required double width,
    double textScale = 1,
    TextStyle textStyle = style,
  }) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: width,
              child: FitWordsText(text, style: textStyle),
            ),
          ),
        ),
      ),
    );
    return tester.renderObject<RenderParagraph>(find.text(text));
  }

  testWidgets('scales a word that is too wide down onto one line', (
    tester,
  ) async {
    // "Resistito!" is 10 glyphs = 200px at 2x, in a 120px box.
    final paragraph = await pumpText(
      tester,
      'Resistito!',
      width: 120,
      textScale: 2,
    );

    expect(paragraph.textScaler.scale(10), lessThan(12));
    expect(paragraph.size.height, lessThan(2 * paragraph.textScaler.scale(10)));
  });

  testWidgets('wraps between words without scaling when each word fits', (
    tester,
  ) async {
    final paragraph = await pumpText(
      tester,
      'Gespart pro Artikel',
      width: 100,
      textScale: 1,
    );

    expect(paragraph.textScaler.scale(10), 10);
    expect(paragraph.size.height, greaterThan(10));
  });

  testWidgets('still fits when letterSpacing (which never scales) is set', (
    tester,
  ) async {
    // 10 glyphs * 20px + 10 * 5px spacing = 250px at 2x, in a 120px box;
    // a single proportional rescale would leave it ~145px wide.
    final paragraph = await pumpText(
      tester,
      'Resistito!',
      width: 120,
      textScale: 2,
      textStyle: style.copyWith(letterSpacing: 5),
    );

    expect(paragraph.size.height, lessThan(2 * paragraph.textScaler.scale(10)));
  });
}
