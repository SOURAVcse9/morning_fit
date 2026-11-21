import 'package:drift/drift.dart';

class Workouts extends Table {
  TextColumn get id => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('recording'))();
  IntColumn get steps => integer().withDefault(const Constant(0))();
  IntColumn get distanceMeters => integer().withDefault(const Constant(0))();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  IntColumn get caloriesEstimate => integer().nullable()();
  RealColumn get averagePaceSecondsPerKm => real().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}
