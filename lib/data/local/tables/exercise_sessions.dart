import 'package:drift/drift.dart';
import 'exercises.dart';

class ExerciseSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  IntColumn get setsCompleted => integer().withDefault(const Constant(0))();
  IntColumn get repsCompleted => integer().withDefault(const Constant(0))();
}
