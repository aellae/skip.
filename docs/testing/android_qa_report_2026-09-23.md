# Skip! — Android QA report (2026-09-23)

## 1. Summary

**Device:** Pixel 6 (`oriole`), Android 17 / API 37, Gboard, system locale `it-IT`, wireless adb. The emulator was already running (`emulator-5554`) and was not used or touched.
**Builds:** current `master` @ `ff2c4f8`, debug APK (main pass) and release APK (smoke checks). The v4 → v6 upgrade test used commit `6763a7b`.
**Disk (host):** 22 GB free at start, 20 GB at end.

| PASS | FAIL | PARTIAL | BLOCKED | NOT RUN | N/A | Total |
|---|---|---|---|---|---|---|
| 92 | 12 | 4 | 7 | 9 | 2 | 126 |

**Top issues**
1. **"Average saved per item" is always formatted in USD** (`$37.50` while EUR is selected), and in DE / at large font sizes the tile overflows (RenderFlex stripes).
2. **Android Auto Backup is on** (no `allowBackup` / `dataExtractionRules`): the DB, prefs and photos can be uploaded to Google Drive, which contradicts the in-app privacy text ("never uploaded anywhere").
3. **Process death during camera loses the entry**: the form and new photo are gone, and a previously copied photo stays orphaned in `skip_images` (there's no `retrieveLostData`).
4. **The Y2K "Resisted!" celebration is invisible in the add-item flow**: the screen pops right away, so no confetti or shimmer shows.
5. **Unlocalized strings**: detail/trash dates, Insights month labels, Material "Back"/"Close" tooltips, the widget month name (follows the device locale, not the app language) and the widget picker description.
6. **Accessibility**: the FAB, quantity −/+, the photo-change button, the coin-flip button and the photo preview have no labels. At max font/display size, text breaks mid-word and overflows.
7. **Landscape**: the add-link dialog overflows by 47 px with the keyboard up, and body content ignores the left camera-cutout inset.

## 2. Results

Evidence paths are relative to the session scratchpad `…/scratchpad/qa/` (temporary; see the note at the end).

| ID | Result | Notes / evidence |
|---|---|---|
| 1.1 | PASS | No issues |
| 1.2 | PASS | 235 tests passed (incl. `contrast_test.dart`) |
| 1.3 | FAIL | Exit 1: `lib/core/localization/locale_provider.dart` (line 16 wrap) and `lib/core/theme/app_themes.dart` (4 `RoundedRectangleBorder` collapses) need formatting. Cosmetic |
| 1.4 | PASS | No matches |
| 1.5 | PASS | No INTERNET in main manifest; release merged manifest has no INTERNET either |
| 1.6 | PASS | debug APK, release APK (56.6 MB), release AAB all built. Release smoke: 3.18, 5.10, 7.3, 11.1 all PASS. Debug and release are signed with different certs (uninstall needed between them) |
| 1.7 | PASS | Clean install + launch, no errors |
| 2.1 | PASS | Minimal, "Skip!", empty state, motto, 0,00 € ×2 (`shots/2.1_first_launch.png`) |
| 2.2 | PARTIAL | Italian default verified (device is it-IT). English default not tested (would need changing the phone's system language) |
| 2.3 | PARTIAL | IT → `0,00 €` verified; EN → USD not tested (same reason) |
| 2.4 | PASS | First Flutter frame already Y2K + Italian (`m_24.png`). Cosmetic: the native launch window is plain white for ~1.5 s even in Y2K |
| 2.5 | PASS | Coin flip / insights / settings / FAB open the right screens |
| 2.6 | PARTIAL | Back key closes sheet first, then dialog, then screen; back on home exits cleanly. Gesture/predictive back not exercised (adb key events only) |
| 2.7 | FAIL | Portrait fine. Landscape: app bar respects the 128 px left cutout inset, body cards start at x=42 and pass beside the camera hole (`shots/2.7_land_left.png`). Minor |
| 3.1 | PASS | Photo Picker (select + "Fine"), file in `skip_images`, relative path; 4500 px source stored at ≤2000 px (93 KB) |
| 3.2 | N/A | App declares no CAMERA permission (camera intent), so there is no prompt to deny |
| 3.3 | PASS | Pixel Camera photo saved and previewed |
| 3.4 | PASS | Cancel picker/camera: no change, no file in `skip_images` (see "Unexpected" for cache leftovers) |
| 3.5 | PASS | Preview B, A's file deleted |
| 3.6 | PASS | Close icon and back both delete the unsaved photo |
| 3.7 | FAIL | "Don't keep activities" (activity recreation): photo arrives and form survives. **Real process death** (`am kill` while camera open): app restarts on home, price and photo lost, previous photo orphaned. Major |
| 3.8 | PASS | `image_path` NULL, placeholder |
| 3.9 | PASS | "Inserisci un prezzo.", nothing saved |
| 3.10 | PASS | "Il prezzo deve essere maggiore di zero." |
| 3.11 | PASS | `12.5`, `12,50`, and real Gboard key taps `12,5` accepted. Gboard IT pad shows both `,` and `.`. Samsung Keyboard not available |
| 3.12 | PASS | `12.555`→`12.55`, `abc`→empty, `1..2`→`1.2`, `1,,2`→`1,2`, `12a3`→`123` |
| 3.13 | PASS | "Totale: 37,50 €" for 12,5 × 3 |
| 3.14 | PASS | Live hours line (25 → 2,0 h, 250 → 20,0 h) |
| 3.15 | PASS | All three rejected with "Inserisci un link valido" |
| 3.16 | PASS | Stored verbatim |
| 3.17 | PASS | Trimmed; empty → NULL |
| 3.18 | PASS | Fields scroll into view, toggles reachable (debug + release) |
| 3.19 | PASS | Checkmark pulse captured (`shots/3.19_pulse.png`), `is_saved=1`, totals update |
| 3.20 | FAIL | Screen recording shows no confetti/shimmer before the pop (`m_frames.png`). Haptic/sound BLOCKED (phone muted, can't feel remotely). Minor |
| 3.21 | PASS | `is_saved` NULL, excluded |
| 3.22 | PASS | `is_saved=0`, in Total Spent |
| 3.23 | PASS | 5 parallel taps → one row |
| 3.24 | PASS | No duplicate, no stuck spinner |
| 4.1 | PASS | Home = SQL (e.g. 1.216,50 € / 140,00 €) |
| 4.2 | PASS | Newest first, 2 columns |
| 4.3 | PASS | Title, dot, amount, `(×3)`, "≈ 3,0 ore di lavoro" |
| 4.4 | PASS | Bolt / bag / hourglass badges |
| 4.5 | NOT RUN | |
| 4.6 | NOT RUN | |
| 4.7 | NOT RUN | |
| 4.8 | NOT RUN | |
| 4.9 | NOT RUN | |
| 5.1 | PASS | All elements present (date is English, see 7.7) |
| 5.2 | PASS | DB cycles 1 → NULL → 0; Y2K confetti + shimmer on detail (`m_52.png`). Widget refresh after a status change not observed separately |
| 5.3 | PASS | No change on re-tap |
| 5.4 | PASS | Title, price, quantity persisted |
| 5.5 | NOT RUN | |
| 5.6 | PASS | `9,99` → 9.99. Cosmetic: dialog prefills `203.00` with a dot under IT/EUR |
| 5.7 | NOT RUN | |
| 5.8 | PASS | Invalid → error, valid → link row |
| 5.9 | PASS | Add/edit/remove on qty 3: quantity stays 3 |
| 5.10 | PASS | Chrome opens, back returns (debug + release) |
| 5.11 | PASS | NULL |
| 5.12 | PASS | Old file deleted |
| 5.13 | PASS | File deleted |
| 5.14 | PASS | Relative path |
| 5.15 | N/A | Photo Picker and camera intent need no app permission |
| 5.16 | PASS | Returns to the same detail |
| 5.17 | PASS | Cancel and back do nothing |
| 5.18 | PASS | `deleted_at` set, image kept |
| 5.19 | FAIL | Theme/currency follow, but the date stays "Sep 23, 2026" in IT/FR/DE (see 7.7) |
| 6.1 | PASS | "Il cestino è vuoto." |
| 6.2 | PASS | Thumbnail, title, 29,97 €, retention notice (date English, see 7.7) |
| 6.3 | PASS | Status/qty/photo intact, totals update |
| 6.4 | PASS | 31 days: row and image removed |
| 6.5 | PASS | 29 days: kept |
| 7.1 | PASS | Animated re-theme, logo swaps |
| 7.2 | PASS | All 8 screens in Y2K and Minimal readable (`m_y2k1.png`, `m_y2k2.png`) |
| 7.3 | PASS | Home/back/Recents: no restart in-app (same PID), swap applied on leave, exactly one icon with correct art (`shots/7.3_icon_y2k.png`). Notes: via Recents the swap applies only once you leave Recents; afterwards the old task vanishes from Recents and its nav stack (e.g. open Settings) is lost |
| 7.4 | NOT RUN | |
| 7.5 | PASS | Only the expected alias enabled |
| 7.6 | PASS | `pm clear` with Y2K active → starts Minimal, icon reverts on leave |
| 7.7 | FAIL | Untranslated: dates (`date_formatter.dart`), chart months, Material tooltips "Back"/"Close", widget picker description; DE overflow in the avg tile (`shots/7.7_de_overflow_crop.png`); widget month follows the device locale (11.5). FR OK apart from months. Minor |
| 7.8 | PASS | Comma `12,50` → "12,50 € /ora"; hours lines appear. Edit/remove not separately exercised |
| 7.9 | PASS | Cancel keeps EUR; Continue → `$2,351.06` / back to `2.351,06 €`, no conversion |
| 7.10 | NOT RUN | |
| 7.11 | BLOCKED | Phone muted; audio can't be verified remotely. Toggle persists (10.1) |
| 7.12 | FAIL | Values correct (6 / 391.84) but always USD: `$37.50`, `$0.00` under EUR (`shots/7_settings_bottom.png`). Major |
| 7.13 | PASS | Readable both themes. Copy says "SKIP" (old branding) |
| 7.14 | PASS | "Nessun backup automatico trovato." |
| 7.15 | PASS | 10 live = 10 in backup (trashed excluded by design) |
| 7.16 | PASS | "Importati 0 elementi." |
| 7.17 | PASS | No duplicates |
| 7.18 | PASS | Backup md5 unchanged after empty-DB launch; restore brought back all 10 |
| 7.19 | PASS | "Il file non è un JSON valido." |
| 7.20 | BLOCKED | Not run: `bmgr backupnow` would upload to your Google account. Auto Backup is enabled with the GMS transport active (see Unexpected) |
| 8.1 | PASS | Empty state |
| 8.2 | PASS | 47,50 € / 40,00 €, pondering excluded |
| 8.3 | PASS | Apr → Sep, empty months zero |
| 8.4 | PASS | Jul/Apr bucketed; Feb (7 mo) absent from chart but in totals; Sep 2025 item did **not** leak into Sep 2026 |
| 8.5 | PASS | `1,0k €` / `$1.0k` |
| 8.6 | FAIL | Month labels English in all languages. Cosmetic: IT/FR this-month cards have different heights due to wrapping |
| 9.1 | PASS | Animation + result (haptics BLOCKED) |
| 9.2 | PASS | |
| 9.3 | PASS | No Dart errors |
| 9.4 | PASS | Row count and backup md5 unchanged |
| 10.1 | PASS | Y2K + IT + EUR + wage + sound off persist after kill |
| 10.2 | PASS | Insights, Settings, Coin flip, Detail restore in place |
| 10.3 | FAIL | Landscape add-link dialog with keyboard: "BOTTOM OVERFLOWED BY 47 PIXELS", field hidden (`shots/10.3_overflow_full.png`). Minor |
| 10.4 | FAIL | font 2.0 + density 525: avg tile overflow, mid-word breaks ("Totale ri/sparmiat/o", "Resisti/to!"), truncated axis (`shots/10.4_maxfont.png`) |
| 10.5 | PASS | App keeps its own themes |
| 10.6 | FAIL | From the accessibility tree: FAB, quantity −/+, detail photo button, entry photo preview (after pick) and coin button have empty labels. TalkBack itself not run |
| 10.7 | BLOCKED | Only one device |
| 10.8 | BLOCKED | Only API 37 available |
| 10.9 | PASS | v4 (`6763a7b`) → current: `user_version` 6, qty=1, photos/link/category/trash intact |
| 11.1 | PASS | Preview layout; renders real data (debug + release) |
| 11.2 | PASS | Wide shows full month + motto; compact short month |
| 11.3 | PASS | This month's values, proportional bar |
| 11.4 | PASS | Add / delete / restore update it (status/edit not observed separately) |
| 11.5 | FAIL | Theme/currency/labels/motto follow, month stays "SETTEMBRE" in English (`shots/11.5_widget.png`). Minor |
| 11.6 | PASS | All keys present and correct (`saved`=47.5, `spent`=40.0, `totalsMonth`=2026-09) |
| 11.7 | PASS | Stale month → zeros (`shots/11.7_widget.png`). The shell `APPWIDGET_UPDATE` broadcast is denied on Android 17; used soft `am kill` + resize instead (after force-stop the launcher shows the OS placeholder, expected) |
| 11.8 | PASS | Re-syncs on app open |
| 11.9 | BLOCKED | Needs 24 h observation |
| 11.10 | PASS | Opens the app, also after the alias swap |
| 11.11 | PASS | Empty bar; compact layout shows no motto by design |
| 11.12 | BLOCKED | Reboot would drop the wireless adb pairing |
| 11.13 | BLOCKED | Pixel Launcher only |
| 12.1 | PARTIAL | Whole run in airplane mode with Wi-Fi on; all flows worked. Offline link opening not tested (Wi-Fi off would drop adb) |
| 12.2 | PASS | No netstats entries for the app UID; release has no INTERNET permission |
| 12.3 | PASS | No app photos in MediaStore/DCIM |

## 3. Failures

**F1 — Average saved per item ignores the currency (7.12)** · Major
Repro: EUR selected, some resisted items → Settings → Riepilogo. Expected `37,50 €`, actual `$37.50` (also `$0.00` with no items).
Cause: [settings_screen.dart:110](lib/features/settings/settings_screen.dart#L110) passes no `formatter`, so `AnimatedCountUp` falls back to `formatCurrency` with its USD default ([animated_count_up.dart:70](lib/core/widgets/animated_count_up.dart#L70)).

**F2 — Stat tile overflows in DE and at large font sizes (7.7, 10.4)** · Minor
Repro: Language Deutsch → Settings → "Durchschnittlich gespart pro Artikel". Yellow/black overflow stripes, value clipped to `$39…` (`shots/7.7_de_overflow_crop.png`). Also in IT at font scale 2.0.
Likely location: `_StatTile` row in [settings_screen.dart](lib/features/settings/settings_screen.dart#L500): the label `Text` isn't `Expanded`/`Flexible`.

**F3 — Entry lost on process death during camera (3.7)** · Major
Repro: Log an item, enter a price, attach photo A, open camera, `adb shell am kill com.skip.finance`, take photo, confirm. Expected the photo arrives or the form is recoverable; actual: app cold-starts on home, entry gone, A's file orphaned in `app_flutter/skip_images` (dispose never ran).
Likely location: [item_entry_screen.dart](lib/features/item_entry/item_entry_screen.dart#L70) has no `ImagePicker.retrieveLostData()` handling.

**F4 — Y2K celebration invisible when saving a new item (3.20)** · Minor
Repro: Y2K → Log an item → price → Resisted!. Frame-by-frame recording (`m_frames.png`): no confetti or shimmer; the route pops within ~150 ms. The sound player is disposed with the screen, so the cue may be cut too (unverified, phone muted).
Location: [decision_toggle.dart:73-90](lib/features/item_entry/widgets/decision_toggle.dart#L73) starts the effects and immediately calls `onChanged`; [item_entry_screen.dart:135-158](lib/features/item_entry/item_entry_screen.dart#L135) pops as soon as the insert finishes. Works on the detail screen (5.2).

**F5 — Unlocalized strings (7.7, 5.19, 6.2, 8.6)** · Minor
- Dates "Sep 23, 2026" and chart months "Apr May …" in every language: [date_formatter.dart](lib/core/utils/date_formatter.dart) is English-only (used by the detail and trash screens and the Insights chart).
- "Back"/"Close" tooltips (TalkBack labels) and the system text toolbar stay English: `MaterialApp` in [main.dart:98](lib/main.dart#L98) has no `localizationsDelegates` / `supportedLocales` / `locale`.
- Widget picker description "This month's saved vs. spent totals." not translated.

**F6 — Widget month name follows device locale, not app language (11.5)** · Minor
Repro: device it-IT, app English → widget shows "SETTEMBRE"/"SET". Location: [SkipHomeWidgetProvider.kt:142](android/app/src/main/kotlin/com/skip/finance/SkipHomeWidgetProvider.kt#L142) uses `Locale.getDefault()`. The app language would need to be passed in `HomeWidgetPreferences`.

**F7 — Landscape dialog overflow with keyboard (10.3)** · Minor
Repro: landscape → item detail → "Aggiungi link al prodotto" → focus field. "BOTTOM OVERFLOWED BY 47 PIXELS"; the input is not visible (`shots/10.3_overflow_full.png`). Dialog content isn't scrollable.

**F8 — Max font / display size breaks layouts (10.4)** · Minor/Major (accessibility)
Summary cards, theme cards, the decision toggle and the Insights axis break mid-word or truncate (`shots/10.4_maxfont.png`), plus F2's overflow.

**F9 — Unlabeled controls (10.6)** · Major (accessibility)
Empty `content-desc` for: home FAB, quantity −/+ ([quantity_stepper.dart](lib/core/widgets/quantity_stepper.dart)), detail photo-change camera button, entry photo preview after a pick, coin-flip coin button.

**F10 — Landscape cutout (2.7)** · Cosmetic
The body isn't inset for the left `DisplayCutout` (128 px) in landscape; the app bar is (`shots/2.7_land_left.png`).

**F11 — Formatting (1.3)** · Cosmetic
Run `dart format lib test`.

## 4. Unexpected (not covered by a check)

- **Android Auto Backup uploads app data.** `allowBackup` is unset (defaults to true), there are no `dataExtractionRules`, and the Google backup transport is active on the device. The DB, prefs and photos (`app_flutter/`) are eligible for Google Drive backup. That contradicts the privacy screen ("never uploaded anywhere") and the offline rule. Set `android:allowBackup="false"` (and `dataExtractionRules`) or update the copy.
- **image_picker leaves copies in `cache/`** (e.g. `scaled_*.jpg`, the original 4500 px file, a 0-byte file from a cancelled camera), including photos that were discarded. They're private and OS-evictable, but never cleaned.
- **Orphaned photos after DB loss**: backups export only live items, so after an empty-DB restore, trashed items and their images aren't restored, and their files are never purged (`qa_purge29.jpg` stayed).
- **Entry toggle shows "Pondering" as selected before any choice** (filled button), which reads as if Pondering were preselected.
- **Stale validator messages**: "Il prezzo deve essere maggiore di zero." stays visible after typing a valid value until the next validation.
- **Sound row**: tapping the "Effetti sonori" label does nothing; only the switch toggles.
- **The auto-backup throttle is in memory only**, so the backup is rewritten on every cold start.
- **Old builds (≤ `a07521d`) used applicationId `com.elenatarantino.skip`**, so installs from those builds can't upgrade in place (only builds from `6763a7b` on can).
- The widget picker shows the Minimal app icon even when the Y2K alias is active; the privacy copy still says "SKIP".

## Environment changes made and reverted

Test photos pushed to `/sdcard/Pictures/SkipQA` (deleted, and removed from MediaStore); "Don't keep activities" on, then off; rotation, font scale, display density and night mode changed, then restored (auto-rotate 1, font 1.0, density 420, night no). Widget added (removed by uninstall). The app is reinstalled as a clean current debug build. The pre-existing app data (empty DB) is saved in `preexisting/appdata.tar`.
Side effect: widening the widget moved the "Nuova scheda Incognito" shortcut on the home screen, and it may not have moved back.
