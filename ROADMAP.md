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

- [ ] **Theme-Specific Micro-Interactions**
  - **Bratz / Y2K Mode:**
    - Confetti explosion & floating spark/heart animations when tapping "Resisted!".
    - Retro glossy buttons with metallic silver outlines.
    - Sassy audio feedback / sound effects on saving money (haptic + sound).
  - **Minimal Mode:**
    - Subtle smooth scale animations and haptic ticks on interactions.
    - Monochrome clean layout with elegant typography.
- [ ] **Theme Switcher & Settings Drawer**
  - Smooth theme switcher toggle in settings.
  - Quick summary stats (Total items resisted count, average savings per item).

---

## 📌 Phase 4: Offline Data Management & Analytics
> **Goal:** Ensure data durability and offer privacy-respecting financial insights.

- [ ] **Local Data Backup & Export**
  - Export database to JSON / CSV file (saved locally to device downloads or shared via system sheet).
  - Import JSON backup file to restore data across devices.
- [ ] **Visual Insights & Monthly Breakdowns**
  - Monthly savings filter (e.g., "This Month's Savings").
  - Simple chart visualizer using offline Flutter charts (Bar chart of monthly savings vs. spend).

---

## 📌 Phase 5: Testing, Hardening & Launch
> **Goal:** Polish performance, ensure zero data leakage, prepare store builds.

- [ ] **Offline Performance Optimization**
  - Image compression & thumbnail generation to prevent memory spikes on large visual feeds.
  - Database indexing on `created_at` and `is_saved` columns.
- [ ] **App Store & Play Store Preparation**
  - Generate app icon variants (Minimal monochrome vs. Y2K neon pink).
  - Automated release builds for iOS (IPA) and Android (APK/AAB).
