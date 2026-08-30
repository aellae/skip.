import 'package:flutter_test/flutter_test.dart';
import 'package:skip/core/theme/theme_provider.dart';

void main() {
  group('ThemeProvider', () {
    test('defaults to the minimal aesthetic', () {
      final provider = ThemeProvider();

      expect(provider.aesthetic, SkipAesthetic.minimal);
      expect(provider.isY2K, isFalse);
    });

    test('can be constructed with an initial aesthetic', () {
      final provider = ThemeProvider(initial: SkipAesthetic.y2k);

      expect(provider.isY2K, isTrue);
    });

    test('setAesthetic switches themeData and notifies listeners', () {
      final provider = ThemeProvider();
      var notifications = 0;
      provider.addListener(() => notifications++);

      provider.setAesthetic(SkipAesthetic.y2k);

      expect(provider.isY2K, isTrue);
      expect(notifications, 1);
    });

    test('setAesthetic is a no-op when already on that aesthetic', () {
      final provider = ThemeProvider();
      var notifications = 0;
      provider.addListener(() => notifications++);

      provider.setAesthetic(SkipAesthetic.minimal);

      expect(notifications, 0);
    });

    test('toggle flips between minimal and y2k', () {
      final provider = ThemeProvider();

      provider.toggle();
      expect(provider.isY2K, isTrue);

      provider.toggle();
      expect(provider.isY2K, isFalse);
    });
  });
}
