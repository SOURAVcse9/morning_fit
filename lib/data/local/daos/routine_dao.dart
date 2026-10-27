import 'package:drift/drift.dart';

import '../app_database.dart';

/// Routine tasks, completions, exercise library/sessions and key-value settings.
class RoutineDao {
  RoutineDao(this.db);
  final AppDatabase db;

  Stream<List<RoutineTask>> watchTasks() => (db.select(db.routineTasks)
        ..orderBy([(t) => OrderingTerm.asc(t.scheduledMinutes)]))
      .watch();

  Future<List<RoutineTask>> tasks() => (db.select(db.routineTasks)
        ..orderBy([(t) => OrderingTerm.asc(t.scheduledMinutes)]))
      .get();

  Future<int> saveTask(RoutineTasksCompanion task) => db.transaction(() async {
        final id = await db.into(db.routineTasks).insertOnConflictUpdate(task);
        final realId = task.id.present ? task.id.value : id;
        await (db.update(db.routineTasks)..where((t) => t.id.equals(realId)))
            .write(RoutineTasksCompanion(notificationId: Value(realId)));
        return realId;
      });

  Future<void> deleteTask(int id) =>
      (db.delete(db.routineTasks)..where((t) => t.id.equals(id))).go();

  Stream<List<TaskCompletion>> watchCompletionsSince(String fromLocalDate) =>
      (db.select(db.taskCompletions)
            ..where((c) => c.localDate.isBiggerOrEqualValue(fromLocalDate)))
          .watch();

  /// Pass [status] null to clear the completion for that day.
  Future<void> setCompletion(int taskId, String localDate, String? status) async {
    if (status == null) {
      await (db.delete(db.taskCompletions)
            ..where((c) => c.taskId.equals(taskId) & c.localDate.equals(localDate)))
          .go();
      return;
    }
    final row = TaskCompletionsCompanion.insert(
      taskId: taskId,
      localDate: localDate,
      completedAt: DateTime.now().toUtc(),
      status: status,
    );
    await db.into(db.taskCompletions).insert(row,
        onConflict: DoUpdate((_) => row, target: [db.taskCompletions.taskId, db.taskCompletions.localDate]));
  }

  Stream<List<Exercise>> watchExercises() =>
      (db.select(db.exercises)..orderBy([(e) => OrderingTerm.asc(e.name)])).watch();

  Future<void> saveExercise(ExercisesCompanion e) =>
      db.into(db.exercises).insertOnConflictUpdate(e);

  Future<void> addExerciseSession(ExerciseSessionsCompanion s) =>
      db.into(db.exerciseSessions).insert(s);

  Stream<List<ExerciseSession>> watchExerciseSessions() => (db.select(db.exerciseSessions)
        ..orderBy([(s) => OrderingTerm.desc(s.startedAt)]))
      .watch();

  Future<Map<String, String>> allSettings() async {
    final rows = await db.select(db.appSettings).get();
    return {for (final r in rows) r.key: r.value};
  }

  Future<void> setSetting(String key, String value) => db
      .into(db.appSettings)
      .insertOnConflictUpdate(AppSettingsCompanion.insert(key: key, value: value));
}
