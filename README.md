# MorningFit v2 🌿

> **Walk Better. Live Healthier.**  
> Minimal, privacy-focused, offline-first morning walking and 24/7 daily activity tracker built with Flutter and Material 3.

[![Release](https://img.shields.io/badge/Release-v2.0.0-2e7d32.svg)](https://github.com/SOURAVcse9/morning_fit/releases/tag/v2.0.0)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-blue.svg)](https://github.com/SOURAVcse9/morning_fit)
[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 📲 Direct Download

Download the latest production release APK:
- **[Download MorningFit v2 Release APK (v2.0.0)](https://github.com/SOURAVcse9/morning_fit/releases/download/v2.0.0/morning_fit-v2.0.0-release.apk)**
- Pre-built local release binary: `release/morning_fit-v2.0.0-release.apk`

---

## 🌟 What's New in MorningFit v2

### 1. 🕒 24/7 Automatic Background Activity Tracking (Midnight to Midnight)
- **Continuous Hardware Sensor Sync:** Connects directly to device hardware pedometer sensors (`Sensor.TYPE_STEP_COUNTER`) running at ultralow power 24/7.
- **Automatic Midnight Rollover:** Seamlessly detects the 12:00 AM (midnight) day transition. Previous day's step counts are preserved into persistent storage, and the current day cleanly resets to 0.
- **Reboot Resilience:** Accurately retains step counts across device reboots and phone restarts using persistent baseline offsets.
- **Date-wise Tracking:** Query and view step counts day by day for any historical calendar date.

### 2. ⚡ Daily Vitality & Health Score (0–100)
- An all-in-one daily vitality index visible on the Home dashboard combining:
  - **Steps Goal Progress:** up to 40 pts
  - **Active Walking Time:** up to 25 pts
  - **Hydration Target:** up to 20 pts
  - **Routine Consistency:** up to 15 pts
- Live status indicators: *Peak Vitality ⚡*, *Thriving 🌿*, *Good Pace 🚶*, and *Recharging 🌅*.

### 3. 💧 Quick One-Tap Hydration Tracker
- 1-tap `+` / `-` water intake tracker on the Home dashboard.
- Tracks 8 glasses (2,000 ml) daily target with animated water drop indicators.
- Automatically resets at midnight and persists historical hydration date by date.

### 4. 📅 Enhanced Date-Wise Activity & Walking History
- Tap any day on the interactive calendar to inspect that day's total steps, hydration count, and recorded GPS walks with routes and durations.

### 5. 🛡️ Production R8 & Proguard Generic Signature Fix
- Fixed Gson reflection issue in Flutter Local Notifications by preserving generic signatures (`-keepattributes Signature, *Annotation*, InnerClasses, EnclosingMethod`) in `proguard-rules.pro`.
- Eliminates release-mode crashes when scheduling routine alarms and reminders.

### 6. ⚙️ Interactive Settings
- Customize daily step goals (5k, 8k, 10k, 12k, 15k).
- Toggle 24/7 background activity tracking on/off.
- View live hardware sensor connection status.

---

## 📱 App Highlights

- **Minimal, Modern, Zero Clutter:** Material 3 with vibrant green accent (`#2E7D32`), large readable numbers, and short labels.
- **100% Offline & Private:** No forced logins, no cloud tracking, no accounts, and no data leaves your phone.
- **Real-Time GPS Tracking:** OpenStreetMap route visualization, live distance, pace, and estimated calories.
- **Beginner Home Exercises:** Built-in guided library with starter movements (Squats, Wall Push-ups, Glute Bridges, Plank, Calf Raises).

---

## 🏗️ Architecture & Stack

- **Framework:** Flutter (Android, iOS, Web)
- **State Management:** Riverpod 2.x
- **Local Database:** Drift (SQLite) with cascade foreign keys
- **Location & GPS:** Geolocator & latlong2
- **Maps:** Flutter Map with OpenStreetMap tiles
- **Sensors:** Pedometer (`Sensor.TYPE_STEP_COUNTER`) & Permission Handler
- **Notifications:** Flutter Local Notifications with Android 13+ support

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>= 3.4.0)
- Android Studio / Android SDK (API 34)
- Java 17 / Gradle 8

### Build & Run Commands

```bash
# 1. Clone repository
git clone https://github.com/SOURAVcse9/morning_fit.git
cd morning_fit

# 2. Install dependencies
flutter pub get

# 3. Generate SQLite code
dart run build_runner build --delete-conflicting-outputs

# 4. Analyze and test
flutter analyze
flutter test

# 5. Run on device or web
flutter run
flutter run -d chrome

# 6. Build production release APK
flutter build apk --release
```

---

## 📜 Version History

### Version 2.0.0 (MorningFit v2) — Current
- Added 24/7 automatic hardware step tracking with automatic midnight (12 AM) date rollover.
- Added Daily Vitality Health Score (0–100) dynamic index on dashboard.
- Added 8-glass Quick Hydration Tracker with 1-tap intake controls.
- Added date-wise daily activity summary in Calendar History.
- Added Proguard R8 Gson TypeToken rules to resolve release notification crash.
- Added configurable daily step goals in Settings.
- Added comprehensive unit tests for trackers and metrics.

### Version 1.0.0 (MorningFit Starter)
- Initial starter architecture with Drift SQLite database.
- GPS walking tracker with OpenStreetMap polyline and location markers.
- Starter home exercises library and morning routine checklist.
- Basic calendar history and monthly workout chart.
- Material 3 theming and GoRouter navigation.
