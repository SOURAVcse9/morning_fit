/// Walking calorie estimate (~0.75 kcal per kg per km standard MET brisk walk).
/// If distance is tiny or unavailable, estimates based on step count (~0.04 kcal per step).
double estimateCalories(double distanceMeters, {double weightKg = 70, int steps = 0}) {
  final fromDist = (distanceMeters / 1000) * weightKg * 0.75;
  final fromSteps = steps * 0.04 * (weightKg / 70);
  final estimate = fromDist > fromSteps ? fromDist : fromSteps;
  return estimate > 0 ? estimate : 0.0;
}

/// Seconds per km, or null when the distance is too short to be meaningful.
double? averagePace(double distanceMeters, int durationSeconds) {
  if (distanceMeters < 50 || durationSeconds <= 0) return null;
  return durationSeconds / (distanceMeters / 1000);
}
