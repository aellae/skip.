# CLAUDE.md — Developer Guidelines & Instructions for Skip!

This document provides guidelines, technical conventions, and architectural rules for AI assistants (like Claude) and developers contributing to **Skip!**.

---

## 📐 Project Rules & Core Principles

1. **Strictly 100% Offline:**
   - **DO NOT** introduce HTTP clients (`http`, `dio`), Firebase, SDK analytics, or remote telemetry packages.
   - All data resides exclusively in SQLite (`sqflite`).
   - All image assets reside exclusively in the local Application Documents directory using `path_provider`.

2. **Dual-Theme Integrity (`Skip!` vs `Skip!`):**
   - Every user-facing UI component must respect the active theme provided by `ThemeProvider`.
   - Never hardcode visual colors, font families, or decorative styling inline unless derived from context (`Theme.of(context)`).
   - Dynamic logo naming convention:
     - Minimal Theme: lowercase `Skip!`
     - Baddie/Y2K Theme: uppercase `Skip!`

3. **Performance & Memory Rules for Images:**
   - Picked images from `image_picker` must be copied into local app documents immediately and referenced by relative file path.
   - Always use `Image.file()` with cached bounds or thumb-friendly constraints to avoid memory crashes on high-res photos in grid views.

---

## 🛠️ Tech Stack & Key Packages

- **Language:** Dart / Flutter
- **State Management:** `provider` (`ChangeNotifier`)
- **Database:** `sqflite`
- **File System:** `path_provider` & `path`
- **Media:** `image_picker`
- **Fonts:** Bundled locally (Playfair Display, Inter, Titan One, Fredoka) — declared in `pubspec.yaml`'s `flutter.fonts` and referenced via `fontFamily:` in `app_themes.dart`; no `google_fonts` package dependency.

---

## 📁 Repository Structure

```text
lib/
├── main.dart                      # App entry point, MultiProvider setup (Theme/Items/Locale/Currency/Sfx/Wage)
├── core/
│   ├── theme/
│   │   ├── app_themes.dart        # Minimal & Y2K ThemeData objects + SkipThemeExtension
│   │   ├── theme_provider.dart    # Theme state management, persists aesthetic, swaps iOS app icon
│   │   ├── app_icon_channel.dart  # Native MethodChannel for alternate iOS home-screen icon
│   │   └── contrast.dart          # bestOnColor text-on-color contrast helper
│   ├── constants/
│   │   ├── app_colors.dart        # Raw theme color constants (consumed only by app_themes.dart)
│   │   └── app_spacing.dart
│   ├── localization/              # app_strings/app_locale (EN/IT/FR/DE)/app_currency (USD/EUR) + providers
│   ├── settings/                  # sfx_provider.dart, wage_provider.dart (persisted per-user settings)
│   ├── audio/                     # sfx_player.dart — "Resisted!" sound cue
│   ├── utils/                     # currency/date/wage formatters, file_helper.dart, url_validator.dart
│   └── widgets/                   # Shared components: skip_card, skip_app_bar, empty_state, status_indicator, etc.
├── data/
│   ├── database_helper.dart       # SQLite singleton database helper (schema v6)
│   ├── items_provider.dart        # ChangeNotifier data facade — feature code goes through this, not the DB directly
│   ├── backup_service.dart        # Automatic local safety-net backup (JSON write + restore)
│   └── models/
│       ├── item_model.dart        # Item model (toMap / fromMap)
│       └── monthly_total.dart
└── features/
    ├── home/                      # Dashboard grid + item detail/edit screen
    ├── item_entry/                # Quick-add form with camera picker; decision toggle saves + persists in one action
    ├── insights/                  # Monthly saved/spent bar chart
    ├── coin_flip/                 # Standalone decision tool (no DB read/write)
    ├── settings/                  # Aesthetic/locale/currency/wage/sfx switchers, backup, trash link, support page
    └── trash/                     # Soft-deleted items list with restore
```

See [docs/NEW_FEATURE_GUIDE.md](docs/NEW_FEATURE_GUIDE.md) for a full walkthrough of what each part above does and how to add a new feature.

---

## 💾 Database Schema Reference

Current schema version: **6** (see migrations in `database_helper.dart`'s `_onUpgrade`). Two migrations (v4, v6) had to rebuild the table via rename→create→copy→drop because SQLite can't relax a column to nullable with `ALTER TABLE` — follow that pattern if a future migration needs the same. Indexes exist on `created_at` and `is_saved`.

Table Name: `items`

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `INTEGER` | `PRIMARY KEY AUTOINCREMENT` | Unique identifier |
| `title` | `TEXT` | `NULLABLE` | Optional product description |
| `price` | `REAL` | `NOT NULL` | Unit price of the item |
| `quantity` | `INTEGER` | `NOT NULL DEFAULT 1` | Number of units; total saved/spent for the item is `price * quantity` |
| `image_path` | `TEXT` | `NULLABLE` | Local device relative file path; `NULL` = item logged without a photo |
| `is_saved` | `INTEGER` | `NULLABLE` | `1` = Resisted/Saved, `0` = Bought/Spent, `NULL` = Pondering/Deciding (undecided) |
| `category` | `TEXT` | `NULLABLE` | Optional category tag |
| `created_at` | `TEXT` | `NOT NULL` | ISO8601 Timestamp string |
| `purchase_url` | `TEXT` | `NULLABLE` | Optional link to the product's page, opened via the OS |
| `deleted_at` | `TEXT` | `NULLABLE` | ISO8601 soft-delete timestamp; the row is hard-deleted (with its image) once past the retention window |

---

## 🧪 Common Commands

```bash
# Get dependencies
flutter pub get

# Run application on emulator/device
flutter run

# Run static analysis
flutter analyze

# Format code according to Dart standards
dart format .

# Run unit tests
flutter test
```

> **⚠️ Do not run the Android emulator unless explicitly requested.**
> Default to iOS Simulator (or static analysis / `flutter test`) for verifying changes. The Android emulator (`Medium_Phone.avd`) consumes several GB of RAM and continuously rewrites a multi-GB disk image while running, which has driven this machine to zero free disk space before. Only launch it when the user specifically asks to test on Android, and prefer `flutter run -d ios` / a booted iOS simulator for routine checks.

---

## ✅ Implemented Features

- **Home** — dashboard with summary cards (total saved/spent) and a staggered masonry grid of items; tapping an item opens a full detail/edit/delete screen with retroactive decision changes, purchase-URL management, and cost-in-hours display.
- **Item Entry** — quick-add form (photo optional, price/quantity/title/purchase-URL). No separate "Save" button: tapping the `DecisionToggle` (Resisted/Pondering/Bought) sets the decision and persists the item in one action.
- **Insights** — this month's saved/spent totals plus a 6-month bar chart comparing saved vs. spent (`fl_chart`).
- **Coin Flip** — standalone decision tool (3D-flip animation, confetti, haptics); does **not** read/write `ItemsProvider` or the database.
- **Settings** — aesthetic switcher, language (EN/IT/FR/DE), currency (USD/EUR), hourly-wage editor, sound toggle, stat tiles, backup section (restore last automatic backup), link to Trash, and a static PayPal support page.
- **Trash** — lists soft-deleted items with per-item restore; never purges itself. Permanent purging (`purgeExpiredTrash`, which also deletes orphaned image files) is triggered once, from `HomeScreen.initState`.
- **Backup/Restore** — fully local (no HTTP). An automatic safety-net backup (`ItemsProvider.load()` throttles writes to once per 10 minutes) restorable via `ItemsProvider.restoreFromAutoBackup()`. Backups don't include photos, only records.
- **Theming** — `SkipThemeExtension` carries app-specific tokens (`savedColor`/`spentColor`/`ponderingColor`, `cardRadius`, `accentGradient`, `logoText`, etc.) alongside the two full `ThemeData` objects in `AppThemes` (`minimal`, `y2k`). Switching aesthetics also swaps the iOS home-screen app icon via a native `MethodChannel`.

Full functional detail and reusable building blocks are documented in [docs/NEW_FEATURE_GUIDE.md](docs/NEW_FEATURE_GUIDE.md#whats-already-implemented).

---

## 🎨 Design Rules for New Features

- **Adding a new feature UI:** Ensure both Minimal (`Skip!`) and Y2K (`Skip!`) variants render properly. Test switching themes live while the screen is open.
- **Form Inputs:** Money fields must enforce double/float numerical inputs with proper currency formatting.
- **Deleting Items:** Deletion is soft — an item is moved to Trash (`deleted_at` set) and stays recoverable from Settings. Local image files are cleaned up only when Trash is purged past its retention window, not at the moment of deletion, so orphaned files still never persist indefinitely.
