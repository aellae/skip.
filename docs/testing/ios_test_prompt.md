# Prompt — Full QA pass of Skip! on iOS

You are QA-testing the **iOS build of Skip!**, a Flutter app (repo root: `/Users/elle/Desktop/skip.`) for logging purchases you resisted ("Resisted!"), bought ("Bought It"), or are still deciding on ("Pondering"). Read `CLAUDE.md` and `docs/NEW_FEATURE_GUIDE.md` first; they describe the architecture, schema (v6), and rules (100% offline, dual theme, soft delete).

Your job is to **verify every flow below and report results**. Do **not** change app code. If a check fails, capture evidence (screenshot, log excerpt, DB/file state) and move on. The final report is the deliverable.

---

## 0. Ground rules

- Target: the booted **iOS Simulator** (`xcrun simctl list devices booted`). If a physical iPhone is connected, repeat the checks marked **[device]** on it (camera, haptics, sound, real widget refresh cadence).
- **Do not start the Android emulator.** It has filled this machine's disk before.
- Drive the UI with whatever automation you have (computer use, Maestro, `flutter drive`, or similar). If you can't tap the simulator, run everything scriptable (sections 1, 11, 12 state checks) and list the remaining checks as **BLOCKED — needs manual run**. Never mark those PASS.
- Take a screenshot for every failure: `xcrun simctl io booted screenshot /tmp/skip_<check-id>.png`.
- Keep `flutter logs` (or the `flutter run` console) open the whole time. **Any uncaught exception, red error screen, `setState() called after dispose`, overflow ("RenderFlex overflowed") or `used after being disposed` counts as a FAIL** for the check that triggered it.

### Useful paths (Simulator)

```bash
BUNDLE=com.skip.finance
DATA=$(xcrun simctl get_app_container booted $BUNDLE data)
GROUP=$(xcrun simctl get_app_container booted $BUNDLE group.com.skip.finance)
DB=$(find "$DATA" -name skip.db | head -1)         # SQLite database
IMAGES="$DATA/Documents/skip_images"                # copied photos
BACKUP="$DATA/Documents/skip_exports/skip_autobackup.json"
WIDGET_PLIST="$GROUP/Library/Preferences/group.com.skip.finance.plist"
sqlite3 "$DB" 'select id,title,price,quantity,image_path,is_saved,created_at,purchase_url,deleted_at from items;'
plutil -p "$WIDGET_PLIST"
```

Close the app (`xcrun simctl terminate booted $BUNDLE`) before writing to the DB or plist by hand, then relaunch.

---

## 1. Static checks and build

| ID | Check | Expected |
|---|---|---|
| 1.1 | `flutter analyze` | No issues |
| 1.2 | `flutter test` | All pass. Record any failure verbatim, including `test/core/theme/contrast_test.dart` |
| 1.3 | `dart format --output=none --set-exit-if-changed lib test` | Exit 0 |
| 1.4 | `grep -rnE "package:(http|dio)|firebase" lib pubspec.yaml` | No matches (offline rule) |
| 1.5 | `flutter build ios --simulator --debug` and `flutter build ios --release --no-codesign` | Both succeed, including the `SkipWidget` extension target |
| 1.6 | Clean install: `xcrun simctl uninstall booted com.skip.finance`, then `flutter run -d <sim-id>` | App launches with no errors in logs |

---

## 2. First launch (fresh install)

| ID | Check | Expected |
|---|---|---|
| 2.1 | Launch after a clean uninstall | Minimal theme, lowercase-style "Skip!" logo, empty-state message, motto under the summary cards, both totals at 0 |
| 2.2 | Language default | Matches the simulator's language (Settings → General → Language). Test once with English and once with Italian (`xcrun simctl` or Settings app); reinstall between runs |
| 2.3 | Currency default | English → USD (`$0.00`); IT/FR/DE → EUR (`0,00 €`) |
| 2.4 | No flash of the wrong theme or language on first frame after relaunch with saved settings | Persisted theme and language show immediately |
| 2.5 | App-bar icons: coin flip, insights, settings. FAB (camera-plus icon) | Each opens the right screen; back returns home |

---

## 3. Add item (FAB → "Log an item")

### Photo
| ID | Check | Expected |
|---|---|---|
| 3.1 | Tap photo box → source sheet → Gallery. Seed photos first: `xcrun simctl addmedia booted <jpg>` (use one large, 4000px+ photo) | Photo previews; a new file appears in `$IMAGES`; stored path in DB is **relative** (`skip_images/...`) after saving |
| 3.2 | First-time photo permission: reset with `xcrun simctl privacy booted reset all com.skip.finance`, then pick → **Don't Allow** / limited access | No crash; either empty picker or a "Something went wrong" snackbar; spinner clears |
| 3.3 | Camera on Simulator (no camera available) | Graceful snackbar, no crash, spinner clears. **[device]** real camera works and photo is saved |
| 3.4 | Cancel the picker | Nothing changes, spinner clears, no new file in `$IMAGES` |
| 3.5 | Pick photo A, then pick photo B | Preview shows B; **A's file is deleted** from `$IMAGES` |
| 3.6 | Pick a photo, then close the screen without saving | That photo file is **deleted** from `$IMAGES` (count files before/after) |
| 3.7 | Save with no photo at all | Item saved with `image_path` NULL; card shows the placeholder |

### Price, quantity, title, link
| ID | Check | Expected |
|---|---|---|
| 3.8 | Tap a decision with empty price | "Enter a price" error, nothing saved, **no confetti / sound / pulse** |
| 3.9 | Price `0` | "must be greater than zero" error |
| 3.10 | Price `12.5` and price `12,50` (switch the simulator keyboard/region to Italian to get a `,` key) | Both accepted, stored as 12.5 |
| 3.11 | Try typing a 3rd decimal (`1.234`), letters, or two separators | Input is blocked |
| 3.12 | Quantity stepper up to 3 | "Total: …" line shows price × 3; stepper can't go below 1 |
| 3.13 | With an hourly wage set (see 7.x), type a price | "≈ X hours of work" line appears and updates live with price and quantity |
| 3.14 | Product link `notaurl`, `ftp://x.com`, `example.com` | Rejected with the invalid-link error |
| 3.15 | Product link `https://example.com/p?id=1` | Accepted and stored |
| 3.16 | Title with leading/trailing spaces; empty title | Trimmed; empty → NULL in DB |
| 3.17 | Price field's check-mark suffix icon | Dismisses the decimal keypad |

### Saving via the decision toggle
| ID | Check | Expected |
|---|---|---|
| 3.18 | Tap **Resisted!** (Minimal) | Checkmark pulse, item saved `is_saved=1`, screen closes, totals update |
| 3.19 | Tap **Resisted!** (Y2K) | Confetti, shimmer sweep across the pill (label stays readable), haptic **[device]**, sound (if sound on) **[device]**, item saved |
| 3.20 | Tap **Pondering** | Saved with `is_saved` NULL; not counted in either total |
| 3.21 | Tap **Bought It** | Saved `is_saved=0`; added to Total Spent |
| 3.22 | Double/triple-tap a decision quickly | Exactly **one** row inserted |
| 3.23 | Background the app mid-save, return | No duplicate, no stuck spinner |

---

## 4. Home dashboard

| ID | Check | Expected |
|---|---|---|
| 4.1 | Totals | Total Saved = Σ(price × quantity) of resisted items; Total Spent = same for bought; pondering and trashed excluded. Cross-check with `sqlite3 "$DB" "select is_saved, sum(price*quantity) from items where deleted_at is null group by is_saved;"` |
| 4.2 | Grid order | Newest first, 2-column masonry |
| 4.3 | Card content | Title (ellipsised if long), status dot, amount in status color, `(×3)` when quantity > 1, hours line when wage set |
| 4.4 | Y2K card badge | Bolt / bag / hourglass icon matches status |
| 4.5 | Pull to refresh | Works; no flicker to the skeleton when items already exist |
| 4.6 | Tap either summary card | Opens Insights |
| 4.7 | 30+ items with large photos; scroll fast top↔bottom | Smooth, no memory warnings or crashes (watch Xcode memory gauge or logs) |
| 4.8 | Photo file deleted by hand from `$IMAGES` | Card shows placeholder, no crash |
| 4.9 | Hero animation card → detail → back | Image animates without glitches, also for items without a photo |

---

## 5. Item detail (tap a card)

| ID | Check | Expected |
|---|---|---|
| 5.1 | Shows photo, title, total (with `(unit × qty)` when qty > 1), hours, date, status toggle, coin-flip button, link section | All correct for the item |
| 5.2 | Change status Resisted → Pondering → Bought → Resisted | DB updates each time; home totals and widget update; Y2K confetti on Resisted |
| 5.3 | Tap the already-selected status | No DB write, no spinner |
| 5.4 | Edit details: change title, price, quantity → Save | All three persist; home card updates |
| 5.5 | Edit details: clear the title | Title becomes NULL, no title line shown |
| 5.6 | Edit details: price with a **comma** (`9,99`) using an IT/FR/DE keyboard | Accepted and saved as 9.99 (regression check, this was broken) |
| 5.7 | Edit details: invalid/zero price; Cancel | Error shown; Cancel leaves item unchanged |
| 5.8 | Add product link (invalid → error; valid → saved) | Link row appears with "Visit product page" and edit icon |
| 5.9 | On an item with **quantity 3**, add/edit/remove its link | **Quantity stays 3** and totals don't change (regression check, this was broken) |
| 5.10 | Visit product page | Opens Safari (app not replaced by an in-app webview); returning to the app works |
| 5.11 | Edit link → Remove | Link cleared (NULL in DB) |
| 5.12 | Tap photo → change photo | New photo shown; **old file deleted** from `$IMAGES` |
| 5.13 | Tap photo → remove photo | Placeholder "No photo"; file deleted |
| 5.14 | Tap photo → add photo on an item that had none | Saved; relative path in DB |
| 5.15 | Photo pick with permission denied / camera on Simulator | Snackbar, no crash, spinner clears, no orphan file |
| 5.16 | Coin-flip button | Opens coin flip; back returns to the same detail screen |
| 5.17 | Delete → Cancel | Nothing happens |
| 5.18 | Delete → Delete | Returns home, item gone, `deleted_at` set in DB, **image file still on disk** (deleted only on purge) |
| 5.19 | Change theme, language and currency in Settings, then reopen an item's detail screen | Detail reflects all three; no errors in logs |

---

## 6. Trash (Settings → Trash)

| ID | Check | Expected |
|---|---|---|
| 6.1 | Empty trash | Empty-state message |
| 6.2 | After deleting items | Listed newest-deleted first with thumbnail, title, **total (price × quantity)**, deletion date, retention notice |
| 6.3 | Restore | Item returns to home with the same status/quantity/photo/link; totals update |
| 6.4 | Purge: terminate app, set `deleted_at` to 31 days ago: `sqlite3 "$DB" "update items set deleted_at=datetime('now','-31 days') where id=<id>;"`. Use ISO format matching the app (`strftime('%Y-%m-%dT%H:%M:%f','now','-31 days')`). Relaunch | Row hard-deleted **and** its image file removed from `$IMAGES` |
| 6.5 | Same with 29 days | Item still in Trash |

---

## 7. Settings

| ID | Check | Expected |
|---|---|---|
| 7.1 | Aesthetic switch Minimal ↔ Y2K | Whole app re-themes with an animated transition; logo switches; each preview tile shows its own theme regardless of the active one |
| 7.2 | Switch aesthetic, then visit **every** screen (home, entry, detail, insights, coin flip, settings, trash, privacy policy) in both themes | No hardcoded colors, unreadable text, or layout breaks |
| 7.3 | App icon swap | iOS shows the "You have changed the icon for Skip!" alert; Home Screen icon matches the theme. **Note:** Simulator icon cache can show a blank/stale icon; if so, restart the simulator before calling it a FAIL (see memory note "iOS alternate icon pitfalls") |
| 7.4 | Relaunch after switching | Theme and icon persist; switching back to Minimal restores the primary icon |
| 7.5 | Language EN / IT / FR / DE | Every screen, dialog, snackbar, empty state and the widget text are translated. No overflow in German/French (long words) |
| 7.6 | Currency switch with items present | Warning dialog; Cancel keeps currency; Continue switches. Formatting: `$1,234.56` vs `1.234,56 €` (display-only, no conversion) |
| 7.7 | Currency switch with no items | Switches without dialog |
| 7.8 | Hourly wage: set (dot and **comma** decimals), edit, remove | Setting shows "$X / hour"; hours-of-work lines appear on cards, detail and entry; Remove hides them all |
| 7.9 | Sound toggle off, then Resisted! in Y2K | No sound (**[device]**, also check with the ring/silent switch) |
| 7.10 | Stat tiles | "Items resisted" = count of resisted live items; "Average saved per item" = Total Saved ÷ that count; 0 with no items |
| 7.11 | Privacy policy | Opens, readable in both themes and all languages |

### Backup / restore (Settings → Data)
| ID | Check | Expected |
|---|---|---|
| 7.12 | Fresh install, tap Restore | "No automatic backup found" (or a restore of 0 if the file was already written; note which) |
| 7.13 | With items, confirm `$BACKUP` exists and contains them (`jq '.items|length' "$BACKUP"`) | Count = live items |
| 7.14 | Restore with data already present | 0 new items (dedupe); no duplicates |
| 7.15 | Tap Restore twice quickly | Second tap is disabled or reports "already restored"; no duplicates |
| 7.16 | **Empty-DB recovery** (the case the backup exists for): with items and a backup present, terminate the app, delete `skip.db` (keep `$BACKUP`), relaunch, then Restore | All items come back. Also verify `$BACKUP` was **not** overwritten with an empty list on that launch (regression check, this was broken) |
| 7.17 | Corrupt the backup (`echo '{bad' > "$BACKUP"`), Restore | Localized error snackbar, spinner clears, no crash |
| 7.18 | Restored items with photos | Records restored; photos may be missing → placeholder, no crash |

---

## 8. Insights

| ID | Check | Expected |
|---|---|---|
| 8.1 | No activity | Empty state |
| 8.2 | This month's cards | Saved/spent **this month only**, price × quantity, pondering excluded |
| 8.3 | 6-month chart | 6 bars pairs, oldest → newest, current month last; months with no data show zero |
| 8.4 | Back-date items (terminate app, `update items set created_at=...` to 2, 5, and 7 months ago, including across a **year boundary**) | Items land in the right month; the 7-month-old one is not in the chart but is in all-time home totals |
| 8.5 | Axis labels | Compact currency format (`$1.2k` / `1,2k €`) |
| 8.6 | Both themes, all languages | Legend and month labels readable and localized |

---

## 9. Coin flip

| ID | Check | Expected |
|---|---|---|
| 9.1 | Flip | 3D flip animation, result shown, haptics **[device]**, confetti where designed |
| 9.2 | Rapid repeated taps | No stacked animations, no errors |
| 9.3 | Leave the screen mid-flip | No `setState after dispose` in logs |
| 9.4 | DB untouched | Row count and `$BACKUP` unchanged by flipping |

---

## 10. Persistence and lifecycle

| ID | Check | Expected |
|---|---|---|
| 10.1 | Set Y2K + Italian + EUR + wage + sound off; terminate; relaunch | All settings and items persist |
| 10.2 | Background for a while, resume on each screen | State intact, no reload flicker |
| 10.3 | Rotate to landscape on every screen (Info.plist allows landscape on iPhone) | No overflow; dialogs usable with the keyboard up |
| 10.4 | Largest Dynamic Type size (Settings → Accessibility → Larger Text) | Text scales without clipped buttons or overflow errors |
| 10.5 | Simulator in Dark Mode | App keeps its own themes and stays readable |
| 10.6 | VoiceOver on home, entry, detail | Logo, icons, toggle options and FAB have meaningful labels |
| 10.7 | **Upgrade install**: check out an older commit with schema < 6 (e.g. `git log -- lib/data/database_helper.dart`), install it, add items (with and without photos, a link, a trashed one), then install the current build over it **without uninstalling** | Migration succeeds; all data, statuses, quantities and photos intact |

---

## 11. Home Screen and Lock Screen widgets

Widget kinds: `SkipWidget` (small, medium, lock-screen rectangular and inline) and `SkipMottoWidget` (lock-screen rectangular). Data comes from app group `group.com.skip.finance`.

| ID | Check | Expected |
|---|---|---|
| 11.1 | Add small and medium `SkipWidget` to the Home Screen; rectangular + inline to the Lock Screen; add `SkipMottoWidget` | All render; no blank/placeholder state once the app has run |
| 11.2 | Values | Show **this month's** saved/spent (not all-time), matching Insights' this-month cards; saved/spent bar split proportional |
| 11.3 | Add / change status / edit price / delete / restore an item, then go Home | Widget updates each time |
| 11.4 | Switch currency, aesthetic and language | Widget format, look, labels and motto language/voice follow |
| 11.5 | `plutil -p "$WIDGET_PLIST"` | Keys `saved`, `spent`, `totalsMonth` (= current `yyyy-MM`), `currencyCode`, `aesthetic`, `savedLabel`, `spentLabel`, `mottos`, `mottoEmpty` present and correct |
| 11.6 | Month rollover: terminate the app, set `totalsMonth` to last month (`plutil -replace totalsMonth -string 2026-08 "$WIDGET_PLIST"`), force a widget reload (remove/re-add the widget or wait for the timeline) | Widget shows **zeros**, not stale totals |
| 11.7 | Open the app after 11.6 | Widget re-syncs to real values and the current month |
| 11.8 | No activity this month | Empty bar + the "empty" motto |
| 11.9 | Tap the widget | Opens the app |
| 11.10 | **[device]** Leave overnight | Motto rotates daily; widget still correct next day |

---

## 12. Offline and privacy

| ID | Check | Expected |
|---|---|---|
| 12.1 | Disconnect the Mac's network, run every flow above | Everything works (link opening fails gracefully in Safari only) |
| 12.2 | Search logs for any HTTP traffic from the app | None |
| 12.3 | Photos | Only stored under the app's own Documents; nothing written to the Photos library |

---

## Report format

Finish with one Markdown report:

1. **Summary**: counts of PASS / FAIL / BLOCKED, and the top issues in one line each.
2. **Results table**: `ID | Result | Notes / evidence path`, for every check above.
3. **Failures**: for each, give the steps to reproduce, expected vs actual result, screenshot path, relevant log lines, severity (critical / major / minor / cosmetic), and a pointer to the likely code location if you can find it.
4. **Anything unexpected** that no check covered.

Do not fix anything. Report only.
