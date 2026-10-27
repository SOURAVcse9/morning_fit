/// Structured, user-readable failure messages.
class Failure implements Exception {
  const Failure(this.message, {this.cause});
  final String message;
  final Object? cause;
  @override
  String toString() => message;
}

class Messages {
  static const locationDisabled =
      'Location services are turned off. Turn on GPS to record your route and distance.';
  static const locationDenied =
      'Location permission was denied. MorningFit needs it to measure distance and draw your route.';
  static const locationDeniedForever =
      'Location permission is permanently denied. Open system settings to enable it.';
  static const sensorUnavailable =
      'Step sensor unavailable on this device. Distance and route still work; steps will not be recorded.';
  static const stepPermissionDenied =
      'Physical-activity permission denied, so steps cannot be counted. GPS distance still works.';
  static const gpsWeak = 'GPS accuracy is low. Move to open sky; weak points are ignored.';
  static const gpsLost = 'No GPS updates received. Distance is not added while the signal is lost.';
  static const dbFailure = 'Could not save to the local database. Please try again.';
  static const interrupted =
      'An interrupted walk was recovered. Resume it, finish it with the saved data, or discard it.';
}
