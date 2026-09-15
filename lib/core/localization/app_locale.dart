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
}
