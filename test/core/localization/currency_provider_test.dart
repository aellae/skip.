import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skip/core/localization/app_currency.dart';
import 'package:skip/core/localization/currency_provider.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('CurrencyProvider', () {
    test('defaults to USD', () {
      final provider = CurrencyProvider();

      expect(provider.currency, AppCurrency.usd);
    });

    test('can be constructed with an initial currency', () {
      final provider = CurrencyProvider(initial: AppCurrency.eur);

      expect(provider.currency, AppCurrency.eur);
    });

    test(
      'setCurrency switches currency, notifies listeners, and persists it',
      () async {
        final provider = CurrencyProvider();
        var notifications = 0;
        provider.addListener(() => notifications++);

        await provider.setCurrency(AppCurrency.eur);

        expect(provider.currency, AppCurrency.eur);
        expect(notifications, 1);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('skip_currency'), 'eur');
      },
    );

    test('setCurrency is a no-op when already on that currency', () async {
      final provider = CurrencyProvider();
      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.setCurrency(AppCurrency.usd);

      expect(notifications, 0);
    });

    test(
      'loadSaved picks up a persisted currency and notifies listeners',
      () async {
        SharedPreferences.setMockInitialValues({'skip_currency': 'eur'});
        final provider = CurrencyProvider();
        var notifications = 0;
        provider.addListener(() => notifications++);

        await provider.loadSaved();

        expect(provider.currency, AppCurrency.eur);
        expect(notifications, 1);
      },
    );

    test('loadSaved is a no-op when nothing was ever persisted', () async {
      final provider = CurrencyProvider();
      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.loadSaved();

      expect(provider.currency, AppCurrency.usd);
      expect(notifications, 0);
    });
  });

  group('AppCurrency', () {
    test('fromCode round-trips known codes', () {
      expect(AppCurrency.fromCode('usd'), AppCurrency.usd);
      expect(AppCurrency.fromCode('eur'), AppCurrency.eur);
    });

    test('fromCode falls back to USD for unknown/null codes', () {
      expect(AppCurrency.fromCode('gbp'), AppCurrency.usd);
      expect(AppCurrency.fromCode(null), AppCurrency.usd);
    });

    test('code is stable for persistence', () {
      expect(AppCurrency.usd.code, 'usd');
      expect(AppCurrency.eur.code, 'eur');
    });
  });
}
