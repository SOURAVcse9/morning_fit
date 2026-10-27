import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'seed.dart';
import 'tables/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Workouts,
  RoutePoints,
  RoutineTasks,
  TaskCompletions,
  Exercises,
  ExerciseSessions,
  AppSettings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Production database stored in the app's documents directory.
  AppDatabase.open() : super(driftDatabase(name: 'morning_fit'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await seedDefaults(this);
        },
        // Add one step per schema bump, e.g.:
        // if (from < 2) { await m.addColumn(workouts, workouts.newColumn); }
        onUpgrade: (m, from, to) async {},
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Deletes all user data and restores the default routine/exercises.
  Future<void> resetAll() => transaction(() async {
        for (final t in allTables.toList().reversed) {
          await delete(t).go();
        }
        await seedDefaults(this);
      });
}
