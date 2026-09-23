import 'dart:math';

import 'package:flutter/material.dart';

/// [Text] that only ever wraps between words. If its longest word is wider
/// than the available width — a long German compound, or any label at a
/// large system text size — the whole text is scaled down just enough for
/// that word to fit, instead of Flutter breaking the word mid-way
/// ("Resisti/to!"). Leaves the text untouched whenever it already fits.
class FitWordsText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;

  const FitWordsText(this.data, {super.key, this.style, this.textAlign});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScaler = MediaQuery.textScalerOf(context);
        final effectiveStyle = DefaultTextStyle.of(context).style.merge(style);
        var scaler = textScaler;

        if (constraints.hasBoundedWidth) {
          final longest = data
              .split(RegExp(r'\s+'))
              .map(
                (word) => _measure(
                  word,
                  effectiveStyle,
                  textScaler,
                  Directionality.of(context),
                ),
              )
              .fold<double>(0, max);
          if (longest > constraints.maxWidth) {
            final fontSize = effectiveStyle.fontSize ?? 14;
            final currentFactor = textScaler.scale(fontSize) / fontSize;
            scaler = TextScaler.linear(
              currentFactor * constraints.maxWidth / longest,
            );
          }
        }

        return Text(
          data,
          style: style,
          textAlign: textAlign,
          textScaler: scaler,
        );
      },
    );
  }

  static double _measure(
    String word,
    TextStyle style,
    TextScaler textScaler,
    TextDirection textDirection,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: word, style: style),
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    // Round up so sub-pixel differences between this measurement and the
    // real layout can't still push the word onto a mid-word break.
    final width = painter.width.ceilToDouble() + 1;
    painter.dispose();
    return width;
  }
}
