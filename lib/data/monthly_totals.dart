import 'models/item_model.dart';
import 'models/monthly_total.dart';

/// Buckets [items] into the last [monthsBack] calendar months, oldest
/// first, ending with the month of [now]. Months with no activity are
/// still included (with zero totals) so the Insights chart always shows a
/// consistent, evenly-spaced set of months rather than skipping gaps.
List<MonthlyTotal> computeMonthlyTotals(
  List<ItemModel> items, {
  required DateTime now,
  int monthsBack = 6,
}) {
  // DateTime normalizes an out-of-range month (e.g. month 0 or -1), so this
  // correctly rolls back across year boundaries without special-casing.
  final months = List.generate(
    monthsBack,
    (i) => DateTime(now.year, now.month - (monthsBack - 1 - i), 1),
  );

  return months.map((month) {
    var saved = 0.0;
    var spent = 0.0;
    for (final item in items) {
      if (item.createdAt.year != month.year ||
          item.createdAt.month != month.month) {
        continue;
      }
      if (item.isSaved) {
        saved += item.price;
      } else {
        spent += item.price;
      }
    }
    return MonthlyTotal(
      year: month.year,
      month: month.month,
      saved: saved,
      spent: spent,
    );
  }).toList();
}
