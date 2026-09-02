import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/widgets/skip_app_bar.dart';
import '../../core/widgets/status_indicator.dart';
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
    final itemsProvider = context.watch<ItemsProvider>();
    final monthlyTotals = itemsProvider.monthlyTotals();

    return Scaffold(
      appBar: SkipAppBar(title: const Text('Insights')),
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
            const SizedBox(height: AppSpacing.sectionGap),
            Text('Last 6 Months', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                StatusIndicator(
                  isSaved: true,
                  label: 'Saved',
                  labelStyle: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 16),
                StatusIndicator(
                  isSaved: false,
                  label: 'Spent',
                  labelStyle: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: MonthlyBarChart(monthlyTotals: monthlyTotals),
            ),
          ],
        ),
      ),
    );
  }
}
