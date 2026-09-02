import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skip/core/constants/app_colors.dart';
import 'package:skip/core/theme/contrast.dart';

void main() {
  group('contrastRatio', () {
    test('black vs white is the maximum ratio', () {
      expect(contrastRatio(Colors.black, Colors.white), closeTo(21.0, 0.01));
    });

    test('identical colors have a ratio of 1', () {
      expect(contrastRatio(Colors.red, Colors.red), closeTo(1.0, 0.01));
    });

    test('is symmetric regardless of argument order', () {
      expect(
        contrastRatio(Colors.black, AppColors.y2kSpent),
        closeTo(contrastRatio(AppColors.y2kSpent, Colors.black), 0.0001),
      );
    });
  });

  group('bestOnColor', () {
    test('picks white for a dark background', () {
      expect(bestOnColor(Colors.black), Colors.white);
    });

    test('picks black for a light background', () {
      expect(bestOnColor(Colors.white), Colors.black);
    });

    test('honors custom light/dark candidates', () {
      expect(
        bestOnColor(Colors.black, light: Colors.yellow, dark: Colors.blue),
        Colors.yellow,
      );
    });
  });

  group('status colors are legible as text', () {
    // WCAG's large-text minimum (3:1) — these colors are always rendered at
    // headline/title sizes (price figures, summary totals), never as small
    // body text, so this is the correct bar rather than the stricter 4.5:1.
    const minimumContrast = 3.0;

    void expectLegible(String label, Color foreground, Color background) {
      final ratio = contrastRatio(foreground, background);
      expect(
        ratio,
        greaterThanOrEqualTo(minimumContrast),
        reason:
            '$label ($foreground on $background) has contrast $ratio, '
            'below the $minimumContrast:1 large-text minimum',
      );
    }

    test('Minimal saved/spent vs. scaffold and card backgrounds', () {
      expectLegible(
        'minimalSaved on soft white',
        AppColors.minimalSaved,
        AppColors.minimalSoftWhite,
      );
      expectLegible(
        'minimalSaved on silk beige',
        AppColors.minimalSaved,
        AppColors.minimalSilkBeige,
      );
      expectLegible(
        'minimalSpent on soft white',
        AppColors.minimalSpent,
        AppColors.minimalSoftWhite,
      );
      expectLegible(
        'minimalSpent on silk beige',
        AppColors.minimalSpent,
        AppColors.minimalSilkBeige,
      );
    });

    test('Y2K saved/spent vs. scaffold and card backgrounds', () {
      expectLegible(
        'y2kSaved on black',
        AppColors.y2kSaved,
        AppColors.y2kBlack,
      );
      expectLegible(
        'y2kSaved on deep surface',
        AppColors.y2kSaved,
        AppColors.y2kDeepSurface,
      );
      expectLegible(
        'y2kSpent on black',
        AppColors.y2kSpent,
        AppColors.y2kBlack,
      );
      expectLegible(
        'y2kSpent on deep surface',
        AppColors.y2kSpent,
        AppColors.y2kDeepSurface,
      );
    });
  });
}
