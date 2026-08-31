import 'package:flutter_test/flutter_test.dart';
import 'package:skip/data/models/item_model.dart';
import 'package:skip/data/monthly_totals.dart';

void main() {
  ItemModel makeItem({
    required double price,
    required bool isSaved,
    required DateTime createdAt,
  }) {
    return ItemModel(
      price: price,
      imagePath: 'x.jpg',
      isSaved: isSaved,
      createdAt: createdAt,
    );
  }

  test('buckets items into the trailing N months, oldest first', () {
    final items = [
      makeItem(price: 10, isSaved: true, createdAt: DateTime(2026, 6, 5)),
      makeItem(price: 5, isSaved: false, createdAt: DateTime(2026, 6, 20)),
      makeItem(price: 30, isSaved: true, createdAt: DateTime(2026, 4, 1)),
    ];

    final totals = computeMonthlyTotals(
      items,
      now: DateTime(2026, 6, 15),
      monthsBack: 3,
    );

    expect(totals.map((t) => '${t.year}-${t.month}'), [
      '2026-4',
      '2026-5',
      '2026-6',
    ]);
    expect(totals[0].saved, 30);
    expect(totals[0].spent, 0);
    expect(totals[1].saved, 0);
    expect(totals[1].spent, 0);
    expect(totals[2].saved, 10);
    expect(totals[2].spent, 5);
  });

  test('rolls back across a year boundary', () {
    final items = [
      makeItem(price: 40, isSaved: true, createdAt: DateTime(2025, 12, 10)),
    ];

    final totals = computeMonthlyTotals(
      items,
      now: DateTime(2026, 1, 20),
      monthsBack: 2,
    );

    expect(totals.map((t) => '${t.year}-${t.month}'), ['2025-12', '2026-1']);
    expect(totals[0].saved, 40);
    expect(totals[1].saved, 0);
  });

  test('returns all-zero months when there are no items', () {
    final totals = computeMonthlyTotals(
      const [],
      now: DateTime(2026, 3, 1),
      monthsBack: 6,
    );

    expect(totals, hasLength(6));
    expect(totals.every((t) => t.saved == 0 && t.spent == 0), isTrue);
  });
}
