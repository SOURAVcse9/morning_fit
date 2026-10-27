import 'package:drift/drift.dart';

@TableIndex(name: 'idx_workouts_local_date', columns: {#localDate})
@TableIndex(name: 'idx_workouts_status', columns: {#status})
class Workouts extends Table {
  TextColumn get id => text()();
  DateTimeColumn get startedAt => dateTime()(); // absolute time
  DateTimeColumn get endedAt => dateTime().nullable()();
  /// recording | paused | completed
  TextColumn get status => text()();
  IntColumn get steps => integer().withDefault(const Constant(0))();
  RealColumn get distanceMeters => real().withDefault(const Constant(0))();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  RealColumn get caloriesEstimate => real().withDefault(const Constant(0))();
  /// Seconds per kilometre; null when distance is too short to be meaningful.
  RealColumn get averagePace => real().nullable()();
  /// Local calendar day (yyyy-MM-dd) the walk started on.
  TextColumn get localDate => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'idx_route_workout', columns: {#workoutId})
class RoutePoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get workoutId =>
      text().customConstraint('NOT NULL REFERENCES workouts(id) ON DELETE CASCADE')();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  DateTimeColumn get recordedAt => dateTime()();
  RealColumn get accuracyMeters => real()();
  IntColumn get segmentIndex => integer()();
}

class RoutineTasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  /// Minutes after local midnight.
  IntColumn get scheduledMinutes => integer()();
  IntColumn get durationMinutes => integer().withDefault(const Constant(0))();
  /// Comma-separated ISO weekdays, 1 = Monday .. 7 = Sunday.
  TextColumn get repeatDays => text().withDefault(const Constant('1,2,3,4,5,6,7'))();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  /// Base for stable notification IDs (see NotificationIds.forTask).
  IntColumn get notificationId => integer().withDefault(const Constant(0))();
}

class TaskCompletions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId =>
      integer().customConstraint('NOT NULL REFERENCES routine_tasks(id) ON DELETE CASCADE')();
  TextColumn get localDate => text()();
  DateTimeColumn get completedAt => dateTime()();
  /// done | skipped
  TextColumn get status => text()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {taskId, localDate}
      ];
}

class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  TextColumn get category => text()();
  TextColumn get difficulty => text()();
  /// One instruction step per line.
  TextColumn get instructions => text()();
  TextColumn get imageAsset => text().nullable()();
  IntColumn get defaultSets => integer()();
  IntColumn get defaultReps => integer()();
  IntColumn get restSeconds => integer()();
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class ExerciseSessions extends Table {
  TextColumn get id => text()();
  TextColumn get exerciseId =>
      text().customConstraint('NOT NULL REFERENCES exercises(id)')();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime()();
  IntColumn get durationSeconds => integer()();
  IntColumn get setsCompleted => integer()();
  IntColumn get repsCompleted => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
