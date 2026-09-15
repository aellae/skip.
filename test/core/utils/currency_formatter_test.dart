import 'package:flutter_test/flutter_test.dart';
import 'package:skip/core/localization/app_currency.dart';
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

  test('formats EUR with a suffix, dot thousands, comma decimal', () {
    expect(formatCurrency(5, currency: AppCurrency.eur), '5,00 €');
    expect(formatCurrency(1234.5, currency: AppCurrency.eur), '1.234,50 €');
    expect(formatCurrency(-42.5, currency: AppCurrency.eur), '-42,50 €');
  });

  test('isEuroCurrency reflects the currency, not any locale', () {
    expect(isEuroCurrency(AppCurrency.usd), isFalse);
    expect(isEuroCurrency(AppCurrency.eur), isTrue);
  });

  test('formatCurrencyCompact respects the given currency', () {
    expect(formatCurrencyCompact(1500), r'$1.5k');
    expect(formatCurrencyCompact(1500, currency: AppCurrency.eur), '1,5k €');
  });
}
