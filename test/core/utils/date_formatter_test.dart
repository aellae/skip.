import 'package:flutter_test/flutter_test.dart';
import 'package:skip/core/utils/date_formatter.dart';

void main() {
  test('formats a date as "Mon d, yyyy"', () {
    expect(formatDate(DateTime(2026, 1, 15)), 'Jan 15, 2026');
    expect(formatDate(DateTime(2026, 12, 1)), 'Dec 1, 2026');
  });

  test('monthAbbreviation returns the three-letter month name', () {
    expect(monthAbbreviation(1), 'Jan');
    expect(monthAbbreviation(6), 'Jun');
    expect(monthAbbreviation(12), 'Dec');
  });
}
