import '../localization/app_locale.dart';

// Month tables per app language, following CLDR's abbreviated (`MMM`)
// forms — kept local rather than pulling in `intl`'s date symbols, which
// would need async locale-data initialization before first use. Dates must
// follow the app's selected language (AppLocale), not the device's.
const Map<AppLocale, List<String>> _monthNames = {
  AppLocale.en: [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ],
  AppLocale.it: [
    'gen', 'feb', 'mar', 'apr', 'mag', 'giu', //
    'lug', 'ago', 'set', 'ott', 'nov', 'dic',
  ],
  AppLocale.fr: [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', //
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ],
  AppLocale.de: [
    'Jan.', 'Feb.', 'März', 'Apr.', 'Mai', 'Juni', //
    'Juli', 'Aug.', 'Sept.', 'Okt.', 'Nov.', 'Dez.',
  ],
};

/// Formats a date in [locale]'s medium style: `Sep 23, 2026` (en),
/// `23 set 2026` (it), `23 sept. 2026` (fr), `23. Sept. 2026` (de).
String formatDate(DateTime date, AppLocale locale) {
  final month = _monthNames[locale]![date.month - 1];
  return switch (locale) {
    AppLocale.en => '$month ${date.day}, ${date.year}',
    AppLocale.it || AppLocale.fr => '${date.day} $month ${date.year}',
    AppLocale.de => '${date.day}. $month ${date.year}',
  };
}

/// Abbreviated month name for [month] (1-12) in [locale], capitalized for
/// use as a standalone label (e.g. chart axes): `Sep`, `Set`, `Sept.`.
String monthAbbreviation(int month, AppLocale locale) {
  final name = _monthNames[locale]![month - 1];
  return name[0].toUpperCase() + name.substring(1);
}
