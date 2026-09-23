# Skip! — Android QA report, emulator run (2026-09-23)

## 1. Summary

**Device:** Android emulator `Skip_Test` (`emulator-5554`), Android 16 / API 36, 1080×2400 @ 420 dpi (≈411 dp wide), Gboard, system locale `en-US`. The connected Pixel 6 was not used.
**Builds:** `master` @ `5ea8ac9`, debug APK for the main pass, release APK for the smoke checks. The v4 → v6 upgrade test used commit `6763a7b`.
**Disk (host):** 18 GB free at start, 13 GB at the lowest point (below the 15 GB stop line, so the run ended there), 15 GB after shutting down the emulator and removing the old-build worktree.

| PASS | FAIL | PARTIAL | BLOCKED | NOT RUN | N/A | Total |
|---|---|---|---|---|---|---|
| 105 | 2 | 9 | 4 | 4 | 2 | 126 |

**Top issues**
1. **Auto-backup can't be restored after data loss if it was ever restored before** (7.18). A restore that imports 0 items still marks the snapshot as restored. After the DB is lost, Restore says "This backup was already restored." and the user can't recover through the UI.
2. **The launcher icon doesn't switch when leaving the app with back** (7.3). On Android 12+, back on the root activity moves the task to the background without finishing it, so the pending alias swap never runs. Home and Recents work.

**Fixed since the Pixel 6 report (same day):** Auto Backup is now off (7.20). Average-saved is formatted in the active currency. The Y2K celebration is visible in the add flow (3.20). Process death during camera now recovers the photo (3.7). Dates, Insights months and the widget month follow the app language (7.7, 11.5). `dart format` is clean (1.3).

## 2. Results

Evidence lives in the session scratchpad `…/scratchpad/qa/` (`shots/`, `logcat_full.txt`). It's temporary.

| ID | Result | Notes / evidence |
|---|---|---|
| 1.1 | PASS | No issues |
| 1.2 | PASS | 344 tests passed, including `contrast_test.dart` |
| 1.3 | PASS | 96 files, 0 changed |
| 1.4 | PASS | No matches |
| 1.5 | PASS | No INTERNET in main manifest (the debug build gets it from the debug manifest) |
| 1.6 | PARTIAL | Debug APK, release APK (57.7 MB) and release AAB (57.0 MB) all built. Release smoke: 5.10, 7.3 (Home exit) and 11.1 pass. 3.18 couldn't be checked: Gboard stayed in its floating-toolbar mode, so no full keyboard |
| 1.7 | PASS | Clean install and launch, no errors |
| 2.1 | PASS | Minimal theme, "Skip!", empty state, motto, `$0.00` ×2 (`2.1_first_launch.png`) |
| 2.2 | PASS | Tested with a per-app locale (`cmd locale set-app-locales`). it-IT → Italian, fr-FR → French, en → English |
| 2.3 | PASS | EN → `$0.00`; IT/FR → `0,00 €` |
| 2.4 | PASS | First Flutter frame is already Y2K + Italian (`2.4_sheet.png`). Cosmetic: the native splash is a white window with the alias icon |
| 2.5 | PASS | |
| 2.6 | PASS | Back key and edge-swipe gesture both close the sheet or dialog first, then the screen. Back on home exits |
| 2.7 | PASS | Nothing under the status bar or gesture bar, portrait or landscape |
| 3.1 | PASS | 4032×3024 photo stored as 2000×1500 under `skip_images/…`, relative path in the DB |
| 3.2 | N/A | No CAMERA permission is declared; image_picker uses the system camera intent, so no prompt appears |
| 3.3 | PASS | Emulator virtual camera; photo saved and previewed |
| 3.4 | PASS | Cancel leaves no file and no stuck spinner |
| 3.5 | PASS | Photo A's file deleted |
| 3.6 | PASS | Photo file deleted for both the close icon and back |
| 3.7 | PASS | With "Don't keep activities", the form and price are kept. With a real kill (`am kill` while the camera is open), the form reopens with the new photo but the typed price is lost, and the previous photo file stays orphaned (`3.7_after_process_death.png`). The 1-hour orphan sweep couldn't be verified because the app was reinstalled |
| 3.8 | PASS | `image_path` NULL, placeholder |
| 3.9 | PASS | "Enter a price.", nothing saved |
| 3.10 | PASS | "Price must be greater than zero." |
| 3.11 | PASS | `12,50` and `12.5` both stored as 12.5 (typed via adb, not with an Italian Gboard layout) |
| 3.12 | PASS | `12.555` → `12.55`, `1a2b` → `12`, `1..2` → `1.2` |
| 3.13 | PASS | "Total: $37.50" at 12.50 × 3 |
| 3.14 | PASS | "≈ 0.3 hrs of work" appears live |
| 3.15 | PASS | `notaurl`, `ftp://x.com` and `example.com` all rejected |
| 3.16 | PASS | `https://example.com/p?id=1` stored |
| 3.17 | PASS | `  Shoes  ` → `Shoes`; empty title → NULL |
| 3.18 | PARTIAL | Debug build with the full keyboard: the focused field scrolled into view. Release build: not testable (compact Gboard) |
| 3.19 | PASS | `is_saved=1`, screen closes, totals update. The pulse wasn't checked visually |
| 3.20 | PASS | Confetti and shimmer visible, label readable (`3.20_burst.png`). Haptics and sound BLOCKED (no device) |
| 3.21 | PASS | `is_saved` NULL, excluded from totals |
| 3.22 | PASS | `is_saved=0` |
| 3.23 | PASS | 6 parallel taps → 1 row |
| 3.24 | PASS | No duplicate, no stuck spinner |
| 4.1 | PASS | With 38 items: $2,013.48 / $410.50, matching SQL |
| 4.2 | PASS | |
| 4.3 | PASS | `4.3_home_cards.png` |
| 4.4 | PASS | `4.4_home_y2k.png` |
| 4.5 | PASS | |
| 4.6 | PASS | Opens Insights |
| 4.7 | PASS | 30 photos at 3000×4000: PSS 357 MB → 319 MB after fast scrolling, no OOM. Jank not measurable (`gfxinfo` doesn't cover the Flutter surface) |
| 4.8 | PASS | No crash. Cosmetic: the detail screen shows a broken-image icon instead of the "No photo" placeholder, and its a11y label still says "Photo, tap to change" (`4.8_crop.png`) |
| 4.9 | NOT RUN | Transition smoothness can't be judged with adb screenshots |
| 5.1 | PASS | |
| 5.2 | PASS | DB and widget prefs update on each change (saved 28.98 / spent 20.0) |
| 5.3 | PASS | No spinner; I didn't confirm that no write happens |
| 5.4 | PASS | Title, price and quantity persist |
| 5.5 | PASS | NULL, title line hidden |
| 5.6 | PASS | `9,99` → 9.99 (regression check) |
| 5.7 | PASS | |
| 5.8 | PASS | |
| 5.9 | PASS | Quantity stays 3 through add, edit and remove link (regression check) |
| 5.10 | PASS | Opens Chrome; back returns (debug and release) |
| 5.11 | PASS | |
| 5.12 | PASS | Old file deleted |
| 5.13 | PASS | File deleted |
| 5.14 | PASS | Relative path |
| 5.15 | N/A | The system Photo Picker needs no permission |
| 5.16 | PASS | |
| 5.17 | PASS | |
| 5.18 | PASS | `deleted_at` set, image still on disk |
| 5.19 | PASS | Detail in DE + EUR, both themes |
| 6.1 | PASS | |
| 6.2 | PASS | Only one trashed item at a time, so the order wasn't checked |
| 6.3 | PASS | |
| 6.4 | PASS | Row and image file gone |
| 6.5 | PASS | |
| 7.1 | PASS | `7.1_settings_y2k.png` |
| 7.2 | PARTIAL | All screens seen in Minimal. In Y2K: home, settings, entry and the celebration only |
| 7.3 | **FAIL** | Home: PASS (same pid, one icon, correct artwork, `7.3_launcher_y2k.png`). Recents: PASS (swap lands once you leave recents). **Back: FAIL**, alias not swapped, see §3 |
| 7.4 | PASS | The hotseat icon follows the swap (Pixel Launcher) |
| 7.5 | PASS | `resolve-activity` shows only the expected alias |
| 7.6 | PASS | `pm clear` leaves the Y2K alias enabled until the next launch; after that the app is Minimal and the icon returns to Minimal once you leave |
| 7.7 | PASS | EN/IT/FR/DE spot-checked: settings, trash, insights, detail, dialogs, widget. See cosmetic notes in §4 |
| 7.8 | PARTIAL | Set with a comma (`12,5` → `$12.50 / hr`) and hours shown everywhere. Edit and remove not tested |
| 7.9 | PASS | Cancel keeps USD; Continue shows `28,98 €` |
| 7.10 | NOT RUN | |
| 7.11 | BLOCKED | Sound needs real hardware |
| 7.12 | PASS | 2 items, $14.49 average; later 17 items, $118.85 |
| 7.13 | PASS | Translated summary. "Read the full statement" opens a web page in Chrome |
| 7.14 | PASS | "No automatic backup found yet." |
| 7.15 | PASS | 3 live items = 3 in backup (trashed ones excluded) |
| 7.16 | PASS | "Imported 0 items." |
| 7.17 | PASS | Second tap: "This backup was already restored." |
| 7.18 | **FAIL** | The backup was *not* overwritten on the empty launch (the earlier regression is fixed), but Restore refuses to run. See §3 |
| 7.19 | PASS | "That file isn't valid JSON." |
| 7.20 | PASS | `bmgr backupnow` → "Backup is not allowed". `data_extraction_rules` excludes everything |
| 8.1 | NOT RUN | |
| 8.2 | PASS | $414.48 / $370.50 for this month, pondering excluded |
| 8.3 | PASS | `8_insights.png` |
| 8.4 | PARTIAL | Jul and Apr buckets correct, and the Feb item is absent from the chart but counted in home totals. The year-boundary case would need a date change on the emulator, which wasn't done |
| 8.5 | PASS | `1,0k €`, `1,5k €`, `2,0k €` |
| 8.6 | PARTIAL | EN/DE/FR in Minimal; Y2K Insights not checked |
| 9.1 | PASS | Result shown ("Lass es."). Haptics BLOCKED |
| 9.2 | PASS | 8 parallel taps, no errors |
| 9.3 | PASS | No `setState after dispose` |
| 9.4 | PASS | Row count 41 → 41, backup md5 unchanged |
| 10.1 | PARTIAL | Y2K + Italian + EUR + wage persist across force-stop. Sound off and swipe-from-recents not tested |
| 10.2 | PASS | Detail, settings and insights recreated without a crash, state kept |
| 10.3 | PASS | All screens usable in landscape; link dialog didn't overflow (compact keyboard only, `10.3_*.png`) |
| 10.4 | PASS | Font 2.0 + density 504, German: no overflow in logcat. Cosmetic: decision-toggle label sizes differ (`10.4_sheet.png`) |
| 10.5 | PASS | App keeps its own theme (`10.5_sheet.png`) |
| 10.6 | PARTIAL | Semantics dump only (no TalkBack run): FAB, quantity −/+, photo box, coin flip and status buttons are all labeled |
| 10.7 | PASS | 720×1520 @ 320 (360 dp) (`10.7_sheet.png`) |
| 10.8 | BLOCKED | Only the API 36 image is installed; getting another would need several GB and the disk was at its limit |
| 10.9 | PASS | v4 → v6: 3 items (photo, link, pondering, trashed) intact, `quantity=1`, `user_version=6`, trash restore works, launcher icon still opens the app |
| 11.1 | PASS | Picker preview, 2×2 with real data (debug and release) |
| 11.2 | PASS | Wide layout with motto and full month name (`11.2_wide.png`) |
| 11.3 | PASS | Matches Insights; bar split proportional |
| 11.4 | PARTIAL | Prefs update after add and status changes; I didn't check the widget visually after every action |
| 11.5 | PASS | FR + EUR + Minimal: `SEPT.`, `ÉCONOMISÉ`, `421,48 €` (`11.5_crop.png`) |
| 11.6 | PASS | All keys present, `totalsMonth=2026-09`, plus `languageCode` |
| 11.7 | PASS | Stale month → `$0.00` ×2. Shell can't send `APPWIDGET_UPDATE` on API 36, so a resize triggered the update |
| 11.8 | PASS | |
| 11.9 | NOT RUN | Would need observing across a real day |
| 11.10 | PASS | Opens `.MainActivity` |
| 11.11 | PASS | "Nothing logged this month. First skip?" |
| 11.12 | BLOCKED | Device check; the widget was removed by the reinstall for the upgrade test |
| 11.13 | BLOCKED | Only Pixel Launcher available |
| 12.1 | PASS | Add/save works in airplane mode; the link hands off to Chrome |
| 12.2 | PASS | No netstats history for uid 10215 |
| 12.3 | PASS | `/sdcard/DCIM` empty; nothing added to the gallery |

## 3. Failures

### 7.18 — Auto-backup can't be restored after data loss (major)

**Steps**
1. With items present, tap Settings → *Restore last automatic backup*. It says "Imported 0 items." (as in 7.16).
2. Force-stop, delete `databases/skip.db*`, relaunch. The app is now empty, and the backup file still holds 3 items.
3. Tap Restore.

**Expected:** 3 items restored. **Actual:** "This backup was already restored." Nothing is imported and the DB stays empty (`7.18_already_restored_empty_db.png`). Removing `flutter.skip_last_restored_auto_backup_exported_at` from prefs and restoring again brings back all 3 items ("Imported 3 items."), which confirms the cause.

**Likely location:** [items_provider.dart:89-98](lib/data/items_provider.dart#L89-L98). The snapshot is marked as restored after every import, even when `count == 0`. Since `load()` only writes a new backup `if (hasData …)` ([items_provider.dart:71](lib/data/items_provider.dart#L71)), an empty DB never produces a new snapshot, so the lock is permanent. Nothing in the UI can unlock it (only clearing app storage, which deletes the backup too).

### 7.3 — Icon swap never applies when leaving with back (major for gesture-navigation users)

**Steps:** Settings → switch aesthetic → back to home → back out of the app (key or edge-swipe gesture).

**Expected:** the launcher shows the new icon. **Actual:** `resolve-activity` still returns the old alias, and the launcher keeps the old icon. The swap happens only after a later exit via Home or Recents, and a user who always exits with back never gets it.

**Logcat:** `I/ActivityTaskManager: moveTaskToBack: Task{7ea9d7d #22 type=standard I=com.skip.finance/.MainActivityY2K}`. Android 12+ moves a root launcher activity's task to the background on back instead of finishing it.

**Likely location:** [MainActivity.kt](android/app/src/main/kotlin/com/skip/finance/MainActivity.kt). `onUserLeaveHint` doesn't fire on back, and `onDestroy` with `isFinishing` isn't reached, so `applyPendingLauncherIcon()` is never called. The pending state is also only in memory, so it's lost if the process dies in the background.

## 4. Anything unexpected

- **Swapping the alias recreates the task.** After a Home-exit swap, tapping the icon opens a new task on the home screen rather than returning to Settings (the process survives, as intended).
- **`pm clear` doesn't reset the alias.** The Y2K alias stays enabled after "Clear storage" until the app runs and is left once. Launching `.MainActivityMinimal` directly fails ("does not exist") in that window.
- **The widget picker shows the Minimal app icon** even when the Y2K alias is active. Cosmetic.
- **German layout:** "Widerstanden!" shrinks to a much smaller font than "Am Überlegen"/"Gekauft", and "Am Überlegen" wraps onto two lines, so the three toggles don't match (both themes, all font sizes). "Gesamt ausgegeben" wraps at 360 dp, so the two summary cards' amounts don't line up. Cosmetic.
- **French currency dialog** writes `1$` / `1€` without the space French typography uses. Cosmetic.
- **Process death during camera** loses the typed price, although the photo is recovered. The previous photo becomes an orphan until a cold start at least 1 hour later.
- **Privacy policy:** "Read the full statement" needs network (it opens a web page), which is worth noting for an offline-only app.
- On API 36, `am broadcast … APPWIDGET_UPDATE` from shell is refused (SecurityException), so the prompt's 11.7 command needs replacing with a widget resize.
