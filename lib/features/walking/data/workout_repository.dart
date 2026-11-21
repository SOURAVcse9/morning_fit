import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../data/local/app_database.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>(
    (ref) => WorkoutRepository(ref.watch(appDatabaseProvider)));

class WorkoutRepository {
  WorkoutRepository(this.db);
  final AppDatabase db;

  Future<void> saveWorkout(WorkoutsCompanion workout) =>
      db.into(db.workouts).insertOnConflictUpdate(workout);

  Stream<List<Workout>> watchCompletedWorkouts() => (db.select(db.workouts)
        ..where((t) => t.status.equals('completed'))
        ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]))
      .watch();

  Future<List<Workout>> workoutsForRange(DateTime start, DateTime end) =>
      (db.select(db.workouts)
            ..where((t) =>
                t.startedAt.isBiggerOrEqualValue(start.toUtc()) &
                t.startedAt.isSmallerThanValue(end.toUtc()))
            ..orderBy([(t) => OrderingTerm.asc(t.startedAt)]))
          .get();
}
