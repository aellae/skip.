import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/utils/motto_picker.dart';
import '../../../core/widgets/fit_words_text.dart';

/// Today's motto under the Home summary cards — the same line the home-screen
/// and lock-screen widgets show, in the active aesthetic's voice: a quiet
/// italic serif aside for "Skip!", a loud rounded shout for "Skip!".
class HomeMotto extends StatelessWidget {
  const HomeMotto({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;
    final strings = context.watch<LocaleProvider>().strings;
    final mottos = skipTheme.isY2K ? strings.mottosY2k : strings.mottosMinimal;

    return _BalancedText(
      typesetMotto(mottoOfTheDay(mottos, DateTime.now())),
      style: theme.textTheme.titleLarge?.copyWith(
        fontSize: 18,
        fontStyle: skipTheme.isY2K ? FontStyle.normal : FontStyle.italic,
        fontWeight: skipTheme.isY2K ? null : FontWeight.w400,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
      ),
    );
  }
}

/// Centered text whose lines come out roughly even instead of one full line
/// and a short tail (what CSS calls `text-wrap: balance`, which Flutter
/// lacks): it narrows the box to the tightest width that still needs the
/// same number of lines.
class _BalancedText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const _BalancedText(this.text, {this.style});

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final textDirection = Directionality.of(context);
    final locale = Localizations.maybeLocaleOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        // Split only where a line may break: typesetMotto glues some words
        // with non-breaking spaces, and those runs must fit whole.
        final words = text.split(RegExp(r'[ \t\n]+'));
        // Shrink the text if even its longest run is wider than the box
        // (large system text sizes), so no word ever breaks mid-way.
        final scaler = FitWordsText.fitScaler(
          words,
          style: DefaultTextStyle.of(context).style.merge(style),
          maxWidth: maxWidth,
          textScaler: textScaler,
          textDirection: textDirection,
        );
        final painter = TextPainter(
          textDirection: textDirection,
          textScaler: scaler,
          locale: locale,
        );
        double widthOf(String s) {
          painter
            ..text = TextSpan(text: s, style: style)
            ..layout();
          return painter.width.ceilToDouble() + 1;
        }

        final longestWord = words.map(widthOf).fold<double>(0, max);
        painter.text = TextSpan(text: text, style: style);
        int linesAt(double width) {
          painter.layout(maxWidth: width);
          return painter.computeLineMetrics().length;
        }

        var width = maxWidth;
        final lines = linesAt(maxWidth);
        if (lines > 1) {
          // Never narrower than the longest word: past that, the line count
          // can stay the same only because a word got split.
          var low = max(maxWidth / lines, longestWord);
          var high = maxWidth;
          while (high - low > 1) {
            final mid = (low + high) / 2;
            if (linesAt(mid) > lines) {
              low = mid;
            } else {
              high = mid;
            }
          }
          width = high;
        }
        painter.dispose();

        return Center(
          child: SizedBox(
            width: width,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: style,
              textScaler: scaler,
            ),
          ),
        );
      },
    );
  }
}
