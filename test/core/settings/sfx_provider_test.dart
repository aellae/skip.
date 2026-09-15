import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skip/core/settings/sfx_provider.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SfxProvider', () {
    test('defaults to enabled', () {
      final provider = SfxProvider();

      expect(provider.enabled, isTrue);
    });

    test('can be constructed with an initial value', () {
      final provider = SfxProvider(initial: false);

      expect(provider.enabled, isFalse);
    });

    test(
      'setEnabled toggles the flag, notifies listeners, and persists it',
      () async {
        final provider = SfxProvider();
        var notifications = 0;
        provider.addListener(() => notifications++);

        await provider.setEnabled(false);

        expect(provider.enabled, isFalse);
        expect(notifications, 1);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('skip_sfx_enabled'), isFalse);
      },
    );

    test('setEnabled is a no-op when already at that value', () async {
      final provider = SfxProvider();
      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.setEnabled(true);

      expect(notifications, 0);
    });

    test(
      'loadSaved picks up a persisted mute choice and notifies listeners',
      () async {
        SharedPreferences.setMockInitialValues({'skip_sfx_enabled': false});
        final provider = SfxProvider();
        var notifications = 0;
        provider.addListener(() => notifications++);

        await provider.loadSaved();

        expect(provider.enabled, isFalse);
        expect(notifications, 1);
      },
    );

    test('loadSaved is a no-op when nothing was ever persisted', () async {
      final provider = SfxProvider();
      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.loadSaved();

      expect(provider.enabled, isTrue);
      expect(notifications, 0);
    });
  });
}
