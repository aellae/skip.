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

  const SkipThemeExtension({
    required this.savedColor,
    required this.spentColor,
    required this.cardBackground,
    required this.logoText,
    required this.isY2K,
  });

  @override
  SkipThemeExtension copyWith({
    Color? savedColor,
    Color? spentColor,
    Color? cardBackground,
    String? logoText,
    bool? isY2K,
  }) {
    return SkipThemeExtension(
      savedColor: savedColor ?? this.savedColor,
      spentColor: spentColor ?? this.spentColor,
      cardBackground: cardBackground ?? this.cardBackground,
      logoText: logoText ?? this.logoText,
      isY2K: isY2K ?? this.isY2K,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.minimalCharcoal,
        foregroundColor: AppColors.minimalSoftWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
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
    extensions: const [
      SkipThemeExtension(
        savedColor: AppColors.minimalSaved,
        spentColor: AppColors.minimalSpent,
        cardBackground: AppColors.minimalSilkBeige,
        logoText: 'skip.',
        isY2K: false,
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
      color: const Color(0xFF241A33),
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
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(
            color: AppColors.y2kMetallicSilver,
            width: 1.5,
          ),
        ),
        elevation: 6,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.y2kHotMagenta,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF241A33),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.y2kMetallicSilver),
      ),
    ),
    extensions: const [
      SkipThemeExtension(
        savedColor: AppColors.y2kSaved,
        spentColor: AppColors.y2kSpent,
        cardBackground: Color(0xFF241A33),
        logoText: 'SKIP!',
        isY2K: true,
      ),
    ],
  );
}
