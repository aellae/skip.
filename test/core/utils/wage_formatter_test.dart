import 'package:flutter_test/flutter_test.dart';
import 'package:skip/core/localization/app_locale.dart';
import 'package:skip/core/utils/wage_formatter.dart';

void main() {
  group('hoursOfWork', () {
    test('divides price by hourly wage', () {
      expect(hoursOfWork(50, 10), 5);
      expect(hoursOfWork(25, 10), 2.5);
    });

    test('returns null when hourlyWage is null', () {
      expect(hoursOfWork(50, null), isNull);
    });

    test('returns null when hourlyWage is zero or negative', () {
      expect(hoursOfWork(50, 0), isNull);
      expect(hoursOfWork(50, -10), isNull);
    });
  });

  group('formatHoursOfWork', () {
    test('uses a period for English', () {
      expect(formatHoursOfWork(3.5, AppLocale.en), '3.5');
    });

    test('uses a comma for Italian/French/German', () {
      expect(formatHoursOfWork(3.5, AppLocale.it), '3,5');
      expect(formatHoursOfWork(3.5, AppLocale.fr), '3,5');
      expect(formatHoursOfWork(3.5, AppLocale.de), '3,5');
    });

    test('rounds to one decimal place', () {
      expect(formatHoursOfWork(3.456, AppLocale.en), '3.5');
    });
  });
}
