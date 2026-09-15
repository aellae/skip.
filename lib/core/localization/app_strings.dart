import '../../data/backup_service.dart';
import 'app_locale.dart';

/// Every user-facing string in SKIP, in all supported languages side by
/// side.
///
/// A single class with an internal `switch (locale)` per string (rather
/// than one implementation per language) so each string's translations sit
/// next to each other — easy to scan for a missing or drifted translation.
class AppStrings {
  final AppLocale locale;

  const AppStrings(this.locale);

  // Home screen
  String get insightsTooltip => switch (locale) {
    AppLocale.en => 'Insights',
    AppLocale.it => 'Statistiche',
    AppLocale.fr => 'Statistiques',
    AppLocale.de => 'Statistiken',
  };
  String get settingsTooltip => switch (locale) {
    AppLocale.en => 'Settings',
    AppLocale.it => 'Impostazioni',
    AppLocale.fr => 'Paramètres',
    AppLocale.de => 'Einstellungen',
  };
  String get emptyHomeMessage => switch (locale) {
    AppLocale.en =>
      "Nothing logged yet.\nTap + to snap something you're tempted to buy.",
    AppLocale.it =>
      'Ancora nessun articolo.\nTocca + per fotografare qualcosa che vorresti comprare.',
    AppLocale.fr =>
      "Rien d'enregistré pour l'instant.\nAppuyez sur + pour photographier quelque chose que vous êtes tenté d'acheter.",
    AppLocale.de =>
      'Noch nichts erfasst.\nTippe auf +, um etwas zu fotografieren, das du kaufen möchtest.',
  };

  // Item detail screen
  String get deleteItemTitle => switch (locale) {
    AppLocale.en => 'Delete this item?',
    AppLocale.it => 'Eliminare questo articolo?',
    AppLocale.fr => 'Supprimer cet article ?',
    AppLocale.de => 'Diesen Artikel löschen?',
  };
  String get deleteItemContent => switch (locale) {
    AppLocale.en => 'This removes it and its photo permanently.',
    AppLocale.it =>
      'Questa azione lo rimuove insieme alla foto in modo permanente.',
    AppLocale.fr =>
      'Cette action le supprime définitivement, ainsi que sa photo.',
    AppLocale.de => 'Dadurch werden er und sein Foto dauerhaft gelöscht.',
  };
  String get cancel => switch (locale) {
    AppLocale.en => 'Cancel',
    AppLocale.it => 'Annulla',
    AppLocale.fr => 'Annuler',
    AppLocale.de => 'Abbrechen',
  };
  String get delete => switch (locale) {
    AppLocale.en => 'Delete',
    AppLocale.it => 'Elimina',
    AppLocale.fr => 'Supprimer',
    AppLocale.de => 'Löschen',
  };
  String get couldntOpenLink => switch (locale) {
    AppLocale.en => "Couldn't open that link.",
    AppLocale.it => 'Impossibile aprire il link.',
    AppLocale.fr => "Impossible d'ouvrir ce lien.",
    AppLocale.de => 'Der Link konnte nicht geöffnet werden.',
  };
  String get status => switch (locale) {
    AppLocale.en => 'Status',
    AppLocale.it => 'Stato',
    AppLocale.fr => 'Statut',
    AppLocale.de => 'Status',
  };
  String get productLink => switch (locale) {
    AppLocale.en => 'Product Link',
    AppLocale.it => 'Link al prodotto',
    AppLocale.fr => 'Lien du produit',
    AppLocale.de => 'Produktlink',
  };
  String get visitProductPage => switch (locale) {
    AppLocale.en => 'Visit product page',
    AppLocale.it => 'Visita la pagina del prodotto',
    AppLocale.fr => 'Voir la page du produit',
    AppLocale.de => 'Produktseite besuchen',
  };
  String get editLinkTooltip => switch (locale) {
    AppLocale.en => 'Edit link',
    AppLocale.it => 'Modifica link',
    AppLocale.fr => 'Modifier le lien',
    AppLocale.de => 'Link bearbeiten',
  };
  String get editDetailsTooltip => switch (locale) {
    AppLocale.en => 'Edit details',
    AppLocale.it => 'Modifica dettagli',
    AppLocale.fr => 'Modifier les détails',
    AppLocale.de => 'Details bearbeiten',
  };
  String get editDetailsDialogTitle => switch (locale) {
    AppLocale.en => 'Edit details',
    AppLocale.it => 'Modifica dettagli',
    AppLocale.fr => 'Modifier les détails',
    AppLocale.de => 'Details bearbeiten',
  };
  String get addProductLink => switch (locale) {
    AppLocale.en => 'Add product link',
    AppLocale.it => 'Aggiungi link al prodotto',
    AppLocale.fr => 'Ajouter un lien produit',
    AppLocale.de => 'Produktlink hinzufügen',
  };
  String get editLinkDialogTitle => switch (locale) {
    AppLocale.en => 'Edit link',
    AppLocale.it => 'Modifica link',
    AppLocale.fr => 'Modifier le lien',
    AppLocale.de => 'Link bearbeiten',
  };
  String get invalidLinkError => switch (locale) {
    AppLocale.en => 'Enter a valid link (https://…).',
    AppLocale.it => 'Inserisci un link valido (https://…).',
    AppLocale.fr => 'Saisissez un lien valide (https://…).',
    AppLocale.de => 'Gib einen gültigen Link ein (https://…).',
  };
  String get linkHint => 'https://…';
  String get remove => switch (locale) {
    AppLocale.en => 'Remove',
    AppLocale.it => 'Rimuovi',
    AppLocale.fr => 'Retirer',
    AppLocale.de => 'Entfernen',
  };
  String get save => switch (locale) {
    AppLocale.en => 'Save',
    AppLocale.it => 'Salva',
    AppLocale.fr => 'Enregistrer',
    AppLocale.de => 'Speichern',
  };

  // Summary / insights
  String get totalSaved => switch (locale) {
    AppLocale.en => 'Total Saved',
    AppLocale.it => 'Totale risparmiato',
    AppLocale.fr => 'Total économisé',
    AppLocale.de => 'Gesamt gespart',
  };
  String get totalSpent => switch (locale) {
    AppLocale.en => 'Total Spent',
    AppLocale.it => 'Totale speso',
    AppLocale.fr => 'Total dépensé',
    AppLocale.de => 'Gesamt ausgegeben',
  };
  String get thisMonthsSavings => switch (locale) {
    AppLocale.en => "This Month's Savings",
    AppLocale.it => 'Risparmi di questo mese',
    AppLocale.fr => 'Économies de ce mois-ci',
    AppLocale.de => 'Ersparnisse diesen Monat',
  };
  String get thisMonthsSpent => switch (locale) {
    AppLocale.en => "This Month's Spent",
    AppLocale.it => 'Spese di questo mese',
    AppLocale.fr => 'Dépenses de ce mois-ci',
    AppLocale.de => 'Ausgaben diesen Monat',
  };
  String get insightsTitle => switch (locale) {
    AppLocale.en => 'Insights',
    AppLocale.it => 'Statistiche',
    AppLocale.fr => 'Statistiques',
    AppLocale.de => 'Statistiken',
  };
  String get last6Months => switch (locale) {
    AppLocale.en => 'Last 6 Months',
    AppLocale.it => 'Ultimi 6 mesi',
    AppLocale.fr => '6 derniers mois',
    AppLocale.de => 'Letzte 6 Monate',
  };
  String get saved => switch (locale) {
    AppLocale.en => 'Saved',
    AppLocale.it => 'Risparmiato',
    AppLocale.fr => 'Économisé',
    AppLocale.de => 'Gespart',
  };
  String get spent => switch (locale) {
    AppLocale.en => 'Spent',
    AppLocale.it => 'Speso',
    AppLocale.fr => 'Dépensé',
    AppLocale.de => 'Ausgegeben',
  };
  String get emptyInsightsMessage => switch (locale) {
    AppLocale.en =>
      'No trends to show yet.\nLog a few items to see your monthly breakdown.',
    AppLocale.it =>
      'Ancora nessuna tendenza da mostrare.\nRegistra qualche articolo per vedere l\'andamento mensile.',
    AppLocale.fr =>
      'Aucune tendance à afficher pour l\'instant.\nEnregistrez quelques articles pour voir votre répartition mensuelle.',
    AppLocale.de =>
      'Noch keine Trends vorhanden.\nErfasse ein paar Artikel, um deine monatliche Übersicht zu sehen.',
  };

  // Item entry screen
  String get camera => switch (locale) {
    AppLocale.en => 'Camera',
    AppLocale.it => 'Fotocamera',
    AppLocale.fr => 'Appareil photo',
    AppLocale.de => 'Kamera',
  };
  String get gallery => switch (locale) {
    AppLocale.en => 'Gallery',
    AppLocale.it => 'Galleria',
    AppLocale.fr => 'Galerie',
    AppLocale.de => 'Galerie',
  };
  String get addPhotoFirst => switch (locale) {
    AppLocale.en => 'Add a photo first.',
    AppLocale.it => 'Aggiungi prima una foto.',
    AppLocale.fr => "Ajoutez d'abord une photo.",
    AppLocale.de => 'Füge zuerst ein Foto hinzu.',
  };
  String get enterPrice => switch (locale) {
    AppLocale.en => 'Enter a price.',
    AppLocale.it => 'Inserisci un prezzo.',
    AppLocale.fr => 'Saisissez un prix.',
    AppLocale.de => 'Gib einen Preis ein.',
  };
  String get enterValidNumber => switch (locale) {
    AppLocale.en => 'Enter a valid number.',
    AppLocale.it => 'Inserisci un numero valido.',
    AppLocale.fr => 'Saisissez un nombre valide.',
    AppLocale.de => 'Gib eine gültige Zahl ein.',
  };
  String get priceGreaterThanZero => switch (locale) {
    AppLocale.en => 'Price must be greater than zero.',
    AppLocale.it => 'Il prezzo deve essere maggiore di zero.',
    AppLocale.fr => 'Le prix doit être supérieur à zéro.',
    AppLocale.de => 'Der Preis muss größer als null sein.',
  };
  String get logAnItem => switch (locale) {
    AppLocale.en => 'Log an item',
    AppLocale.it => 'Registra un articolo',
    AppLocale.fr => 'Enregistrer un article',
    AppLocale.de => 'Artikel erfassen',
  };
  String get tapToAddPhoto => switch (locale) {
    AppLocale.en => 'Tap to add a photo',
    AppLocale.it => 'Tocca per aggiungere una foto',
    AppLocale.fr => 'Appuyez pour ajouter une photo',
    AppLocale.de => 'Tippen, um ein Foto hinzuzufügen',
  };
  String get priceLabel => switch (locale) {
    AppLocale.en => 'Price',
    AppLocale.it => 'Prezzo',
    AppLocale.fr => 'Prix',
    AppLocale.de => 'Preis',
  };
  String get titleOptionalLabel => switch (locale) {
    AppLocale.en => 'Title (optional)',
    AppLocale.it => 'Titolo (facoltativo)',
    AppLocale.fr => 'Titre (facultatif)',
    AppLocale.de => 'Titel (optional)',
  };
  String get productLinkOptionalLabel => switch (locale) {
    AppLocale.en => 'Product link (optional)',
    AppLocale.it => 'Link al prodotto (facoltativo)',
    AppLocale.fr => 'Lien du produit (facultatif)',
    AppLocale.de => 'Produktlink (optional)',
  };
  String get tapOneToLogIt => switch (locale) {
    AppLocale.en => 'Tap one to log it',
    AppLocale.it => 'Toccane uno per registrarlo',
    AppLocale.fr => "Appuyez sur un élément pour l'enregistrer",
    AppLocale.de => 'Tippe auf eins, um es zu erfassen',
  };

  // Decision toggle
  String get resisted => switch (locale) {
    AppLocale.en => 'Resisted!',
    AppLocale.it => 'Resistito!',
    AppLocale.fr => 'Résisté !',
    AppLocale.de => 'Widerstanden!',
  };
  String get boughtIt => switch (locale) {
    AppLocale.en => 'Bought It',
    AppLocale.it => 'Comprato',
    AppLocale.fr => 'Acheté',
    AppLocale.de => 'Gekauft',
  };

  // Backup section
  String get photosStayOnDevice => switch (locale) {
    AppLocale.en =>
      'Photos stay on this device — backups cover item records only.',
    AppLocale.it =>
      'Le foto restano solo su questo dispositivo: i backup includono solo i dati degli articoli.',
    AppLocale.fr =>
      'Les photos restent uniquement sur cet appareil : les sauvegardes ne couvrent que les données des articles.',
    AppLocale.de =>
      'Fotos verbleiben nur auf diesem Gerät – Backups umfassen nur die Artikeldaten.',
  };
  String get exportBackup => switch (locale) {
    AppLocale.en => 'Export backup',
    AppLocale.it => 'Esporta backup',
    AppLocale.fr => 'Exporter la sauvegarde',
    AppLocale.de => 'Backup exportieren',
  };
  String get importBackup => switch (locale) {
    AppLocale.en => 'Import backup',
    AppLocale.it => 'Importa backup',
    AppLocale.fr => 'Importer une sauvegarde',
    AppLocale.de => 'Backup importieren',
  };
  String get exportAsJson => switch (locale) {
    AppLocale.en => 'Export as JSON',
    AppLocale.it => 'Esporta come JSON',
    AppLocale.fr => 'Exporter en JSON',
    AppLocale.de => 'Als JSON exportieren',
  };
  String get exportAsCsv => switch (locale) {
    AppLocale.en => 'Export as CSV',
    AppLocale.it => 'Esporta come CSV',
    AppLocale.fr => 'Exporter en CSV',
    AppLocale.de => 'Als CSV exportieren',
  };
  String get couldntExportBackup => switch (locale) {
    AppLocale.en => "Couldn't export backup.",
    AppLocale.it => 'Impossibile esportare il backup.',
    AppLocale.fr => "Impossible d'exporter la sauvegarde.",
    AppLocale.de => 'Backup konnte nicht exportiert werden.',
  };
  String get couldntReadFile => switch (locale) {
    AppLocale.en => "Couldn't read that file.",
    AppLocale.it => 'Impossibile leggere il file.',
    AppLocale.fr => 'Impossible de lire ce fichier.',
    AppLocale.de => 'Die Datei konnte nicht gelesen werden.',
  };

  String importedItems(int count) {
    switch (locale) {
      case AppLocale.en:
        return 'Imported $count item${count == 1 ? '' : 's'}.';
      case AppLocale.it:
        final verb = count == 1 ? 'Importato' : 'Importati';
        final noun = count == 1 ? 'elemento' : 'elementi';
        return '$verb $count $noun.';
      case AppLocale.fr:
        final noun = count == 1 ? 'élément importé' : 'éléments importés';
        return '$count $noun.';
      case AppLocale.de:
        final noun = count == 1 ? 'Element' : 'Elemente';
        return '$count $noun importiert.';
    }
  }

  String backupErrorMessage(BackupFormatError code) => switch (code) {
    BackupFormatError.invalidJson => switch (locale) {
      AppLocale.en => "That file isn't valid JSON.",
      AppLocale.it => 'Il file non è un JSON valido.',
      AppLocale.fr => "Ce fichier n'est pas un JSON valide.",
      AppLocale.de => 'Diese Datei ist kein gültiges JSON.',
    },
    BackupFormatError.notASkipBackup => switch (locale) {
      AppLocale.en => "That file doesn't look like a SKIP backup.",
      AppLocale.it => 'Il file non sembra essere un backup di SKIP.',
      AppLocale.fr => 'Ce fichier ne semble pas être une sauvegarde SKIP.',
      AppLocale.de => 'Diese Datei scheint kein SKIP-Backup zu sein.',
    },
    BackupFormatError.invalidItemEntry => switch (locale) {
      AppLocale.en => 'The backup contains an invalid item entry.',
      AppLocale.it => 'Il backup contiene una voce non valida.',
      AppLocale.fr => 'La sauvegarde contient une entrée invalide.',
      AppLocale.de => 'Das Backup enthält einen ungültigen Eintrag.',
    },
    BackupFormatError.invalidItemFields => switch (locale) {
      AppLocale.en =>
        'The backup contains an item with missing or invalid fields.',
      AppLocale.it =>
        'Il backup contiene un articolo con campi mancanti o non validi.',
      AppLocale.fr =>
        'La sauvegarde contient un article avec des champs manquants ou invalides.',
      AppLocale.de =>
        'Das Backup enthält einen Artikel mit fehlenden oder ungültigen Feldern.',
    },
    BackupFormatError.fileReadError => couldntReadFile,
  };

  // Settings screen
  String get settingsTitle => switch (locale) {
    AppLocale.en => 'Settings',
    AppLocale.it => 'Impostazioni',
    AppLocale.fr => 'Paramètres',
    AppLocale.de => 'Einstellungen',
  };
  String get aesthetic => switch (locale) {
    AppLocale.en => 'Aesthetic',
    AppLocale.it => 'Estetica',
    AppLocale.fr => 'Esthétique',
    AppLocale.de => 'Ästhetik',
  };
  String get quietLuxury => switch (locale) {
    AppLocale.en => 'Quiet Luxury',
    AppLocale.it => 'Lusso silenzioso',
    AppLocale.fr => 'Luxe discret',
    AppLocale.de => 'Leiser Luxus',
  };
  String get bratzY2k => 'Bratz Y2K';
  String get summary => switch (locale) {
    AppLocale.en => 'Summary',
    AppLocale.it => 'Riepilogo',
    AppLocale.fr => 'Résumé',
    AppLocale.de => 'Zusammenfassung',
  };
  String get itemsResisted => switch (locale) {
    AppLocale.en => 'Items resisted',
    AppLocale.it => 'Articoli evitati',
    AppLocale.fr => 'Articles évités',
    AppLocale.de => 'Widerstandene Artikel',
  };
  String get averageSavedPerItem => switch (locale) {
    AppLocale.en => 'Average saved per item',
    AppLocale.it => 'Media risparmiata per articolo',
    AppLocale.fr => 'Économie moyenne par article',
    AppLocale.de => 'Durchschnittlich gespart pro Artikel',
  };
  String get data => switch (locale) {
    AppLocale.en => 'Data',
    AppLocale.it => 'Dati',
    AppLocale.fr => 'Données',
    AppLocale.de => 'Daten',
  };
  String get language => switch (locale) {
    AppLocale.en => 'Language',
    AppLocale.it => 'Lingua',
    AppLocale.fr => 'Langue',
    AppLocale.de => 'Sprache',
  };
  String get currency => switch (locale) {
    AppLocale.en => 'Currency',
    AppLocale.it => 'Valuta',
    AppLocale.fr => 'Devise',
    AppLocale.de => 'Währung',
  };
  String get usDollar => switch (locale) {
    AppLocale.en => 'US Dollar',
    AppLocale.it => 'Dollaro USA',
    AppLocale.fr => 'Dollar américain',
    AppLocale.de => 'US-Dollar',
  };
  String get euro => switch (locale) {
    AppLocale.en => 'Euro',
    AppLocale.it => 'Euro',
    AppLocale.fr => 'Euro',
    AppLocale.de => 'Euro',
  };

  // Each language's own name, in that language — not translated into the
  // active one, so a user who ends up on the wrong language can still
  // recognize and tap their way back.
  String get english => 'English';
  String get italian => 'Italiano';
  String get french => 'Français';
  String get german => 'Deutsch';

  // Support screen
  String get supportSectionLabel => switch (locale) {
    AppLocale.en => 'Support',
    AppLocale.it => 'Supporto',
    AppLocale.fr => 'Soutien',
    AppLocale.de => 'Unterstützung',
  };
  String get supportSkip => switch (locale) {
    AppLocale.en => 'Support SKIP',
    AppLocale.it => 'Sostieni SKIP',
    AppLocale.fr => 'Soutenir SKIP',
    AppLocale.de => 'SKIP unterstützen',
  };
  String get supportBody => switch (locale) {
    AppLocale.en =>
      "If SKIP has helped you spend a little less, you can support its "
          "development.\n\nThis is entirely voluntary. There's no "
          "subscription and nothing to unlock — SKIP's features stay "
          'exactly the same either way. 100% of what you choose to send '
          'goes directly to the developer.',
    AppLocale.it =>
      "Se SKIP ti ha aiutato a spendere un po' meno, puoi sostenerne lo "
          'sviluppo.\n\nÈ del tutto volontario. Non c\'è alcun abbonamento '
          'né nulla da sbloccare: le funzionalità di SKIP restano identiche '
          'in ogni caso. Il 100% di quanto scegli di inviare va '
          'direttamente alla sviluppatrice.',
    AppLocale.fr =>
      'Si SKIP vous a aidé à dépenser un peu moins, vous pouvez soutenir '
          "son développement.\n\nC'est entièrement volontaire. Il n'y a pas "
          "d'abonnement ni rien à débloquer — les fonctionnalités de SKIP "
          'restent exactement les mêmes dans tous les cas. 100 % de ce que '
          'vous choisissez d\'envoyer va directement à la développeuse.',
    AppLocale.de =>
      'Wenn SKIP dir geholfen hat, etwas weniger auszugeben, kannst du die '
          'Entwicklung unterstützen.\n\nDas ist völlig freiwillig. Es gibt '
          'kein Abo und nichts freizuschalten – die Funktionen von SKIP '
          'bleiben so oder so genau gleich. 100 % dessen, was du sendest, '
          'geht direkt an die Entwicklerin.',
  };
  String get supportButton => switch (locale) {
    AppLocale.en => 'Support the developer',
    AppLocale.it => 'Sostieni la sviluppatrice',
    AppLocale.fr => 'Soutenir la développeuse',
    AppLocale.de => 'Die Entwicklerin unterstützen',
  };
  String get supportOpensExternally => switch (locale) {
    AppLocale.en => 'Opens PayPal in your browser.',
    AppLocale.it => 'Apre PayPal nel browser.',
    AppLocale.fr => 'Ouvre PayPal dans votre navigateur.',
    AppLocale.de => 'Öffnet PayPal in deinem Browser.',
  };
}
