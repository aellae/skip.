# SKIP. / SKIP! — Build & Test Execution Prompt

Paste this entire file as your first message in a **fresh Claude Code session opened in this repo folder**. It is self-contained: read the three referenced docs yourself before acting.

---

## 0. Context

You are building **SKIP** (`skip.` / `SKIP!`), a 100% offline Flutter app that lets users log items they resisted buying (money "saved") vs. items they bought (money "spent"), with a photo, a price, and a dual-theme UI (Minimal Luxury vs. Bratz Y2K).

Read these three files first, in full — they are the source of truth for product intent, architecture, and coding rules:
- `README.md` — concept, dual-theme spec, tech stack, project structure.
- `CLAUDE.md` — binding developer guidelines. Treat every rule in it as a hard constraint, not a suggestion.
- `ROADMAP.md` — the phased backlog you will execute, in order.

## 1. Known state — do not trust the roadmap checkboxes

`ROADMAP.md` currently marks all of Phase 1 as complete (`[x]`). **This is false.** As of the start of this task, this directory contains only `README.md`, `CLAUDE.md`, `ROADMAP.md`, and this file — no `pubspec.yaml`, no `lib/`, no git history, nothing else. Treat Phase 1 as entirely unstarted. Build it for real.

As you complete each phase, update its checkboxes in `ROADMAP.md` yourself — but only check a box once the corresponding code exists, is tested, and passes `flutter analyze`. Do not batch-check boxes speculatively the way the current file does.

## 2. Two conflicts in the source docs — already resolved, apply as stated

1. **Schema conflict**: `CLAUDE.md`'s schema table omits a `category` column that `ROADMAP.md`'s SQL includes. Resolved: **include `category TEXT`, nullable.** Use the exact schema in §5 below. No feature currently reads/writes it — that's fine, it's forward-provisioning, not a bug.
2. **`google_fonts` vs. "100% offline"**: `google_fonts` fetches font files over HTTP on first use by default and caches them — this silently violates CLAUDE.md's offline rule the first time the app runs online, and will hang/fallback awkwardly if the very first run is offline (common for this app). Resolved: **bundle the four required font files as local assets and disable runtime fetching.** Concretely, in `main()` before `runApp`:
   ```dart
   GoogleFonts.config.allowRuntimeFetching = false;
   ```
   Download the actual font files for Playfair Display, Inter, Titan One, and Fredoka (all SIL Open Font License, free to bundle) once during setup, place them under `assets/fonts/`, and declare them in `pubspec.yaml`'s `flutter: fonts:` section under their exact Google Fonts family names. With fetching disabled, `GoogleFonts.playfairDisplay()` etc. will resolve to the bundled asset instead of the network — you still get the convenient `google_fonts` API, with zero network calls, ever. Verify this by running the app in airplane mode before considering Phase 1 done.

## 3. Environment check (do this before writing any code)

Run `flutter doctor -v`. If Flutter/Dart isn't installed, stop and ask the user to install it — don't attempt to install the SDK yourself. If neither an iOS nor an Android toolchain is available for local run/test, stop and ask the user which platform to target for development, since you'll need a working simulator/emulator to visually verify both themes per CLAUDE.md's design rule.

## 4. Repo & project setup

1. `git init` in this folder, then an initial commit containing the three existing docs as-is (message: something like "Initial docs"). This repo has no remote — do not add one, do not attempt to push anywhere.
2. `flutter create` the project in place (package/app name `skip`, or ask the user if you need a reverse-domain bundle ID for iOS/Android — don't invent one, e.g. `com.someguess.skip`, since that's part of store identity and hard to change later).
3. Rebuild the `lib/` tree to match the structure documented in both `README.md` and `CLAUDE.md` (they agree with each other):
   ```text
   lib/
   ├── main.dart
   ├── core/
   │   ├── theme/
   │   │   ├── app_themes.dart
   │   │   └── theme_provider.dart
   │   ├── constants/
   │   │   └── app_colors.dart
   │   └── utils/
   │       └── file_helper.dart
   ├── data/
   │   ├── database_helper.dart
   │   └── models/
   │       └── item_model.dart
   └── features/
       ├── home/
       ├── item_entry/
       └── settings/
   ```
4. Add dependencies with `flutter pub add <package>` (don't hand-write version numbers into `pubspec.yaml` — let pub resolve current compatible versions):
   - Runtime: `sqflite`, `path`, `path_provider`, `provider`, `image_picker`, `google_fonts`, `flutter_staggered_grid_view`, `confetti`, `audioplayers`, `fl_chart`, `csv`, `share_plus`, `file_picker`
   - Dev: `flutter pub add --dev flutter_lints integration_test mocktail sqflite_common_ffi flutter_launcher_icons`

   Rationale, so you're not guessing later:
   - `confetti` — Bratz/Y2K "Resisted!" celebration animation (Phase 3).
   - `audioplayers` — Y2K SFX. **Only ever play bundled local asset files, never a network URL** — that's the offline boundary; don't stream anything.
   - `fl_chart` — Phase 4 monthly savings/spend bar chart. Pure rendering, no network.
   - `csv` + `share_plus` — Phase 4 export (write file locally, hand to system share sheet).
   - `file_picker` — Phase 4 import (user picks a JSON backup file from local storage).
   - `sqflite_common_ffi` — lets you unit-test `database_helper.dart` on the host machine (desktop/CI) instead of only on a real device/emulator.
   - `mocktail` — mocking in widget tests.
   - `flutter_launcher_icons` — Phase 5 icon generation from source images (dev-only, no runtime footprint).
   - Haptics need no package — use `HapticFeedback` from `flutter/services.dart` (already in the Flutter SDK).

## 5. Database schema (final — matches §2.1 resolution)

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
This is a greenfield project with no existing installs to migrate, so define the indexes directly in the initial `onCreate`, not as a later migration — but still only tick the Phase 5 "Database indexing" roadmap box once you've confirmed (e.g. via `EXPLAIN QUERY PLAN`) that the relevant queries actually use them.

## 6. Hard constraints — restated from CLAUDE.md, do not violate these

- No `http`/`dio`/Firebase/analytics/telemetry packages, ever. If a package you're about to add makes network calls internally (check its docs), don't add it — ask instead.
- Every user-facing widget must read colors/fonts/spacing from `Theme.of(context)` via the active `ThemeProvider` — no hardcoded visual values. Both themes must render correctly for every screen you build; check this live, in-app, before marking a UI task done.
- Images from `image_picker` are copied into the app's local Application Documents directory immediately and referenced by relative path — never keep a reference to the picker's temp file.
- Use `Image.file()` with `cacheWidth`/`cacheHeight` (matched to actual display size) for every image in a grid/list context, to avoid memory blowups on high-res photos.
- When an item record is deleted from SQLite, delete its backing image file too. No orphaned files.

## 7. Execution plan — follow `ROADMAP.md`'s phase order exactly

Do not start phase *N+1* until phase *N* is: implemented, covered by tests (see §8), passes `flutter analyze` and `dart format --set-exit-if-changed .` cleanly, and manually verified in both themes via the `run` skill. At the end of each phase: update `ROADMAP.md` checkboxes for that phase only, then make one git commit for the phase (small logical commits within a phase are fine too).

- **Phase 1 — Core Architecture**: project scaffolding, schema + CRUD repo in `database_helper.dart`, image pipeline (`file_helper.dart`), `ThemeProvider` + both `ThemeData` objects, font bundling per §2.2. This is the foundation — don't rush verification here.
- **Phase 2 — Core Workflows**: home dashboard (logo, Total Saved/Total Spent cards, staggered grid), quick-add flow (FAB → photo → price/title → Resisted/Bought toggle), card detail view + status change + delete (with image cleanup per §6).
- **Phase 3 — Polish & Micro-interactions**: Y2K confetti/sparkle on "Resisted!", metallic button styling, SFX via `audioplayers` (see asset gap below), Minimal-mode subtle scale/haptic feedback, theme switcher in settings with summary stats.
- **Phase 4 — Data Management & Analytics**: JSON/CSV export via `csv` + `share_plus`, JSON import via `file_picker` with validation (don't silently accept malformed backups — surface a clear error), monthly savings/spend bar chart via `fl_chart`.
- **Phase 5 — Hardening & Launch prep**: image thumbnailing/compression review, DB indexing (already in §5, just verify), app icon generation via `flutter_launcher_icons` (needs source artwork — see asset gap below), local release build configs for iOS/Android.

  **Phase 5 scope boundary**: you can prepare and produce local release builds (`flutter build apk`/`ipa`) and store-listing config files. You cannot and should not attempt actual App Store/Play Store submission — that needs developer account credentials, signing certificates, and a bundle ID decision that are the user's to provide. Stop and hand off there rather than guessing at any of it.

## 8. Testing strategy (not specified in the source docs — pinned here)

- **Unit tests** (`sqflite_common_ffi` for host-side SQLite): full CRUD coverage for `database_helper.dart`, `ItemModel.toMap`/`fromMap` round-trip, `file_helper.dart` copy/delete logic (use a temp dir, not real app documents).
- **Widget tests**: home dashboard counters compute correctly from seeded data; item-entry form rejects non-numeric/negative price input; theme switch re-renders logo text (`skip.` vs `SKIP!`) and typography; card delete triggers both DB delete and file delete (mock the file system with `mocktail`).
- **Integration tests** (`integration_test` package, run on at least one simulator/emulator): full add-item-and-see-it-in-grid flow; export-then-import round-trip preserves data.
- Minimum bar: every new file under `lib/data/` and `lib/core/` gets at least one unit test; every screen under `lib/features/` gets at least one widget test. No specific coverage percentage is mandated beyond that.
- Run `flutter analyze`, `dart format .`, and `flutter test` before every phase-completion commit. Don't defer testing to the end of the project.

## 9. Things you cannot fabricate — stop and ask the user for these

- **SFX audio files** (Phase 3): you cannot generate real audio. Ask the user to supply short sound clips (or explicitly say "use silence/no-op stubs for now"), rather than inventing or sourcing copyrighted sounds yourself.
- **App icon artwork** (Phase 5): `flutter_launcher_icons` needs source images for both the Minimal monochrome and Y2K neon-pink variants. You may draft a simple placeholder, but confirm with the user before treating anything as final, store-ready artwork.
- **Bundle identifiers, signing certificates, store developer accounts**: needed for real Phase 5 release builds and any store submission. Ask; don't invent placeholder values that look real.

## 10. General judgment rule

For small, cosmetic, easily-reversed ambiguities in the roadmap (exact confetti duration, bar vs. line chart for monthly breakdown, spacing values) — make a reasonable minimal choice, note what you chose and why in the commit message, and keep moving. For anything that touches the data schema, the offline guarantee, or store submission — stop and ask, the same way this prompt itself was only written after asking about the schema conflict and the offline/`google_fonts` interaction. Don't assume; when genuinely unsure, ask.

## 11. Reporting

At the end of each phase, report: what was built, which files changed, test results (pass/fail counts), and which `ROADMAP.md` boxes you checked. At the end of all 5 phases, give a final summary of what's shippable vs. what's blocked on user-supplied assets/credentials per §9.
