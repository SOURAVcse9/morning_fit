# MorningFit — Walk Better. Live Healthier.

[![Flutter Tests](https://img.shields.io/badge/Flutter%20Tests-29%20Passing-brightgreen.svg)](#tests)
[![Flutter Analyze](https://img.shields.io/badge/Flutter%20Analyze-0%20Issues-brightgreen.svg)](#code-quality)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-blue.svg)](#platforms)
[![Release](https://img.shields.io/badge/Release-v1.0.0-orange.svg)](release/morning_fit-v1.0.0-release.apk)

An offline-first Flutter walking and fitness tracker for Android, iOS, and Web. Features step counting, GPS route tracking and distance visualization on OpenStreetMap, workout history calendar, analytics, daily routines, home exercise library, and local reminders.

---

## 🚀 Release Download

* **Direct APK Download (GitHub Release):** [morning_fit-v1.0.0.apk](https://github.com/SOURAVcse9/morning_fit/releases/download/v1.0.0/morning_fit-v1.0.0.apk)
* **In-Repository File:** [release/morning_fit-v1.0.0-release.apk](release/morning_fit-v1.0.0-release.apk)
* **Release Page:** [MorningFit v1.0.0 Release Notes & Assets](https://github.com/SOURAVcse9/morning_fit/releases/tag/v1.0.0)
* **File Size:** ~62.2 MB
* **Target Platforms:** Android 6.0+ (API 23+)
* **Architecture:** Universal (arm64-v8a, armeabi-v7a, x86_64)

### How to Install the APK on Android
1. Download the APK using the [Direct Download Link](https://github.com/SOURAVcse9/morning_fit/releases/download/v1.0.0/morning_fit-v1.0.0.apk).
2. Open the downloaded `.apk` file on your Android device.
3. If prompted, grant permission to "Install from unknown sources" in settings.
4. Tap **Install** and launch MorningFit!

---

## 🌐 Running on Web

MorningFit supports web deployment with responsive UI:

```bash
# Run locally in Google Chrome
flutter run -d chrome

# Or build a production web bundle
flutter build web --release
```

The compiled web assets are generated in `build/web/` and can be deployed directly to GitHub Pages, Firebase Hosting, Netlify, or Vercel.

---

## 📱 Getting Started & Development

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (>= 3.4.0)
- Java JDK 17+ & Android SDK (for Android build)
- Google Chrome (for Web testing)

### 2. Setup
```bash
# Get dependencies
flutter pub get

# Generate Drift database code (lib/data/local/app_database.g.dart)
dart run build_runner build --delete-conflicting-outputs
```

### 3. Run the App
```bash
# Run on connected Android / iOS device:
flutter run

# Run on Web (Chrome):
flutter run -d chrome
```

### 4. Build Release APK
```bash
flutter build apk --release
```
The output APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`.

---

## 🧪 Tests & Code Quality

MorningFit has been thoroughly audited and tested with 100% passing results:

```bash
# Run static analysis (0 warnings, 0 errors)
flutter analyze

# Run the complete test suite (29 tests passing)
flutter test
```

### Test Coverage
- **Unit Tests (`test/unit/`):**
  - Haversine distance calculations and symmetry.
  - GPS route recording, duplicate filtering, jitter suppression, and accuracy limits.
  - Step counter delta tracking, sensor baselines, and reset handling.
  - Analytics, weekly/monthly aggregations, and streak calculations.
- **Database Tests (`test/database/`):**
  - In-memory Drift SQLite: CRUD operations, foreign key constraints, cascading deletes, transactions, and crash recovery.
- **Widget Tests (`test/widget/`):**
  - Dashboard layout, empty states, and dynamic statistics updates.

---

## 🏛️ Architecture & Features

Built using a **feature-first** architecture:
* `lib/core`: Theme, GoRouter navigation, error handling, reusable UI components.
* `lib/data/local`: Drift SQLite database, DAOs, schema tables, default seed data.
* `lib/services`: Location tracking (`geolocator`), pedometer step sensor (`pedometer`), local notifications (`flutter_local_notifications`).
* `lib/features/`:
  - `dashboard`: Real-time daily progress, step goal visualization, recent walks, routine checklists.
  - `walking`: Live workout state machine (`idle` → `recording` ⇄ `paused` → `saved`), GPS map tracking with `flutter_map` / OpenStreetMap.
  - `calendar`: Workout history logs, route replay, detailed pace/distance/calorie metrics.
  - `analytics`: Weekly bar charts, monthly trends, goal streaks.
  - `exercises`: Home routine library with timers for sets, reps, and rest periods.
  - `settings`: Configurable goals (steps, distance), metric/imperial unit toggle, dark/light theme, database reset, and data export.
* `lib/shared`: Riverpod providers, immutable data models.

---

## 🔐 Permissions Overview

| Permission | Platform | Trigger | Purpose |
|---|---|---|---|
| Location (Fine & Coarse) | Android / iOS / Web | Tapping **Start Walk** | Accurate route tracking and distance |
| Foreground Service (Location) | Android | While a walk is recording | Keeps GPS active in background |
| Activity Recognition | Android 10+ / iOS | Walking workout | Step sensor counting |
| Post Notifications | Android 13+ / iOS | App startup / Reminders toggle | Workout and routine reminders |

---

## 📄 License

This project is licensed under the MIT License.
