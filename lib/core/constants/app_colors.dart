import 'package:flutter/material.dart';

/// Raw color tokens for the two SKIP aesthetics.
///
/// These are only ever consumed by [AppThemes] to build [ThemeData] objects.
/// Widgets must read colors via `Theme.of(context)`, never these constants
/// directly.
class AppColors {
  AppColors._();

  // Quiet Luxury ("skip.")
  static const minimalCharcoal = Color(0xFF2B2925);
  static const minimalSilkBeige = Color(0xFFE7DFD3);
  static const minimalChampagne = Color(0xFFD4C2A5);
  static const minimalSoftWhite = Color(0xFFFAF8F5);
  static const minimalSaved = Color(0xFF3F6B4F);
  static const minimalSpent = Color(0xFFA34C3F);

  // Bratz Y2K ("SKIP!")
  static const y2kHotMagenta = Color(0xFFFF2E9A);
  static const y2kElectricViolet = Color(0xFF8A2BE2);
  static const y2kMetallicSilver = Color(0xFFC9CDD6);
  static const y2kGlitterPink = Color(0xFFFFD1EC);
  static const y2kBlack = Color(0xFF181022);
  static const y2kSaved = Color(0xFF00E5A0);
  static const y2kSpent = Color(0xFFFF4D6D);
}
