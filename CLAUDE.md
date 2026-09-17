# CLAUDE.md — Developer Guidelines & Instructions for Skip!

This document provides guidelines, technical conventions, and architectural rules for AI assistants (like Claude) and developers contributing to **Skip!**.

---

## 📐 Project Rules & Core Principles

1. **Strictly 100% Offline:**
   - **DO NOT** introduce HTTP clients (`http`, `dio`), Firebase, SDK analytics, or remote telemetry packages.
   - All data resides exclusively in SQLite (`sqflite`).
   - All image assets reside exclusively in the local Application Documents directory using `path_provider`.

2. **Dual-Theme Integrity (`skip.` vs `SKIP!`):**
   - Every user-facing UI component must respect the active theme provided by `ThemeProvider`.
   - Never hardcode visual colors, font families, or decorative styling inline unless derived from context (`Theme.of(context)`).
   - Dynamic logo naming convention:
     - Minimal Theme: lowercase `skip.`
     - Bratz/Y2K Theme: uppercase `SKIP!`

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
├── main.dart                      # App entry point, Provider initialization
├── core/
│   ├── theme/
│   │   ├── app_themes.dart        # Minimal & Bratz ThemeData objects
│   │   └── theme_provider.dart    # Theme state management
│   └── constants/
│       └── app_colors.dart        # Theme color constants
├── data/
│   ├── database_helper.dart       # SQLite singleton database helper
│   └── models/
│       └── item_model.dart        # Item model (toMap / fromMap)
└── features/
    ├── home/                      # Dashboard UI (Counters, Staggered Grid)
    ├── item_entry/                # Quick-add modal form with camera picker
    └── settings/                  # Aesthetic switcher drawer/screen
```

---

## 💾 Database Schema Reference

Table Name: `items`

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `INTEGER` | `PRIMARY KEY AUTOINCREMENT` | Unique identifier |
| `title` | `TEXT` | `NULLABLE` | Optional product description |
| `price` | `REAL` | `NOT NULL` | Monetary value of the item |
| `image_path` | `TEXT` | `NOT NULL` | Local device absolute file path |
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

## 🎨 Design Rules for New Features

- **Adding a new feature UI:** Ensure both Minimal (`skip.`) and Y2K (`SKIP!`) variants render properly. Test switching themes live while the screen is open.
- **Form Inputs:** Money fields must enforce double/float numerical inputs with proper currency formatting.
- **Deleting Items:** Deletion is soft — an item is moved to Trash (`deleted_at` set) and stays recoverable from Settings. Local image files are cleaned up only when Trash is purged past its retention window, not at the moment of deletion, so orphaned files still never persist indefinitely.
