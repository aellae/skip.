import 'package:flutter_test/flutter_test.dart';
import 'package:skip/core/localization/app_locale.dart';
import 'package:skip/core/localization/app_strings.dart';
import 'package:skip/data/backup_service.dart';

void main() {
  group('AppStrings', () {
    test('English strings read in English', () {
      const strings = AppStrings(AppLocale.en);

      expect(strings.settingsTitle, 'Settings');
      expect(strings.resisted, 'Resisted!');
      expect(strings.boughtIt, 'Bought It');
      expect(strings.totalSaved, 'Total Saved');
    });

    test('Italian strings read in Italian', () {
      const strings = AppStrings(AppLocale.it);

      expect(strings.settingsTitle, 'Impostazioni');
      expect(strings.resisted, 'Resistito!');
      expect(strings.boughtIt, 'Comprato');
      expect(strings.totalSaved, 'Totale risparmiato');
    });

    test('importedItems pluralizes in both languages', () {
      const en = AppStrings(AppLocale.en);
      const it = AppStrings(AppLocale.it);

      expect(en.importedItems(1), 'Imported 1 item.');
      expect(en.importedItems(3), 'Imported 3 items.');
      expect(it.importedItems(1), 'Importato 1 elemento.');
      expect(it.importedItems(3), 'Importati 3 elementi.');
    });

    test('backupErrorMessage covers every BackupFormatError code', () {
      const en = AppStrings(AppLocale.en);
      const it = AppStrings(AppLocale.it);

      for (final code in BackupFormatError.values) {
        expect(en.backupErrorMessage(code), isNotEmpty);
        expect(it.backupErrorMessage(code), isNotEmpty);
      }
    });
  });

  group('AppLocale', () {
    test('fromCode round-trips known codes', () {
      expect(AppLocale.fromCode('en'), AppLocale.en);
      expect(AppLocale.fromCode('it'), AppLocale.it);
    });

    test('fromCode falls back to English for unknown/null codes', () {
      expect(AppLocale.fromCode('fr'), AppLocale.en);
      expect(AppLocale.fromCode(null), AppLocale.en);
    });

    test('code is stable for persistence', () {
      expect(AppLocale.en.code, 'en');
      expect(AppLocale.it.code, 'it');
    });
  });
}
