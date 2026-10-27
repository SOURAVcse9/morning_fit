import 'dart:io' show Platform;

import 'package:geolocator/geolocator.dart';

import 'route_recorder.dart';

enum LocationAccess { granted, serviceDisabled, denied, deniedForever }

abstract class LocationService {
  Future<LocationAccess> currentAccess();
  Future<LocationAccess> ensureAccess();
  Stream<LocationSample> track();
  Future<void> openSettings();
}

class GeolocatorLocationService implements LocationService {
  @override
  Future<LocationAccess> currentAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationAccess.serviceDisabled;
    return _map(await Geolocator.checkPermission());
  }

  /// Requests permission only when called (from an explicit user action).
  @override
  Future<LocationAccess> ensureAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationAccess.serviceDisabled;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    return _map(p);
  }

  LocationAccess _map(LocationPermission p) => switch (p) {
        LocationPermission.always || LocationPermission.whileInUse => LocationAccess.granted,
        LocationPermission.deniedForever => LocationAccess.deniedForever,
        _ => LocationAccess.denied,
      };

  /// Android: runs as a foreground service with a persistent notification.
  /// iOS: enables background location updates (needs the UIBackgroundModes
  /// "location" entry in Info.plist).
  @override
  Stream<LocationSample> track() {
    final LocationSettings settings;
    if (Platform.isAndroid) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 3,
        intervalDuration: const Duration(seconds: 2),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'MorningFit walk in progress',
          notificationText: 'Recording your route and distance',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    } else if (Platform.isIOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.best,
        activityType: ActivityType.fitness,
        distanceFilter: 3,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    } else {
      settings = const LocationSettings(accuracy: LocationAccuracy.best, distanceFilter: 3);
    }
    return Geolocator.getPositionStream(locationSettings: settings).map((p) => LocationSample(
          latitude: p.latitude,
          longitude: p.longitude,
          accuracyMeters: p.accuracy,
          time: p.timestamp.toUtc(),
        ));
  }

  @override
  Future<void> openSettings() async {
    await Geolocator.openAppSettings();
  }
}
