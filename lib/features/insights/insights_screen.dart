import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_spacing.dart';
import '../../core/localization/currency_provider.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_themes.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/entrance_fade.dart';
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
    final skipTheme = theme.extension<SkipThemeExtension>()!;
    final itemsProvider = context.watch<ItemsProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final strings = localeProvider.strings;
    final currency = context.watch<CurrencyProvider>().currency;
    final monthlyTotals = itemsProvider.monthlyTotals();
    final hasActivity = monthlyTotals.any((m) => m.saved != 0 || m.spent != 0);

    return Scaffold(
      appBar: SkipAppBar(title: Text(strings.insightsTitle)),
      body: SafeArea(
        child: EntranceFade(
          beginScale: 1.0,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SummaryCards(
                totalSaved: itemsProvider.totalSavedThisMonth,
                totalSpent: itemsProvider.totalSpentThisMonth,
                savedLabel: strings.thisMonthsSavings,
                spentLabel: strings.thisMonthsSpent,
              ),
              const SizedBox(height: AppSpacing.sectionGap),
              if (!hasActivity)
                EmptyState(
                  icon: skipTheme.isY2K
                      ? Icons.trending_up_rounded
                      : Icons.bar_chart_outlined,
                  message: strings.emptyInsightsMessage,
                )
              else ...[
                Text(strings.last6Months, style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    StatusIndicator(
                      isSaved: true,
                      label: strings.saved,
                      labelStyle: theme.textTheme.bodySmall,
                    ),
                    StatusIndicator(
                      isSaved: false,
                      label: strings.spent,
                      labelStyle: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: MonthlyBarChart(
                    monthlyTotals: monthlyTotals,
                    currency: currency,
                    locale: localeProvider.locale,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
