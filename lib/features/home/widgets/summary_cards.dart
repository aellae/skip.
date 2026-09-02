import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/widgets/animated_count_up.dart';
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

  @override
  Widget build(BuildContext context) {
    final skipTheme = Theme.of(context).extension<SkipThemeExtension>()!;
    final strings = context.watch<LocaleProvider>().strings;
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: savedLabel ?? strings.totalSaved,
            amount: totalSaved,
            color: skipTheme.savedColor,
            onTap: onTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: spentLabel ?? strings.totalSpent,
            amount: totalSpent,
            color: skipTheme.spentColor,
            onTap: onTap,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final VoidCallback? onTap;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SkipCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          AnimatedCountUp(
            value: amount,
            style: theme.textTheme.headlineSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
