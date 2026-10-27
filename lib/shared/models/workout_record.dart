/// Plain model used by business logic so it stays independent of Drift.
class WorkoutRecord {
  const WorkoutRecord({
    required this.id,
    required this.startedAt,
    required this.localDate,
    required this.durationSeconds,
    required this.distanceMeters,
    required this.steps,
    required this.calories,
  });
  final String id;
  final DateTime startedAt;
  final String localDate; // yyyy-MM-dd
  final int durationSeconds;
  final double distanceMeters;
  final int steps;
  final double calories;
}
