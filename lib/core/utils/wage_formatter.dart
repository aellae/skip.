import '../localization/app_locale.dart';

/// Hours of work [price] represents at [hourlyWage]. Returns `null` when
/// there's no sane wage to divide by, so callers can skip rendering rather
/// than show a nonsensical value.
double? hoursOfWork(double price, double? hourlyWage) {
  if (hourlyWage == null || hourlyWage <= 0) return null;
  return price / hourlyWage;
}

/// Formats [hours] to one decimal place, using [locale]'s own decimal
/// separator — comma for it/fr/de, period for en — the same convention
/// `formatCurrency` already applies for its own separators.
String formatHoursOfWork(double hours, AppLocale locale) {
  final fixed = hours.toStringAsFixed(1);
  return locale == AppLocale.en ? fixed : fixed.replaceAll('.', ',');
}
