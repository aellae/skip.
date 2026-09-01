import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_themes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/monthly_total.dart';

/// Grouped bar chart: saved (left bar) vs spent (right bar) per month.
class MonthlyBarChart extends StatelessWidget {
  final List<MonthlyTotal> monthlyTotals;

  const MonthlyBarChart({super.key, required this.monthlyTotals});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skipTheme = theme.extension<SkipThemeExtension>()!;
    final axisStyle = theme.textTheme.labelSmall;
    final barRadius = BorderRadius.vertical(
      top: Radius.circular(skipTheme.isY2K ? 8 : 3),
    );

    final maxValue = monthlyTotals.fold<double>(0, (max, m) {
      final localMax = m.saved > m.spent ? m.saved : m.spent;
      return localMax > max ? localMax : max;
    });
    final maxY = maxValue <= 0 ? 10.0 : maxValue * 1.2;

    BarChartRodData rod(double value, Color statusColor) {
      return BarChartRodData(
        toY: value,
        // Y2K bars get a per-status gradient (never the shared brand
        // accentGradient, which would erase the saved/spent distinction);
        // Minimal stays flat.
        color: skipTheme.isY2K ? null : statusColor,
        gradient: skipTheme.isY2K
            ? LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [statusColor, Colors.white.withValues(alpha: 0.85)],
              )
            : null,
        width: 8,
        borderRadius: barRadius,
      );
    }

    return BarChart(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => skipTheme.cardBackground,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final statusColor = rodIndex == 0
                  ? skipTheme.savedColor
                  : skipTheme.spentColor;
              return BarTooltipItem(
                formatCurrencyCompact(rod.toY),
                (axisStyle ?? const TextStyle()).copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) =>
                  Text(formatCurrencyCompact(value), style: axisStyle),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= monthlyTotals.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: 8,
                  child: Text(
                    monthAbbreviation(monthlyTotals[index].month),
                    style: axisStyle,
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < monthlyTotals.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: 4,
              barRods: [
                rod(monthlyTotals[i].saved, skipTheme.savedColor),
                rod(monthlyTotals[i].spent, skipTheme.spentColor),
              ],
            ),
        ],
      ),
    );
  }
}
