# 🗺️ SKIP. / SKIP! — Product & Technical Roadmap

A privacy-first, 100% offline mobile app built with Flutter and SQLite. SKIP allows users to track financial decisions visually by logging items they resisted buying (money saved) vs. items they purchased (money spent), wrapped in a dual-theme UI experience (Minimal Luxury vs. Bratz/Y2K Explosive).

---

## 📌 Phase 1: Core Architecture & Setup (MVP)
> **Goal:** Establish baseline Flutter project structure, local database, offline image handling, and dynamic theme engine.

- [x] **Project Scaffolding**
  - Initialize Flutter project with standard clean directory architecture (`core/`, `features/`, `data/`).
  - Configure `pubspec.yaml` with essential dependencies (`sqflite`, `path`, `image_picker`, `provider`, `google_fonts`, `flutter_staggered_grid_view`, plus the full Phase 2-5 dependency set added up front per the build prompt).
- [x] **Offline Database Layer (`sqflite`)**
  - Design SQLite schema:
    ```sql
    CREATE TABLE items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT,
      price REAL NOT NULL,
      image_path TEXT NOT NULL,
      is_saved INTEGER NOT NULL, -- 1 = Resisted (Saved), 0 = Purchased (Spent)
      category TEXT,
      created_at TEXT NOT NULL
    );
    CREATE INDEX idx_items_created_at ON items(created_at);
    CREATE INDEX idx_items_is_saved ON items(is_saved);
    ```
  - Implement CRUD repository for local item storage (`DatabaseHelper`: insert/update/delete/query/aggregate totals), with `deleteItem` also removing the backing image file.
- [x] **Local Storage & Image Pipeline**
  - `FileHelper` copies files into the app's local application documents directory (`path_provider`) under a `skip_images/` subdir and stores a *relative* path (not absolute — iOS sandbox container paths aren't stable across reinstalls).
  - `image_picker` wiring for Camera & Gallery access lands in Phase 2 alongside the quick-add UI that actually calls it.
- [x] **Dual-Theme Engine**
  - `ThemeProvider` managing dynamic toggle between **Minimal Luxury (`skip.`)** and **Bratz Y2K (`SKIP!`)**.
  - Typographic sets (Playfair Display + Inter vs. Titan One + Fredoka), bundled as local variable-font assets — zero runtime network fetches (`GoogleFonts.config.allowRuntimeFetching = false`).
  - Dynamic palette tokens (Charcoal/Silk Beige/Champagne/Soft White vs. Hot Magenta/Electric Violet/Metallic Silver) exposed via `SkipThemeExtension`.

---

## 📌 Phase 2: Core User Workflows & UI
> **Goal:** Deliver smooth visual logging of wishlist/resisted items and clear financial impact counters.

- [x] **Home Dashboard & Counters**
  - Header with dynamic logo rendering based on active theme (`skip.` vs `SKIP!`).
  - Dual prominent financial status cards:
    - **Total Saved** (Money retained by resisting purchases).
    - **Total Spent** (Money spent on executed purchases).
  - Moodboard / Gallery Feed using `flutter_staggered_grid_view`'s masonry grid displaying product cards (`Image.file` with `cacheWidth` per CLAUDE.md).
- [x] **Item Creation Workflow (Quick-Add)**
  - Floating Action Button to initiate rapid photo log.
  - Photo preview modal (camera/gallery action sheet) with quick price input field and optional title.
  - Decision toggle: **"Resisted! / Skip"** vs. **"Bought It / Spent"**.
- [x] **Interactive Card Management**
  - Tap card to view detail modal (full image, date, status change).
  - Toggle status retroactively (e.g., changed mind and bought later). Delete is a button + confirmation dialog on the detail screen rather than swipe-to-delete on the grid — a deliberate, minimal choice: destructive delete behind a confirmation is safer than an easily-mis-triggered swipe gesture, and the roadmap phrased these as alternatives ("swipe-to-delete *or* toggle status"). Deleting always cleans up the backing image file (CLAUDE.md orphan-file rule).

---

## 📌 Phase 3: Y2K Polish & Micro-Interactions
> **Goal:** Elevate user delight with distinctive tactile feedback, sound effects, and celebratory visuals.

- [x] **Theme-Specific Micro-Interactions**
  - **Bratz / Y2K Mode:**
    - Confetti explosion when tapping "Resisted!" (`confetti` package via `DecisionToggle`) — the explosive burst itself is the floating-particle celebration; no separate heart/spark animation layer was added on top of it (reasonable minimal choice, not a data/offline/schema question).
    - Retro glossy buttons with metallic silver outlines: gradient sheen + metallic-silver border on the selected Y2K toggle option.
    - Sassy audio feedback / sound effects on saving money (haptic + sound): `SkipSfxPlayer` wraps `audioplayers` and is wired into the "Resisted!" tap alongside a `HapticFeedback.mediumImpact()`. No real SFX asset is bundled yet — user chose a no-op stub for now (BUILD_PROMPT.md §9: can't fabricate real audio); playback fails silently until a real file lands at `assets/sfx/resisted.mp3`.
  - **Minimal Mode:**
    - Subtle smooth scale animations and haptic ticks on interactions: shared `TapScale` widget (press-down scale + `HapticFeedback.selectionClick()`), used by grid cards and all toggle/option buttons in both aesthetics.
    - Monochrome clean layout with elegant typography (already in place since Phase 1's theme engine).
- [x] **Theme Switcher & Settings Drawer**
  - Smooth theme switcher toggle in settings (`SettingsScreen`, pushed from a new gear icon in the home AppBar — a screen rather than a literal `Drawer` widget, consistent with the rest of the app's push-based navigation; cosmetic choice, not a schema/offline one).
  - Quick summary stats: Total items resisted count, average saved per item (`ItemsProvider.resistedCount` / `.averageSavedPerItem`).

---

## 📌 Phase 4: Offline Data Management & Analytics
> **Goal:** Ensure data durability and offer privacy-respecting financial insights.

- [x] **Local Data Backup & Export**
  - Export database to JSON / CSV file (saved locally to device downloads or shared via system sheet): `BackupSection` builds a JSON or CSV backup via `ItemsProvider.buildJsonBackup`/`buildCsvBackup`, writes it via `FileHelper.writeExportFile`, and hands it to the system share sheet (`share_plus`).
  - Import JSON backup file to restore data across devices: `file_picker` → `ItemsProvider.importJsonBackup`, additive (doesn't wipe existing items) and throws a typed `BackupFormatException` surfaced as a clear on-screen error for malformed files rather than silently accepting them.
- [x] **Visual Insights & Monthly Breakdowns**
  - Monthly savings filter (e.g., "This Month's Savings"): `ItemsProvider.totalSavedThisMonth` / `.totalSpentThisMonth`.
  - Simple chart visualizer using offline Flutter charts (Bar chart of monthly savings vs. spend): `InsightsScreen` + `MonthlyBarChart` (`fl_chart`), fed by `computeMonthlyTotals`.

---

## 📌 Phase 5: Testing, Hardening & Launch
> **Goal:** Polish performance, ensure zero data leakage, prepare store builds.

- [x] **Offline Performance Optimization**
  - Image compression & thumbnail generation to prevent memory spikes on large visual feeds: `ItemEntryScreen` now caps picked photos to 2000×2000 at capture time (`image_picker`'s `maxWidth`/`maxHeight`, alongside the existing `imageQuality: 85`) so a full-res camera photo never lands in `skip_images/` uncompressed — on top of the per-context `Image.file` `cacheWidth`/`cacheHeight` bounds already in place since Phase 1/2, which only capped the display-time decode, not what's actually stored on disk. A separate physical thumbnail file was deliberately not added — the resolution cap plus existing decode-time bounds cover the memory-spike risk without the extra disk footprint of duplicate thumbnail files.
  - Database indexing on `created_at` and `is_saved` columns: indexes existed since Phase 1; now *confirmed* via `EXPLAIN QUERY PLAN` (not just existence) that the app's real queries actually use them — `getAllItems`/`_sumPrice`'s `is_saved` filter uses `idx_items_is_saved`, unfiltered `getAllItems` uses `idx_items_created_at` for the scan+sort.
- [x] **App Store & Play Store Preparation**
  - Generate app icon variants (Minimal monochrome vs. Y2K neon pink): placeholder wordmark icons for both aesthetics at `assets/icon/icon_minimal.png` / `icon_y2k.png` (real bundled fonts/brand colors, not final store-ready art — confirm with the user before real submission), wired via `flutter_launcher_icons`; ships with the Minimal variant since that's `ThemeProvider`'s default aesthetic.
  - Automated release builds for iOS (IPA) and Android (APK/AAB): local release builds now succeed — `flutter build apk --release` (debug-signed pending a real keystore at `android/key.properties`, see `key.properties.example`) and `flutter build ios --release --no-codesign` (needs a real Apple signing identity to produce a signed IPA). Per BUILD_PROMPT.md §7's Phase 5 scope boundary, actual App/Play Store submission is out of scope here — needs the user's developer account credentials and a real keystore/signing identity.
