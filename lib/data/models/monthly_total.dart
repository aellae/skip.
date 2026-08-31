/// Aggregated saved/spent totals for one calendar month, used to power the
/// Insights bar chart.
class MonthlyTotal {
  final int year;
  final int month; // 1-12
  final double saved;
  final double spent;

  const MonthlyTotal({
    required this.year,
    required this.month,
    required this.saved,
    required this.spent,
  });
}
