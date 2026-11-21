import 'package:drift/drift.dart';
import 'routine_tasks.dart';

class TaskCompletions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get taskId =>
      text().references(RoutineTasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get localDate => text()(); // yyyy-MM-dd in user's local timezone
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  @override
  List<Set<Column>> get uniqueKeys => [
        {taskId, localDate}
      ];
}
