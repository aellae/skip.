import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/localization/app_currency.dart';
import '../../../core/theme/app_themes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/monthly_total.dart';

/// Grouped bar chart: saved (left bar) vs spent (right bar) per month.
class MonthlyBarChart extends StatelessWidget {
  final List<MonthlyTotal> monthlyTotals;
  final AppCurrency currency;

  const MonthlyBarChart({
    super.key,
    required this.monthlyTotals,
    required this.currency,
  });

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
    // Pick a "nice" (1/2/5 * 10^n) axis interval instead of letting fl_chart's
    // auto-interval fall back to raw, unrounded steps — those can land two
    // labels (e.g. 200 and 204) close enough together to overlap.
    final axisInterval = _niceInterval(maxValue <= 0 ? 10.0 : maxValue / 4);
    // Add half a step of headroom above the top tick label: fl_chart's
    // fitInside otherwise nudges a label sitting flush at the chart's top
    // edge downward to avoid clipping it, which visually shrinks the gap
    // to the tick below it and makes the axis steps look uneven. Because
    // this pushes maxY past the last clean multiple of axisInterval,
    // leftTitles also sets maxIncluded: false below, so fl_chart doesn't
    // additionally force a label at this odd maxY value.
    final maxY = maxValue <= 0
        ? 10.0
        : (maxValue * 1.2 / axisInterval).ceil() * axisInterval +
              axisInterval / 2;

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
            // fl_chart's tooltip defaults to a 4px radius — round it to match
            // the app's own card language instead of the package default.
            tooltipBorderRadius: BorderRadius.circular(skipTheme.cardRadius),
            getTooltipColor: (_) => skipTheme.cardBackground,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final statusColor = rodIndex == 0
                  ? skipTheme.savedColor
                  : skipTheme.spentColor;
              return BarTooltipItem(
                formatCurrencyCompact(rod.toY, currency: currency),
                (axisStyle ?? const TextStyle()).copyWith(color: statusColor),
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
              reservedSize: 44,
              interval: axisInterval,
              // fl_chart always labels the exact chart maxY by default
              // (maxIncluded), even when it isn't a clean multiple of
              // interval. Since maxY here is intentionally headroom above
              // the last real tick (see below), suppress that forced label
              // so only evenly-spaced multiples of axisInterval are shown.
              maxIncluded: false,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                child: Text(
                  formatCurrencyCompact(value, currency: currency),
                  style: axisStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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

  /// Rounds [rough] up to the nearest 1/2/5 * 10^n step, so Y-axis labels
  /// land on clean, well-spaced values instead of fl_chart's raw auto-interval.
  static double _niceInterval(double rough) {
    if (rough <= 0) return 1.0;
    final magnitude = pow(10, (log(rough) / ln10).floor()).toDouble();
    final normalized = rough / magnitude;
    final niceNormalized = normalized <= 1
        ? 1.0
        : normalized <= 2
        ? 2.0
        : normalized <= 5
        ? 5.0
        : 10.0;
    return niceNormalized * magnitude;
  }
}
