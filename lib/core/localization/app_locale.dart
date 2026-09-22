import 'dart:ui' show PlatformDispatcher;

/// The display languages SKIP supports.
enum AppLocale {
  en,
  it,
  fr,
  de;

  /// Persistence/storage code — stable even if display names change.
  String get code => switch (this) {
    AppLocale.en => 'en',
    AppLocale.it => 'it',
    AppLocale.fr => 'fr',
    AppLocale.de => 'de',
  };

  static AppLocale fromCode(String? code) => switch (code) {
    'it' => AppLocale.it,
    'fr' => AppLocale.fr,
    'de' => AppLocale.de,
    _ => AppLocale.en,
  };

  /// The best-supported match for the device's current system language,
  /// falling back to English when the device language isn't one SKIP has
  /// strings for.
  static AppLocale system() =>
      fromCode(PlatformDispatcher.instance.locale.languageCode);
}
