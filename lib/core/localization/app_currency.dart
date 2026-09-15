/// The pricing currencies SKIP supports, chosen independently of the
/// display language — a user can run the Italian UI while pricing items in
/// US Dollars, or vice versa.
enum AppCurrency {
  usd,
  eur;

  /// Persistence/storage code — stable even if display names change.
  String get code => switch (this) {
    AppCurrency.usd => 'usd',
    AppCurrency.eur => 'eur',
  };

  static AppCurrency fromCode(String? code) => switch (code) {
    'eur' => AppCurrency.eur,
    _ => AppCurrency.usd,
  };
}
