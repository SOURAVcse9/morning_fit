import 'package:drift/drift.dart';
import 'workouts.dart';

class RoutePoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get workoutId =>
      text().references(Workouts, #id, onDelete: KeyAction.cascade)();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  DateTimeColumn get recordedAt => dateTime()();
  RealColumn get accuracyMeters => real().nullable()();
  IntColumn get segmentIndex => integer().withDefault(const Constant(0))();
  @override
  List<Set<Column>> get uniqueKeys => [
        {workoutId, recordedAt, latitude, longitude}
      ];
}
