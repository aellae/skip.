/// The two display languages SKIP supports.
enum AppLocale {
  en,
  it;

  /// Persistence/storage code — stable even if display names change.
  String get code => switch (this) {
    AppLocale.en => 'en',
    AppLocale.it => 'it',
  };

  static AppLocale fromCode(String? code) => switch (code) {
    'it' => AppLocale.it,
    _ => AppLocale.en,
  };
}
