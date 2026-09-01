import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// App-specific theme tokens that don't map onto [ThemeData]'s built-in
/// fields (financial semantics, dynamic logo text, card surfaces).
///
/// Widgets read these via `Theme.of(context).extension<SkipThemeExtension>()`
/// rather than importing [AppColors] directly, so every visual value still
/// flows through the active theme.
@immutable
class SkipThemeExtension extends ThemeExtension<SkipThemeExtension> {
  final Color savedColor;
  final Color spentColor;
  final Color cardBackground;
  final String logoText;
  final bool isY2K;

  /// Corner radius for passive surfaces (cards, images, media containers).
  final double cardRadius;

  /// Corner radius for interactive surfaces (buttons, toggles).
  final double buttonRadius;

  /// Ambient, at-rest depth for [SkipCard] and similar passive surfaces.
  final List<BoxShadow> cardShadow;

  /// Stronger depth for selected/emphasized/lifted states.
  final List<BoxShadow> glowShadow;

  /// Brand/CTA accent gradient (badges, stickers, app bar chrome). Never
  /// used to encode saved/spent financial semantics.
  final Gradient? accentGradient;

  /// Shimmer highlight / confetti extra / Minimal confirmation-motion tint.
  final Color accentHighlight;

  const SkipThemeExtension({
    required this.savedColor,
    required this.spentColor,
    required this.cardBackground,
    required this.logoText,
    required this.isY2K,
    required this.cardRadius,
    required this.buttonRadius,
    required this.cardShadow,
    required this.glowShadow,
    required this.accentGradient,
    required this.accentHighlight,
  });

  @override
  SkipThemeExtension copyWith({
    Color? savedColor,
    Color? spentColor,
    Color? cardBackground,
    String? logoText,
    bool? isY2K,
    double? cardRadius,
    double? buttonRadius,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? glowShadow,
    Gradient? accentGradient,
    Color? accentHighlight,
  }) {
    return SkipThemeExtension(
      savedColor: savedColor ?? this.savedColor,
      spentColor: spentColor ?? this.spentColor,
      cardBackground: cardBackground ?? this.cardBackground,
      logoText: logoText ?? this.logoText,
      isY2K: isY2K ?? this.isY2K,
      cardRadius: cardRadius ?? this.cardRadius,
      buttonRadius: buttonRadius ?? this.buttonRadius,
      cardShadow: cardShadow ?? this.cardShadow,
      glowShadow: glowShadow ?? this.glowShadow,
      accentGradient: accentGradient ?? this.accentGradient,
      accentHighlight: accentHighlight ?? this.accentHighlight,
    );
  }

  @override
  SkipThemeExtension lerp(ThemeExtension<SkipThemeExtension>? other, double t) {
    if (other is! SkipThemeExtension) return this;
    return SkipThemeExtension(
      savedColor: Color.lerp(savedColor, other.savedColor, t)!,
      spentColor: Color.lerp(spentColor, other.spentColor, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      logoText: t < 0.5 ? logoText : other.logoText,
      isY2K: t < 0.5 ? isY2K : other.isY2K,
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t)!,
      buttonRadius: lerpDouble(buttonRadius, other.buttonRadius, t)!,
      cardShadow:
          BoxShadow.lerpList(cardShadow, other.cardShadow, t) ?? cardShadow,
      glowShadow:
          BoxShadow.lerpList(glowShadow, other.glowShadow, t) ?? glowShadow,
      accentGradient: Gradient.lerp(accentGradient, other.accentGradient, t),
      accentHighlight: Color.lerp(accentHighlight, other.accentHighlight, t)!,
    );
  }
}

/// The two SKIP aesthetics: Quiet Luxury (`skip.`) and Bratz Y2K (`SKIP!`).
class AppThemes {
  AppThemes._();

  static final TextTheme _minimalTextTheme =
      TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 57,
          fontWeight: FontWeight.w600,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 45,
          fontWeight: FontWeight.w600,
        ),
        displaySmall: GoogleFonts.playfairDisplay(
          fontSize: 36,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: GoogleFonts.playfairDisplay(
          fontSize: 32,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: GoogleFonts.playfairDisplay(
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: GoogleFonts.playfairDisplay(
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ).apply(
        bodyColor: AppColors.minimalCharcoal,
        displayColor: AppColors.minimalCharcoal,
      );

  static final TextTheme _y2kTextTheme = TextTheme(
    displayLarge: GoogleFonts.titanOne(
      fontSize: 52,
      fontWeight: FontWeight.w400,
    ),
    displayMedium: GoogleFonts.titanOne(
      fontSize: 42,
      fontWeight: FontWeight.w400,
    ),
    displaySmall: GoogleFonts.titanOne(
      fontSize: 34,
      fontWeight: FontWeight.w400,
    ),
    headlineLarge: GoogleFonts.titanOne(
      fontSize: 30,
      fontWeight: FontWeight.w400,
    ),
    headlineMedium: GoogleFonts.titanOne(
      fontSize: 26,
      fontWeight: FontWeight.w400,
    ),
    headlineSmall: GoogleFonts.titanOne(
      fontSize: 22,
      fontWeight: FontWeight.w400,
    ),
    titleLarge: GoogleFonts.titanOne(fontSize: 20, fontWeight: FontWeight.w400),
    titleMedium: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.w600),
    titleSmall: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.w600),
    bodyLarge: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.w500),
    bodyMedium: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.w500),
    bodySmall: GoogleFonts.fredoka(fontSize: 12, fontWeight: FontWeight.w500),
    labelLarge: GoogleFonts.fredoka(fontSize: 14, fontWeight: FontWeight.w700),
    labelMedium: GoogleFonts.fredoka(fontSize: 12, fontWeight: FontWeight.w600),
    labelSmall: GoogleFonts.fredoka(fontSize: 11, fontWeight: FontWeight.w600),
  ).apply(bodyColor: AppColors.y2kMetallicSilver, displayColor: Colors.white);

  static final ThemeData minimal = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.minimalSoftWhite,
    colorScheme: const ColorScheme.light(
      primary: AppColors.minimalCharcoal,
      onPrimary: AppColors.minimalSoftWhite,
      secondary: AppColors.minimalChampagne,
      onSecondary: AppColors.minimalCharcoal,
      surface: AppColors.minimalSoftWhite,
      onSurface: AppColors.minimalCharcoal,
      error: AppColors.minimalSpent,
    ),
    textTheme: _minimalTextTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.minimalSoftWhite,
      foregroundColor: AppColors.minimalCharcoal,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: _minimalTextTheme.headlineSmall,
    ),
    cardTheme: CardThemeData(
      color: AppColors.minimalSilkBeige,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.minimalCharcoal,
        foregroundColor: AppColors.minimalSoftWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.minimalCharcoal,
        side: BorderSide(
          color: AppColors.minimalCharcoal.withValues(alpha: 0.3),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.minimalCharcoal),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.minimalCharcoal,
      foregroundColor: AppColors.minimalSoftWhite,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.minimalSilkBeige,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: BorderSide.none,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.minimalSoftWhite,
      elevation: 3,
      shadowColor: AppColors.minimalCharcoal.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titleTextStyle: _minimalTextTheme.headlineSmall,
      contentTextStyle: _minimalTextTheme.bodyMedium,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.minimalSoftWhite,
      modalBackgroundColor: AppColors.minimalSoftWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      showDragHandle: true,
      dragHandleColor: AppColors.minimalCharcoal.withValues(alpha: 0.3),
      elevation: 4,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.minimalCharcoal,
      contentTextStyle: _minimalTextTheme.bodyMedium?.copyWith(
        color: AppColors.minimalSoftWhite,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      actionTextColor: AppColors.minimalChampagne,
    ),
    dividerTheme: DividerThemeData(
      color: AppColors.minimalCharcoal.withValues(alpha: 0.08),
      thickness: 1,
      space: 32,
    ),
    iconTheme: const IconThemeData(color: AppColors.minimalCharcoal, size: 22),
    extensions: [
      SkipThemeExtension(
        savedColor: AppColors.minimalSaved,
        spentColor: AppColors.minimalSpent,
        cardBackground: AppColors.minimalSilkBeige,
        logoText: 'skip.',
        isY2K: false,
        cardRadius: 10,
        buttonRadius: 8,
        cardShadow: [
          BoxShadow(
            color: AppColors.minimalCharcoal.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
        glowShadow: [
          BoxShadow(
            color: AppColors.minimalCharcoal.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -2,
          ),
        ],
        accentGradient: null,
        accentHighlight: AppColors.minimalChampagne,
      ),
    ],
  );

  static final ThemeData y2k = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.y2kBlack,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.y2kHotMagenta,
      onPrimary: AppColors.y2kBlack,
      secondary: AppColors.y2kElectricViolet,
      onSecondary: Colors.white,
      surface: AppColors.y2kBlack,
      onSurface: AppColors.y2kMetallicSilver,
      error: AppColors.y2kSpent,
    ),
    textTheme: _y2kTextTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.y2kBlack,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: _y2kTextTheme.headlineSmall,
    ),
    cardTheme: CardThemeData(
      color: AppColors.y2kDeepSurface,
      elevation: 4,
      shadowColor: AppColors.y2kHotMagenta.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.y2kMetallicSilver, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.y2kHotMagenta,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(
            color: AppColors.y2kMetallicSilver,
            width: 1.5,
          ),
        ),
        elevation: 6,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: AppColors.y2kMetallicSilver, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.y2kHotMagenta),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.y2kHotMagenta,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.y2kDeepSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.y2kMetallicSilver),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.y2kDeepSurface,
      elevation: 8,
      shadowColor: AppColors.y2kHotMagenta.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.y2kMetallicSilver, width: 1.5),
      ),
      titleTextStyle: _y2kTextTheme.headlineSmall,
      contentTextStyle: _y2kTextTheme.bodyMedium,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.y2kDeepSurface,
      modalBackgroundColor: AppColors.y2kDeepSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      showDragHandle: true,
      dragHandleColor: AppColors.y2kMetallicSilver,
      elevation: 12,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.y2kDeepSurface,
      contentTextStyle: _y2kTextTheme.bodyMedium?.copyWith(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.y2kMetallicSilver, width: 1.5),
      ),
      actionTextColor: AppColors.y2kHotMagenta,
    ),
    dividerTheme: DividerThemeData(
      color: AppColors.y2kMetallicSilver.withValues(alpha: 0.3),
      thickness: 1.5,
      space: 32,
    ),
    iconTheme: const IconThemeData(color: Colors.white, size: 24),
    extensions: [
      SkipThemeExtension(
        savedColor: AppColors.y2kSaved,
        spentColor: AppColors.y2kSpent,
        cardBackground: AppColors.y2kDeepSurface,
        logoText: 'SKIP!',
        isY2K: true,
        cardRadius: 20,
        buttonRadius: 28,
        cardShadow: [
          BoxShadow(
            color: AppColors.y2kHotMagenta.withValues(alpha: 0.30),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppColors.y2kElectricViolet.withValues(alpha: 0.20),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        glowShadow: [
          BoxShadow(
            color: AppColors.y2kHotMagenta.withValues(alpha: 0.55),
            blurRadius: 24,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: AppColors.y2kElectricViolet.withValues(alpha: 0.35),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
        accentGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.y2kHotMagenta, AppColors.y2kElectricViolet],
        ),
        accentHighlight: AppColors.y2kGlitterPink,
      ),
    ],
  );
}
