import 'package:flutter/material.dart';

/// Raw color tokens for the two SKIP aesthetics.
///
/// These are only ever consumed by [AppThemes] to build [ThemeData] objects.
/// Widgets must read colors via `Theme.of(context)`, never these constants
/// directly.
class AppColors {
  AppColors._();

  // Quiet Luxury ("Skip!")
  static const minimalCharcoal = Color(0xFF2C302E);
  static const minimalSilkBeige = Color(0xFFE7DFD3);
  static const minimalChampagne = Color(0xFFE9D5A5);
  static const minimalSoftWhite = Color(0xFFFDFBF7);
  static const minimalSaved = Color(0xFF3F5470);
  static const minimalSpent = Color(0xFFB07A6E);
  static const minimalPondering = Color(0xFF9A8F84);

  // Baddie Y2K ("Skip!")
  static const y2kHotMagenta = Color(0xFFFF007F);
  static const y2kElectricViolet = Color(0xFFB026FF);
  static const y2kMetallicSilver = Color(0xFFE0E0E0);
  static const y2kGlitterPink = Color(0xFFFFD1EC);
  static const y2kBlack = Color(0xFF181022);
  static const y2kSaved = Color(0xFF00E5FF);
  static const y2kSpent = Color(0xFFFF5FC8);
  static const y2kPondering = Color(0xFFFFC400);
  static const y2kDeepSurface = Color(0xFF241A33);
}
