import 'package:flutter/material.dart';

import '../../../core/theme/app_themes.dart';
import '../../../core/utils/currency_formatter.dart';

/// The two headline financial status cards: Total Saved and Total Spent.
class SummaryCards extends StatelessWidget {
  final double totalSaved;
  final double totalSpent;
  final String savedLabel;
  final String spentLabel;

  const SummaryCards({
    super.key,
    required this.totalSaved,
    required this.totalSpent,
    this.savedLabel = 'Total Saved',
    this.spentLabel = 'Total Spent',
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
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: spentLabel,
            amount: totalSpent,
            color: skipTheme.spentColor,
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

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: skipTheme.cardBackground,
        borderRadius: BorderRadius.circular(skipTheme.isY2K ? 20 : 4),
        border: skipTheme.isY2K
            ? Border.all(color: theme.colorScheme.onSurface, width: 1.5)
            : null,
      ),
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
