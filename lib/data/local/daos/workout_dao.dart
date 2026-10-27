import 'package:drift/drift.dart';

import '../app_database.dart';

class WorkoutDao {
  WorkoutDao(this.db);
  final AppDatabase db;

  Future<void> insert(String id, DateTime startedAtUtc, String localDate) {
    final now = DateTime.now().toUtc();
    return db.into(db.workouts).insert(WorkoutsCompanion.insert(
          id: id,
          startedAt: startedAtUtc,
          status: 'recording',
          localDate: localDate,
          createdAt: now,
          updatedAt: now,
        ));
  }

  /// Persists buffered route points and the running totals atomically.
  Future<void> saveProgress({
    required String id,
    required String status,
    required int steps,
    required double distanceMeters,
    required int durationSeconds,
    required List<RoutePointsCompanion> points,
  }) =>
      db.transaction(() async {
        if (points.isNotEmpty) {
          await db.batch((b) => b.insertAll(db.routePoints, points));
        }
        await (db.update(db.workouts)..where((w) => w.id.equals(id))).write(
          WorkoutsCompanion(
            status: Value(status),
            steps: Value(steps),
            distanceMeters: Value(distanceMeters),
            durationSeconds: Value(durationSeconds),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
      });

  Future<void> complete({
    required String id,
    required DateTime endedAtUtc,
    required int steps,
    required double distanceMeters,
    required int durationSeconds,
    required double calories,
    required double? averagePace,
    required List<RoutePointsCompanion> points,
  }) =>
      db.transaction(() async {
        if (points.isNotEmpty) {
          await db.batch((b) => b.insertAll(db.routePoints, points));
        }
        await (db.update(db.workouts)..where((w) => w.id.equals(id))).write(
          WorkoutsCompanion(
            status: const Value('completed'),
            endedAt: Value(endedAtUtc),
            steps: Value(steps),
            distanceMeters: Value(distanceMeters),
            durationSeconds: Value(durationSeconds),
            caloriesEstimate: Value(calories),
            averagePace: Value(averagePace),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
      });

  Future<void> delete(String id) =>
      (db.delete(db.workouts)..where((w) => w.id.equals(id))).go();

  Stream<List<Workout>> watchCompleted() => (db.select(db.workouts)
        ..where((w) => w.status.equals('completed'))
        ..orderBy([(w) => OrderingTerm.desc(w.startedAt)]))
      .watch();

  Future<Workout?> byId(String id) =>
      (db.select(db.workouts)..where((w) => w.id.equals(id))).getSingleOrNull();

  Future<List<Workout>> unfinished() => (db.select(db.workouts)
        ..where((w) => w.status.isIn(['recording', 'paused']))
        ..orderBy([(w) => OrderingTerm.desc(w.startedAt)]))
      .get();

  Future<List<RoutePoint>> routePoints(String workoutId) =>
      (db.select(db.routePoints)
            ..where((p) => p.workoutId.equals(workoutId))
            ..orderBy([(p) => OrderingTerm.asc(p.recordedAt)]))
          .get();
}
