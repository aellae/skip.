import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skip/core/settings/wage_provider.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('WageProvider', () {
    test('defaults to unset', () {
      final provider = WageProvider();

      expect(provider.hourlyWage, isNull);
    });

    test('can be constructed with an initial value', () {
      final provider = WageProvider(initial: 25);

      expect(provider.hourlyWage, 25);
    });

    test(
      'setHourlyWage sets the wage, notifies listeners, and persists it',
      () async {
        final provider = WageProvider();
        var notifications = 0;
        provider.addListener(() => notifications++);

        await provider.setHourlyWage(25);

        expect(provider.hourlyWage, 25);
        expect(notifications, 1);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getDouble('skip_hourly_wage'), 25);
      },
    );

    test(
      'setHourlyWage(null) clears a previously set wage and removes it from prefs',
      () async {
        final provider = WageProvider();
        await provider.setHourlyWage(25); // seed persisted value
        var notifications = 0;
        provider.addListener(() => notifications++);

        await provider.setHourlyWage(null);

        expect(provider.hourlyWage, isNull);
        expect(notifications, 1);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey('skip_hourly_wage'), isFalse);
      },
    );

    test('setHourlyWage is a no-op when already at that value', () async {
      final provider = WageProvider();
      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.setHourlyWage(null);

      expect(notifications, 0);
    });

    test(
      'loadSaved picks up a persisted wage and notifies listeners',
      () async {
        SharedPreferences.setMockInitialValues({'skip_hourly_wage': 30.0});
        final provider = WageProvider();
        var notifications = 0;
        provider.addListener(() => notifications++);

        await provider.loadSaved();

        expect(provider.hourlyWage, 30);
        expect(notifications, 1);
      },
    );

    test('loadSaved is a no-op when nothing was ever persisted', () async {
      final provider = WageProvider();
      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.loadSaved();

      expect(provider.hourlyWage, isNull);
      expect(notifications, 0);
    });
  });
}
