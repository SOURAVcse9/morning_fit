import 'package:drift/drift.dart';

class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get difficulty => text().withDefault(const Constant('Beginner'))();
  TextColumn get description => text()();
  TextColumn get instructions => text()();
  TextColumn get imageAsset => text().nullable()();
  IntColumn get defaultSets => integer().withDefault(const Constant(2))();
  IntColumn get defaultReps => integer().withDefault(const Constant(10))();
  IntColumn get restSeconds => integer().withDefault(const Constant(60))();
  @override
  Set<Column> get primaryKey => {id};
}
