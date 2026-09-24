# Skip! — iOS QA report, physical iPhone (2026-09-24)

## 1. Summary

**Device:** iPhone 15 Pro ("Elena (2)"), iOS 26.6.2, connected by cable. System language `it_IT`.
**Build:** `master` @ `50e7c8d`. Debug build for the automated runs; release build for 1.5 and for the reinstall at the end.
**How it was driven:** screenshots don't work on iOS 26 and iPhone Mirroring isn't available in the EU, so nothing could tap the phone's screen from the Mac. The app was instead driven from inside by Flutter `integration_test` scripts (`flutter test -d <iPhone> --no-uninstall`). They launch the real app with its real SQLite DB, files and app group, tap and type through the widget tree, check the DB and files on the phone, and save screenshots. The runs were chained so relaunch checks see the earlier data: A (fresh install, split into two parts), B (relaunch), C (empty-DB launch), D (upgrade over a v4 install). The harness was temporary; it was removed afterwards and nothing in the app was changed.

What the harness can't reach: native iOS UI (photo picker, camera, permission prompts, Safari, the icon-change alert, Home Screen and Lock Screen widgets), anything felt or heard (haptics, sound), and system settings (language, Larger Text, Dark Mode, rotation, network). Those checks are BLOCKED, or PARTIAL where the app-side half was checked with a stand-in (e.g. a fake picker that feeds the app's copy pipeline real 4000×3000 files).

| PASS | FAIL | PARTIAL | BLOCKED | Total |
|---|---|---|---|---|
| 74 | 1 | 27 | 13 | 115 |

**Top issues**
1. **Restore duplicates an item that was edited after the last automatic backup** (7.14, major): the backup held "Leather bag", 12.5 × 2. The item was later edited, and tapping "Restore last automatic backup" inserted the old version as a second live row with the same `created_at`. Totals count it twice.
2. **The automatic backup lags well behind the data** (7.13, by design but worth knowing): with the 10-minute throttle, 20 minutes of normal use left the backup with 1 item while 41 were live. Combined with issue 1, a restore can bring back stale versions.

**Regression checks:** 5.6 (comma price in edit details) PASS. 5.9 (quantity kept when editing the link) PASS. 7.16 (empty-DB launch keeps the backup, then Restore recovers everything) PASS. Two findings from yesterday's Simulator report look fixed on the phone (spot-checked in screenshots, not a full pass): the German edit-details error now wraps instead of being cut off, and the French Minimal Insights axis shows "2,0k €" in full (`extra/spotcheck_de_fr_y2k.png`).

## 2. Results

Evidence paths are relative to the session scratchpad `…/scratchpad/dev/evidence/` (`A` = `qa_A`, `A2` = `qa_A2`, `B` = `qa_B`, …), which is temporary.

| ID | Result | Notes / evidence |
|---|---|---|
| 1.1 | PASS | No issues found |
| 1.2 | PASS | 343 tests passed, including `contrast_test.dart` |
| 1.3 | PASS | Exit 0 |
| 1.4 | PASS | No matches |
| 1.5 | PASS | Both builds succeed; both contain `PlugIns/SkipWidgetExtension.appex`. The release build rewrote `ios/Podfile.lock` again (restored afterwards) |
| 1.6 | PASS | Clean uninstall from the iPhone, then install and launch: no errors in the log (run A boot) |
| 2.1 | PASS | Minimal theme, "Skip!" logo, empty state, motto, `0,00 €` ×2 (`A/2.1_first_launch.png`) |
| 2.2 | PARTIAL | iPhone language `it_IT` → app in Italian. The English half isn't run: the phone's system language can't be changed from the Mac |
| 2.3 | PARTIAL | Italian → EUR (`0,00 €`). English → USD isn't run (same reason as 2.2) |
| 2.4 | PASS | After relaunch, the first frame that shows HomeScreen is already Y2K + Italian (`B/2.4_first_frame.png`) |
| 2.5 | PASS | Coin flip, Insights, Settings and the FAB each open the right screen; back returns home |
| 3.1 | PARTIAL | Stand-in picker fed a 4000×3000 PNG: copied into `skip_images`, DB path `skip_images/…` (relative). The native PHPicker and its 2000 px downscale need a person |
| 3.2 | PARTIAL | Simulated denial (`photo_access_denied`): localized snackbar "Photo access is turned off…", spinner clears, no file. The real iOS permission prompt needs a person |
| 3.3 | BLOCKED | The iPhone has a camera, so the sheet offers Camera. Simulated denial shows "Camera access is turned off…". A real photo capture needs a person |
| 3.4 | PARTIAL | Stand-in picker returns nothing: no change, spinner clears, no new file |
| 3.5 | PARTIAL | Stand-in picker: B replaces A; A's file deleted |
| 3.6 | PARTIAL | Stand-in picker: `skip_images` 2 → 1 files after closing without saving |
| 3.7 | PASS | `image_path` NULL; card shows the placeholder |
| 3.8 | PASS | "Enter a price."; nothing saved (no DB write); screen stays open; no pulse (`A/3.8_empty_price.png`) |
| 3.9 | PASS | "Price must be greater than zero." |
| 3.10 | PASS | `12,50` and `12.5` both stored as 12.5. Typed through the test input channel, not the Italian keypad |
| 3.11 | PASS | Typed one keystroke at a time: `1.234` → `1.23`, `ab1c` → `1`, `1..,5` → `1.5` |
| 3.12 | PASS | "Total: 37,50 €" at ×3; can't go below 1 (− disabled) |
| 3.13 | PASS | "≈ 3.0 hrs of work", then "≈ 6.0 hrs of work" when the price changes (wage €12.50) |
| 3.14 | PASS | `notaurl`, `ftp://x.com`, `example.com` all rejected; nothing saved |
| 3.15 | PASS | `https://example.com/p?id=1` stored |
| 3.16 | PASS | `"  Leather bag  "` → `Leather bag`; whitespace-only title → NULL |
| 3.17 | PARTIAL | The check-mark icon unfocuses the price field. The real keypad wasn't on screen (typing went through the test input channel), so seeing it dismiss needs a person |
| 3.18 | PASS | `is_saved=1`, qty 3, screen closes, Total Saved updates. Pulse frames in `A/3.18_pulse_*.png` |
| 3.19 | PARTIAL | Saved `is_saved=1`; confetti shown and the label stays readable (`extra/spotcheck_de_fr_y2k.png`, 4th panel). Haptic and sound fire on the phone but need a person to feel and hear them |
| 3.20 | PASS | `is_saved` NULL; totals unchanged |
| 3.21 | PASS | `is_saved=0`; added to Total Spent |
| 3.22 | PASS | Three taps 30 ms apart → exactly one row |
| 3.23 | PARTIAL | App lifecycle paused → resumed mid-save, simulated in-app: one row, screen closed, no spinner. Pressing Home on the phone needs a person |
| 4.1 | PASS | DB `sum(price*quantity)` per status = both cards (95,50 € / 19,50 €) |
| 4.2 | PASS | Newest first, 2-column masonry |
| 4.3 | PASS | Hours line checked by the final run. The `(×3)` card was off-screen when the final run looked, so it's confirmed by an earlier on-device screenshot: "29,97 € (×3)" + hours line (`extra/4.3_card_qty3.png`) |
| 4.4 | PASS | Bolt / bag / hourglass badges present in Y2K |
| 4.5 | PASS | Pull to refresh with items: no skeleton frame |
| 4.6 | PASS | Both summary cards open Insights |
| 4.7 | PARTIAL | 30 items with 4000×3000 photos, 8 fast flings: no errors or crash. RSS 411 → 680 MB peak in the final run (up to 1020 MB in earlier runs; debug build). Smoothness not judged by eye |
| 4.8 | PASS | File deleted, then relaunch: card shows the placeholder, no crash (`B/4.8_missing_file.png`) |
| 4.9 | PARTIAL | Hero in and out, with and without a photo: no errors. Only frames captured (`A/4.9_hero_*.png`), not judged in motion |
| 5.1 | PASS | Title, total, `(12,50 € × 3)`, hours, date, status toggle, coin-flip button and link row all shown |
| 5.2 | PASS | Pondering → Bought → Resisted: DB updates each time; widget saved/spent: 58.0/19.5 → 58.0/57.0 → 95.5/19.5 |
| 5.3 | PASS | Tapping the selected status: `total_changes()` unchanged, no spinner |
| 5.4 | PASS | Price 15, qty 4, new title persisted; home updates |
| 5.5 | PASS | Title NULL; no title line |
| 5.6 | PASS | `9,99` saved as 9.99 (regression check) |
| 5.7 | PASS | Zero rejected; Cancel leaves the row unchanged |
| 5.8 | PASS | Invalid link rejected; valid one saved; "Visit product page" row with edit icon |
| 5.9 | PASS | On a qty-3 item, editing then removing the link keeps quantity 3 and totals (regression check) |
| 5.10 | BLOCKED | The tap passes `https://shop.example.com/x` to the launcher (stubbed). Opening Safari and returning to the app needs a person |
| 5.11 | PASS | Remove → `purchase_url` NULL; "Add product link" shown again |
| 5.12 | PARTIAL | Stand-in picker: new photo stored; old file deleted |
| 5.13 | PASS | Remove photo → NULL, file deleted, placeholder |
| 5.14 | PARTIAL | Stand-in picker: photo added to an item that had none; relative path stored |
| 5.15 | PARTIAL | Simulated denial: snackbar, spinner clears, no orphan file |
| 5.16 | PASS | Coin-flip button opens coin flip; back returns to the detail |
| 5.17 | PASS | Delete → Cancel: nothing happens |
| 5.18 | PASS | Returns home, card gone, `deleted_at` set, image file still on disk |
| 5.19 | PASS | After Y2K + German + USD, the reopened detail shows German labels, `$` amounts and Y2K (`A2/5.19_detail_de_usd_y2k.png`) |
| 6.1 | PASS | "Trash is empty." |
| 6.2 | PASS | Newest-deleted first, price × qty totals, dates, retention notice, thumbnails |
| 6.3 | PASS | Restore: back on home with status and quantity intact; totals update |
| 6.4 | PASS | Trashed 31 days ago → row hard-deleted and image file removed on relaunch |
| 6.5 | PASS | Trashed 29 days ago → still in Trash, file kept |
| 7.1 | PASS | Y2K ↔ Minimal re-themes the app; logo asset switches; the Minimal preview tile stays beige in Y2K (`A/7.1_*.png`) |
| 7.2 | PARTIAL | 13 screens and dialogs in each theme with no FlutterError or overflow. Visual readability spot-checked only (`A2/sweep_y2k_*`, `A2/sweep_minimal_*`) |
| 7.3 | BLOCKED | The "You have changed the icon" alert and the Home Screen icon are native UI that app screenshots can't capture. Needs a person |
| 7.4 | BLOCKED | Same reason as 7.3 |
| 7.5 | PASS | EN/IT/FR/DE × 13 screens: no overflow errors. Widget labels follow (Saved / Risparmiato / Économisé / Gespart) |
| 7.6 | PASS | Warning dialog; Cancel keeps EUR; Continue switches; `$1,234.56` vs `1.234,56 €` |
| 7.7 | PASS | No items: switches with no dialog |
| 7.8 | PASS | `12,5` (comma) → "12,50 € / hr"; `20.75` (dot) edit saved; Remove shows "Not set" and hides hours on cards and entry |
| 7.9 | BLOCKED | The toggle turns sound off (`SfxProvider.enabled=false`). Whether the phone stays silent (and on silent mode) needs a person to listen |
| 7.10 | PASS | "Items resisted" = count of resisted items; average = Total Saved ÷ count |
| 7.11 | PASS | Privacy policy opens in both themes and all four languages (sweeps) |
| 7.12 | PASS | Fresh install: "Nessun backup automatico trovato." |
| 7.13 | PARTIAL | Backup file exists. It held 1 item while 41 were live: the write is throttled to once per 10 min, so it lags. By run B it held 42 |
| 7.14 | FAIL | Restore with data present **added a row** (42 → 43). See Failures |
| 7.15 | PASS | Two taps 20 ms apart: no extra rows |
| 7.16 | PASS | Empty DB at launch: backup **not** overwritten; Restore brought back all 42 items ("Importati 42 elementi.") (regression check) |
| 7.17 | PASS | Corrupt file: "That file isn't valid JSON."; spinner clears |
| 7.18 | PASS | Restored records render; missing photos show placeholders; no crash |
| 8.1 | PASS | Empty state |
| 8.2 | PASS | This month's cards = price × qty for this month; pondering excluded |
| 8.3 | PASS | 6 month pairs, oldest → newest, September last, empty months at zero |
| 8.4 | PARTIAL | Items back-dated 2 and 5 months ago land in July and April. Items 7 and 9 months old are outside the chart but in all-time totals. No year boundary falls inside a 6-month window ending in September |
| 8.5 | PASS | Compact labels `1,0k €`, `1,5k €`, `2,0k €`; French labels not cut off (`extra/spotcheck_de_fr_y2k.png`) |
| 8.6 | PASS | Insights swept in 4 languages × 2 themes; month labels localized ("Avr. Mai Juin Juil. Août Sept.") |
| 9.1 | PARTIAL | Flip animates and shows a result (`A/9.1_*.png`). Haptics need a person |
| 9.2 | PASS | 6 taps 16 ms apart: no errors |
| 9.3 | PASS | Left mid-flip: no `setState() called after dispose` |
| 9.4 | PASS | 0 rows and no backup file after flipping |
| 10.1 | PASS | Y2K + Italian + EUR + wage + sound off, and 42 items, all persist across relaunch |
| 10.2 | PARTIAL | Background/resume simulated in-app on 4 screens: state kept (entry price kept), no skeleton flash |
| 10.3 | BLOCKED | Physical rotation needs a person. A simulated landscape pass (view size swapped) broke the harness. One earlier simulated pass logged "RenderFlex overflowed by 3.9 pixels on the bottom" on a screen I couldn't identify (low confidence, see Unexpected) |
| 10.4 | BLOCKED | Settings → Larger Text needs a person. The simulated 3.12× text scale broke the harness before finishing |
| 10.5 | BLOCKED | Dark Mode needs a person; the simulated pass broke the harness |
| 10.6 | PARTIAL | Semantics: logo, the three app-bar tooltips, FAB, toggle options and photo box all have labels. Listening with VoiceOver needs a person |
| 10.7 | PASS | v4 install (`05f5c35`) with 4 items, current build installed over it: migrated to v6; statuses, price, link, trash state and photos intact; quantity = 1 |
| 11.1 | BLOCKED | Adding and viewing widgets needs a person |
| 11.2 | PARTIAL | App group `saved`/`spent` = this month's totals (not all-time). Widget rendering not seen |
| 11.3 | PARTIAL | App group values update after each status change (5.2). Widget redraw not seen |
| 11.4 | PARTIAL | `currencyCode`, `aesthetic`, `savedLabel`/`spentLabel`, `mottos`, `languageCode` follow settings. Widget redraw not seen |
| 11.5 | PASS | All keys present; `totalsMonth=2026-09`; values match. Read from the app group via `home_widget`, not `plutil` |
| 11.6 | PARTIAL | `totalsMonth` set to `2026-08`. `SkipWidget.swift` zeroes totals when the month is stale; the widget itself not seen |
| 11.7 | PASS | On the next launch `totalsMonth` resynced to `2026-09` with real values |
| 11.8 | BLOCKED | Widget rendering needs a person (`mottoEmpty` value is present) |
| 11.9 | BLOCKED | Needs a person |
| 11.10 | BLOCKED | Needs an overnight check on the phone |
| 12.1 | BLOCKED | Cellular/Wi-Fi on the phone can't be toggled from the Mac |
| 12.2 | PARTIAL | No HTTP client in `lib` or `pubspec.yaml` (1.4). Traffic on the phone not captured |
| 12.3 | PARTIAL | Images only under `Documents/skip_images`; no photo-library write path in the app. Real-picker `tmp/` leftovers not checked (stand-in picker) |

## 3. Failures

### 7.14 — Restore with data present adds a stale duplicate (major)

**Steps**
1. Fresh install. Log an item, e.g. "Leather bag", €12.50 × 2, Resisted. The first `load()` with data writes the automatic backup containing this item.
2. Within 10 minutes (before the next backup write), open the item and edit anything: title, price, quantity, status or link.
3. Settings → "Restore last automatic backup".

**Expected:** 0 new items ("This backup was already restored."), no duplicates.
**Actual:** 1 item imported. The DB now has row 1 (the edited item) and row 43 ("Leather bag", 12.5 × 2, `created_at` `2026-09-24T09:44:16.209107`, same as row 1). Both are live and both count in the totals.

Evidence: `extra/7.14_skip.db`, `extra/7.14_autobackup.json` (pulled from the phone). No Flutter errors in the log.

**Likely cause:** `BackupService._dedupeSignature` (`lib/data/backup_service.dart:202`) builds the dedupe key from every mutable field: title, price, quantity, image path, status, category, link. Any edit after the backup makes the item look new to `importItems` (`:185`). `created_at` alone (microsecond ISO timestamp, never edited) would identify the item; whether a restore should then overwrite the newer edit or skip it is a product decision.

## 4. Anything unexpected

- **`flutter test` on a physical device uninstalls the app when it finishes** unless you pass `--no-uninstall`. My first smoke run wiped the Skip! data on the phone. I had backed up the app container first; at the end I installed a release build of `50e7c8d` and copied the original `skip.db`, backups, photos and preferences back. That data was 10 test items, all in Trash, with Minimal / Italian / EUR / €10 per hour.
- **Old picker temp files on the phone:** before the run, the app's `tmp/` held five `image_picker_*.jpg/png` copies (17–21 Sep, about 3 MB). These match finding 5 of yesterday's report. They were dropped when the app was reinstalled. Whether `50e7c8d` stops new ones needs one real photo pick followed by a look at `tmp/` (the stand-in picker doesn't use `tmp/`).
- **Memory with full-resolution photos:** 30 items with 4000×3000 PNGs peaked at 680–1020 MB RSS across runs (debug build). There was no crash or memory warning on an 8 GB iPhone 15 Pro, but that's on the heavy side. Real picks are capped at 2000 px, so real-world use should be lighter.
- **Possible small overflow in landscape (low confidence):** one simulated landscape pass (view size swapped in-app, portrait safe-area insets kept) logged "A RenderFlex overflowed by 3.9 pixels on the bottom" on a screen I couldn't identify. Worth a look when 10.3 is done on the real phone.
- **Empty-DB launch doesn't sweep photos:** with an empty database the launch-time orphan sweep left all 31 photos in place (31 before, 31 after), so a Restore still has them. Good, and worth keeping.

### Still needs a person on the iPhone

3.1–3.3 real picker, camera and permission prompt (then check `tmp/` for `image_picker_*` leftovers) · 3.17 keypad dismiss · 3.19 / 7.9 / 9.1 haptics and sound, including silent mode · 3.23 Home button mid-save · 5.10 Safari round trip · 7.3 / 7.4 icon alert and Home Screen icon · 10.3 rotate · 10.4 Larger Text · 10.5 Dark Mode · 10.6 VoiceOver · 11.x widgets · 12.1 Airplane Mode.
