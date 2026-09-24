# Adding a New Feature to Skip!

This is a step-by-step checklist for implementing a new feature in this repo. It complements [CLAUDE.md](../CLAUDE.md), which has the full rules — read that first if you haven't.

---

## 1. Scaffold the feature folder

Features live under `lib/features/<feature_name>/`, following the existing pattern (see `item_entry/`, `trash/`):

```text
lib/features/<feature_name>/
├── <feature_name>_screen.dart   # Main screen/widget entry point
└── widgets/                     # Feature-local widgets, if any
    └── some_widget.dart
```

Only add a `widgets/` subfolder if the feature has sub-components worth splitting out.

## 2. Respect the offline-only rule

- No `http`, `dio`, Firebase, analytics SDKs, or any remote calls.
- Persist data in SQLite via `database_helper.dart`, extending the `items` table or adding a new table/method there.
- Persist images by copying them into the app documents directory (`path_provider`) and storing a relative path — never store absolute paths or keep the picker's original file.

## 3. Wire up state

- Use `provider` (`ChangeNotifier`) for state management — no new state management libraries.
- If the feature needs shared/global state, add a provider in `main.dart`'s provider tree rather than reaching into other features' state directly.

## 4. Theme integrity

- Every widget must read colors/fonts from `Theme.of(context)` — no hardcoded colors or font families.
- Manually verify the feature in **both** themes:
  - Minimal (`Skip!`, lowercase branding)
  - Baddie/Y2K (`Skip!`, uppercase branding)
- Toggle themes live (Settings) while the new screen is open to confirm it adapts.

## 5. Images (if the feature touches photos)

- Copy picked images into app documents immediately (don't reference the picker's temp path).
- Use `Image.file()` with bounded/thumbnail-friendly constraints in any grid or list view to avoid memory blowups on high-res photos.

## 6. Deletion semantics (if the feature deletes items)

- Deletion must be **soft**: set `deleted_at`, don't hard-delete the row or its image.
- Hard-delete (row + image file) only happens when Trash purges past the retention window — don't add new hard-delete paths.

## 7. Database changes

If the feature needs a schema change:
- Add a migration in `database_helper.dart` (bump the DB version, add an `onUpgrade` step).
- Update the schema table in [CLAUDE.md](../CLAUDE.md) to match.

## 8. Verify

```bash
flutter analyze
dart format .
flutter test
flutter run -d ios   # or a booted iOS simulator
```

> Don't launch the Android emulator unless explicitly asked — it's heavy on disk/RAM on this machine.

Manually exercise the golden path and edge cases in the simulator before calling the feature done — `flutter analyze`/`flutter test` verify correctness, not that the feature actually works end-to-end.

## 9. Keep docs in sync

If the feature adds a new top-level folder, a DB column, or changes a cross-cutting convention, update [CLAUDE.md](../CLAUDE.md) (repo structure / schema reference) in the same change.

---

## What's already implemented

A factual snapshot of the current app, so new work builds on the right primitives instead of re-inventing them.

### App shell (`lib/main.dart`)

`main()` is `async` and `await`s `.loadSaved()` on every provider (`ThemeProvider`, `LocaleProvider`, `CurrencyProvider`, `SfxProvider`, `WageProvider`) before `runApp`, so persisted settings are active on the first frame. `SkipApp` wraps the tree in a `MultiProvider` with those 6 `ChangeNotifierProvider`s (each also accepts an `*Override` constructor param used only by tests). There's no route table — navigation is imperative `Navigator.push(MaterialPageRoute(...))` from a single root, `HomeScreen`. `MaterialApp.builder` wraps the child in `AnimatedTheme` (450ms) so aesthetic switches animate.

### Theming (`lib/core/theme/`)

- `SkipThemeExtension` (a `ThemeExtension`) carries app-specific tokens `ThemeData` doesn't cover: `savedColor`/`spentColor`/`ponderingColor`, `cardBackground`, `logoText` (`'Skip!'` vs `'Skip!'`), `isY2K`, `cardRadius`/`buttonRadius`, `cardShadow`/`glowShadow`, `accentGradient` (nullable), `accentHighlight`. Read it via `Theme.of(context).extension<SkipThemeExtension>()`.
- `AppThemes.minimal` and `AppThemes.y2k` are the two full `ThemeData` objects (fonts, `ColorScheme`, and every major component theme). Minimal = light, Playfair Display/Inter, soft shadows, no gradient. Y2K = dark, Titan One/Fredoka, bordered cards, magenta→violet glow/gradient.
- `ThemeProvider` holds the active `SkipAesthetic`, persists it to `SharedPreferences`, and — on iOS — swaps the home-screen app icon via `AppIconChannel` (a native `MethodChannel`; alternate icon `AppIcon-Y2K` declared in `ios/Runner/Info.plist`).
- Raw color constants live in `lib/core/constants/app_colors.dart` but are only consumed by `AppThemes` — feature code should never reference them directly, only `Theme.of(context)`.

### Database (`lib/data/database_helper.dart`)

Singleton `DatabaseHelper.instance`, db `skip.db`, currently **schema version 6**. The `items` table matches the schema table in [CLAUDE.md](../CLAUDE.md) exactly, plus indexes on `created_at` and `is_saved`. Migrations are sequential `if (oldVersion < N)` blocks in `_onUpgrade` — two of them (v4, v5→6) had to rebuild the table via rename/create/copy/drop because SQLite can't relax a column to nullable with `ALTER TABLE`; follow that pattern if a future migration needs the same.

Key methods: `insertItem`, `updateItem`, `getItemById`, `getAllItems({isSaved, pondering})` (excludes soft-deleted rows), `getTrashedItems()`, `deleteItem`/`restoreItem` (soft-delete via `deleted_at`), `purgeExpiredTrash({retention = 30 days})` (hard-deletes rows past retention **and** their image files — the only place image files are ever removed), `getTotalSaved()`/`getTotalSpent()`.

`lib/data/items_provider.dart` is the single `ChangeNotifier` facade feature code should go through — don't call `DatabaseHelper` directly from a screen. `HomeScreen.initState` calls `ItemsProvider.load()` then `purgeExpiredTrash()`, which is the app's only trigger point for permanent cleanup.

### Backup/restore (`lib/data/backup_service.dart`)

All local, no HTTP. The only backup feature is the **automatic safety-net backup**: `ItemsProvider.load()` debounces `writeAutoBackup()` by 3 seconds, writing `skip_autobackup.json`, and `HomeWidgetSync` calls `ItemsProvider.flushAutoBackup()` when the app is backgrounded so a pending write isn't lost if iOS kills the app. Restoring it goes through `ItemsProvider.restoreFromAutoBackup()`, which returns a sealed result (`AutoBackupRestored`/`AutoBackupAlreadyRestored`/`AutoBackupNotFound`). `BackupService.importItems` recognizes items already present — live or trashed — by `created_at` (set once at creation, kept by every edit), so a restore only adds items that are missing entirely: it never duplicates an item or brings back an older version of it. Backups don't include photos — only records — so a restored item can show a blank image tile.

### Features (`lib/features/`)

| Folder | What it does |
| --- | --- |
| `home/` | Dashboard: `home_screen.dart` shows summary cards + a staggered masonry grid of items (FAB → add item); `item_detail_screen.dart` is the full view/edit/delete screen for one item, including retroactive decision changes, purchase-URL management, and cost-in-hours display. |
| `item_entry/` | Quick-add form (photo optional, price/quantity/title/URL). No separate "Save" button — tapping a `DecisionToggle` option (Resisted/Pondering/Bought) both sets the decision and persists the item in one action. |
| `insights/` | This month's saved/spent totals plus a 6-month bar chart (`fl_chart`) comparing saved vs. spent. |
| `coin_flip/` | Standalone decision tool (3D-flip animation, confetti, haptics). Does **not** read/write `ItemsProvider` or the database — purely momentary. |
| `settings/` | Aesthetic switcher, language (EN/IT/FR/DE), currency (USD/EUR), hourly-wage editor, sound toggle, stat tiles, `BackupSection`, links to Trash and a static PayPal support page. |
| `trash/` | Lists soft-deleted items with per-item "Restore". Never purges itself — purging happens from `HomeScreen.initState`. |

### Shared building blocks worth reusing

- `lib/core/widgets/` — `empty_state.dart`, `skip_card.dart`, `skip_app_bar.dart`, `status_indicator.dart`, `quantity_stepper.dart`, `image_source_sheet.dart`, `animated_count_up.dart`, `entrance_fade.dart`, `tap_scale.dart`, `item_image_placeholder.dart`.
- `lib/core/utils/` — `currency_formatter.dart`, `date_formatter.dart`, `file_helper.dart` (image save/resolve/delete), `url_validator.dart`, `wage_formatter.dart`.
- `lib/core/localization/` — `app_strings.dart`, `app_locale.dart`, `app_currency.dart`, plus their providers.
- `lib/core/settings/` — `sfx_provider.dart`, `wage_provider.dart` (pattern to copy for any new persisted per-user setting).

### Key dependencies (`pubspec.yaml`)

`sqflite`/`path`/`path_provider` (storage), `provider` (state), `image_picker`, `flutter_staggered_grid_view` (home grid), `confetti` + `audioplayers` + `shimmer` (celebratory effects), `fl_chart` (Insights), `url_launcher`, `shared_preferences` (all persisted settings). Dev-only: `mocktail`, `sqflite_common_ffi` (in-memory DB for tests), `flutter_launcher_icons`, `integration_test`.
