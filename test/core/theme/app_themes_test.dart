import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skip/core/theme/app_themes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppThemes.minimal', () {
    final theme = AppThemes.minimal;
    final ext = theme.extension<SkipThemeExtension>();

    test('exposes the lowercase skip. logo via SkipThemeExtension', () {
      expect(ext, isNotNull);
      expect(ext!.logoText, 'skip.');
      expect(ext.isY2K, isFalse);
    });

    test('uses Playfair Display for headlines and Inter for body text', () {
      expect(
        theme.textTheme.headlineMedium!.fontFamily,
        contains('PlayfairDisplay'),
      );
      expect(theme.textTheme.bodyMedium!.fontFamily, contains('Inter'));
    });

    test('is a light theme', () {
      expect(theme.brightness, Brightness.light);
    });
  });

  group('AppThemes.y2k', () {
    final theme = AppThemes.y2k;
    final ext = theme.extension<SkipThemeExtension>();

    test('exposes the uppercase SKIP! logo via SkipThemeExtension', () {
      expect(ext, isNotNull);
      expect(ext!.logoText, 'SKIP!');
      expect(ext.isY2K, isTrue);
    });

    test('uses Titan One for headlines and Fredoka for body text', () {
      expect(theme.textTheme.headlineMedium!.fontFamily, contains('TitanOne'));
      expect(theme.textTheme.bodyMedium!.fontFamily, contains('Fredoka'));
    });

    test('is a dark theme', () {
      expect(theme.brightness, Brightness.dark);
    });
  });

  test('minimal and y2k use distinct saved/spent colors', () {
    final minimalExt = AppThemes.minimal.extension<SkipThemeExtension>()!;
    final y2kExt = AppThemes.y2k.extension<SkipThemeExtension>()!;

    expect(minimalExt.savedColor, isNot(equals(y2kExt.savedColor)));
    expect(minimalExt.spentColor, isNot(equals(y2kExt.spentColor)));
  });

  test('SkipThemeExtension.lerp switches logoText/isY2K past the midpoint', () {
    final minimalExt = AppThemes.minimal.extension<SkipThemeExtension>()!;
    final y2kExt = AppThemes.y2k.extension<SkipThemeExtension>()!;

    final past = minimalExt.lerp(y2kExt, 0.6);
    final before = minimalExt.lerp(y2kExt, 0.4);

    expect(past.logoText, 'SKIP!');
    expect(past.isY2K, isTrue);
    expect(before.logoText, 'skip.');
    expect(before.isY2K, isFalse);
  });
}
