import 'package:flutter_test/flutter_test.dart';
import 'package:skip/core/utils/currency_formatter.dart';

void main() {
  test('formats whole and fractional amounts with two decimals', () {
    expect(formatCurrency(5), r'$5.00');
    expect(formatCurrency(19.99), r'$19.99');
    expect(formatCurrency(0), r'$0.00');
  });

  test('inserts thousands separators for large amounts', () {
    expect(formatCurrency(1234.5), r'$1,234.50');
    expect(formatCurrency(1000000), r'$1,000,000.00');
  });

  test('rounds to two decimal places', () {
    expect(formatCurrency(19.999), r'$20.00');
    expect(formatCurrency(19.994), r'$19.99');
  });

  test(
    'formats negative amounts with the minus sign before the dollar sign',
    () {
      expect(formatCurrency(-42.5), r'-$42.50');
    },
  );
}
