# Prompt — Fix the findings from the iOS QA report (2026-09-23)

You are fixing bugs in **Skip!**, a Flutter app (repo root: `/Users/elle/Desktop/skip.`). Read `CLAUDE.md` and `docs/NEW_FEATURE_GUIDE.md` first. They describe the architecture, schema (v6), and project rules (100% offline, dual theme, soft delete, no hardcoded styling). Then read the source report, `docs/testing/ios_qa_report_2026-09-23.md`. Each item below refers to its IDs: F1–F4, "Unexpected" items U1–U9 (numbered as in the report's section 4), and check IDs like 10.4.

The report's line numbers were taken at commit `3d6ecb2`. Check each cause in the code before changing anything. If the code doesn't match the report, say so instead of guessing.

---

## 0. Ground rules

- **No network code, no new remote SDKs.** Flutter SDK packages and `intl` are fine because they're local.
- **Both themes.** Every UI change must render correctly in Minimal and Y2K. Take colors, radii and fonts from `Theme.of(context)` / `SkipThemeExtension`, never inline.
- **All four languages.** Every new user-facing string goes in `app_strings.dart` with EN/IT/FR/DE values. Native iOS strings (Info.plist) get all four languages too.
- **Don't start the Android emulator.** Verify with `flutter analyze`, `flutter test` and the booted iOS Simulator. Don't use a physical device unless asked.
- **Don't clamp the system text scale app-wide.** Fix each layout so it wraps or scales down.
- **Keep changes small and on-pattern.** Match the surrounding code's naming, comment density and structure. Don't refactor unrelated code.
- **One commit per fix group** (e.g. `fix(detail): wrap the total row at large text sizes`). Don't push.

---

## 1. Must fix

### F1 — Layouts break at the largest Dynamic Type size (check 10.4), major
Repro: `xcrun simctl ui booted content_size accessibility-extra-extra-extra-large`, then open Home, Settings, Insights and an item with quantity > 1. Evidence: `a11y_*.png` in the report.
- **Detail total row:** [item_detail_screen.dart:398](../../lib/features/home/item_detail_screen.dart#L398) overflows by 270 px. The `Row` holding the total and `(unit × qty)` has no `Flexible`/`Wrap`. Let the quantity part wrap onto its own line (e.g. `Wrap` with a baseline-friendly spacing) instead of overflowing.
- **Settings language buttons:** labels cut off to "E…", "It…", "F…", "D…" (and at one point only the German flag showed). Let the label wrap whole words or scale down (`FittedBox(fit: BoxFit.scaleDown)`), and never drop the text entirely. Check the currency and aesthetic tiles the same way.
- **Home cards:** amounts cut off (`50,0…`, `39,9…`). Amounts must stay fully readable: scale down rather than use an ellipsis.
- **Summary cards (Home and Insights):** the two side-by-side cards end up with very different font sizes. `FitWordsText` (see commit `955c164`) sizes each card on its own. Make the pair use one shared size (the smaller of the two), and give the cards equal heights.
- **Insights chart:** the y-axis labels take almost the whole width and squeeze the bars to a sliver. Cap the reserved axis width (or scale the axis labels down) so the plot keeps a usable width. Coordinate with F3.
- Add a widget test that pumps Home, Settings, Insights and Item Detail (qty > 1) in German with `textScaler: TextScaler.linear(3.0)` (roughly the AX5 size) and asserts `tester.takeException()` is null.

### F2 — Coin flip overflows in landscape (check 10.3)
Evidence: `land_coin.png` in the report, "BOTTOM OVERFLOWED BY 48 PIXELS".
- [coin_flip_screen.dart:118](../../lib/features/coin_flip/coin_flip_screen.dart#L118) is a `Column` that isn't in a scroll view. Make the body fit short heights: e.g. `LayoutBuilder` + `SingleChildScrollView` with `ConstrainedBox(minHeight: …)` so it stays centered in portrait and scrolls in landscape. You could also shrink the coin to fit the available height.
- Check that the 3D flip and the confetti still look right in both orientations and that a flip mid-rotation doesn't throw.
- Add a widget test at a landscape phone size (e.g. 852×393) that asserts no overflow.

### U1 — Photo cleanup doesn't work on iOS (follow-up to `4b55b09`)
Every picked photo leaves an `image_picker_<UUID>.jpg` copy in the app's `tmp/`. `FileHelper.deletePickerTempFile` ([file_helper.dart:73](../../lib/core/utils/file_helper.dart#L73)) only deletes files inside `getTemporaryDirectory()`. On iOS that's `Library/Caches`, but image_picker_ios writes to `NSTemporaryDirectory()`, which is the container's `tmp/` (a sibling of `Library/`, not inside it). So the guard rejects every real path and nothing is ever deleted.
- Widen the allow-list to the directories image_picker actually uses, and nothing else:
  - Android: the cache directory (current behavior).
  - iOS: the container's `tmp/` directory. Get it reliably, e.g. `Directory.systemTemp` (which is `NSTemporaryDirectory()` on iOS), and check it resolves inside the app's own container, next to the documents directory's parent. Don't hardcode the string `tmp`.
- Keep the safety rule: **never delete a file outside the app's own temp or cache directories.** Files in `skip_images` and anything in Photos must stay untouched. Normalize and resolve symlinks before comparing (`/private/var` vs `/var` on iOS).
- Keep calling it from both pick sites (`item_entry_screen.dart` and `item_detail_screen.dart`). Also delete the temp file when the copy into `skip_images` fails, or when the screen was disposed mid-pick.
- Tests: extend `test/core/utils/file_helper_test.dart` and `test/test_helpers/fake_path_provider.dart`. Cover: a file in the iOS-style temp dir is deleted; a file in the cache dir is deleted; a file in documents/`skip_images` is **not** deleted; a path elsewhere is **not** deleted; `..` path tricks don't escape the allow-list.
- Verify on the Simulator: pick two photos from the gallery on the entry screen and once on the detail screen. `ls "$DATA/tmp"` must have no `image_picker_*` files afterwards (see the report's "Useful paths").

### U2 — Permission prompts say "SKIP" and are English-only
`ios/Runner/Info.plist` lines 38–41: `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` say "SKIP needs…" and aren't localized. `CFBundleLocalizations` already lists en/it/fr/de, but the project's `knownRegions` is only `en, Base` and there's no InfoPlist localization.
- Change the base strings to "Skip!" and keep them friendly, e.g. "Skip! needs camera access so you can snap a photo of something you're tempted to buy."
- Add localized versions for IT, FR and DE. Prefer an `InfoPlist.xcstrings` string catalog in `ios/Runner` (the widget target already uses `Localizable.xcstrings`, so follow that pattern). Or use `it.lproj/`, `fr.lproj/`, `de.lproj/InfoPlist.strings`. Register the file in the Runner target and add `it`, `fr`, `de` to `knownRegions` in `project.pbxproj`. Edit the pbxproj carefully: note from memory "iOS alternate icon pitfalls" that tooling has rewritten this file badly before, so review the diff by hand.
- Match the app's tone in each language (look at the existing IT/FR/DE strings in `app_strings.dart`).
- Also check `NSPhotoLibraryAddUsageDescription` isn't needed (the app never writes to Photos). Don't add it if unused.
- Verify: `flutter build ios --simulator --debug`, then for each of EN and IT: set the Simulator language, `xcrun simctl privacy booted reset all com.skip.finance`, reinstall, and trigger the camera prompt. Screenshot it. Restore the Simulator's language afterwards (`en-US`, `it-US`; locale `en_US@rg=itzzzz`).

---

## 2. Should fix

### F3 — Insights y-axis labels cut off in French + Minimal (check 8.5)
`3,0k…` / `2,0k…` instead of `3,0k €` (evidence `fr_insights.png`). The cause is at [monthly_bar_chart.dart:114](../../lib/features/insights/widgets/monthly_bar_chart.dart#L114): `reservedSize: textScaler.scale(44)` with `TextOverflow.ellipsis` at line 129.
- Size the reserved width from the widest label actually drawn, measured with a `TextPainter` using the theme's axis text style, the locale and the currency. Clamp it to a sensible maximum so F1's chart doesn't get squeezed. Don't use a hardcoded bigger number.
- Check all four languages × both currencies × both themes. `$1.2k` and `1,2k €` must never show an ellipsis.

### F4 — Edit-details price error cut off (check 5.7)
The error "Price must be greater than zero." shows as "Price must be gr…" because the price field shares a row with `QuantityStepper` in the edit dialog ([item_detail_screen.dart:753](../../lib/features/home/item_detail_screen.dart#L753)).
- Give the error room: `errorMaxLines: 2` (or 3) on the price field's `InputDecoration`, or move the stepper under the field. Check the entry form's price field too; it has the same row layout.
- Verify in German (the longest string) in both themes.

### U3 + U4 — Camera errors are unhelpful (checks 3.2, 3.3, 5.15)
- **No camera (U3):** image_picker_ios shows its own English "Error / Camera not available." alert and then returns `null` (see `FLTImagePickerPlugin.m`, around line 331, in the pub cache). The app can't localize that alert. Fix it on our side: when the device has no camera, don't offer the Camera option (or show it disabled with a localized reason). To find out if a camera exists, add a method to the existing native channel pattern (`app_icon_channel.dart` / `AppDelegate`) that returns `UIImagePickerController.isSourceTypeAvailable(.camera)`. Keep it iOS-only and default to "available" on other platforms.
- **Camera denied (U4):** the generic "Something went wrong" snackbar gives no guidance. When the `PlatformException` code is `camera_access_denied` (or `photo_access_denied`), show a localized message saying access is off, with a snackbar action that opens the app's Settings page. Use `UIApplication.openSettingsURLString` through the same native channel; `url_launcher` with `app-settings:` is also fine since it's local. Other errors keep the generic message.
- Apply both to the entry screen and the detail screen.

---

## 3. Cosmetic / low effort

- **U5 — detail "Flip a coin" button:** a faint square-cornered tint shows behind the rounded pill in Y2K (`5.1_detail.png`). Find the glow or shadow and clip it (or apply it) with the same border radius as the button.
- **U6 — Lock Screen inline widget** cuts off 4-digit totals: "Skip! $1,929.41 · $2,204…". In `ios/SkipWidget/SkipWidget.swift` (~line 281), use a more compact inline format when the full text is too long: e.g. compact currency (`$1.9K · $2.2K`) or `ViewThatFits` with a shorter fallback.
- **U7 — entry form:** at the default text size on iPhone 16, the decision toggle (the only way to save) sits just below the fold, with the pills cut at the screen edge. Make it visible without scrolling on a 393×852 screen: e.g. make the photo box shorter than full width (cap its height with the available space via `LayoutBuilder`), or pin the prompt + toggle to the bottom. Don't break the keyboard behavior (the fields must still scroll into view when focused).
- **U8 — summary cards** have different heights when one label wraps ("This Month's Savings" vs "This Month's Spent"). Covered by the F1 shared-size fix. Also make the pair equal height (`IntrinsicHeight` + `CrossAxisAlignment.stretch`, or similar).
- **U9 — empty-state copy** says "Tap + to snap…", but the FAB shows a camera-plus icon. Reword in all four languages (e.g. "Tap the camera button to…").
- **Wage format (7.8):** IT shows "12,50 € /ora" while EN shows "$12.50 / hr". Use the same spacing around the slash in every language.

---

## 4. Leave alone (report, don't change)

- The widget gallery's title and description follow the device language, not the app language. That's how iOS works.
- iOS "smart punctuation" turning a double space into ". " in the title field (3.16) is system behavior.
- Checks marked NOT RUN or BLOCKED in the report (3.17, 7.7, 7.9, 7.18, 10.6, 11.10, 12.1, and the **[device]** parts of 3.3, 3.19, 9.1) are not part of this task. Say in your report which of them your changes could affect.

---

## 5. Verification

After each fix group, and once more at the end:

```bash
flutter analyze                                   # no issues
flutter test                                      # all pass, incl. the new tests
dart format --output=none --set-exit-if-changed lib test
flutter build ios --simulator --debug             # includes SkipWidgetExtension
```

`flutter build ios` runs `pod install`, which can rewrite `ios/Podfile.lock` (the QA run saw it drop the dev-only `integration_test` pod). Don't commit that change unless it's intended.

On the **booted iOS Simulator**, rerun the report's failed checks in both themes and at least EN and DE (use the report's commands and paths):
- F1: 10.4 at `accessibility-extra-extra-extra-large`: Home, Settings, Insights, Item Detail. Reset with `xcrun simctl ui booted content_size large`.
- F2: 10.3, coin flip in landscape (Device → Rotate Left), including a flip.
- F3: 8.5, Insights in FR + Minimal and in DE + Y2K with 1k+ totals.
- F4: 5.7 in DE.
- U1: the `tmp/` check above, plus 3.1, 3.4, 3.5, 3.6, 5.12 and 5.13 still pass (no orphan in `skip_images`, the right file shown).
- U2: the permission prompt in EN and IT.
- U3/U4: 3.2 and 3.3 on the entry and detail screens.
- Keep `flutter run` attached (or `flutter logs`) the whole time. Any overflow, exception, or `setState() called after dispose` counts as a failure.

Restore the Simulator afterwards: light appearance, `large` text size, portrait, original language and locale.

---

## 6. Deliverable

Finish with a short report:

| ID | Status (FIXED / PARTIAL / NOT FIXED / LEFT ALONE) | What changed (files) | How it was verified |
|---|---|---|---|

List the commits, any new dependencies (with why), anything you found that differs from the QA report, and which checks still need a rerun on a physical iPhone (camera, haptics, permission prompts, widget refresh).
