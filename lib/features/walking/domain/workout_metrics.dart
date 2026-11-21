class WorkoutMetrics {
  const WorkoutMetrics(
      {required this.steps,
      required this.distanceMeters,
      required this.durationSeconds});
  final int steps;
  final int distanceMeters;
  final int durationSeconds;

  double get distanceKm => distanceMeters / 1000;
  double? get paceSecondsPerKm =>
      distanceMeters <= 0 ? null : durationSeconds / (distanceMeters / 1000);
}
