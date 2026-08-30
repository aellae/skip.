# 🗺️ SKIP. / SKIP! — Product & Technical Roadmap

A privacy-first, 100% offline mobile app built with Flutter and SQLite. SKIP allows users to track financial decisions visually by logging items they resisted buying (money saved) vs. items they purchased (money spent), wrapped in a dual-theme UI experience (Minimal Luxury vs. Bratz/Y2K Explosive).

---

## 📌 Phase 1: Core Architecture & Setup (MVP)
> **Goal:** Establish baseline Flutter project structure, local database, offline image handling, and dynamic theme engine.

- [x] **Project Scaffolding**
  - Initialize Flutter project with standard clean directory architecture (`core/`, `features/`, `data/`, `presentation/`).
  - Configure `pubspec.yaml` with essential dependencies (`sqflite`, `path`, `image_picker`, `provider`, `google_fonts`, `flutter_staggered_grid_view`).
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
    ```
  - Implement CRUD repository for local item storage.
- [x] **Local Storage & Image Pipeline**
  - Integrate native image picker (`image_picker`) for Camera & Gallery access.
  - Implement file persistence utility to copy picked images into the app's local application documents directory (`path_provider`).
- [x] **Dual-Theme Engine**
  - Create `ThemeProvider` managing dynamic toggle between **Minimal Luxury (`skip.`)** and **Bratz Y2K (`SKIP!`)**.
  - Configure typographic sets (Playfair Display + Inter vs. Titan One + Fredoka).
  - Configure dynamic palette tokens (Antracite/Silk/Beige vs. Hot Magenta/Electric Purple/Glitter Pink).

---

## 📌 Phase 2: Core User Workflows & UI
> **Goal:** Deliver smooth visual logging of wishlist/resisted items and clear financial impact counters.

- [ ] **Home Dashboard & Counters**
  - Header with dynamic logo rendering based on active theme (`skip.` vs `SKIP!`).
  - Dual prominent financial status cards:
    - **Total Saved** (Money retained by resisting purchases).
    - **Total Spent** (Money spent on executed purchases).
  - Moodboard / Gallery Feed using staggered grid view displaying product cards.
- [ ] **Item Creation Workflow (Quick-Add)**
  - Floating Action Button to initiate rapid photo log.
  - Photo preview modal with quick price input field and optional title.
  - Decision toggle: **"Resisted! / Skip"** vs. **"Bought It / Spent"**.
- [ ] **Interactive Card Management**
  - Tap card to view detail modal (full image, date, status change).
  - Swipe-to-delete or toggle status retroactively (e.g., changed mind and bought later).

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
