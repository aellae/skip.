# Skip! — iOS QA report (2026-09-23)

## 1. Summary

**Device:** iOS Simulator, iPhone 16, iOS 26.5 (`2B6FB822-…`), system language `en-US` (Italian region). No physical iPhone was connected, so every **[device]** check is BLOCKED.
**Builds:** current `master` @ `3d6ecb2`, debug simulator build for the main pass. The release `--no-codesign` build was only compiled, not run. The v4 → v6 upgrade test used `05f5c35`, the oldest commit that already has the `com.skip.finance` bundle ID. Older commits such as `6763a7b` use `com.elenatarantino.skip`, so they install as a separate app instead of upgrading.
**How it was driven:** Simulator taps via `cliclick`, plus `simctl` for screenshots, privacy, appearance and text size. Section 10.3 uses the Simulator's rotate menu. DB and plist state was checked with `sqlite3`, `plutil` and `defaults`.

| PASS | FAIL | PARTIAL | BLOCKED | NOT RUN | Total |
|---|---|---|---|---|---|
| 95 | 4 | 9 | 3 | 4 | 115 |

**Top issues**
1. **Item detail overflows at the largest Dynamic Type size**: "RIGHT OVERFLOWED BY 270 PIXELS" on the amount row (`50,00 € (25 …`). At the same size, labels across the app are cut off: the language buttons read "E…", "It…", "F…", "D…" (at first Deutsch showed only its flag), and the Insights chart is squeezed by its y-axis labels.
2. **Coin flip overflows in landscape**: "BOTTOM OVERFLOWED BY 48 PIXELS" (the screen's `Column` doesn't scroll).
3. **Insights y-axis labels are cut off in French with the Minimal theme**: `3,0k…` and `2,0k…` (the "€" is dropped). The reserved width is too narrow for the Playfair/Inter labels.
4. **Edit-details price error is unreadable**: "Price must be gr…" is cut off inside the narrow price field of the edit dialog.
5. **The iOS temp-copy cleanup from `4b55b09` doesn't work on iOS**: every picked photo leaves an `image_picker_*.jpg` copy in the app's `tmp/`. The helper only deletes inside `getTemporaryDirectory()` (Library/Caches), but image_picker_ios writes to `NSTemporaryDirectory()` (`tmp/`).
6. **The camera and photo permission prompts aren't localized and say "SKIP"** instead of "Skip!". With no camera (Simulator), the only feedback is image_picker's native English alert, not the app's localized snackbar.

**Verified regressions:** 5.6 (comma price in edit details) PASS, 5.9 (quantity kept when editing the link) PASS, 7.16 (empty-DB launch doesn't overwrite the backup) PASS, even with the backup throttle backdated so a write was due.

## 2. Results

Evidence paths are relative to the session scratchpad `…/scratchpad/qa/shots/`, which is temporary (see the note at the end).

| ID | Result | Notes / evidence |
|---|---|---|
| 1.1 | PASS | No issues found |
| 1.2 | PASS | 273 tests passed, including `contrast_test.dart` |
| 1.3 | PASS | Exit 0, 0 of 92 files changed |
| 1.4 | PASS | No matches |
| 1.5 | PASS | Both builds succeed and both contain `PlugIns/SkipWidgetExtension.appex`. The release build's `pod install` rewrote `ios/Podfile.lock` (dropped the dev-only `integration_test` pod); I restored the committed file afterwards |
| 1.6 | PASS | Clean uninstall, then `flutter run`; launches with no errors |
| 2.1 | PASS | Minimal theme, "Skip!" logo, empty state, motto, `$0.00` ×2 (`2.1_en.png`). Cosmetic: the empty state says "Tap + …" but the FAB shows a camera icon |
| 2.2 | PASS | Fresh install with device language set to `it-IT`: Italian UI (`2.2_it.png`). With `en-US`: English. The Simulator's language was restored afterwards |
| 2.3 | PASS | EN → `$0.00`, IT → `0,00 €` |
| 2.4 | PARTIAL | After relaunch, Y2K + Italian + EUR show on the first app frame I captured (`10.1_relaunch.png`). The very first frame can't be told apart from the iOS resume snapshot |
| 2.5 | PASS | Coin flip, Insights, Settings and the FAB each open the right screen; back returns home |
| 3.1 | PASS | PHPicker, no permission prompt. A 4800 px source is stored at 2000 px (160 KB). Path in the DB is `skip_images/…`. See "Anything unexpected" for leftover `tmp/` copies |
| 3.2 | PASS | After `simctl privacy reset`, Camera → "Don't Allow" shows the snackbar "Qualcosa è andato storto. Riprova." The spinner clears and no file is written (`3.2_denied.png`). There is no hint to enable the camera in Settings |
| 3.3 | PARTIAL | No crash, spinner clears, no file written. But the feedback is image_picker's native English alert, not the app's snackbar (`3.3_camera_after.png`). **[device]** camera: BLOCKED |
| 3.4 | PASS | Cancel: preview unchanged, no new file |
| 3.5 | PASS | Preview shows B; A's file is deleted |
| 3.6 | PASS | Closing with a picked photo: `skip_images` goes from 1 file to 0 |
| 3.7 | PASS | `image_path` NULL; card shows the placeholder |
| 3.8 | PASS | "Enter a price.", nothing saved, no pulse |
| 3.9 | PASS | "Price must be greater than zero." |
| 3.10 | PASS | `12,50` is stored as `12.5`. A dot is accepted in the field (`1.23`). The Italian decimal keypad shows a `,` key (`land_editdialog.png`). Input was sent as hardware key events |
| 3.11 | PASS | `1.234ab..,5` becomes `1.23` |
| 3.12 | PASS | "Total: $50.00" for 12.50 × 4, then ×3. − is greyed out at 1 |
| 3.13 | PASS | "≈ 4.0 hrs of work" for $25 × 2 at $12.50/hr; updates live |
| 3.14 | PASS | `notaurl`, `ftp://x.com` and `example.com` are all rejected with "Enter a valid link" |
| 3.15 | PASS | `https://example.com/p?id=1` stored |
| 3.16 | PARTIAL | Trailing spaces are trimmed. Empty → NULL was confirmed via edit details (5.5), not on the entry form. iOS "smart punctuation" turned a double space into ". " (system behavior) |
| 3.17 | NOT RUN | The hardware keyboard was connected, so the on-screen keypad wasn't up while I tested the form |
| 3.18 | PASS | Checkmark pulse (`3.18_pulse*.png`), `is_saved=1`, screen closes, totals update |
| 3.19 | PASS | Confetti plus a shimmer across the pill; the label stays readable (`3.19_f*.png`); saved. Haptics and sound **[device]**: BLOCKED |
| 3.20 | PASS | `is_saved` NULL; excluded from both totals |
| 3.21 | PASS | `is_saved=0`; added to Total Spent |
| 3.22 | PASS | A triple-click on "Bought It" inserted exactly one row |
| 3.23 | PASS | Tap Resisted and immediately go Home: 32 → 33 rows, no stuck spinner on return |
| 4.1 | PASS | Home totals match `sum(price*quantity)` by status (e.g. 2,420.46 / 2,778.72 with 33 rows) |
| 4.2 | PASS | Newest first, 2-column masonry |
| 4.3 | PASS | Ellipsis on long titles, status dot, colored amount, `(×4)`, hours line |
| 4.4 | PASS | Y2K bolt, bag and hourglass badges match status |
| 4.5 | PASS | Pull to refresh works with no skeleton flash (`4.5_refresh.png`) |
| 4.6 | PASS | Summary card opens Insights |
| 4.7 | PASS | 32 items, 30 of them with 2000 px photos. 30 fast flings: memory steady at 535–563 MB (debug build) with no growth, no warnings |
| 4.8 | PASS | Deleting `seed_29.jpg` by hand: card shows the placeholder, no crash (`4.8_home.png`) |
| 4.9 | PARTIAL | Clean mid-transition frame (`4.9_hero.png`), but only tested on an item without a photo |
| 5.1 | PASS | `$37.50 ($12.50 × 3)`, hours, date, toggle, coin, link section (`5.1_detail.png`) |
| 5.2 | PASS | Resisted → Pondering → Bought → Resisted: DB updates each time and so does the widget plist; Y2K confetti on Resisted |
| 5.3 | PASS | Tapping the selected status: DB file mtime unchanged, no spinner |
| 5.4 | PASS | Title, price and quantity all persist (`Edited`, 9.99, 4) |
| 5.5 | PASS | `typeof(title)` = null; no title line shown |
| 5.6 | PASS | `9,99` saved as 9.99 (regression fixed) |
| 5.7 | FAIL | The error appears but reads "Price must be gr…" (`5.7_zero.png`). Cancel leaves the item unchanged. Minor |
| 5.8 | PASS | Invalid link → error; valid → link row with "Visit product page" and an edit icon |
| 5.9 | PASS | Adding, editing and removing the link on a qty-3 item: quantity stays 3 (regression fixed) |
| 5.10 | PASS | Opens Safari (external); the "◀ Skip!" breadcrumb returns to the same detail screen |
| 5.11 | PASS | Remove → `purchase_url` NULL |
| 5.12 | PASS | New photo shown; the old file is deleted |
| 5.13 | PASS | "No photo" placeholder; file deleted |
| 5.14 | PASS | Photo added to an item without one; relative path |
| 5.15 | PARTIAL | Camera on the Simulator: native alert, no crash, no leftover file. Permission denied on the detail screen wasn't tested separately |
| 5.16 | PASS | Coin flip opens; back returns to the same detail screen |
| 5.17 | PASS | Cancel: `deleted_at` stays NULL |
| 5.18 | PASS | `deleted_at` set; the image file is still on disk |
| 5.19 | PASS | Detail screen after switching IT, DE, FR, EUR and Minimal/Y2K: all reflected |
| 6.1 | PASS | "Trash is empty." |
| 6.2 | PASS | Newest-deleted first; thumbnail, total `$39.96`, deletion date, retention notice (`6.2_trash.png`) |
| 6.3 | PASS | Restored with the same status, quantity and link; widget `saved` updated |
| 6.4 | PASS | 31 days old: row hard-deleted and its image removed on relaunch |
| 6.5 | PASS | 29 days old: still in Trash |
| 7.1 | PASS | Animated re-theme, logo switch; each preview tile keeps its own theme |
| 7.2 | PARTIAL | Home, entry, detail, Insights, coin flip and Settings checked in both themes; Trash and Privacy only in Y2K. Hardcoded colors: none seen |
| 7.3 | PASS | "You have changed the icon for 'Skip!'" alert; the Home Screen icon is Y2K |
| 7.4 | PASS | Y2K icon persists after relaunch; switching to Minimal shows the alert with the primary icon |
| 7.5 | PASS | EN, IT, FR and DE translated, including snackbars, dialogs, empty states and widget labels/mottos. Framework-level strings in English: permission prompts (Info.plist), image_picker's no-camera alert, widget gallery title (follows the system language). French axis cut-off is logged under 8.5 |
| 7.6 | PASS | Dialog shown; Cancel keeps USD; Continue switches to EUR; the widget follows |
| 7.7 | NOT RUN | |
| 7.8 | PARTIAL | `12,5` saved as "$12.50 / hr"; hours lines on cards, detail and entry. Edit and remove not run. Cosmetic: IT shows "12,50 € /ora" (space only before the slash) vs EN "$12.50 / hr" |
| 7.9 | BLOCKED | **[device]** |
| 7.10 | PASS | 2 resisted, avg $44.98 = 89.96 / 2; 0 and $0.00 on a fresh install |
| 7.11 | PASS | Readable in DE/Y2K (`de_privacy.png`). The "Read full policy" link (GitHub) wasn't opened |
| 7.12 | PASS | "No automatic backup found yet." |
| 7.13 | PASS | `jq '.items|length'` = live items (4, then 2 after purge/relaunch) |
| 7.14 | PASS | "Imported 0 items", no duplicates |
| 7.15 | PASS | Triple-click on Restore: one result, no duplicates |
| 7.16 | PASS | Deleted `skip.db` (kept the backup) and backdated `skip_last_auto_backup_at` so a write was due. Relaunched: the backup was **not** overwritten (byte-identical). Restore brought both items back |
| 7.17 | PASS | `{bad` gives a localized snackbar ("Diese Datei ist kein gültiges JSON." in DE), spinner clears |
| 7.18 | NOT RUN | The restored items had no photos at the time |
| 8.1 | PASS | "No trends to show yet." |
| 8.2 | PASS | This month only, price × qty, pondering excluded (matches SQL) |
| 8.3 | PASS | Apr → Sep, current month last, zero months empty |
| 8.4 | PASS | Items backdated to Jul, Apr, Feb and 31 Dec 2025 land in the right months; Feb and Dec are outside the chart but included in the all-time home totals. A year boundary *inside* the 6-month window can't happen in September without changing the clock |
| 8.5 | FAIL | Compact format is right in Y2K and IT (`3,0k €`), but in **FR + Minimal** the labels are cut off: `3,0k…`, `2,0k…` (`fr_insights.png`). Minor |
| 8.6 | PASS | Legend and months localized (Apr/Mag/Giu, Apr./Mai/Juni, Avr./Mai/Juin) |
| 9.1 | PASS | 3D flip, result, confetti (`9.1_*.png`). Haptics **[device]**: BLOCKED |
| 9.2 | PASS | Rapid taps: no stacked animations, nothing in the log |
| 9.3 | PASS | Leaving mid-flip: nothing logged (`flutter run` attached) |
| 9.4 | PASS | Row count and backup md5 unchanged |
| 10.1 | PASS | Y2K + IT + EUR + wage + sound off persist after terminate and relaunch |
| 10.2 | PARTIAL | Resume from Safari (detail) and from Home mid-save (entry) are fine; not every screen tested |
| 10.3 | FAIL | Coin flip: **BOTTOM OVERFLOWED BY 48 PIXELS** (`land_coin.png`). Home, entry, Settings, Insights, detail and the edit dialog with the keypad up are fine (Cancel/Save still reachable) |
| 10.4 | FAIL | At `accessibility-extra-extra-extra-large`, detail shows **RIGHT OVERFLOWED BY 270 PIXELS** (`a11y_detail.png`). Also: language buttons cut off to "E…/It…/F…" with Deutsch at first showing only its flag (`a11y_settings.png`); card amounts cut off (`50,0…`); the two summary cards get very different font sizes (`a11y_home.png`, `a11y_insights.png`); the chart is squeezed. Major |
| 10.5 | PASS | Dark Mode: both themes keep their own look (`dark_*.png`) |
| 10.6 | BLOCKED | VoiceOver can't be driven here. Code check: FAB (`logAnItem`), quantity stepper (`Semantics(label:)`), coin button, delete/edit tooltips and photo `semanticLabel` are present |
| 10.7 | PASS | `05f5c35` (v4, same bundle ID) with 4 items (resisted with photo, bought with link + category, pondering, trashed), then installed current over it: `user_version` 6, `quantity` = 1, `image_path` nullable, all fields and photos intact, trashed item still in Trash. v4 required a photo, so "without photo" doesn't apply |
| 11.1 | PASS | Small and medium Home Screen widgets, Lock Screen rectangular, inline and `SkipMottoWidget` all render with real data |
| 11.2 | PASS | This-month values (1,929.41 / 2,204.78) match Insights; the bar split is proportional |
| 11.3 | PARTIAL | The widget plist updates on add, status change, delete and restore. The visible widget was only compared after reopening the app |
| 11.4 | PASS | EUR, Italian labels and mottos, Y2K look all follow |
| 11.5 | PASS | All 9 keys present and correct, plus `languageCode` |
| 11.6 | PASS | `totalsMonth` = `2026-08` gives `0,00 €` ×2 and an empty bar (`11.6_gallery.png`) |
| 11.7 | PASS | After opening the app: `2026-09` and real values (`11.7_home.png`) |
| 11.8 | PASS | Empty bar plus "Ancora zero. Vai, skippa qualcosa!" |
| 11.9 | PASS | Tapping the widget opens the app |
| 11.10 | BLOCKED | **[device]** |
| 12.1 | NOT RUN | I didn't disconnect the Mac's network (it would have disrupted the machine). See 12.2 for the network evidence |
| 12.2 | PASS | 51k log lines: no outgoing connections from `Runner` (only OS launch bookkeeping). Release frameworks have no HTTP client |
| 12.3 | PASS | The simulator's Photos library only contains the 4 seeded images plus the ones that were already there |

## 3. Failures

### F1. Item detail overflows at the largest text size (10.4), major
- **Steps:** `xcrun simctl ui booted content_size accessibility-extra-extra-extra-large`, Minimal, Italian, EUR. Open an item with quantity > 1 (e.g. "Y2K resist", 25,00 € × 2).
- **Expected:** text scales with no clipping or overflow. **Actual:** yellow/black stripes, "RIGHT OVERFLOWED BY 270 PIXELS", on the total + `(unit × qty)` row.
- **Evidence:** `a11y_detail.png`. It wasn't in the log: by then the app had been relaunched without `flutter run` attached (see the note on logging).
- **Likely location:** [item_detail_screen.dart:398](../../lib/features/home/item_detail_screen.dart#L398). The `Row` with the total and the quantity text has no `Flexible`/`Wrap`.
- **Same run:** language buttons cut off to "E…", "It…", "F…" (Deutsch at first showed only its flag); home card amounts cut off (`50,0…`, `39,9…`); summary cards with very different font sizes; the Insights chart squeezed to a sliver by the y-axis labels (`a11y_*.png`).

### F2. Coin flip overflows in landscape (10.3), minor
- **Steps:** open Coin Flip, then Device → Rotate Left.
- **Expected:** no overflow. **Actual:** "BOTTOM OVERFLOWED BY 48 PIXELS" below the coin (`land_coin.png`).
- **Likely location:** [coin_flip_screen.dart:118](../../lib/features/coin_flip/coin_flip_screen.dart#L118), a `Column` that isn't in a scroll view or `LayoutBuilder`.

### F3. Insights y-axis labels cut off in French + Minimal (8.5), minor
- **Steps:** Minimal theme, Français, EUR, with 1k+ totals. Open Insights.
- **Expected:** `3,0k €`. **Actual:** `3,0k…`, `2,0k…`; only `1,0k €` fits (`fr_insights.png`). Y2K and Italian render fine.
- **Likely location:** [monthly_bar_chart.dart:114](../../lib/features/insights/widgets/monthly_bar_chart.dart#L114), `reservedSize: textScaler.scale(44)`, combined with `TextOverflow.ellipsis` at line 129.

### F4. Edit-details price error cut off (5.7), minor
- **Steps:** detail → pencil → price `0` → Save.
- **Expected:** a readable "Price must be greater than zero." **Actual:** "Price must be gr…" (`5.7_zero.png`). The price field shares its row with the quantity stepper. German will be worse.
- **Likely location:** the edit-details dialog in `item_detail_screen.dart` (the price `TextFormField` next to `QuantityStepper`). Allowing `errorMaxLines` or putting the stepper below the field would fix it.

## 4. Anything unexpected

1. **Picker temp files pile up on iOS.** Each gallery pick leaves `tmp/image_picker_<UUID>.jpg` (e.g. 160 KB and 113 KB after two picks). `FileHelper.deletePickerTempFile` ([file_helper.dart:73](../../lib/core/utils/file_helper.dart#L73)) only deletes inside `getTemporaryDirectory()`, which is `Library/Caches` on iOS, while image_picker_ios writes to `NSTemporaryDirectory()` (`tmp/`). So the fix in `4b55b09` is a no-op on iOS. iOS may purge `tmp/` eventually. Minor.
2. **Permission prompts:** `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` in `ios/Runner/Info.plist` say "SKIP needs…" (not "Skip!") and are English-only (no `InfoPlist.strings` / `.xcstrings`), so Italian, French and German users see English prompts.
3. **Camera unavailable:** image_picker's own English `UIAlertController` shows instead of the app's localized error snackbar (3.3, 5.15).
4. **Camera denied:** the generic "Something went wrong" snackbar gives no hint to enable the camera in Settings.
5. **Item detail, "Flip a coin" button:** a faint square-cornered tint shows behind the rounded pill (Y2K; `5.1_detail.png`). Cosmetic.
6. **Lock Screen inline widget** cuts off 4-digit totals: "Skip! $1,929.41 · $2,204…". Cosmetic; inline widgets are width-limited.
7. **Entry form:** at the default text size on iPhone 16, the decision toggle (the only way to save) sits just below the fold, with the pills cut at the screen edge. Users must scroll to find it. Minor UX.
8. **Summary cards** are different heights when one label wraps ("This Month's Savings" vs "This Month's Spent" in EN Insights). Cosmetic.
9. **Empty-state copy** says "Tap +", but the FAB is a camera-plus icon.

**Note on logging:** `flutter run` was attached (logs in `logs/run1.txt`) from 1.6 through 6.4. After the app was terminated for the DB edits in 6.4, later launches went through `simctl launch`, and Flutter error output from those launches wasn't captured. The two overflow failures (F1, F2) were detected from the debug-mode overflow stripes in screenshots. There may be other Flutter errors from that phase that I couldn't see.

**Note on evidence:** screenshots and logs are in the session scratchpad (`/private/tmp/claude-501/…/scratchpad/qa/`), which is temporary. Copy anything you want to keep.

**Simulator state after the run:** Skip! is freshly installed (empty data, English). The widgets I added were removed by the uninstall. Appearance, text size, language and locale are back to their original values. The 4 seeded photos are still in the simulator's Photos library.
