/// Shared spacing scale — theme-independent, unlike [SkipThemeExtension]'s
/// radius/shadow tokens, since gaps between elements don't vary by aesthetic.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  /// Canonical vertical gap between a screen's stacked sections.
  static const double sectionGap = xl;
}
