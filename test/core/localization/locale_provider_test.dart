import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skip/core/localization/app_locale.dart';
import 'package:skip/core/localization/locale_provider.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('LocaleProvider', () {
    test('defaults to English', () {
      final provider = LocaleProvider();

      expect(provider.locale, AppLocale.en);
      expect(provider.isItalian, isFalse);
    });

    test('can be constructed with an initial locale', () {
      final provider = LocaleProvider(initial: AppLocale.it);

      expect(provider.isItalian, isTrue);
    });

    test(
      'setLocale switches locale, notifies listeners, and persists it',
      () async {
        final provider = LocaleProvider();
        var notifications = 0;
        provider.addListener(() => notifications++);

        await provider.setLocale(AppLocale.it);

        expect(provider.isItalian, isTrue);
        expect(notifications, 1);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('skip_locale'), 'it');
      },
    );

    test('setLocale is a no-op when already on that locale', () async {
      final provider = LocaleProvider();
      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.setLocale(AppLocale.en);

      expect(notifications, 0);
    });

    test(
      'loadSaved picks up a persisted locale and notifies listeners',
      () async {
        SharedPreferences.setMockInitialValues({'skip_locale': 'it'});
        final provider = LocaleProvider();
        var notifications = 0;
        provider.addListener(() => notifications++);

        await provider.loadSaved();

        expect(provider.isItalian, isTrue);
        expect(notifications, 1);
      },
    );

    test('loadSaved is a no-op when nothing was ever persisted', () async {
      final provider = LocaleProvider();
      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.loadSaved();

      expect(provider.locale, AppLocale.en);
      expect(notifications, 0);
    });
  });
}
