import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_currency.dart';
import '../../../core/localization/currency_provider.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/animated_count_up.dart';
import '../../../core/widgets/fit_words_text.dart';
import '../../../core/widgets/skip_card.dart';

/// The two headline financial status cards: Total Saved and Total Spent.
class SummaryCards extends StatelessWidget {
  final double totalSaved;
  final double totalSpent;

  /// Defaults to the localized "Total Saved" / "Total Spent" when omitted;
  /// callers (e.g. the Insights screen) override these for a different
  /// framing of the same two numbers, like "This Month's Savings".
  final String? savedLabel;
  final String? spentLabel;

  /// Invoked when either card is tapped — both cards point at the same
  /// destination (e.g. the Insights screen), so a single callback covers
  /// both rather than two near-identical ones.
  final VoidCallback? onTap;

  const SummaryCards({
    super.key,
    required this.totalSaved,
    required this.totalSpent,
    this.savedLabel,
    this.spentLabel,
    this.onTap,
  });

  static const double _gap = 12;
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 20,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;
    final strings = context.watch<LocaleProvider>().strings;
    final currency = context.watch<CurrencyProvider>().currency;
    final saved = savedLabel ?? strings.totalSaved;
    final spent = spentLabel ?? strings.totalSpent;

    // Both cards share one label size and one amount size (the smaller of
    // the two), so a long word or a large total on one side doesn't leave
    // the pair looking mismatched at large system text sizes.
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScaler = MediaQuery.textScalerOf(context);
        var labelScaler = textScaler;
        var amountScaler = textScaler;
        if (constraints.hasBoundedWidth) {
          final width = (constraints.maxWidth - _gap) / 2 - _padding.horizontal;
          final baseStyle = DefaultTextStyle.of(context).style;
          final textDirection = Directionality.of(context);
          labelScaler = FitWordsText.fitScaler(
            '$saved $spent'.split(RegExp(r'\s+')),
            style: baseStyle.merge(theme.textTheme.labelLarge),
            maxWidth: width,
            textScaler: textScaler,
            textDirection: textDirection,
          );
          amountScaler = FitWordsText.fitScaler(
            [
              formatCurrency(totalSaved, currency: currency),
              formatCurrency(totalSpent, currency: currency),
            ],
            style: baseStyle.merge(theme.textTheme.headlineSmall),
            maxWidth: width,
            textScaler: textScaler,
            textDirection: textDirection,
          );
        }

        Widget card(String label, double amount, Color color) => _SummaryCard(
          label: label,
          amount: amount,
          color: color,
          currency: currency,
          labelScaler: labelScaler,
          amountScaler: amountScaler,
          onTap: onTap,
        );

        // Equal heights even when only one label wraps.
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: card(saved, totalSaved, skipTheme.savedColor)),
              const SizedBox(width: _gap),
              Expanded(child: card(spent, totalSpent, skipTheme.spentColor)),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final AppCurrency currency;
  final TextScaler labelScaler;
  final TextScaler amountScaler;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.currency,
    required this.labelScaler,
    required this.amountScaler,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SkipCard(
      padding: SummaryCards._padding,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge,
            textScaler: labelScaler,
          ),
          const SizedBox(height: 8),
          // One line, scaled down if needed: a wrapped or clipped amount
          // (large totals, large system text) is harder to read than a
          // smaller one. The FittedBox only matters mid count-up.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedCountUp(
              value: amount,
              formatter: (v) => formatCurrency(v, currency: currency),
              style: theme.textTheme.headlineSmall?.copyWith(color: color),
              textScaler: amountScaler,
            ),
          ),
        ],
      ),
    );
  }
}
