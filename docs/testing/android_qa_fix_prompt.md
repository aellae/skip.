# Prompt — Fix the findings from the Android QA report (2026-09-23)

You are fixing bugs in **Skip!**, a Flutter app (repo root: `/Users/elle/Desktop/skip.`). Read `CLAUDE.md` and `docs/NEW_FEATURE_GUIDE.md` first; they describe the architecture, schema (v6), and project rules (100% offline, dual theme, soft delete, no hardcoded styling). Then read the source report: `docs/testing/android_qa_report_2026-09-23.md`. Each item below refers to its IDs (F1–F11, check IDs like 7.12).

The report's line numbers were taken at commit `ff2c4f8`. Verify each cause in the code before changing anything; if the code doesn't match the report, say so instead of guessing.

---

## 0. Ground rules

- **No network code, no new remote SDKs.** Flutter SDK packages (`flutter_localizations`) and `intl` are fine because they're local.
- **Both themes.** Every UI change must render correctly in Minimal and Y2K. Take colors, radii and fonts from `Theme.of(context)` / `SkipThemeExtension`, never inline.
- **All four languages.** Every new user-facing string goes in `app_strings.dart` with EN/IT/FR/DE values. Don't hardcode English.
- **Don't start the Android emulator.** Use `flutter analyze`, `flutter test`, and the iOS Simulator. Changes that only apply to Android (manifest, Kotlin widget) are verified by building (`flutter build apk --debug`) and, if a physical device is connected over adb, on that device only.
- **Keep changes small and on-pattern.** Match the surrounding code's naming, comment density and structure. Don't refactor unrelated code.
- **One commit per fix group** (e.g. `fix(settings): format average-saved tile with the selected currency`). Don't push.

---

## 1. Must fix (Major)

### F1 — "Average saved per item" is always USD (check 7.12)
`settings_screen.dart` (~line 110) builds the `_StatTile` for `averageSavedPerItem` without a `formatter`, so `AnimatedCountUp` falls back to `formatCurrency` with its USD default (`animated_count_up.dart` ~line 70).
- Pass a formatter that uses the selected currency and locale (see how the Home summary cards format totals and reuse that).
- Also check whether the USD fallback in `AnimatedCountUp` is a trap for other callers. If it is, make it currency-aware or require the formatter, whichever is less invasive.
- Add or extend a widget test: EUR + IT shows `37,50 €`, and USD + EN shows `$37.50`.

### F3 — Entry lost on process death during camera (check 3.7)
When Android kills the process while the camera is open, the app cold-starts on Home, the new photo is lost, and any previously copied photo stays orphaned in `skip_images`.
- Implement `ImagePicker().retrieveLostData()` (Android only) so a photo returned after process death isn't lost. Look at how `item_entry_screen.dart` currently picks and copies photos and route the recovered file through the same copy-to-documents path.
- Decide how the user gets back to the entry form. Minimum acceptable fix: on startup, if lost data exists, open the Item Entry screen with the recovered photo attached. Restoring the typed price/title is optional; if you use `RestorationMixin` or persist a draft, keep it local and simple.
- Orphan cleanup: a photo copied into `skip_images` that never got attached to a saved row must not persist forever. Extend the existing purge (`purgeExpiredTrash`, run from `HomeScreen.initState`) or add a similar pass that deletes files in `skip_images` that no row (live or trashed) references. Make sure it can never delete a file referenced by any row, and add a unit test for that.

### F9 — Unlabeled controls (check 10.6)
Add localized semantic labels (tooltip or `Semantics(label:)`, whichever fits the widget) to:
- Home FAB ("Log an item")
- Quantity − / + in `quantity_stepper.dart` ("Decrease quantity" / "Increase quantity")
- Detail screen photo-change camera button
- Entry photo preview after a photo is picked (e.g. "Photo, tap to change")
- Coin-flip coin button ("Flip the coin")

Add a widget test that checks these labels are present (`find.bySemanticsLabel`).

### Unexpected #1 — Android Auto Backup uploads app data
`AndroidManifest.xml` has no `allowBackup` or `dataExtractionRules`, so the DB, prefs and photos can go to Google Drive. That contradicts the offline rule and the in-app privacy copy.
- **Decided: turn Android backup off completely** (cloud backup and device-to-device transfer). Keep the privacy copy as it is. This is a deliberate product choice: users switching phones start with an empty app. Don't add a partial exception for device transfer.
- Set `android:allowBackup="false"` and add `android:dataExtractionRules` (API 31+) and `android:fullBackupContent` (older APIs) XML that exclude everything, for both cloud backup and device transfer.
- Confirm the merged release manifest (`build/app/intermediates/merged_manifests/...` or `aapt dump xmltree`) has `allowBackup=false`.

---

## 2. Should fix (Minor)

### F2 + F8 — Overflow in DE and at large font sizes (checks 7.7, 10.4)
- `_StatTile` (settings_screen.dart ~line 500): wrap the label in `Expanded`/`Flexible` so it wraps instead of overflowing; let the value scale down (`FittedBox(fit: BoxFit.scaleDown)`) rather than clip.
- At font scale 2.0 (see `shots/10.4_maxfont.png` in the report): summary cards, theme cards, the decision toggle ("Resisti/to!") and the Insights axis break mid-word or truncate. Fix each so words wrap whole or scale down. Don't clamp the system text scale app-wide.
- Add a widget test that pumps Settings and Home in German with `textScaler: TextScaler.linear(2.0)` and asserts no overflow exceptions (`tester.takeException()` is null).

### F4 — Y2K "Resisted!" celebration invisible on new items (check 3.20)
`decision_toggle.dart` (~lines 73–90) starts confetti/shimmer and calls `onChanged` at once; `item_entry_screen.dart` (~lines 135–158) pops as soon as the insert finishes, so nothing is visible and the sound may be cut off.
- **Decided approach: wait before popping.** Only in Y2K after Resisted!, wait for the celebration (about 1–1.3 s; the shimmer timer is 1300 ms, so reuse that duration rather than a new magic number) before `Navigator.pop`. Minimal, Bought and Pondering stay instant. Don't move the celebration to Home.
- Save first, then wait, then pop: the row must be persisted before the delay so nothing is lost if the user leaves.
- During the wait, block further input: taps on the toggle must not start a second save (check 3.23: rapid taps create one row), and Back must neither pop twice nor throw (`mounted` check after the delay, `PopScope` or equivalent).
- Make sure the SFX player isn't disposed before the cue finishes.

### F5 — Unlocalized strings (checks 5.19, 6.2, 7.7, 8.6)
- `date_formatter.dart` is English-only: dates like "Sep 23, 2026" and the Insights chart months ("Apr May …") show in English in every language. Format with the app's selected locale (`AppLocale`), not the device's. Use `intl`'s `DateFormat` with the app locale, or localized tables in `app_strings.dart` if you'd rather not add `intl`. Check that `intl` locale data is initialized if needed.
- `MaterialApp` in `main.dart` (~line 98) has no `localizationsDelegates` / `supportedLocales` / `locale`, so Material tooltips ("Back", "Close") and the text-selection toolbar stay English. Add `flutter_localizations` and wire `locale` to the `LocaleProvider`.
- Translate the Android widget picker description ("This month's saved vs. spent totals.") with `values-it`, `values-fr`, `values-de` string resources.
- Update tests that assert English dates.

### F6 — Widget month follows device locale (check 11.5)
`SkipHomeWidgetProvider.kt` (~line 142) uses `Locale.getDefault()`. Write the app language code into `HomeWidgetPreferences` wherever the widget data is already synced from Dart, read it in Kotlin, and use it for the month name and the uppercase calls. Fall back to `Locale.getDefault()` if the key is missing (widget data written by an older build).
Check whether the iOS widget has the same issue. If it does, fix it the same way; if not, say so.

### F7 — Landscape add-link dialog overflows with the keyboard (check 10.3)
Make the add/edit link dialog content scrollable (`SingleChildScrollView` / `scrollable: true` on `AlertDialog`) so the field stays visible with the keyboard up in landscape. Check the other text-input dialogs (price edit, wage editor) for the same issue.

---

## 3. Cosmetic / low effort

- **F10 — landscape cutout (2.7):** body content ignores the left display cutout in landscape. Wrap the affected screen bodies in `SafeArea` (or apply `MediaQuery.padding`) horizontally; start with Home.
- **F11 — formatting (1.3):** run `dart format lib test` last, after all other changes.
- **Branding copy:** the privacy/support copy and backup error strings in `app_strings.dart` still say "SKIP". Change them to "Skip!" (all four languages). The code comments that say "SKIP" can stay.
- **5.6:** the price-edit dialog prefills `203.00` with a dot under IT/EUR. Prefill using the locale's decimal separator.
- **Stale validator message:** "Il prezzo deve essere maggiore di zero." stays after typing a valid value. Use `autovalidateMode: AutovalidateMode.onUserInteraction` after the first failed submit, or clear the error on change.
- **Sound row:** tapping the "Effetti sonori" label should toggle the switch too (`SwitchListTile` or an `InkWell` on the row).
- **Entry toggle:** before any choice, "Pondering" looks selected (filled). Show all three as unselected until the user taps one.
- **Auto-backup throttle** is in memory only, so the backup is rewritten on every cold start. Persist the last-write timestamp (SharedPreferences) so the 10-minute throttle survives restarts.
- **image_picker cache leftovers:** after a photo is copied into `skip_images` (or the pick is cancelled), delete the temporary source file if it's inside the app's cache directory. Never delete files outside app storage.

---

## 4. Leave alone (report, don't change)

- Native launch window is plain white in Y2K (2.4): it needs per-alias launch themes. Note it as a follow-up.
- Widget picker preview shows the Minimal icon when Y2K is active: OS-controlled, not fixable from the app.
- Trashed items aren't in backups (by design, 7.15). Old builds with applicationId `com.elenatarantino.skip` can't upgrade in place: expected.
- Items the report marked NOT RUN or BLOCKED (4.5–4.9, 5.5, 5.7, 7.4, 7.10, 7.11, 7.20, 10.7, 10.8, 11.9, 11.12, 11.13): not part of this task.

---

## 5. Verification

After each fix group, and once more at the end:

```bash
flutter analyze            # no issues
flutter test               # all pass, incl. the new tests
dart format --set-exit-if-changed lib test
flutter build apk --debug  # Android manifest/Kotlin changes compile
```

- On the **iOS Simulator**, check in both themes and at least EN and DE: Settings stat tiles (F1/F2), the Y2K celebration when saving a new Resisted item (F4), localized dates on Detail/Trash/Insights and the Back tooltip (F5), and the landscape link dialog (F7).
- If a physical Android device is connected (`adb devices`), rerun the report's failed checks on it: 3.7, 3.20, 7.7, 7.12, 10.3, 10.4, 10.6, 11.5, plus 2.7. For F3, use the report's repro (`adb shell am kill com.skip.finance` while the camera is open). Don't start the emulator.

---

## 6. Deliverable

Finish with a short report:

| ID | Status (FIXED / PARTIAL / NOT FIXED / LEFT ALONE) | What changed (files) | How it was verified |
|---|---|---|---|

List the commits, any new dependencies (with why), and anything you found that differs from the QA report. Name the checks that still need a manual rerun on a physical Android device.
