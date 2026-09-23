import 'package:flutter_test/flutter_test.dart';
import 'package:skip/core/localization/app_locale.dart';
import 'package:skip/core/localization/app_strings.dart';
import 'package:skip/core/utils/motto_picker.dart';

void main() {
  const mottos = ['a', 'b', 'c'];

  group('mottoOfTheDay', () {
    test('indexes by whole days since 1970-01-01', () {
      // 1970-01-01 is day 0; 2026-09-23 is day 20719 (20719 % 3 == 1).
      expect(mottoOfTheDay(mottos, DateTime(1970, 1, 1)), 'a');
      expect(mottoOfTheDay(mottos, DateTime(1970, 1, 2)), 'b');
      expect(mottoOfTheDay(mottos, DateTime(2026, 9, 23)), 'b');
    });

    test('stays the same all day and changes at midnight', () {
      final morning = mottoOfTheDay(mottos, DateTime(2026, 9, 23, 0, 0, 1));
      final night = mottoOfTheDay(mottos, DateTime(2026, 9, 23, 23, 59, 59));
      final nextDay = mottoOfTheDay(mottos, DateTime(2026, 9, 24));
      expect(night, morning);
      expect(nextDay, isNot(morning));
    });
  });

  group('typesetMotto', () {
    const nbsp = '\u00A0';

    test('keeps French high punctuation off the start of a line', () {
      expect(
        typesetMotto('Rien ce mois-ci. Premier skip ?'),
        'Rien ce mois-ci. Premier${nbsp}skip$nbsp?',
      );
      expect(
        typesetMotto('Ton portefeuille a appelé : il va super bien.'),
        'Ton portefeuille a appelé$nbsp: il va super${nbsp}bien.',
      );
    });

    test('binds ≠ to both words and a dash to the word before it', () {
      expect(
        typesetMotto('Want ≠ need. Period.'),
        'Want$nbsp≠${nbsp}need.${nbsp}Period.',
      );
      expect(
        typesetMotto('Willst du es – oder willst du es jetzt?'),
        'Willst du es$nbsp– oder willst du es${nbsp}jetzt?',
      );
    });

    test('leaves one- and two-word lines alone', () {
      expect(typesetMotto('Skippen.'), 'Skippen.');
      expect(typesetMotto('Lass es.'), 'Lass es.');
    });

    test('every motto in every language wraps without orphans', () {
      for (final locale in AppLocale.values) {
        final strings = AppStrings(locale);
        final all = [
          ...strings.mottosMinimal,
          ...strings.mottosY2k,
          strings.widgetMottoEmptyMinimal,
          strings.widgetMottoEmptyY2k,
        ];
        for (final motto in all) {
          final typeset = typesetMotto(motto);
          final reason = '$locale: "$motto"';
          expect(
            typeset,
            isNot(matches(RegExp(r' [?!:;»≠–—]'))),
            reason: reason,
          );
          final words = typeset.split(' ');
          if (words.length > 1) {
            expect(words.last, contains(nbsp), reason: reason);
          }
          expect(typeset.replaceAll(nbsp, ' '), motto, reason: reason);
        }
      }
    });
  });
}
