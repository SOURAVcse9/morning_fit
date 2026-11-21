import 'package:drift/drift.dart';

class RoutineTasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get scheduledTime => text()(); // Local HH:mm
  IntColumn get durationMinutes => integer().withDefault(const Constant(5))();
  TextColumn get repeatDays =>
      text().withDefault(const Constant('1,2,3,4,5,6,7'))();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  IntColumn get notificationId => integer().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}
