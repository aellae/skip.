import 'package:flutter/material.dart';

/// Raw color tokens for the two SKIP aesthetics.
///
/// These are only ever consumed by [AppThemes] to build [ThemeData] objects.
/// Widgets must read colors via `Theme.of(context)`, never these constants
/// directly.
class AppColors {
  AppColors._();

  // Quiet Luxury ("skip.")
  static const minimalCharcoal = Color(0xFF2C302E);
  static const minimalSilkBeige = Color(0xFFE7DFD3);
  static const minimalChampagne = Color(0xFFE9D5A5);
  static const minimalSoftWhite = Color(0xFFFDFBF7);
  static const minimalSaved = Color(0xFFA8BBA2);
  static const minimalSpent = Color(0xFFE7BEBE);

  // Bratz Y2K ("SKIP!")
  static const y2kHotMagenta = Color(0xFFFF007F);
  static const y2kElectricViolet = Color(0xFFB026FF);
  static const y2kMetallicSilver = Color(0xFFE0E0E0);
  static const y2kGlitterPink = Color(0xFFFFD1EC);
  static const y2kBlack = Color(0xFF181022);
  static const y2kSaved = Color(0xFF00E5A0);
  static const y2kSpent = Color(0xFF6B003B);
  static const y2kDeepSurface = Color(0xFF241A33);
}
