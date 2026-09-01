# 💸 SKIP. / SKIP!

> **Visual Financial Resistance & Impulsive Spend Tracker**  
> *100% Offline • Dual Aesthetic Engine (Quiet Luxury vs. Bratz Y2K)*

---

## 🌟 Concept

**SKIP** turns the traditional wishlist upside down. Instead of encouraging endless consumption, SKIP uses visual reinforcement to show you **how much money you've saved by choosing NOT to buy items**, alongside the reality of what you've actually spent.

Take a quick picture of something you're tempted to buy, input the price, and choose your action:
* **Resisted! (Saved)** — Victory! The money stays in your pocket, and the item enters your savings visual trophy case.
* **Bought It (Spent)** — Tracked transparently so you see the true cost of your spending habits.

All your data and images stay **100% on your device**. No servers, no accounts, no tracking, complete privacy.

---

## 🎭 Dual Aesthetic Engine

Switch between two distinct UI personalities anytime in settings:

| Aesthetic | Theme Name | Primary Palette | Typography | Vibe |
| :--- | :--- | :--- | :--- | :--- |
| **Quiet Luxury** | `skip.` | Charcoal, Silk Beige, Champagne, Soft White | *Playfair Display* & *Inter* | Minimalist, serene, disciplined financial diary. |
| **Bratz Y2K** | `SKIP!` | Hot Magenta, Electric Violet, Metallic Silver | *Titan One* & *Fredoka* | Explosive 2000s pop, sassy, "Girl Math" victory celebration. |

---

## 🛠️ Architecture & Tech Stack

- **Framework:** [Flutter](https://flutter.dev/) (Cross-platform iOS & Android)
- **Database:** `sqflite` (Local SQLite database)
- **State Management:** `provider` (Theme switcher & reactive UI updates)
- **Image Handling:** `image_picker` + local Application Documents File System storage
- **Typography:** `google_fonts`
- **Networking:** **None** (100% Offline application)

---

## 📱 Project Structure

```text
lib/
├── core/
│   ├── theme/
│   │   ├── app_themes.dart       # Minimal & Bratz theme declarations
│   │   └── theme_provider.dart   # Theme switcher logic
│   └── utils/
│       └── file_helper.dart      # Local image copy utility
├── data/
│   ├── database_helper.dart      # SQLite database initialization & queries
│   └── models/
│       └── item_model.dart       # Item entity model
└── features/
    ├── home/                     # Dashboard with visual grid & total metrics
    ├── item_entry/               # Photo capture & price logger modal
    └── settings/                 # Theme switcher & local backup settings
```

---

## 🚀 Quick Start (Development)

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>=3.0.0`)
- Android Studio / Xcode (for emulators & native builds)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/skip-app.git
   cd skip-app
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run on connected device or emulator:
   ```bash
   flutter run
   ```
4. Run on a specific physical device (real iPhone/Android):
   ```bash
   # List connected/paired devices (USB or wireless) and copy the device id
   flutter devices

   # Launch on that device
   flutter run -d <device-id>
   ```
   For iOS, prefer a USB connection over wireless debugging — wireless links can drop mid-session and end the run.

---

## 📄 License
MIT License. Created for mindful spenders and dopamine shoppers worldwide.

