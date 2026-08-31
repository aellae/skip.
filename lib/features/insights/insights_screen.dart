import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_themes.dart';
import '../../data/items_provider.dart';
import '../home/widgets/summary_cards.dart';
import 'widgets/monthly_bar_chart.dart';

/// Monthly savings/spend breakdown: this month's totals plus a 6-month bar
/// chart, so the user can see financial-resistance trends over time.
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;
    final itemsProvider = context.watch<ItemsProvider>();
    final monthlyTotals = itemsProvider.monthlyTotals();

    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SummaryCards(
              totalSaved: itemsProvider.totalSavedThisMonth,
              totalSpent: itemsProvider.totalSpentThisMonth,
              savedLabel: "This Month's Savings",
              spentLabel: "This Month's Spent",
            ),
            const SizedBox(height: 32),
            Text('Last 6 Months', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                _LegendDot(color: skipTheme.savedColor, label: 'Saved'),
                const SizedBox(width: 16),
                _LegendDot(color: skipTheme.spentColor, label: 'Spent'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: MonthlyBarChart(monthlyTotals: monthlyTotals),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
