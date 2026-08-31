import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_themes.dart';
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
    final barRadius = BorderRadius.circular(skipTheme.isY2K ? 4 : 2);

    final maxValue = monthlyTotals.fold<double>(0, (max, m) {
      final localMax = m.saved > m.spent ? m.saved : m.spent;
      return localMax > max ? localMax : max;
    });
    final maxY = maxValue <= 0 ? 10.0 : maxValue * 1.2;

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
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
                BarChartRodData(
                  toY: monthlyTotals[i].saved,
                  color: skipTheme.savedColor,
                  width: 8,
                  borderRadius: barRadius,
                ),
                BarChartRodData(
                  toY: monthlyTotals[i].spent,
                  color: skipTheme.spentColor,
                  width: 8,
                  borderRadius: barRadius,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
