# Privacy Policy

**Effective date:** September 16, 2026

This policy covers **SKIP** (shown in-app as `skip.` or `SKIP!` depending on the theme you pick), a mobile app for tracking purchases you resist or make. It applies to the iOS and Android versions of the app.

## The short version

SKIP has no servers, no accounts, and no analytics. Everything you enter — photos, prices, titles, categories — is stored **only on your device**. Nothing is uploaded anywhere, ever. We (the developer) never see your data, because the app has no way to send it to us.

## Information the app stores

When you log an item, SKIP saves the following to a local database on your device:

- Title / description (optional)
- Price
- Photo (saved to your device's app storage folder, not your camera roll)
- Category (optional)
- Whether you resisted (saved) or bought (spent) it
- The date you logged it
- A product link, if you added one (optional)

This data stays in a local SQLite database and a local folder of photos, both private to the app. None of it is transmitted over the network, because the app does not include any networking code.

## Permissions the app requests

- **Camera** — to let you take a photo of the item you're logging.
- **Photo Library** — to let you pick an existing photo instead of taking a new one.

Photos you take or pick are copied into the app's own local storage. The app does not scan, upload, or otherwise access your camera roll beyond the single photo you choose.

## What SKIP does not do

- No account or sign-in of any kind
- No analytics, crash reporting, or telemetry SDKs
- No advertising or ad-tracking SDKs
- No location, contacts, or device-identifier collection
- No network requests — the app has no HTTP client and cannot reach the internet even if it wanted to

## Links that leave the app

A couple of things in SKIP open outside the app, in your browser or another installed app:

- **Product links** — if you save a link with an item, tapping it opens that page in your device's browser.
- **Support / donate link** — the optional "Support SKIP" screen links to a PayPal.me page.

These are only opened when you tap them, and once you leave SKIP, the privacy practices of that external site or app apply, not this one.

## Exporting or backing up your data

Settings includes an optional backup feature: exporting your items to a file, and importing a file back in. Exporting uses your device's native share sheet, so where the file goes (Files app, AirDrop, email, a cloud drive, etc.) is entirely your choice — SKIP itself doesn't send it anywhere. Importing uses your device's file picker to read a file you select. Both actions happen locally and only when you initiate them.

## Deleting your data

Deleting an item moves it to Trash rather than erasing it immediately, so you can restore it by mistake-proofing your workflow. Items left in Trash for more than 30 days are automatically and permanently deleted, along with their photo file. You can also manage Trash directly from Settings at any time.

Uninstalling the app removes its local database and all stored photos from your device.

## Device backups

If you have iCloud Backup, Google backup, or a similar device-level backup enabled, your device's operating system may include SKIP's local app data in that backup as part of backing up your whole device. That's a feature of your OS, not something SKIP initiates or controls, and it's governed by Apple's or Google's own privacy terms for that backup service.

## Children's privacy

SKIP is not directed at children and does not knowingly collect information from anyone, regardless of age — since the app doesn't collect or transmit data at all, this applies equally to users of any age.

## Changes to this policy

If this policy changes, the update will be posted here with a new effective date at the top.

## Contact

Questions about this policy or the app's privacy practices can be raised via [GitHub Issues](https://github.com/aellae/skip./issues).
