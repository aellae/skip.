/// Formats a price as `$1,234.56` without pulling in a locale/formatting
/// package — SKIP doesn't need multi-currency or locale support.
String formatCurrency(double value) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts[0];
  final cents = parts[1];
  final isNegative = whole.startsWith('-');
  final digits = isNegative ? whole.substring(1) : whole;

  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }

  return '${isNegative ? '-' : ''}\$$buffer.$cents';
}

/// Compact form for tight spaces (chart axis labels): no cents, and values
/// at or above 1,000 collapse to e.g. `$1.2k` / `$120k`.
String formatCurrencyCompact(double value) {
  final isNegative = value < 0;
  final abs = value.abs();
  final body = abs >= 1000
      ? '${(abs / 1000).toStringAsFixed(abs >= 100000 ? 0 : 1)}k'
      : abs.toStringAsFixed(0);
  return '${isNegative ? '-' : ''}\$$body';
}
