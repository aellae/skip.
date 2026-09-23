import 'package:flutter_test/flutter_test.dart';
import 'package:skip/core/localization/app_locale.dart';
import 'package:skip/core/utils/date_formatter.dart';

void main() {
  final date = DateTime(2026, 9, 23);

  test('formatDate follows each app language', () {
    expect(formatDate(date, AppLocale.en), 'Sep 23, 2026');
    expect(formatDate(date, AppLocale.it), '23 set 2026');
    expect(formatDate(date, AppLocale.fr), '23 sept. 2026');
    expect(formatDate(date, AppLocale.de), '23. Sept. 2026');
    expect(formatDate(DateTime(2026, 12, 1), AppLocale.en), 'Dec 1, 2026');
  });

  test('monthAbbreviation is localized and capitalized', () {
    expect(monthAbbreviation(1, AppLocale.en), 'Jan');
    expect(monthAbbreviation(9, AppLocale.it), 'Set');
    expect(monthAbbreviation(2, AppLocale.fr), 'Févr.');
    expect(monthAbbreviation(3, AppLocale.de), 'März');
    for (final locale in AppLocale.values) {
      for (var month = 1; month <= 12; month++) {
        expect(monthAbbreviation(month, locale), isNotEmpty);
      }
    }
  });
}
