import '../localization/app_currency.dart';

/// Whether [currency] displays as euros (suffixed `€`) rather than dollars
/// (prefixed `$`) — the single source of truth other currency-aware UI
/// (entry form prefixes, formatters below) should read instead of
/// re-deriving `currency == AppCurrency.eur` themselves.
bool isEuroCurrency(AppCurrency currency) => currency == AppCurrency.eur;

/// Formats a price for display, following the active currency's own
/// convention rather than a single hardcoded one — independent of the UI's
/// display language:
/// - USD: `$1,234.56` — dollar prefix, comma thousands, dot decimal.
/// - EUR: `1.234,56 €` — euro suffix, dot thousands, comma decimal.
String formatCurrency(double value, {AppCurrency currency = AppCurrency.usd}) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts[0];
  final cents = parts[1];
  final isNegative = whole.startsWith('-');
  final digits = isNegative ? whole.substring(1) : whole;
  final isEuro = isEuroCurrency(currency);
  final thousandsSeparator = isEuro ? '.' : ',';

  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(thousandsSeparator);
    }
    buffer.write(digits[i]);
  }

  final sign = isNegative ? '-' : '';
  return isEuro ? '$sign$buffer,$cents €' : '$sign\$$buffer.$cents';
}

/// A bare, editable amount for prefilling a price field: two decimals with
/// the active currency's decimal separator (`203.00` / `203,00`, matching
/// [formatCurrency]), no symbol or grouping — the price fields accept
/// either separator back.
String formatAmountForInput(double value, {required AppCurrency currency}) {
  final fixed = value.toStringAsFixed(2);
  return isEuroCurrency(currency) ? fixed.replaceAll('.', ',') : fixed;
}

/// Compact form for tight spaces (chart axis labels): no cents, and values
/// at or above 1,000 collapse to e.g. `$1.2k` / `1,2k €`.
String formatCurrencyCompact(
  double value, {
  AppCurrency currency = AppCurrency.usd,
}) {
  final isNegative = value < 0;
  final abs = value.abs();
  final body = abs >= 1000
      ? '${(abs / 1000).toStringAsFixed(abs >= 100000 ? 0 : 1)}k'
      : abs.toStringAsFixed(0);
  final sign = isNegative ? '-' : '';

  if (!isEuroCurrency(currency)) {
    return '$sign\$$body';
  }
  return '$sign${body.replaceAll('.', ',')} €';
}
