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
        final scaler = constraints.hasBoundedWidth
            ? fitScaler(
                data.split(RegExp(r'\s+')),
                style: DefaultTextStyle.of(context).style.merge(style),
                maxWidth: constraints.maxWidth,
                textScaler: textScaler,
                textDirection: Directionality.of(context),
              )
            : textScaler;

        return Text(
          data,
          style: style,
          textAlign: textAlign,
          textScaler: scaler,
        );
      },
    );
  }

  /// The [textScaler], shrunk just enough for the widest of [words] to fit
  /// in [maxWidth] at [style] — or [textScaler] itself when all already
  /// fit. Measuring several texts' words together gives them one shared
  /// size (e.g. a pair of side-by-side cards); pass a whole string as a
  /// single "word" to fit it on one line.
  static TextScaler fitScaler(
    Iterable<String> words, {
    required TextStyle style,
    required double maxWidth,
    required TextScaler textScaler,
    required TextDirection textDirection,
  }) {
    double longestAt(TextScaler scaler) => words
        .map((w) => _measure(w, style, scaler, textDirection))
        .fold<double>(0, max);

    var scaler = textScaler;
    var longest = longestAt(textScaler);
    if (longest > maxWidth) {
      final fontSize = style.fontSize ?? 14;
      var factor = textScaler.scale(fontSize) / fontSize;
      // Scaling isn't perfectly proportional (letterSpacing, for one,
      // doesn't scale), so re-measure and tighten until it fits.
      for (var i = 0; i < 4 && longest > maxWidth; i++) {
        factor *= maxWidth / longest;
        scaler = TextScaler.linear(factor);
        longest = longestAt(scaler);
      }
    }
    return scaler;
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
