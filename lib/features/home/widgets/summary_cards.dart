import 'package:flutter/material.dart';

import '../../../core/theme/app_themes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/skip_card.dart';

/// The two headline financial status cards: Total Saved and Total Spent.
class SummaryCards extends StatelessWidget {
  final double totalSaved;
  final double totalSpent;
  final String savedLabel;
  final String spentLabel;

  /// Invoked when either card is tapped — both cards point at the same
  /// destination (e.g. the Insights screen), so a single callback covers
  /// both rather than two near-identical ones.
  final VoidCallback? onTap;

  const SummaryCards({
    super.key,
    required this.totalSaved,
    required this.totalSpent,
    this.savedLabel = 'Total Saved',
    this.spentLabel = 'Total Spent',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final skipTheme = Theme.of(context).extension<SkipThemeExtension>()!;
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: savedLabel,
            amount: totalSaved,
            color: skipTheme.savedColor,
            onTap: onTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: spentLabel,
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
          Text(
            formatCurrency(amount),
            style: theme.textTheme.headlineSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
