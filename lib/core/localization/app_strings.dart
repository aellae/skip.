import '../../data/backup_service.dart';
import 'app_locale.dart';

/// Every user-facing string in SKIP, in English and Italian side by side.
///
/// A single class with an internal `_it` switch (rather than one
/// implementation per language) so each string's two translations sit next
/// to each other — easy to scan for a missing or drifted translation.
class AppStrings {
  final AppLocale locale;

  const AppStrings(this.locale);

  bool get _it => locale == AppLocale.it;

  // Home screen
  String get insightsTooltip => _it ? 'Statistiche' : 'Insights';
  String get settingsTooltip => _it ? 'Impostazioni' : 'Settings';
  String get emptyHomeMessage => _it
      ? 'Ancora nessun articolo.\nTocca + per fotografare qualcosa che vorresti comprare.'
      : "Nothing logged yet.\nTap + to snap something you're tempted to buy.";

  // Item detail screen
  String get deleteItemTitle =>
      _it ? 'Eliminare questo articolo?' : 'Delete this item?';
  String get deleteItemContent => _it
      ? 'Questa azione lo rimuove insieme alla foto in modo permanente.'
      : 'This removes it and its photo permanently.';
  String get cancel => _it ? 'Annulla' : 'Cancel';
  String get delete => _it ? 'Elimina' : 'Delete';
  String get couldntOpenLink =>
      _it ? 'Impossibile aprire il link.' : "Couldn't open that link.";
  String get status => _it ? 'Stato' : 'Status';
  String get productLink => _it ? 'Link al prodotto' : 'Product Link';
  String get visitProductPage =>
      _it ? 'Visita la pagina del prodotto' : 'Visit product page';
  String get editLinkTooltip => _it ? 'Modifica link' : 'Edit link';
  String get addProductLink =>
      _it ? 'Aggiungi link al prodotto' : 'Add product link';
  String get editLinkDialogTitle => _it ? 'Modifica link' : 'Edit link';
  String get invalidLinkError => _it
      ? 'Inserisci un link valido (https://…).'
      : 'Enter a valid link (https://…).';
  String get linkHint => 'https://…';
  String get remove => _it ? 'Rimuovi' : 'Remove';
  String get save => _it ? 'Salva' : 'Save';

  // Summary / insights
  String get totalSaved => _it ? 'Totale risparmiato' : 'Total Saved';
  String get totalSpent => _it ? 'Totale speso' : 'Total Spent';
  String get thisMonthsSavings =>
      _it ? 'Risparmi di questo mese' : "This Month's Savings";
  String get thisMonthsSpent =>
      _it ? 'Spese di questo mese' : "This Month's Spent";
  String get insightsTitle => _it ? 'Statistiche' : 'Insights';
  String get last6Months => _it ? 'Ultimi 6 mesi' : 'Last 6 Months';
  String get saved => _it ? 'Risparmiato' : 'Saved';
  String get spent => _it ? 'Speso' : 'Spent';

  // Item entry screen
  String get camera => _it ? 'Fotocamera' : 'Camera';
  String get gallery => _it ? 'Galleria' : 'Gallery';
  String get addPhotoFirst =>
      _it ? 'Aggiungi prima una foto.' : 'Add a photo first.';
  String get enterPrice => _it ? 'Inserisci un prezzo.' : 'Enter a price.';
  String get enterValidNumber =>
      _it ? 'Inserisci un numero valido.' : 'Enter a valid number.';
  String get priceGreaterThanZero => _it
      ? 'Il prezzo deve essere maggiore di zero.'
      : 'Price must be greater than zero.';
  String get logAnItem => _it ? 'Registra un articolo' : 'Log an item';
  String get tapToAddPhoto =>
      _it ? 'Tocca per aggiungere una foto' : 'Tap to add a photo';
  String get priceLabel => _it ? 'Prezzo' : 'Price';
  String get titleOptionalLabel =>
      _it ? 'Titolo (facoltativo)' : 'Title (optional)';
  String get productLinkOptionalLabel =>
      _it ? 'Link al prodotto (facoltativo)' : 'Product link (optional)';
  String get tapOneToLogIt =>
      _it ? 'Toccane uno per registrarlo' : 'Tap one to log it';

  // Decision toggle
  String get resisted => _it ? 'Resistito!' : 'Resisted!';
  String get boughtIt => _it ? 'Comprato' : 'Bought It';

  // Backup section
  String get photosStayOnDevice => _it
      ? 'Le foto restano solo su questo dispositivo: i backup includono solo i dati degli articoli.'
      : 'Photos stay on this device — backups cover item records only.';
  String get exportBackup => _it ? 'Esporta backup' : 'Export backup';
  String get importBackup => _it ? 'Importa backup' : 'Import backup';
  String get exportAsJson => _it ? 'Esporta come JSON' : 'Export as JSON';
  String get exportAsCsv => _it ? 'Esporta come CSV' : 'Export as CSV';
  String get couldntExportBackup =>
      _it ? 'Impossibile esportare il backup.' : "Couldn't export backup.";
  String get couldntReadFile =>
      _it ? 'Impossibile leggere il file.' : "Couldn't read that file.";

  String importedItems(int count) {
    if (_it) {
      final verb = count == 1 ? 'Importato' : 'Importati';
      final noun = count == 1 ? 'elemento' : 'elementi';
      return '$verb $count $noun.';
    }
    return 'Imported $count item${count == 1 ? '' : 's'}.';
  }

  String backupErrorMessage(BackupFormatError code) => switch (code) {
    BackupFormatError.invalidJson =>
      _it ? 'Il file non è un JSON valido.' : "That file isn't valid JSON.",
    BackupFormatError.notASkipBackup =>
      _it
          ? 'Il file non sembra essere un backup di SKIP.'
          : "That file doesn't look like a SKIP backup.",
    BackupFormatError.invalidItemEntry =>
      _it
          ? 'Il backup contiene una voce non valida.'
          : 'The backup contains an invalid item entry.',
    BackupFormatError.invalidItemFields =>
      _it
          ? 'Il backup contiene un articolo con campi mancanti o non validi.'
          : 'The backup contains an item with missing or invalid fields.',
    BackupFormatError.fileReadError => couldntReadFile,
  };

  // Settings screen
  String get settingsTitle => _it ? 'Impostazioni' : 'Settings';
  String get aesthetic => _it ? 'Estetica' : 'Aesthetic';
  String get quietLuxury => _it ? 'Lusso silenzioso' : 'Quiet Luxury';
  String get bratzY2k => 'Bratz Y2K';
  String get summary => _it ? 'Riepilogo' : 'Summary';
  String get itemsResisted => _it ? 'Articoli evitati' : 'Items resisted';
  String get averageSavedPerItem =>
      _it ? 'Media risparmiata per articolo' : 'Average saved per item';
  String get data => _it ? 'Dati' : 'Data';
  String get language => _it ? 'Lingua' : 'Language';

  // Each language's own name, in that language — not translated into the
  // active one, so a user who ends up on the wrong language can still
  // recognize and tap their way back.
  String get english => 'English';
  String get italian => 'Italiano';
}
