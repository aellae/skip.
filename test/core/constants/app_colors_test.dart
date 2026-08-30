import 'package:flutter_test/flutter_test.dart';
import 'package:skip/core/constants/app_colors.dart';

void main() {
  test('minimal and y2k palettes are fully opaque and mutually distinct', () {
    final minimal = [
      AppColors.minimalCharcoal,
      AppColors.minimalSilkBeige,
      AppColors.minimalChampagne,
      AppColors.minimalSoftWhite,
      AppColors.minimalSaved,
      AppColors.minimalSpent,
    ];
    final y2k = [
      AppColors.y2kHotMagenta,
      AppColors.y2kElectricViolet,
      AppColors.y2kMetallicSilver,
      AppColors.y2kGlitterPink,
      AppColors.y2kBlack,
      AppColors.y2kSaved,
      AppColors.y2kSpent,
    ];

    for (final color in [...minimal, ...y2k]) {
      expect(color.a, 1.0, reason: '$color must be fully opaque');
    }
    expect(
      minimal.toSet().length,
      minimal.length,
      reason: 'minimal palette has a duplicate',
    );
    expect(
      y2k.toSet().length,
      y2k.length,
      reason: 'y2k palette has a duplicate',
    );
  });
}
