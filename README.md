# MorningFit

Offline-first Flutter walking and home-fitness tracker starter project.

## Included in this starter

- Feature-first Flutter folder structure.
- Material 3 light/dark theme and GoRouter routes.
- Drift SQLite schema for workouts, route points, routine tasks, completions, exercises, exercise sessions, and settings.
- Starter home-exercise records seeded into SQLite.
- Walking screen prototype with GPS stream, step stream, OpenStreetMap tiles, and route polyline.
- Local workout persistence and completed-workout history.
- Calendar history and monthly distance chart.
- Local notification initialization and a test-notification action.
- Android permission manifest and iOS usage descriptions.
- Basic unit/widget tests.

## Important status note

This is a **starter implementation, not yet a production-ready release**. The current source passes static analysis and automated tests, but it still needs real-device and release-build validation. Native background tracking is not fully implemented: a production version needs an Android foreground location service and platform-specific lifecycle handling, plus a tested iOS Core Location background configuration. Scheduled daily alarms also need timezone-aware scheduling and platform-specific validation. Step-count behavior varies by device and operating system.

The generated Drift file `lib/data/local/app_database.g.dart` is intentionally not included; generate it locally with build_runner.

## Requirements

Install a current stable Flutter SDK, Android Studio/Android SDK for Android builds, and macOS with Xcode for iOS builds. iOS builds cannot be produced on Windows.

## Setup

```bash
flutter doctor
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```

If the generated platform directories are incomplete for your local Flutter version, create a fresh shell project with `flutter create .` from the project root and carefully merge the supplied platform configuration. Back up files before merging.

## Map

The walking screen uses OpenStreetMap standard tiles and displays attribution through `flutter_map`'s standard tile layer behavior. Follow the tile provider's current usage policy. Do not bulk-download standard OSM tiles for offline use.

## Permissions

### Android

The manifest includes location, activity recognition, notification, and foreground-service permission declarations. Confirm exact requirements for the Android versions you target. Do not add background location permission unless the implemented feature genuinely needs it and the permission flow is justified. Configure a location foreground service before claiming active background GPS tracking works.

### iOS

The supplied Info.plist includes location and motion usage descriptions and the location background mode. Validate the Runner target capabilities and Core Location implementation in Xcode. Background tracking can be interrupted by system policies and is not guaranteed after a force quit.

## Data model notes

- Distances are stored in meters and durations in seconds.
- Absolute timestamps should be UTC; calendar groupings use local dates.
- Route points are linked to workouts and cascade on workout deletion.
- Do not count the same workout twice in daily summaries.

## Known limitations to complete before release

1. Complete and test native background location recording on Android and iOS.
2. Add timezone-aware daily/weekly notification scheduling.
3. Improve step baseline and midnight/day-boundary handling using device-specific tests.
4. Add editing/completion UI for routine tasks and exercise session logging.
5. Add workout detail, route replay, export, settings persistence, and migration tests.
6. Review GPS outlier handling and persist route points in a robust batch strategy.
7. Validate dependency versions and fix any analyzer/build issues for the installed SDK.
8. Test on real devices with permissions granted, denied, revoked, and after reboot.

## Tests

The current test suite checks the Haversine utility and app startup. All 3 tests pass; expand coverage and validate hardware-dependent behavior before release.
