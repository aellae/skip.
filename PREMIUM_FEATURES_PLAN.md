# SKIP — Feature Plan v3 (23 Features)

## Context

SKIP currently ships all 5 roadmap phases plus a purchase-link add-on: home dashboard, quick-add, item detail, JSON/CSV backup (JSON round-trips on import today, CSV is export-only by design — confirmed in `lib/data/backup_service.dart:36-41`), monthly insights, EN/IT localization, dual theme. This plan grows the app with 22 new features/fixes plus the entitlement layer they sit behind, and monetizes a subset:

- **Free:** cooling-off timer + reminder notifications (the app's core impulse-control mechanic — kept out of the paywall on purpose), item notes/reflection, search/filter/sort, bulk select & actions, a soft-delete trash bin ✅ + undo snackbar, CSV import (flagged for sign-off, see Risks), editing an item's price/title after creation ✅, locale-aware currency entry + an independent currency picker ✅, "cost in hours worked" ✅, a sound-effects mute toggle ✅. (✅ = delivered, see Round 4 below and each item's own section.)
- **Premium** (behind one paywall): categories/tags, savings goals, streaks/badges, extra theme packs, a shareable "I saved $X" image card, a category breakdown chart on Insights, a spending activity heatmap, milestone celebrations, an annual "Year in Skip" wrap-up, a home screen widget.
- Monetization uses the `in_app_purchase` plugin (StoreKit/Play Billing) — a deliberate, user-approved exception to CLAUDE.md's "100% offline, no HTTP clients" rule, since it's a platform payment rail, not telemetry/analytics. Local notifications (for reminders) are also on-device only — no network call, no remote push service. No other network access is introduced anywhere in this plan.

**Revision history:**
- **Round 2 (2026-09-15):** superseded the original 7-feature draft. **App Lock (biometric/PIN) was dropped entirely** per explicit request — every reference to `local_auth`, `AppLockProvider`, and the related manifest/`Info.plist` permission entries has been removed. The free tier is anchored by the cooling-off timer + reminders instead.
- **Round 3 (2026-09-15):** added 8 more items (§3o–§3v below): two are real gaps found while re-reading the code (no way to edit a saved item's price/title; the entry form's currency prefix ignores locale even though display formatting already respects it), the rest are new free-tier polish (bulk actions, undo, sound toggle, cost-in-hours) and premium gamification/insight extras (milestones, activity heatmap) that pair with features already in this plan.
- **Round 4 (2026-09-16) — delivery update:** 5 of the free-tier items are built, tested, and merged to `master`: **§3j soft-delete/trash bin**, **§3o edit price/title**, **§3p currency (both parts)**, **§3q cost in hours worked**, **§3t sound-effects mute toggle**. Each is marked "✅ Delivered" below with the actual files/behavior, which in a few small spots differs from what this plan originally proposed (noted inline). Nothing premium/entitlement-gated has been started — §1 (entitlement layer) and everything under §3a–§3n, §3f–§3g, §3k, §3r–§3s, §3u–§3v remain exactly as planned, not built. See §2 for a consequence of building the trash bin in isolation rather than as part of the originally-planned consolidated migration.

Every pass is verified against the codebase — file paths, exact call-site counts, and existing patterns to reuse are confirmed, not assumed.

---

## 1. Premium/entitlement layer (build first — everything else depends on it)

New files:
- `lib/data/entitlement_service.dart` — thin wrapper around `InAppPurchase.instance` (product query, `buyNonConsumable`, purchase-update stream, `restorePurchases`). Same split as `DatabaseHelper`/`ItemsProvider`: this is the raw-mechanics layer.
- `lib/data/entitlement_provider.dart` — `EntitlementProvider extends ChangeNotifier`, exposes `isPremium`, `purchasePremium()`, `restorePurchases()`. Two-phase init mirroring `LocaleProvider` (`lib/core/localization/locale_provider.dart`, confirmed pattern: `SharedPreferences.getInstance()` in an async `loadSaved()`/`setLocale()`):
  - `loadPersistedFlag()` — fast `SharedPreferences` read of `skip_premium_unlocked`, awaited before `runApp` in `lib/main.dart` (same as `localeProvider.loadSaved()` today) so there's no locked-UI flash.
  - `initialize()` — subscribes to the purchase-update stream, calls `restorePurchases()`, run after first frame (not awaited).
- `lib/core/widgets/premium_gate.dart` — the one reusable primitive every premium feature uses: declarative `PremiumGate({required child, required locked})` for wrapping sections, plus an imperative `EntitlementProvider.requirePremiumOrPrompt(context)` for action-triggered gates (e.g. tapping "share").
- `lib/features/paywall/paywall_screen.dart` (+ `widgets/paywall_feature_row.dart`) — lists all 8 gated features (categories, goals, streaks, theme packs, share card, category chart, Year in Skip, home widget), real store-sourced price from `ProductDetails.price` (never hardcoded), "Unlock Premium" CTA, mandatory **Restore Purchases** action (required for App Store review).

Product model: **one non-consumable** "unlock premium" purchase (e.g. `skip_premium_unlock`), not a subscription — there's no server to validate a subscription against in an offline app, and a non-consumable's entitlement ("was it ever bought") is exactly what local persistence + restore-purchases can answer.

Wiring: add `ChangeNotifierProvider(create: (_) => entitlementProviderOverride ?? EntitlementProvider())` to `lib/main.dart`'s `MultiProvider`, following the existing `themeProviderOverride`/`itemsProviderOverride`/`localeProviderOverride` test-injection convention already in that file.

Dev unblocking: a debug-only override forcing `isPremium = true` so the premium features below can be built/tested before real App Store Connect / Play Console products exist (those are manual, out-of-code setup steps — see Risks).

---

## 2. DB migration — one consolidated schema change, land it early

**⚠️ Superseded by what actually shipped (2026-09-16):** this section originally proposed bundling five features' schema needs into one v2→v3 bump. In practice, only the trash bin (§3j) was built in this pass, so **v3 shipped with just `ALTER TABLE items ADD COLUMN deleted_at TEXT`** — none of `notes`, `is_pending`, `decide_by`, or the `goals` table exist yet. Confirmed current state: `dbVersion = 3` (`lib/data/database_helper.dart:15`), `items` schema is `id, title, price, image_path, is_saved NOT NULL, category, created_at NOT NULL, purchase_url, deleted_at`. **Consequence for whoever builds §3b (goals), §3f (cooling-off), or §3h (notes) next: that work needs a new v3→v4 migration, not a slot in v3 — this "land it early, all at once" plan no longer applies as written.** The original v2→v3 proposal is left below for reference on the *shape* of those remaining additive changes, not as something still pending in v3.

Original proposal (partially superseded, see above): bump to **v3**, in one migration, since five different features below each need one small additive piece — better one version bump with several statements than several bumps:

```sql
CREATE TABLE goals (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  target_amount REAL NOT NULL,
  created_at TEXT NOT NULL,
  achieved_at TEXT
);

ALTER TABLE items ADD COLUMN notes TEXT;          -- §3h: item notes/reflection — NOT YET BUILT
ALTER TABLE items ADD COLUMN deleted_at TEXT;     -- §3j: soft-delete trash bin — ✅ DELIVERED in v3
ALTER TABLE items ADD COLUMN is_pending INTEGER NOT NULL DEFAULT 0; -- §3f: cooling-off — NOT YET BUILT
ALTER TABLE items ADD COLUMN decide_by TEXT;      -- §3f: cooling-off deadline — NOT YET BUILT
```

Add all of the above to both `_onCreate` and `_onUpgrade` (`if (oldVersion < 3) { ... }`) in `lib/data/database_helper.dart`, following the exact additive-`ALTER TABLE` precedent already used for `purchase_url` (v1→v2). Note `is_pending`/`decide_by` deliberately don't touch `is_saved`'s existing `NOT NULL` — SQLite can't relax a column constraint without a full table rebuild (rename/create/copy/drop), so a pending item gets a placeholder `is_saved` value that every aggregate query must additionally filter out (see §3f).

Existing queries that need updating for the new columns (all in `lib/data/database_helper.dart`):
- `getAllItems()` — ✅ delivered: defaults to `WHERE deleted_at IS NULL` (the `is_pending = 0` half is future work, once §3f exists); `getTrashedItems()` ✅ delivered, `getPendingItems()` still not built (waits on §3f).
- `_sumPrice()` (backs `getTotalSaved`/`getTotalSpent`) — ✅ delivered: adds `AND deleted_at IS NULL` (the `is_pending` half again waits on §3f).

Streaks/badges/theme packs need **zero** schema change beyond the above: streaks/badges are computed in-memory from `ItemsProvider.items`; theme packs are `SharedPreferences`; the share card is a transient render, not persisted data.

Migration test: ✅ delivered for the v2→v3 slice that shipped — `test/data/database_helper_test.dart` has a `'upgrading a v2 database adds deleted_at and keeps existing rows'` test following the existing v1→v2 pattern. Still needed when §3b/§3f/§3h land: the same pattern extended to assert the `goals` table and `notes`/`is_pending`/`decide_by` columns on the eventual v3→v4 bump.

**Doc fix while touching this area:** ✅ delivered — `CLAUDE.md`'s schema reference table now lists `category` and `deleted_at`. Still missing (add when built): `notes`, `is_pending`, `decide_by`, and the `goals` table.

---

## 3. Feature build-out

### 3a. Categories/tags (premium) — build second, cheapest real feature
- `lib/core/constants/item_categories.dart` — `enum ItemCategory` with icon + localized `label(AppStrings)`.
- `lib/features/item_entry/widgets/category_picker.dart` — chip row inserted in `item_entry_screen.dart` between the title and purchase-url fields, wrapped in `PremiumGate`. Wire into the **already-existing** `addItem(category: ...)` param on `ItemsProvider` (`lib/data/items_provider.dart:54`) — no provider change needed, only the missing UI plumbing.
- Render a category chip on `ItemGridCard` and `ItemDetailScreen` (not currently rendered anywhere — confirmed, `lib/features/home/widgets/item_grid_card.dart` has no category UI today).
- Filtering the home grid by category: now in scope, covered by §3i (not a follow-up anymore).

### 3b. Savings goals (premium)
- `lib/data/models/goal_model.dart` (mirrors `ItemModel`'s `toMap`/`fromMap` shape).
- `DatabaseHelper` CRUD: `insertGoal`/`updateGoal`/`getAllGoals`/`deleteGoal`.
- `lib/data/goal_progress.dart` — pure fn `computeGoalProgress(items, goal)`, summing `price` for resisted, non-pending, non-trashed items with `createdAt >= goal.createdAt` (progress accrues *since the goal was set* — avoids a new goal instantly completing from prior history; confirm this matches intent, see Risks).
- `lib/data/goals_provider.dart` — `GoalsProvider extends ChangeNotifier`, CRUD-only, **not** proxy-coupled to `ItemsProvider` (this app doesn't use `ChangeNotifierProxyProvider` anywhere); progress computed in the widget layer via `context.watch` on both providers, same as `HomeScreen` already does for totals.
- `lib/features/goals/goals_screen.dart`, `widgets/savings_goal_card.dart`, `widgets/add_goal_sheet.dart` (reuse the price field's numeric validator/formatter from `item_entry_screen.dart`).
- Celebration reuses the `ConfettiController` pattern from `lib/features/item_entry/widgets/decision_toggle.dart` (+ optionally `SkipSfxPlayer`); mark-achieved runs from a post-frame callback, mirroring `HomeScreen.initState`'s existing `addPostFrameCallback`.
- New `SliverToBoxAdapter` in `home_screen.dart` between `SummaryCards` and the grid, wrapped in `PremiumGate`.

### 3c. Streaks/badges (premium)
- `lib/data/streaks.dart` — pure fns `computeCurrentStreak`/`computeLongestStreak(items, {now})`, grouping by distinct local calendar day with a resisted item. Excludes pending/trashed items (same filter as §2). Same testable style as `lib/data/monthly_totals.dart`.
- `lib/data/badges.dart` + `lib/data/models/badge_model.dart` — badges derived from **all-time maxima** (longest streak ever, lifetime totals), not live/current state, so a badge never visually "un-earns" itself — this needs no persistence table.
- `lib/features/gamification/streaks_badges_screen.dart`, `widgets/streak_flame_card.dart` (reuse `AnimatedCountUp`), `widgets/badge_grid.dart`.
- Second `PremiumGate`-wrapped slot on Home, paired with the goals card.

### 3d. Theme packs (premium) — highest UI-refactor risk
**Verified blast radius:** `isY2K` is referenced 44 times across 12 files (`app_themes.dart`, `theme_provider.dart`, `skip_card.dart`, `skip_app_bar.dart`, `empty_state.dart`, `insights_screen.dart`, `monthly_bar_chart.dart`, `settings_screen.dart`, `home_screen.dart`, `item_entry_screen.dart`, `item_grid_card.dart`, `decision_toggle.dart`) vs. the identity enum `SkipAesthetic`, referenced in only 2 (`theme_provider.dart`, `settings_screen.dart`).

**Also confirmed: `ThemeProvider` currently has zero `SharedPreferences` usage** — the active aesthetic resets to Minimal on every cold start today. This is a pre-existing gap, worth fixing as part of this work since a paid feature is now at stake.

**Recommended minimal-diff approach** (sound under one explicit constraint):
- Keep `SkipThemeExtension.isY2K` exactly as-is, re-scoped in its doc comment from "is this the Y2K pack" to "render with the bold/loud rule-set (borders/gradients/glow) vs. the soft/quiet rule-set." None of the 44 call sites change.
- **Constraint this requires:** every new pack must pick a *side* of that existing quiet/loud axis (e.g. a new loud-bucket pack sets `isY2K: true` with its own palette; a new quiet-bucket pack sets `isY2K: false`). A pack wanting a genuinely third rendering behavior (flat/no-shadow/no-border) needs real N-way branching across all 44 sites — a much bigger diff. **Confirm this constraint with whoever designs the new packs' art direction before implementation starts.**
- Add a `String themeId` field to `SkipThemeExtension` as the stable identity/selection key (separate from `isY2K`'s rendering-bucket role and `logoText`'s display role).
- Introduce `SkipThemePack` (`id`, `ThemeData`, label, `isPremium`); refactor `app_themes.dart` to expose `AppThemes.all` (a list) instead of only the two named `minimal`/`y2k` getters.
- Refactor `ThemeProvider`: replace the hardcoded switch with a lookup into `AppThemes.all` by `themeId`, and add persistence (save/load `themeId` via `SharedPreferences`, copying `LocaleProvider`'s pattern verbatim).
- Refactor `SettingsScreen._AestheticSwitcher` from its literal 2-cell `Row` into an iteration over `AppThemes.all` (reusing `_AestheticOption` unchanged), with a lock overlay on premium tiles opening the paywall.
- Extend `lib/core/constants/app_colors.dart` with each new pack's palette.
- Ship 2 new packs for v1 (one per bucket) to exercise both `isY2K` branches; exact creative direction is open.

### 3e. Shareable "I saved $X" card (premium)
- No new dependency: `RepaintBoundary` + `dart:ui` (`RenderRepaintBoundary.toImage`) handles capture; `share_plus` (existing dependency, already used by `lib/features/settings/widgets/backup_section.dart`) handles the share sheet.
- `lib/features/share_card/widgets/share_card_widget.dart` — themed card, wrapped by the caller in `RepaintBoundary`+`GlobalKey`.
- Add `Future<File> writeExportBytes(String fileName, Uint8List bytes)` to `lib/core/utils/file_helper.dart`, next to the existing `writeExportFile` (`lib/core/utils/file_helper.dart:91`), using `writeAsBytesSync` — **must** follow the project's established sync-dart:io-underneath pattern (see Testing section below).
- `lib/features/share_card/share_card_service.dart` — capture → PNG bytes → `writeExportBytes` → `Share.shareXFiles`.
- New share action on `ItemDetailScreen`'s app bar (next to delete), gated by `PremiumGate`.

### 3f. Cooling-off timer (free) — biggest free-tier lift
The core mechanic this app is missing: today the decision (Resisted!/Bought It) is forced immediately at entry, via `DecisionToggle` inside `_saveWithDecision` in `item_entry_screen.dart:118-143`. This adds a third path: "I'll decide later."

- `item_entry_screen.dart` gets a new `_saveAsPending()` sibling to `_saveWithDecision()`, and a new "Decide later" text button under the existing `DecisionToggle`. It inserts an item with `is_pending = 1`, `decide_by = now + cooldownDuration`, and a placeholder `is_saved` (the value is never read for a pending item — every aggregate query in §2 excludes it).
- `lib/core/config/cooldown_config.dart` — a single `Duration cooldownDuration` constant (default 48h, pending product sign-off — see Risks).
- `ItemsProvider` gets `pendingItems` (loaded via the new `getPendingItems()`) and `resolvePendingItem(int id, bool isSaved)`, which sets `is_saved`, clears `is_pending`, and cancels the item's scheduled reminder (§3g).
- New "Still deciding" section on `home_screen.dart` (a `SliverToBoxAdapter` above the main grid, mirroring the goals/streaks card slots from §3b/3c but **not** `PremiumGate`-wrapped), showing each pending item with a countdown to `decide_by` and tapping through to a decision screen that reuses `DecisionToggle` exactly as `ItemDetailScreen` already does.
- **Not premium-gated** — this is core app-purpose functionality, not a delight feature; keeping it free is a judgment call worth explicit sign-off (see Risks).

### 3g. Reminder notifications (free) — pairs with 3f
- New dependency: `flutter_local_notifications` — on-device only, no remote push service, no server, consistent with CLAUDE.md's offline rule.
- `lib/core/notifications/reminder_scheduler.dart` — thin wrapper (`scheduleReminder(itemId, fireAt)`, `cancelReminder(itemId)`) around the plugin, behind an injectable interface — same DI seam this app already uses for `image_picker`/`launchUrlOverride`/`pickJsonFile`, so widget tests never touch a real platform channel.
- Scheduled from `_saveAsPending()` (§3f) for `decide_by`; canceled from `resolvePendingItem()`.
- **iOS:** local notifications request permission at runtime via the plugin's own API — no new `Info.plist` usage-description string is needed (unlike camera/photo library, which do require one).
- **Android:** confirmed the manifest currently declares **zero** `uses-permission` entries (`android/app/src/main/AndroidManifest.xml`) — this is new ground for the project. Needs `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>` (required at runtime on API 33+) plus the plugin's standard receiver/service manifest entries.
- Tapping the notification deep-links into the pending item's decision screen (`decide_by` reached → prompt to decide now).

### 3h. Item notes/reflection field (free)
- Add `notes` to `ItemModel` (`toMap`/`fromMap`/`copyWith`/equality/`hashCode`) — small, mechanical, same shape as every other field in `lib/data/models/item_model.dart`.
- Optional multiline `TextFormField` in `item_entry_screen.dart`, same `_ThemedFocusField` wrapper pattern already used for title/purchase-url (`item_entry_screen.dart:247-271`).
- Display + inline edit on `ItemDetailScreen`, following the existing `_editPurchaseLink`/`_PurchaseLinkDialog` pattern (`item_detail_screen.dart:105-122, 275-339`) rather than inventing a new interaction shape.
- Searchable by §3i.

### 3i. Search, filter & sort (free)
No schema change — the item set is small enough (personal spend log) to filter/sort the already-loaded in-memory list, same as `computeMonthlyTotals` already does.
- `lib/data/item_query.dart` — pure fn(s) operating on `List<ItemModel>`: text search (title + notes), filter by status (saved/spent)/category/date range/price range, sort by date/price.
- `lib/features/home/widgets/item_search_bar.dart` + a filter sheet, added to `home_screen.dart`'s app bar.
- Category filtering only does anything once a user has categorized items (i.e. has premium) — no gating needed, it degrades gracefully to "no effect" otherwise.

### 3j. Soft-delete / trash bin (free) — ✅ Delivered 2026-09-16
Built as planned, no deviations. `ItemDetailScreen._confirmDelete` → `ItemsProvider.deleteItem(id)` now soft-deletes instead of hard-deleting.
- `DatabaseHelper.deleteItem(id)` sets `deleted_at = now` instead of removing the row; image file is untouched at delete time.
- `DatabaseHelper.restoreItem(id)` clears `deleted_at`; `DatabaseHelper.purgeExpiredTrash({retention = 30 days, now})` hard-deletes rows past retention and calls `fileHelper.deleteImage` — retention defaults to 30 days as this plan assumed, resolving the Risks item below.
- `purgeExpiredTrash` runs from `HomeScreen.initState`'s post-frame callback, right after `ItemsProvider.load()` — a silent app-start sweep, resolving the "purge trigger point" Risks item below (no explicit "Empty Trash" action was added).
- `lib/features/trash/trash_screen.dart` — reachable from a new "Trash" row in Settings' Data section; lists soft-deleted items with a Restore action (no "delete forever" action — kept to what this plan specified).
- `ItemsProvider` gained `trashedItems`, `restoreItem(id)`, `purgeExpiredTrash({retention})`.
- Delete confirmation dialog copy updated in all 4 locales to explain the item moves to Trash and is recoverable for 30 days.
- **CLAUDE.md consequence:** ✅ delivered — the "Deleting Items" rule now describes the deferred-cleanup behavior.
- Tests: `test/data/database_helper_test.dart` (soft-delete/restore/purge/trashed-items CRUD + a v2→v3 migration test), `test/data/items_provider_test.dart`, `test/features/trash/trash_screen_test.dart`, plus the existing `item_detail_screen_test.dart` delete test updated for the new soft-delete semantics.

### 3k. CSV import (free) — reconsider before building, see Risks
`buildCsvBackup`/`parseJsonBackup` already exist; **JSON import is fully shipped today** — `ItemsProvider.importJsonBackup` (`lib/data/items_provider.dart:113-118`) is already wired into `BackupSection`'s UI (`lib/features/settings/widgets/backup_section.dart`) via `file_picker`. `backup_service.dart` explicitly documents CSV as export-only by design: *"JSON is the round-trippable format used for import; CSV is export-only, meant for opening in a spreadsheet"* (`lib/data/backup_service.dart:36-41`). Building CSV import means reversing that documented decision, not filling a gap — see Risks before scoping this.
- If confirmed: `BackupService.parseCsvBackup(content)`, mirroring `parseJsonBackup`'s validation shape (`BackupFormatException` per malformed row — bad price format, wrong locale decimal separator, missing columns), plus a new `_BackupSectionState._import` branch that lets the user pick either format.

### 3l. Category breakdown chart on Insights (premium) — depends on §3a
- `lib/data/category_totals.dart` — pure fn `computeCategoryTotals(items)`, same style as `lib/data/monthly_totals.dart`.
- New pie/donut section in `insights_screen.dart`, using `fl_chart` (already a dependency, confirmed in `pubspec.yaml` — `MonthlyBarChart` already uses it for the bar chart, this is a new chart type from the same package, no new dependency).
- `PremiumGate`-wrapped; naturally has nothing to show pre-premium since categories are premium-only (§3a).

### 3m. "Year in Skip" annual wrap-up (premium) — build after §3a/3b/3c/3e exist
A Spotify-Wrapped-style annual summary: total resisted, top category, longest streak, biggest single "skip." Depends on categories, goals, and streaks data all existing, and reuses the share-card capture pipeline — build this last among the content features.
- `lib/data/year_in_skip.dart` — pure fn aggregating the year's `ItemModel`s + streak/badge data already computed elsewhere.
- `lib/features/wrapup/year_in_skip_screen.dart`, reusing `ShareCardService` (§3e) for the shareable image rather than building a second capture pipeline.
- `PremiumGate`-wrapped.

### 3n. Home screen widget (premium) — highest native-code risk
A widget on the device home screen showing running total saved or current streak, driving re-engagement without opening the app.
- New dependency: `home_widget` (Dart/Flutter side is a normal package add — the risk is entirely on the native side).
- **iOS:** requires a real WidgetKit Widget Extension target in `ios/Runner.xcodeproj` (a new Xcode target, a Swift `Widget`/`TimelineProvider`, and an App Group entitlement to share data between the app and the extension) — this is Xcode-GUI setup, not something achieved by editing Dart files, similar in kind to the manual App Store Connect / Play Console setup already called out for IAP.
- **Android:** requires a native `AppWidgetProvider` (Kotlin) + XML layout + a `<receiver>` entry in `AndroidManifest.xml` — the manifest's first `<receiver>` entry, on top of the notification permission added in §3g.
- Recommend treating this as a stretch feature, built last, with explicit scope sign-off before starting given the native surface (see Risks).

### 3o. Edit price/title after creation (free) — closes a real gap — ✅ Delivered
Built and shipped in an earlier pass this session, confirmed working. Two small deviations from the original proposal:
- The method is `ItemsProvider.updateDetails(int id, {required String? title, required double price})`, not `updateItemDetails` — same fresh-`ItemModel`-not-`copyWith` reasoning as planned.
- `_validatePrice` was **not** extracted into a shared `price_validator.dart` — `ItemDetailScreen`'s `_EditDetailsDialogState._validatePrice` duplicates `item_entry_screen.dart`'s validator instead (same three rules: required, valid number, `> 0`). Small, harmless duplication; extracting it is still a reasonable follow-up if a third call site ever needs it.
- Edit affordance on `ItemDetailScreen` matches the proposed `_PurchaseLinkDialog`-style shape: an edit icon next to the price opens `_EditDetailsDialog`, its own `StatefulWidget` for the same controller-disposal-timing reason.
- Tests: `test/data/items_provider_test.dart` (`updateDetails`, including the `title: null` clear case and the unknown-id no-op) and `test/features/home/item_detail_screen_test.dart` (edit dialog widget tests, including price validation).

### 3p. Currency: locale-aware entry field, then an independent picker (free) — ✅ Delivered (both parts)
Built and shipped in an earlier pass this session, confirmed working — including part 2, which this plan flagged as optional/confirm-first. Matches the proposal closely:
- `formatCurrency`/`formatCurrencyCompact` (`lib/core/utils/currency_formatter.dart`) now take an `AppCurrency currency` parameter (`lib/core/localization/app_currency.dart`, `usd`/`eur`) instead of `AppLocale` — the entry form's price field and every display call site derive prefix/suffix from it via `isEuroCurrency`.
- `lib/core/localization/currency_provider.dart` — `CurrencyProvider`, persisted via `SharedPreferences` (`LocaleProvider`'s pattern verbatim), wired into `main.dart` (defaults to EUR on first launch if the device locale isn't English, USD otherwise, then persists whatever the user picks).
- `_CurrencySwitcher` added to `settings_screen.dart` alongside `_LanguageSwitcher`, confirmed independent (switching language doesn't change currency and vice versa).
- Tests: `test/core/localization/currency_provider_test.dart`, plus currency-prefix/independence assertions across `item_entry_screen_test.dart`, `item_detail_screen_test.dart`, `settings_screen_test.dart`.

### 3q. "Cost in hours worked" (free) — ✅ Delivered
Built on top of §3p as planned. One structural deviation: no separate model file.
- `lib/core/settings/wage_provider.dart` — `WageProvider extends ChangeNotifier`, `double? hourlyWage`, `SharedPreferences`-backed two-phase load (`LocaleProvider`-style), nullable — invisible until a wage is set, as planned. (The plan proposed a separate `lib/data/models/wage_settings.dart` model; a single nullable field on the provider was simpler and sufficient, so no model class was added.)
- `lib/core/utils/wage_formatter.dart` — `hoursOfWork(price, hourlyWage)` (pure fn, `null` if no sane wage) and `formatHoursOfWork(hours, locale)` (1 decimal, locale-aware decimal separator).
- Rendered under the price on `ItemGridCard`, `ItemDetailScreen`, and as a live `ValueListenableBuilder` preview under the entry form's price field — all three as planned, gated on a wage being set.
- Settings gained a "Cost in Hours" section: current wage (or "Not set") opens an add/edit/remove dialog, same shape as the purchase-link dialog.
- Tests: `test/core/utils/wage_formatter_test.dart`, `test/core/settings/wage_provider_test.dart`, plus live-preview/display assertions in `item_entry_screen_test.dart`, `item_detail_screen_test.dart`, `home_screen_test.dart`, `settings_screen_test.dart`.

### 3r. Milestone celebrations (premium) — pairs with §3c
Crossing a lifetime-saved threshold ($100/$500/$1,000/…) triggers a bigger version of the confetti/SFX `DecisionToggle` already has on every "Resisted!" (`lib/features/item_entry/widgets/decision_toggle.dart`) — same `ConfettiController`/`SkipSfxPlayer` infra, reused rather than rebuilt.
- `lib/data/milestones.dart` — pure fn `milestoneCrossed(previousTotal, newTotal)` against a fixed threshold list.
- A `SharedPreferences` "highest milestone already celebrated" value, checked on every `ItemsProvider.load()`/`addItem()`/`resolvePendingItem()`. **Must be backfilled from the user's current `totalSaved` on first run after this ships**, not initialized to zero — otherwise every existing user gets every threshold's celebration firing at once on update (see Risks).
- New full-screen or bottom-sheet celebration overlay, `PremiumGate`-wrapped (milestones only fire for premium users, same bucket as streaks/badges).

### 3s. Spending activity heatmap (premium) — depends on §3c
A GitHub-contributions-style grid of days with resisted/bought activity, on `insights_screen.dart` alongside the category chart (§3l) and Year in Skip (§3m).
- `lib/data/daily_activity.dart` — pure fn `computeDailyActivity(items)`, reusing the same by-calendar-day grouping `streaks.dart` (§3c) already implements rather than writing it twice.
- `lib/features/insights/widgets/activity_heatmap.dart` — hand-rolled grid (no new chart dependency needed; `fl_chart` has no built-in calendar-heatmap mark type).
- `PremiumGate`-wrapped.

### 3t. Sound-effects mute toggle (free) — ✅ Delivered
Built as planned, one small deviation: a full `ChangeNotifier` provider instead of a bare `SharedPreferences` bool, for consistency with `LocaleProvider`/`CurrencyProvider`/`WageProvider`'s established pattern.
- `SkipSfxPlayer` (`lib/core/audio/sfx_player.dart`) takes an injectable `bool Function()? isEnabled`, checked at the top of `playResisted()` (re-checked on every call, not just once, so a mute toggled mid-session takes effect immediately).
- `lib/core/settings/sfx_provider.dart` — `SfxProvider`, `SharedPreferences`-backed (`skip_sfx_enabled`, default true), same two-phase load as the other settings providers.
- `DecisionToggle`'s real (non-test) `SkipSfxPlayer` construction wires `isEnabled: () => context.read<SfxProvider>().enabled`.
- One new `Switch` in `settings_screen.dart`'s new "Sound" section.
- Tests: `test/core/settings/sfx_provider_test.dart`; `test/core/audio/sfx_player_test.dart` extended with a mocked `AudioPlayer` asserting `play()` is never called when `isEnabled` returns false (and is called when it returns true).

### 3u. Undo snackbar (free) — build after §3j
A lighter safety net than the trash bin for the common case: a few seconds of "Undo" after deleting an item or changing its status, via `ScaffoldMessenger`. Deletion's undo is trivial once §3j lands (soft-delete already just sets `deleted_at` — undo is `restoreItem` within the snackbar's window, no image-file race to worry about); status-change undo is just re-calling `setSavedStatus` with the previous value.
- Wrap `ItemDetailScreen._confirmDelete` and `_changeStatus` (`item_detail_screen.dart:49-58, 60-91`) with a `SnackBar(action: SnackBarAction(...))`.

### 3v. Bulk select & actions (free) — pairs with §3i
Multi-select on the home grid for batch delete or (if premium) batch re-categorize.
- Long-press an `ItemGridCard` to enter selection mode; `HomeScreen` tracks `Set<int> _selectedIds` and swaps its `SkipAppBar` for contextual actions.
- Bulk delete routes through the same soft-delete as §3j (never a bulk hard-delete) — confirm this default before building (see Risks).
- Bulk re-categorize opens `category_picker.dart` (§3a) once for the whole selection; gracefully does nothing useful pre-premium, same degrade-gracefully treatment as category filtering in §3i.

---

## 4. Build order

Steps 7–11 are ✅ **delivered** (2026-09-16), out of planned order (built before categories/search/notes/goals, not after) — the free-tier polish and gap-fixes turned out to be the priority, not the premium-first sequencing this plan assumed. Steps 1–6 and 12+ are all still exactly as planned, not started.

1. Entitlement skeleton (`EntitlementService`, `EntitlementProvider` + dev override, `PremiumGate`, `main.dart` wiring) — nothing premium can be built without this existing, even as a stub.
2. DB migration v3, consolidated (goals table + `notes`/`deleted_at`/`is_pending`/`decide_by` columns) — **partially done**: v3 shipped with only `deleted_at` (step 11). The rest of this step is now a future v3→v4 migration — see §2.
3. Categories UI (§3a) — cheapest feature, exercises `PremiumGate` end-to-end before it's load-bearing elsewhere.
4. Search, filter & sort (§3i) — free, independent, safe early win.
5. Bulk select & actions (§3v) — reuses the selection-adjacent UI area §3i just built.
6. Item notes (§3h) — small, touches the same entry/detail screens as categories; batch together.
7. ✅ Edit price/title (§3o).
8. ✅ Currency: locale-aware entry fix + independent picker (§3p) — both parts.
9. ✅ Cost in hours worked (§3q).
10. ✅ Sound-effects mute toggle (§3t).
11. ✅ Soft-delete / trash bin (§3j).
12. Undo snackbar (§3u) — depends on 11 for delete-undo. 11 is now done; this is unblocked whenever it's picked up.
13. Cooling-off timer (§3f) — consumes `is_pending`/`decide_by`; the largest free-tier feature.
14. Reminder notifications (§3g) — depends on 13 (needs pending items to remind about).
15. CSV import (§3k) — smallest, or dropped entirely pending the sign-off in Risks.
16. Savings goals (§3b) — consumes the `goals` table from step 2.
17. Streaks/badges (§3c) — no migration, pairs naturally with goals in the same Home-screen slot design.
18. Milestone celebrations (§3r) — pairs with 17's totals/thresholds, same gamification bucket.
19. Category breakdown chart (§3l) — depends on step 3.
20. Spending activity heatmap (§3s) — reuses 17's day-grouping logic.
21. Share card (§3e) — depends only on `PremiumGate` + a small `FileHelper` addition.
22. "Year in Skip" wrap-up (§3m) — depends on 3, 16, 17, 21 all existing first.
23. Theme packs (§3d) — needs the `AppThemes`/`ThemeProvider`/`_AestheticSwitcher` refactor, and benefits from every other premium surface already existing so new packs get validated against the full app in one pass.
24. Home screen widget (§3n) — last, highest native-code risk; can run in parallel with 25.
25. Real `in_app_purchase` wiring + `PaywallScreen` polish + store product setup — swap the dev override once App Store Connect / Play Console products exist; can run in parallel with 3–24.

---

## 5. Risks / open questions

- **IAP:** product IDs need manual setup in App Store Connect and Play Console; the full purchase/restore flow can't be meaningfully exercised in CI or iOS Simulator — use Xcode's local StoreKit Testing configuration file for dev-time iteration. A locally-trusted premium flag with no server validation is an accepted trust boundary for an offline app, not an oversight.
- **Categories:** curated enum, not free-text, for v1; filtering is now covered by §3i, not deferred.
- **Goals:** "progress since goal creation" (not all-time total) needs sign-off — it's the only sane default for supporting sequential goals, but confirm before building.
- **Streaks/badges:** confirm all-time-maxima ("sticky") badges are the desired UX — a "losable" badge needs a persistence table and is more scope.
- **Theme packs:** the biggest UI-refactor risk in the plan — the minimal-diff approach only holds if new packs stay within the existing quiet/loud binary. Get explicit sign-off on that constraint before any pack art direction is locked in.
- **Share card:** capturing a `RepaintBoundary` inside `testWidgets` is expected to be fine (it's a rendering-pipeline future, not `dart:io`) but unverified — spike this first; the project's `integration_test/` dir is the fallback venue if it hangs.
- **Cooling-off timer:** the single biggest open product decision in this pass — confirm the cooldown duration (48h assumed above), whether an early "decide now" bypass is allowed at all (if it always is, the mechanic loses teeth; if it never is, that's a harder product commitment), and whether it should be user-configurable in Settings, before implementation starts.
- **Reminder notifications:** first use of `flutter_local_notifications` in this app; Android's `POST_NOTIFICATIONS` runtime permission (API 33+) is new manifest/runtime-request territory here — confirm the prompt timing (at first pending item vs. proactively in onboarding) with whoever owns the notification-permission UX, since a denied prompt can't be re-asked.
- **Soft-delete / trash:** ✅ resolved — shipped with a 30-day retention window and a silent app-start purge sweep (no explicit "Empty Trash" action), and CLAUDE.md's delete-cleanup rule now describes the deferred behavior.
- **CSV import:** `backup_service.dart` currently documents CSV as deliberately export-only, and JSON import already fully covers the "restore my data" path end-to-end today. Building CSV import means re-implementing the same malformed-input hardening `parseJsonBackup` already has (bad price format, locale decimal separators, missing columns) for a format that's strictly worse for round-tripping. Recommend confirming this is actually wanted, not just technically buildable, before scoping it.
- **Home screen widget:** the biggest native-code lift in the whole plan — a real iOS Widget Extension target (App Group entitlement) and an Android `AppWidgetProvider`, both largely manual Xcode/Android Studio setup rather than something achieved purely by editing Dart. Treat as optional/stretch and confirm scope before starting.
- **Currency picker (§3p part 2):** ✅ resolved — built. `AppCurrency`/`CurrencyProvider` shipped independent of `AppLocale`, confirmed live (Italian UI + USD pricing works).
- **Milestone celebrations:** the threshold list ($100/$500/$1,000/… or something scaled to the user's own totals) needs product sign-off. Critically, the "highest milestone celebrated" tracker **must be backfilled from the user's existing `totalSaved` on first run after this ships**, not initialized to zero — otherwise an existing user with $2,000 already saved gets every threshold's celebration fired at once the moment they update.
- **Bulk delete:** confirm it always routes through the soft-delete/trash from §3j rather than ever being an instant, unrecoverable bulk hard-delete — the whole point of adding a trash bin is undermined if the one place someone's most likely to delete several items at once bypasses it.
- **Undo snackbar:** decide the undo window's duration and whether rapid repeated actions (e.g. deleting 3 items in a row) queue separate undo snackbars or collapse into one — small but real UX decision, not just an implementation detail.

---

## 6. Testing

- Pure-function logic (`goal_progress.dart`, `streaks.dart`, `badges.dart`, `category_totals.dart`, `year_in_skip.dart`, `item_query.dart`) needs no DB/widget harness — cheapest, highest-value tests, same style as existing `test/data/monthly_totals_test.dart`.
- Widget tests: `setUpWidgetTestEnvironment()` (`test/test_helpers/widget_test_env.dart`) in `setUpAll` + `buildTestItemsProvider()`, per existing convention.
- Entitlement: mock `InAppPurchase`'s stream via `mocktail`, mock `SharedPreferences` via `setMockInitialValues`; widget-test `PremiumGate`'s locked/unlocked branches.
- Goals: migration test per §2; `GoalsProvider` CRUD against in-memory db; pure-fn tests for `computeGoalProgress`.
- Theme packs: unit test that `AppThemes.all` entries have complete, non-null extension fields; widget test that `_AestheticSwitcher` renders N tiles with correct lock states; extend CLAUDE.md's "test both themes live" rule to "test all themes live" for any UI touched.
- Share card: unit test `writeExportBytes`; capture-to-bytes test per the spike above; the OS share sheet itself is manual-QA-only, same non-automatable category as IAP restore.
- Cooling-off timer: `ItemsProvider`/pending-item logic tested with an injected `now` (same seam `computeMonthlyTotals` already uses), not real `DateTime.now()`; widget test for the "Still deciding" section and the decide-now flow.
- Reminders: `ReminderScheduler` behind an injectable interface (same reasoning as this app's existing `imagePicker`/`launchUrlOverride`/`pickJsonFile` injection points) so tests never touch a real platform channel; assert schedule-on-create and cancel-on-resolve.
- Trash: ✅ delivered — CRUD + `purgeExpiredTrash` tested with an injected `now`, asserting rows younger than retention survive and older ones both delete the row and call `fileHelper.deleteImage`.
- CSV import (if built): mirror `parseJsonBackup`'s malformed-input test matrix in `test/data/backup_service_test.dart`.
- Home widget: native surface, not exercisable via `flutter test`; manual-QA-only, same category as IAP restore and the OS share sheet.
- Item editing: ✅ delivered — widget test for the edit dialog, mirroring the existing `_PurchaseLinkDialog` test.
- Currency: ✅ delivered — unit tests for the locale-aware prefix/suffix fix and per-`AppCurrency` formatting in the currency-formatter test file.
- Cost in hours worked: ✅ delivered — pure-fn tests (`wage_formatter_test.dart`). Milestones / activity heatmap: still not built (premium, not in this pass).
- Sound toggle: ✅ delivered — `SkipSfxPlayer` tested with an injected `isEnabled: () => false`/`true` against a mocked `AudioPlayer`, asserting `play()` is/isn't called.
- Undo / bulk actions: widget tests that the undo action restores prior state, and that selection-mode toggling and bulk delete route through the soft-delete path.
- **Standing project rule, applies to every feature above:** any real `dart:io` file I/O awaited from a widget event handler or directly inside a `testWidgets` body hangs forever under Flutter's fake-clock test environment (no error until the test's own timeout). Existing fix pattern in `FileHelper`: use the synchronous `dart:io` call (`writeAsBytesSync`, etc.) internally, wrapped in a `Future`-returning method. Every new file-I/O call in this plan (`writeExportBytes`) must follow this.

### Critical files
- `lib/data/entitlement_provider.dart` (new) — foundational gate — **not yet built**
- `lib/core/theme/app_themes.dart` + `lib/core/theme/theme_provider.dart` — highest UI-refactor risk — **not yet built**
- `lib/data/database_helper.dart` — **v3 shipped with only `deleted_at`** (trash); the `goals` table + `notes`/`is_pending`/`decide_by` are a future v3→v4 migration, see §2
- `lib/data/items_provider.dart` — **trash state (`trashedItems`, `restoreItem`, `purgeExpiredTrash`) and detail-editing (`updateDetails`) ship today**; pending/notes state still doesn't exist, waits on §3f/§3h
- `lib/features/home/home_screen.dart` — **not yet built**: gains the pending-decisions section, search bar, and two premium card slots. (Did gain a `purgeExpiredTrash()` call in its existing post-frame callback.)
- `lib/features/item_entry/item_entry_screen.dart` — **not yet built**: category picker, notes field, decide-later path. (Did gain the locale-aware price prefix/suffix and the hours-of-work live preview.)
- `lib/core/utils/currency_formatter.dart` — ✅ delivered: locale-aware entry fix, and the `AppCurrency`/`CurrencyProvider` refactor (§3p part 2)
- `lib/main.dart` — wiring point for `EntitlementProvider` — **not yet built**. (Did gain `CurrencyProvider`, `SfxProvider`, `WageProvider` wiring.)
- New this pass, not in the original file list: `lib/core/settings/sfx_provider.dart`, `lib/core/settings/wage_provider.dart`, `lib/core/utils/wage_formatter.dart`, `lib/features/trash/trash_screen.dart`, `lib/core/localization/app_currency.dart`, `lib/core/localization/currency_provider.dart`.
