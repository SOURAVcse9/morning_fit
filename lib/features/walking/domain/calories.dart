/// Rough walking estimate (~0.53 kcal per kg per km). Always show as "estimated".
double estimateCalories(double distanceMeters, {double weightKg = 70}) =>
    (distanceMeters / 1000) * weightKg * 0.53;

/// Seconds per km, or null when the distance is too short to be meaningful.
double? averagePace(double distanceMeters, int durationSeconds) {
  if (distanceMeters < 50 || durationSeconds <= 0) return null;
  return durationSeconds / (distanceMeters / 1000);
}
