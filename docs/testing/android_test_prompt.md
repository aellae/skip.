# Prompt — Full QA pass of Skip! on Android

You are QA-testing the **Android build of Skip!**, a Flutter app (repo root: `/Users/elle/Desktop/skip.`) for logging purchases you resisted ("Resisted!"), bought ("Bought It"), or are still deciding on ("Pondering"). Read `CLAUDE.md` and `docs/NEW_FEATURE_GUIDE.md` first; they describe the architecture, schema (v6), and rules (100% offline, dual theme, soft delete).

Your job is to **verify every flow below and report results**. Do **not** change app code. If a check fails, capture evidence (screenshot, logcat excerpt, DB/file state) and move on. The final report is the deliverable.

---

## 0. Ground rules

- **Prefer a physical Android device** (`adb devices`). The emulator (`Medium_Phone.avd`) uses several GB of RAM and rewrites a multi-GB disk image, and it has filled this machine's disk before. If you must use it:
  - check free space first (`df -h ~`) and stop if under ~15 GB;
  - start it only for this run, and **shut it down when you finish** (`adb emu kill`);
  - re-check free space at the end and report both numbers.
- Checks marked **[device]** need real hardware (camera, haptics, sound, launcher icon behavior, widget refresh cadence). On the emulator, mark them BLOCKED if they can't be verified.
- Drive the UI with whatever automation you have (computer use, Maestro, `adb shell input`, `flutter drive`, or similar). If you can't interact, run everything scriptable and list the rest as **BLOCKED — needs manual run**. Never mark those PASS.
- Screenshot every failure: `adb exec-out screencap -p > /tmp/skip_<check-id>.png`.
- Keep `flutter logs` and `adb logcat -v time | grep -iE "skip|flutter|AndroidRuntime"` running. **Any uncaught exception, red error screen, ANR, `setState() called after dispose`, "RenderFlex overflowed" or `used after being disposed` is a FAIL** for the check that triggered it.

### Useful commands (debug build; `run-as` needs a debuggable app)

```bash
PKG=com.skip.finance
adb shell run-as $PKG ls -R files app_flutter databases shared_prefs
adb shell run-as $PKG ls app_flutter/skip_images            # copied photos (Documents = app_flutter)
adb shell run-as $PKG cat app_flutter/skip_exports/skip_autobackup.json
adb shell run-as $PKG cat shared_prefs/HomeWidgetPreferences.xml   # widget data (home_widget plugin)
# Pull / edit / push the DB (sqlite3 is usually not on-device):
adb shell run-as $PKG cat databases/skip.db > /tmp/skip.db
sqlite3 /tmp/skip.db 'select id,title,price,quantity,image_path,is_saved,created_at,purchase_url,deleted_at from items;'
# after editing (app stopped with `adb shell am force-stop $PKG`):
adb push /tmp/skip.db /data/local/tmp/skip.db
adb shell run-as $PKG cp /data/local/tmp/skip.db databases/skip.db
adb shell run-as $PKG rm -f databases/skip.db-wal databases/skip.db-shm
```

If the DB or prefs live under different names, find them with `adb shell run-as $PKG find . -name "*.db" -o -name "*.xml"` and note the real paths in the report.

---

## 1. Static checks and build

| ID | Check | Expected |
|---|---|---|
| 1.1 | `flutter analyze` | No issues |
| 1.2 | `flutter test` | All pass. Record any failure verbatim, including `test/core/theme/contrast_test.dart` |
| 1.3 | `dart format --output=none --set-exit-if-changed lib test` | Exit 0 |
| 1.4 | `grep -rnE "package:(http|dio)|firebase" lib pubspec.yaml` | No matches (offline rule) |
| 1.5 | `grep -rn "INTERNET" android/app/src/main/AndroidManifest.xml` | Not requested in the main manifest (debug/profile manifests may add it for tooling) |
| 1.6 | `flutter build apk --debug` and `flutter build apk --release` (also `flutter build appbundle --release`) | All succeed. Install the **release** APK too and repeat the smoke checks 3.18, 5.10, 7.3 and 11.1 on it, since R8/minification can break the widget, the icon channel or url_launcher |
| 1.7 | Clean install: `adb uninstall com.skip.finance`, then `flutter run -d <device>` | Launches, no errors |

---

## 2. First launch (fresh install)

| ID | Check | Expected |
|---|---|---|
| 2.1 | Launch after a clean uninstall | Minimal theme, "Skip!" logo, empty-state message, motto under summary cards, both totals 0 |
| 2.2 | Language default | Matches the device language. Test English and Italian (reinstall between) |
| 2.3 | Currency default | English → USD (`$0.00`); IT/FR/DE → EUR (`0,00 €`) |
| 2.4 | Relaunch with saved settings | Saved theme and language on the first frame, no flash |
| 2.5 | App-bar icons (coin flip, insights, settings) and FAB | Each opens the right screen |
| 2.6 | System **back** (button and gesture, incl. predictive back on Android 14+) from every screen and every open dialog/bottom sheet | Closes the dialog/sheet first, then pops the screen; back on home exits the app cleanly |
| 2.7 | Edge-to-edge / insets (Android 15+ enforces edge-to-edge) | No content under the status bar, navigation bar or camera cutout; FAB and bottom content not hidden by gesture bar |

---

## 3. Add item (FAB → "Log an item")

### Photo
| ID | Check | Expected |
|---|---|---|
| 3.1 | Tap photo box → Gallery (Android 13+ system Photo Picker; seed images with `adb push img.jpg /sdcard/Pictures/` + `adb shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/img.jpg`; include one 4000px+ photo) | Preview shows; new file in `app_flutter/skip_images`; DB path is **relative** (`skip_images/...`) |
| 3.2 | Camera: first use → permission prompt → **Deny**, then **Deny & don't ask again** | No crash; snackbar or no-op; spinner clears |
| 3.3 | Camera: allow and take a photo **[device]** (emulator virtual camera acceptable) | Photo saved and previewed |
| 3.4 | Cancel picker / camera | Nothing changes, spinner clears, no new file |
| 3.5 | Pick photo A then photo B | Preview B; **A's file deleted** |
| 3.6 | Pick a photo, then leave without saving (back button **and** close icon) | That photo file is **deleted** |
| 3.7 | **Process death during camera**: enable Developer options → "Don't keep activities", open camera, take photo, return | App doesn't crash; either the photo arrives or the form is recoverable. Note the behavior (lost-data handling). Disable the option afterwards |
| 3.8 | Save with no photo | `image_path` NULL, placeholder shown |

### Price, quantity, title, link
| ID | Check | Expected |
|---|---|---|
| 3.9 | Decision tap with empty price | "Enter a price" error, nothing saved, **no confetti / sound / pulse** |
| 3.10 | Price `0` | Greater-than-zero error |
| 3.11 | Price `12.5` and `12,50` (Gboard with Italian/German locale shows `,` on the numeric pad; also test Samsung Keyboard if available) | Both accepted as 12.5 |
| 3.12 | Three decimals, letters, double separators | Blocked |
| 3.13 | Quantity stepper to 3 | "Total" line = price × 3; min 1 |
| 3.14 | Wage set (see 7.8), type price | Hours-of-work line appears and updates live |
| 3.15 | Links `notaurl`, `ftp://x.com`, `example.com` | Rejected |
| 3.16 | Link `https://example.com/p?id=1` | Accepted and stored |
| 3.17 | Title with spaces / empty | Trimmed / NULL |
| 3.18 | Keyboard open while scrolling the form | Fields scroll into view; decision buttons reachable |

### Saving via the decision toggle
| ID | Check | Expected |
|---|---|---|
| 3.19 | **Resisted!** (Minimal) | Checkmark pulse, `is_saved=1`, screen closes, totals update |
| 3.20 | **Resisted!** (Y2K) | Confetti, shimmer (label readable), haptic **[device]**, sound if enabled **[device]** |
| 3.21 | **Pondering** | `is_saved` NULL; excluded from totals |
| 3.22 | **Bought It** | `is_saved=0`; in Total Spent |
| 3.23 | Rapid multi-tap on a decision | Exactly one row |
| 3.24 | Press Home mid-save, return | No duplicate, no stuck spinner |

---

## 4. Home dashboard

| ID | Check | Expected |
|---|---|---|
| 4.1 | Totals | Saved = Σ(price × quantity) of resisted, Spent = same for bought; pondering and trashed excluded. Cross-check via SQL: `select is_saved, sum(price*quantity) from items where deleted_at is null group by is_saved;` |
| 4.2 | Order | Newest first, 2-column masonry |
| 4.3 | Card content | Title (ellipsised), status dot, colored amount, `(×3)`, hours line |
| 4.4 | Y2K badges | Bolt / bag / hourglass per status |
| 4.5 | Pull to refresh | Works; no skeleton flicker when items exist |
| 4.6 | Tap summary card | Opens Insights |
| 4.7 | 30+ items with large photos, fast scrolling | No jank spikes, no OOM (`adb shell dumpsys meminfo com.skip.finance` before/after) |
| 4.8 | Delete a photo file by hand | Placeholder, no crash |
| 4.9 | Hero transition card ↔ detail | Smooth, also for items without photo |

---

## 5. Item detail

| ID | Check | Expected |
|---|---|---|
| 5.1 | Content | Photo, title, total with `(unit × qty)`, hours, date, status, coin-flip button, link section |
| 5.2 | Cycle status Resisted → Pondering → Bought → Resisted | DB, home totals and widget update; Y2K confetti on Resisted |
| 5.3 | Tap already-selected status | No write, no spinner |
| 5.4 | Edit details: title, price, quantity | All persist |
| 5.5 | Clear title | NULL, no title line |
| 5.6 | Edit price with a **comma** (`9,99`) on an IT/FR/DE keyboard | Accepted as 9.99 (regression check, this was broken) |
| 5.7 | Invalid/zero price; Cancel | Error; Cancel leaves it unchanged |
| 5.8 | Add link (invalid → error; valid → saved) | Link row appears |
| 5.9 | On a **quantity 3** item, add / edit / remove the link | **Quantity stays 3**, totals unchanged (regression check, this was broken) |
| 5.10 | Visit product page | Opens in an external browser (Chrome) on Android 11+ (package-visibility rules); back returns to the app. If nothing opens, "Couldn't open link" snackbar must show |
| 5.11 | Remove link | NULL in DB |
| 5.12 | Change photo | New photo; **old file deleted** |
| 5.13 | Remove photo | Placeholder; file deleted |
| 5.14 | Add photo to a photo-less item | Saved, relative path |
| 5.15 | Photo pick with permission denied | Snackbar, spinner clears, no orphan file |
| 5.16 | Coin-flip button | Opens and returns to the same detail |
| 5.17 | Delete → Cancel / back button on the dialog | Nothing happens |
| 5.18 | Delete → Delete | Back home, item gone, `deleted_at` set, **image still on disk** |
| 5.19 | Change theme, language and currency in Settings, then reopen an item | Detail reflects all three, no errors |

---

## 6. Trash (Settings → Trash)

| ID | Check | Expected |
|---|---|---|
| 6.1 | Empty trash | Empty state |
| 6.2 | With trashed items | Newest-deleted first; thumbnail, title, **total (price × quantity)**, deletion date, retention notice |
| 6.3 | Restore | Returns with same status/quantity/photo/link; totals update |
| 6.4 | Purge: stop app, set `deleted_at` to 31 days ago in the pulled DB (ISO format like `strftime('%Y-%m-%dT%H:%M:%f','now','-31 days')`), push back, relaunch | Row hard-deleted **and** image file removed |
| 6.5 | Same with 29 days | Still in Trash |

---

## 7. Settings

| ID | Check | Expected |
|---|---|---|
| 7.1 | Aesthetic Minimal ↔ Y2K | Animated re-theme; logo switches; previews show their own theme |
| 7.2 | Visit **every** screen (home, entry, detail, insights, coin flip, settings, trash, privacy policy) in both themes | No hardcoded colors, unreadable text or layout breaks |
| 7.3 | **Launcher icon swap** (activity-alias `.MainActivityMinimal` / `.MainActivityY2K`) **[device]** | The icon change is deferred until you **leave** the app. Check leaving with the Home button, the back button, and the recents screen. The app must **not** be killed or restarted while you're in it; afterwards the launcher shows exactly **one** Skip! icon, with the right artwork; tapping it opens the app with data and theme intact |
| 7.4 | Pinned shortcuts / icon placed on the home screen before the swap | Still works or is cleanly removed by the launcher (note which) |
| 7.5 | Relaunch after switching | Theme and icon persist; `adb shell pm dump com.skip.finance \| grep -A2 MainActivity` shows only the expected alias enabled |
| 7.6 | "Clear storage" while Y2K icon is active, relaunch | App starts in Minimal and the icon returns to Minimal |
| 7.7 | Languages EN / IT / FR / DE | All screens, dialogs, snackbars, empty states and the widget translated; no overflow in DE/FR |
| 7.8 | Hourly wage: set (dot and **comma** decimals), edit, remove | "X / hour" shown; hours lines appear/disappear everywhere |
| 7.9 | Currency switch with items → warning; Cancel / Continue | Cancel keeps it; Continue switches format (`$1,234.56` ↔ `1.234,56 €`), no conversion |
| 7.10 | Currency switch with no items | No dialog |
| 7.11 | Sound off → Y2K Resisted! **[device]** | Silent; with sound on it plays and respects media volume / Do Not Disturb |
| 7.12 | Stat tiles | Resisted count and average saved per item correct; 0 with no items |
| 7.13 | Privacy policy | Opens, readable in both themes and all languages |

### Backup / restore
| ID | Check | Expected |
|---|---|---|
| 7.14 | Fresh install → Restore | "No automatic backup found" (or 0 restored; note which) |
| 7.15 | Backup file exists and matches live items (`… cat app_flutter/skip_exports/skip_autobackup.json`) | Item count = live items |
| 7.16 | Restore with data present | 0 new, no duplicates |
| 7.17 | Double-tap Restore | No duplicates; second tap disabled or "already restored" |
| 7.18 | **Empty-DB recovery**: with items and backup present, force-stop, delete `databases/skip.db*` (keep the backup), relaunch, Restore | All items return, and the backup was **not** overwritten with an empty list on that launch (regression check, this was broken) |
| 7.19 | Corrupt the backup file, Restore | Localized error snackbar, no crash |
| 7.20 | Android Auto Backup / device transfer: `adb shell bmgr backupnow com.skip.finance` then reinstall and `adb shell bmgr restore` (if `allowBackup` is on) | Note what's restored; the app must not crash on restored data with missing photos |

---

## 8. Insights

| ID | Check | Expected |
|---|---|---|
| 8.1 | No activity | Empty state |
| 8.2 | This-month cards | This month only, price × quantity, pondering excluded |
| 8.3 | 6-month chart | Oldest → newest, current month last, empty months zero |
| 8.4 | Back-date items (2, 5, 7 months ago, one across a **year boundary**) | Correct buckets; 7-month-old item absent from chart but in home totals |
| 8.5 | Axis labels | `$1.2k` / `1,2k €` |
| 8.6 | Both themes, all languages | Readable, localized |

---

## 9. Coin flip

| ID | Check | Expected |
|---|---|---|
| 9.1 | Flip | Animation, result, haptics **[device]** |
| 9.2 | Rapid taps | No stacked animations/errors |
| 9.3 | Back mid-flip | No `setState after dispose` |
| 9.4 | DB untouched | Row count and backup file unchanged |

---

## 10. Persistence, lifecycle and device variety

| ID | Check | Expected |
|---|---|---|
| 10.1 | Set Y2K + Italian + EUR + wage + sound off; swipe away from recents; relaunch | Everything persists |
| 10.2 | "Don't keep activities" on; background/restore on each screen | No crash; state restored or cleanly reset |
| 10.3 | Rotate (auto-rotate on) on every screen, with keyboard up in dialogs | No overflow; usable |
| 10.4 | Font size and display size at max (Settings → Display) | No clipped buttons/overflow |
| 10.5 | System dark theme | App keeps its themes, readable |
| 10.6 | TalkBack on home, entry, detail | Meaningful labels on logo, icons, toggle, FAB |
| 10.7 | Small screen (≈360dp wide) and a tablet/foldable if available | Layouts hold; grid and toggles fit |
| 10.8 | Android versions: at least the minSdk-era version available and the latest (API 35/36) | Core flows pass on both |
| 10.9 | **Upgrade install**: install an older commit with schema < 6 (see `git log -- lib/data/database_helper.dart`), add items (photo/no photo, link, trashed one), then `flutter install` the current build **over it** | Migration succeeds; all data intact |

---

## 11. Home-screen widget (`SkipHomeWidgetProvider`)

| ID | Check | Expected |
|---|---|---|
| 11.1 | Widget picker shows the preview layout; add the widget at 2×2 | Renders with real data once the app has run |
| 11.2 | Resize to ≥ ~4 cells wide (≥ 250dp) and back | Switches between compact and wide layout; month name short vs full |
| 11.3 | Values | **This month's** saved/spent, matching Insights; progress bar split proportional |
| 11.4 | Add / change status / edit / delete / restore, then go Home | Widget updates each time |
| 11.5 | Switch currency, aesthetic, language | Widget formatting, background/colors, labels and motto follow |
| 11.6 | Inspect `shared_prefs/HomeWidgetPreferences.xml` | `saved`, `spent`, `totalsMonth` (= current `yyyy-MM`), `currencyCode`, `aesthetic`, `savedLabel`, `spentLabel`, `mottos`, `mottoEmpty` present and correct |
| 11.7 | Month rollover: force-stop the app, edit `totalsMonth` to last month in the prefs XML (pull/push via `run-as` as for the DB), then trigger an update (resize the widget or `adb shell am broadcast -a android.appwidget.action.APPWIDGET_UPDATE -n com.skip.finance/.SkipHomeWidgetProvider`) | Widget shows **zeros**, not stale totals |
| 11.8 | Open the app after 11.7 | Widget re-syncs |
| 11.9 | Note: `updatePeriodMillis` is 24h, so without the app being opened the widget may keep showing last month for up to a day after the 1st | Report the observed behavior. It's a known limitation, not a FAIL, unless it never refreshes |
| 11.10 | Tap anywhere on the widget | Opens the app (including after the launcher-icon alias swap in 7.3) |
| 11.11 | No activity this month | Empty bar + "empty" motto |
| 11.12 | Reboot the device **[device]** | Widget still renders correct data |
| 11.13 | Different launchers (Pixel Launcher, One UI, Nova if available) **[device]** | Rounded corners, text and colors render correctly |

---

## 12. Offline and privacy

| ID | Check | Expected |
|---|---|---|
| 12.1 | Airplane mode; run the core flows | Everything works except opening product links, which fails gracefully |
| 12.2 | `adb shell dumpsys netstats detail \| grep -A3 com.skip.finance` after a full session | No app network traffic |
| 12.3 | Photos | Stored only in the app's private storage; nothing added to the gallery |

---

## 13. Clean-up

- Turn "Don't keep activities" off and restore font/display size and language.
- If you used the emulator, shut it down (`adb emu kill`) and report free disk space before and after.

---

## Report format

Finish with one Markdown report:

1. **Summary**: counts of PASS / FAIL / BLOCKED, device(s) and Android version(s) used, and the top issues in one line each.
2. **Results table**: `ID | Result | Notes / evidence path`, for every check above.
3. **Failures**: for each, give the steps to reproduce, expected vs actual result, screenshot path, relevant logcat lines, severity (critical / major / minor / cosmetic), and a pointer to the likely code location if you can find it.
4. **Anything unexpected** that no check covered.

Do not fix anything. Report only.
