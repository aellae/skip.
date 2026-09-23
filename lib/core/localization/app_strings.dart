import '../../data/backup_service.dart';
import '../utils/wage_formatter.dart';
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
      "Nothing logged yet.\nTap the camera button to snap something you're tempted to buy.",
    AppLocale.it =>
      'Ancora nessun articolo.\nTocca il pulsante della fotocamera per fotografare qualcosa che vorresti comprare.',
    AppLocale.fr =>
      "Rien d'enregistré pour l'instant.\nAppuyez sur le bouton appareil photo pour photographier quelque chose que vous êtes tenté d'acheter.",
    AppLocale.de =>
      'Noch nichts erfasst.\nTippe auf den Kamera-Button, um etwas zu fotografieren, das du kaufen möchtest.',
  };

  // Item detail screen
  String get deleteItemTitle => switch (locale) {
    AppLocale.en => 'Delete this item?',
    AppLocale.it => 'Eliminare questo articolo?',
    AppLocale.fr => 'Supprimer cet article ?',
    AppLocale.de => 'Diesen Artikel löschen?',
  };
  String get deleteItemContent => switch (locale) {
    AppLocale.en =>
      'Moves it to Trash. You can restore it from Settings within 30 days.',
    AppLocale.it =>
      'Lo sposta nel Cestino. Puoi ripristinarlo dalle Impostazioni entro 30 giorni.',
    AppLocale.fr =>
      'Le déplace vers la Corbeille. Vous pouvez le restaurer depuis les '
          'Paramètres dans les 30 jours.',
    AppLocale.de =>
      'Verschiebt ihn in den Papierkorb. Du kannst ihn innerhalb von 30 '
          'Tagen in den Einstellungen wiederherstellen.',
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
  String get somethingWentWrong => switch (locale) {
    AppLocale.en => 'Something went wrong. Please try again.',
    AppLocale.it => 'Qualcosa è andato storto. Riprova.',
    AppLocale.fr => "Une erreur s'est produite. Veuillez réessayer.",
    AppLocale.de => 'Etwas ist schiefgelaufen. Bitte versuche es erneut.',
  };
  String get cameraAccessOff => switch (locale) {
    AppLocale.en =>
      'Camera access is turned off. You can turn it on in Settings.',
    AppLocale.it =>
      "L'accesso alla fotocamera è disattivato. Puoi attivarlo nelle Impostazioni.",
    AppLocale.fr =>
      "L'accès à l'appareil photo est désactivé. Vous pouvez l'activer dans les Réglages.",
    AppLocale.de =>
      'Der Kamerazugriff ist deaktiviert. Du kannst ihn in den Einstellungen aktivieren.',
  };
  String get photoAccessOff => switch (locale) {
    AppLocale.en =>
      'Photo access is turned off. You can turn it on in Settings.',
    AppLocale.it =>
      "L'accesso alle foto è disattivato. Puoi attivarlo nelle Impostazioni.",
    AppLocale.fr =>
      "L'accès aux photos est désactivé. Vous pouvez l'activer dans les Réglages.",
    AppLocale.de =>
      'Der Fotozugriff ist deaktiviert. Du kannst ihn in den Einstellungen aktivieren.',
  };
  String get openSettings => switch (locale) {
    AppLocale.en => 'Open Settings',
    AppLocale.it => 'Apri Impostazioni',
    AppLocale.fr => 'Ouvrir Réglages',
    AppLocale.de => 'Einstellungen öffnen',
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
    AppLocale.en => 'Tap to add a photo (optional)',
    AppLocale.it => 'Tocca per aggiungere una foto (facoltativo)',
    AppLocale.fr => 'Appuyez pour ajouter une photo (facultatif)',
    AppLocale.de => 'Tippen, um ein Foto hinzuzufügen (optional)',
  };
  String get photoTapToChange => switch (locale) {
    AppLocale.en => 'Photo, tap to change',
    AppLocale.it => 'Foto, tocca per cambiarla',
    AppLocale.fr => 'Photo, appuyez pour la changer',
    AppLocale.de => 'Foto, tippen zum Ändern',
  };
  String get decreaseQuantity => switch (locale) {
    AppLocale.en => 'Decrease quantity',
    AppLocale.it => 'Diminuisci quantità',
    AppLocale.fr => 'Diminuer la quantité',
    AppLocale.de => 'Menge verringern',
  };
  String get increaseQuantity => switch (locale) {
    AppLocale.en => 'Increase quantity',
    AppLocale.it => 'Aumenta quantità',
    AppLocale.fr => 'Augmenter la quantité',
    AppLocale.de => 'Menge erhöhen',
  };
  String get noPhotoLabel => switch (locale) {
    AppLocale.en => 'No photo',
    AppLocale.it => 'Nessuna foto',
    AppLocale.fr => 'Pas de photo',
    AppLocale.de => 'Kein Foto',
  };
  String get removePhoto => switch (locale) {
    AppLocale.en => 'Remove photo',
    AppLocale.it => 'Rimuovi foto',
    AppLocale.fr => 'Retirer la photo',
    AppLocale.de => 'Foto entfernen',
  };
  String get priceLabel => switch (locale) {
    AppLocale.en => 'Price',
    AppLocale.it => 'Prezzo',
    AppLocale.fr => 'Prix',
    AppLocale.de => 'Preis',
  };
  String get doneLabel => switch (locale) {
    AppLocale.en => 'Done',
    AppLocale.it => 'Fatto',
    AppLocale.fr => 'Terminé',
    AppLocale.de => 'Fertig',
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
  String get pondering => switch (locale) {
    AppLocale.en => 'Pondering',
    AppLocale.it => 'In sospeso',
    AppLocale.fr => 'En réflexion',
    AppLocale.de => 'Am Überlegen',
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
  String get couldntReadFile => switch (locale) {
    AppLocale.en => "Couldn't read that file.",
    AppLocale.it => 'Impossibile leggere il file.',
    AppLocale.fr => 'Impossible de lire ce fichier.',
    AppLocale.de => 'Die Datei konnte nicht gelesen werden.',
  };
  String get restoreAutoBackup => switch (locale) {
    AppLocale.en => 'Restore last automatic backup',
    AppLocale.it => "Ripristina l'ultimo backup automatico",
    AppLocale.fr => 'Restaurer la dernière sauvegarde automatique',
    AppLocale.de => 'Letztes automatisches Backup wiederherstellen',
  };
  String get noAutoBackupFound => switch (locale) {
    AppLocale.en => 'No automatic backup found yet.',
    AppLocale.it => 'Nessun backup automatico trovato.',
    AppLocale.fr => 'Aucune sauvegarde automatique trouvée.',
    AppLocale.de => 'Noch kein automatisches Backup gefunden.',
  };
  String get autoBackupAlreadyRestored => switch (locale) {
    AppLocale.en => 'This backup was already restored.',
    AppLocale.it => 'Questo backup è già stato ripristinato.',
    AppLocale.fr => 'Cette sauvegarde a déjà été restaurée.',
    AppLocale.de => 'Dieses Backup wurde bereits wiederhergestellt.',
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
      AppLocale.en => "That file doesn't look like a Skip! backup.",
      AppLocale.it => 'Il file non sembra essere un backup di Skip!',
      AppLocale.fr => 'Ce fichier ne semble pas être une sauvegarde de Skip!',
      AppLocale.de => 'Diese Datei scheint kein Backup von Skip! zu sein.',
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
  String get baddieY2k => 'Baddie Y2K';
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
    AppLocale.en => 'Dollar',
    AppLocale.it => 'Dollaro',
    AppLocale.fr => 'Dollar',
    AppLocale.de => 'Dollar',
  };
  String get euro => switch (locale) {
    AppLocale.en => 'Euro',
    AppLocale.it => 'Euro',
    AppLocale.fr => 'Euro',
    AppLocale.de => 'Euro',
  };
  String get currencyChangeWarningTitle => switch (locale) {
    AppLocale.en => 'Change currency?',
    AppLocale.it => 'Cambiare valuta?',
    AppLocale.fr => 'Changer de devise ?',
    AppLocale.de => 'Währung ändern?',
  };
  String get currencyChangeWarningContent => switch (locale) {
    AppLocale.en =>
      'This only changes how amounts are displayed. Amounts already saved '
          "won't be converted — a \$1 item will simply show as €1.",
    AppLocale.it =>
      'Questo cambia solo come vengono mostrati gli importi. Gli importi '
          'già salvati non verranno convertiti: un articolo da 1\$ verrà '
          'semplicemente mostrato come 1€.',
    AppLocale.fr =>
      "Cela ne change que l'affichage des montants. Les montants déjà "
          "enregistrés ne seront pas convertis : un article à 1\$ "
          's\'affichera simplement comme 1€.',
    AppLocale.de =>
      'Dies ändert nur die Anzeige der Beträge. Bereits gespeicherte '
          'Beträge werden nicht umgerechnet — ein Artikel für 1\$ wird '
          'einfach als 1€ angezeigt.',
  };
  String get continueAction => switch (locale) {
    AppLocale.en => 'Continue',
    AppLocale.it => 'Continua',
    AppLocale.fr => 'Continuer',
    AppLocale.de => 'Fortfahren',
  };
  String get costInHours => switch (locale) {
    AppLocale.en => 'Cost in Hours',
    AppLocale.it => 'Costo in ore',
    AppLocale.fr => 'Coût en heures',
    AppLocale.de => 'Kosten in Stunden',
  };
  String get hourlyWageLabel => switch (locale) {
    AppLocale.en => 'Hourly wage',
    AppLocale.it => 'Paga oraria',
    AppLocale.fr => 'Salaire horaire',
    AppLocale.de => 'Stundenlohn',
  };
  String get hourlyWageNotSet => switch (locale) {
    AppLocale.en => 'Not set — prices shown as-is',
    AppLocale.it => 'Non impostata: i prezzi restano invariati',
    AppLocale.fr => 'Non défini — les prix restent inchangés',
    AppLocale.de => 'Nicht festgelegt – Preise bleiben unverändert',
  };
  String get hourlyWageDialogTitle => switch (locale) {
    AppLocale.en => 'Set hourly wage',
    AppLocale.it => 'Imposta paga oraria',
    AppLocale.fr => 'Définir le salaire horaire',
    AppLocale.de => 'Stundenlohn festlegen',
  };
  String hourlyWageValue(String formattedAmount) => switch (locale) {
    AppLocale.en => '$formattedAmount / hr',
    AppLocale.it => '$formattedAmount / ora',
    AppLocale.fr => '$formattedAmount / h',
    AppLocale.de => '$formattedAmount / Std.',
  };
  String hoursOfWork(double hours) {
    final formatted = formatHoursOfWork(hours, locale);
    return switch (locale) {
      AppLocale.en => '≈ $formatted hrs of work',
      AppLocale.it => '≈ $formatted ore di lavoro',
      AppLocale.fr => '≈ $formatted h de travail',
      AppLocale.de => '≈ $formatted Std. Arbeit',
    };
  }

  String totalForQuantity(String formattedAmount) => switch (locale) {
    AppLocale.en => 'Total: $formattedAmount',
    AppLocale.it => 'Totale: $formattedAmount',
    AppLocale.fr => 'Total : $formattedAmount',
    AppLocale.de => 'Gesamt: $formattedAmount',
  };

  String get sound => switch (locale) {
    AppLocale.en => 'Sound',
    AppLocale.it => 'Audio',
    AppLocale.fr => 'Son',
    AppLocale.de => 'Ton',
  };
  String get soundEffects => switch (locale) {
    AppLocale.en => 'Sound effects',
    AppLocale.it => 'Effetti sonori',
    AppLocale.fr => 'Effets sonores',
    AppLocale.de => 'Soundeffekte',
  };
  String get trashSectionLabel => switch (locale) {
    AppLocale.en => 'Trash',
    AppLocale.it => 'Cestino',
    AppLocale.fr => 'Corbeille',
    AppLocale.de => 'Papierkorb',
  };
  String get emptyTrashMessage => switch (locale) {
    AppLocale.en => 'Trash is empty.',
    AppLocale.it => 'Il cestino è vuoto.',
    AppLocale.fr => 'La corbeille est vide.',
    AppLocale.de => 'Der Papierkorb ist leer.',
  };
  String get restore => switch (locale) {
    AppLocale.en => 'Restore',
    AppLocale.it => 'Ripristina',
    AppLocale.fr => 'Restaurer',
    AppLocale.de => 'Wiederherstellen',
  };
  String get trashRetentionNotice => switch (locale) {
    AppLocale.en => 'Items are permanently deleted 30 days after trashing.',
    AppLocale.it =>
      'Gli articoli vengono eliminati definitivamente 30 giorni dopo essere '
          'stati cestinati.',
    AppLocale.fr =>
      'Les articles sont définitivement supprimés 30 jours après leur mise '
          'à la corbeille.',
    AppLocale.de =>
      'Artikel werden 30 Tage nach dem Verschieben in den Papierkorb '
          'endgültig gelöscht.',
  };

  // Each language's own name, in that language — not translated into the
  // active one, so a user who ends up on the wrong language can still
  // recognize and tap their way back.
  String get english => 'English';
  String get italian => 'Italiano';
  String get french => 'Français';
  String get german => 'Deutsch';

  // Privacy policy
  String get legalSectionLabel => switch (locale) {
    AppLocale.en => 'Legal',
    AppLocale.it => 'Note legali',
    AppLocale.fr => 'Mentions légales',
    AppLocale.de => 'Rechtliches',
  };
  String get privacyPolicy => switch (locale) {
    AppLocale.en => 'Privacy Policy',
    AppLocale.it => 'Informativa sulla privacy',
    AppLocale.fr => 'Politique de confidentialité',
    AppLocale.de => 'Datenschutzerklärung',
  };
  String get privacyPolicyBody => switch (locale) {
    AppLocale.en =>
      'Skip! has no servers, no accounts, and no analytics. Everything you '
          'enter — photos, prices, titles, categories — stays only on your '
          'device and is never uploaded anywhere.',
    AppLocale.it =>
      'Skip! non ha server, account o analisi statistiche. Tutto ciò che '
          'inserisci — foto, prezzi, titoli, categorie — resta solo sul tuo '
          'dispositivo e non viene mai caricato altrove.',
    AppLocale.fr =>
      "Skip! n'a ni serveurs, ni comptes, ni outils d'analyse. Tout ce que "
          'vous saisissez — photos, prix, titres, catégories — reste '
          "uniquement sur votre appareil et n'est jamais téléversé ailleurs.",
    AppLocale.de =>
      'Skip! hat keine Server, keine Konten und keine Analysetools. Alles, '
          'was du eingibst – Fotos, Preise, Titel, Kategorien – bleibt nur '
          'auf deinem Gerät und wird nirgendwohin hochgeladen.',
  };
  String get privacyPolicyButton => switch (locale) {
    AppLocale.en => 'Read the full policy',
    AppLocale.it => 'Leggi l\'informativa completa',
    AppLocale.fr => 'Lire la politique complète',
    AppLocale.de => 'Vollständige Erklärung lesen',
  };
  String get privacyPolicyOpensExternally => switch (locale) {
    AppLocale.en => 'Opens on GitHub in your browser.',
    AppLocale.it => 'Apre GitHub nel browser.',
    AppLocale.fr => 'Ouvre GitHub dans votre navigateur.',
    AppLocale.de => 'Öffnet GitHub in deinem Browser.',
  };

  // Coin flip
  String get coinFlipTooltip => switch (locale) {
    AppLocale.en => 'Flip a coin',
    AppLocale.it => 'Lancia una moneta',
    AppLocale.fr => 'Lancer une pièce',
    AppLocale.de => 'Münze werfen',
  };
  String get flipTheCoin => switch (locale) {
    AppLocale.en => 'Flip the coin',
    AppLocale.it => 'Lancia la moneta',
    AppLocale.fr => 'Lancer la pièce',
    AppLocale.de => 'Münze werfen',
  };
  String get coinFlipTitle => switch (locale) {
    AppLocale.en => 'Coin Flip',
    AppLocale.it => 'Lancio della moneta',
    AppLocale.fr => 'Pile ou face',
    AppLocale.de => 'Münzwurf',
  };
  String get coinFlipSubtitle => switch (locale) {
    AppLocale.en => "Still can't decide? Let chance settle it.",
    AppLocale.it => 'Ancora indeciso? Lascia decidere il caso.',
    AppLocale.fr => "Toujours indécis ? Laissez le hasard trancher.",
    AppLocale.de => 'Immer noch unentschlossen? Lass den Zufall entscheiden.',
  };
  String get coinFlipYes => switch (locale) {
    AppLocale.en => 'Get it.',
    AppLocale.it => 'Prendilo.',
    AppLocale.fr => 'Prends-le.',
    AppLocale.de => 'Kauf es.',
  };
  String get coinFlipNo => switch (locale) {
    AppLocale.en => 'Skip it.',
    AppLocale.it => 'Lascialo.',
    AppLocale.fr => 'Laisse-le.',
    AppLocale.de => 'Lass es.',
  };

  // Mottos: shown under the Home summary cards and pushed to the native
  // widgets by HomeWidgetService (the iOS/Android extensions can't reach
  // this class).
  /// Short nudges the app and widgets rotate through, one per day, in the calm
  /// voice of the minimal "Skip!" aesthetic. Kept neutral so each reads right
  /// whether the month is going well or not, and short enough for three
  /// lines of a medium widget's half column.
  List<String> get mottosMinimal => switch (locale) {
    AppLocale.en => const [
      'Want it, or want it today?',
      "Sleep on it. It'll still be there.",
      'Every skip is a small win.',
      'Future you says thanks.',
      'Not buying is always on sale.',
      'Pause before you pay.',
      'Less stuff, more choices.',
    ],
    AppLocale.it => const [
      'Lo vuoi, o lo vuoi subito?',
      'Dormici su. Sarà ancora lì.',
      'Ogni rinuncia è una piccola vittoria.',
      'Il te del futuro ringrazia.',
      'Non comprare è sempre in saldo.',
      'Fermati prima di pagare.',
      'Meno cose, più libertà.',
    ],
    AppLocale.fr => const [
      'Envie, ou envie tout de suite ?',
      'La nuit porte conseil.',
      'Chaque renoncement est une petite victoire.',
      'Ton futur toi te remercie.',
      "Ne pas acheter, c'est toujours en solde.",
      'Une pause avant de payer.',
      'Moins de choses, plus de choix.',
    ],
    AppLocale.de => const [
      'Willst du es – oder willst du es jetzt?',
      'Schlaf eine Nacht drüber.',
      'Jeder Verzicht ist ein kleiner Sieg.',
      'Dein zukünftiges Ich sagt danke.',
      'Nicht kaufen ist immer im Angebot.',
      'Erst durchatmen, dann zahlen.',
      'Weniger Zeug, mehr Freiheit.',
    ],
  };

  /// Same role as [mottosMinimal], in the sassier voice of the Y2K
  /// "Skip!" aesthetic. Still never scolds: the line shows on bad months too.
  List<String> get mottosY2k => switch (locale) {
    AppLocale.en => const [
      'Put the card down. Slowly.',
      'Cart abandoned. Iconic.',
      'Your wallet called. It\'s thriving.',
      'Want ≠ need. Period.',
      'Main character energy: not buying it.',
      'Skip it like it\'s hot.',
      'Rich is a mindset. And a savings account.',
    ],
    AppLocale.it => const [
      'Giù la carta. Piano.',
      'Carrello abbandonato. Iconico.',
      'Il portafoglio ha chiamato: sta benissimo.',
      'Volere ≠ servire. Punto.',
      'Energia da protagonista: non lo compro.',
      'Skippalo con stile.',
      'Essere ricchi è uno stato mentale. E un salvadanaio.',
    ],
    AppLocale.fr => const [
      'Pose la carte. Doucement.',
      'Panier abandonné. Iconique.',
      'Ton portefeuille a appelé : il va super bien.',
      'Envie ≠ besoin. Point.',
      'Énergie de star : je ne l\'achète pas.',
      'Skippe-le avec style.',
      'Être riche, c\'est un état d\'esprit. Et une épargne.',
    ],
    AppLocale.de => const [
      'Karte runter. Ganz langsam.',
      'Warenkorb verlassen. Ikonisch.',
      'Dein Konto hat angerufen: Es blüht auf.',
      'Wollen ≠ brauchen. Punkt.',
      'Hauptrollen-Energie: Kauf ich nicht.',
      'Skippen mit Stil.',
      'Reich ist eine Einstellung. Und ein Sparkonto.',
    ],
  };

  /// Shown by the widget instead of a motto while this month is still empty.
  String get widgetMottoEmptyMinimal => switch (locale) {
    AppLocale.en => 'Nothing logged this month. First skip?',
    AppLocale.it => 'Ancora niente questo mese. Primo skip?',
    AppLocale.fr => 'Rien ce mois-ci. Premier skip ?',
    AppLocale.de => 'Diesen Monat noch nichts. Erster Skip?',
  };
  String get widgetMottoEmptyY2k => switch (locale) {
    AppLocale.en => 'Zero logged. Go skip something!',
    AppLocale.it => 'Ancora zero. Vai, skippa qualcosa!',
    AppLocale.fr => 'Zéro ce mois-ci. Va skipper un truc !',
    AppLocale.de => 'Noch null. Los, skip was!',
  };
}
