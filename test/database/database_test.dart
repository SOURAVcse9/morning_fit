import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morning_fit/data/local/app_database.dart';
import 'package:morning_fit/data/local/daos/workout_dao.dart';
import 'package:morning_fit/features/walking/data/workout_repository.dart';
import 'package:morning_fit/services/location/route_recorder.dart';

RecordedPoint pt(double lat, int sec, int seg) => RecordedPoint(
      LocationSample(latitude: lat, longitude: 0, accuracyMeters: 5, time: DateTime.utc(2026, 1, 1, 6, 0, sec)),
      seg,
    );

void main() {
  late AppDatabase db;
  late WorkoutRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory(setup: (rawDb) {
      rawDb.execute('PRAGMA foreign_keys = ON;');
    }));
    repo = WorkoutRepository(WorkoutDao(db));
  });
  tearDown(() => db.close());

  test('seeds default routine and exercise library', () async {
    expect((await db.select(db.routineTasks).get()).length, 6);
    expect((await db.select(db.exercises).get()).length, 8);
  });

  test('create, save progress, finish and read back with route points', () async {
    await repo.create('w1', DateTime.utc(2026, 1, 1, 6));
    await repo.saveProgress('w1', 'recording', 10, 50, 30, [pt(0, 0, 0), pt(0.0001, 10, 0)]);
    await repo.finish('w1', 40, 120, 90, [pt(0.0002, 20, 1)]);
    final w = (await repo.byId('w1'))!;
    expect(w.status, 'completed');
    expect(w.steps, 40);
    expect(w.distanceMeters, 120);
    expect(w.localDate, isNotEmpty);
    expect(w.caloriesEstimate, greaterThan(0));
    expect((await repo.routePoints('w1')).length, 3);
  });

  test('deleting a workout cascades to its route points', () async {
    await repo.create('w1', DateTime.utc(2026, 1, 1, 6));
    await repo.saveProgress('w1', 'recording', 0, 0, 0, [pt(0, 0, 0)]);
    await repo.delete('w1');
    expect(await db.select(db.routePoints).get(), isEmpty);
  });

  test('route point with unknown workout violates the foreign key', () async {
    expect(
      db.into(db.routePoints).insert(RoutePointsCompanion.insert(
            workoutId: 'missing', latitude: 0, longitude: 0, recordedAt: DateTime.utc(2026), accuracyMeters: 5, segmentIndex: 0)),
      throwsA(isA<Exception>()),
    );
  });

  test('failed transaction rolls back every write', () async {
    await repo.create('w1', DateTime.utc(2026, 1, 1, 6));
    await expectLater(
      db.transaction(() async {
        await db.into(db.routePoints).insert(RoutePointsCompanion.insert(
            workoutId: 'w1', latitude: 1, longitude: 1, recordedAt: DateTime.utc(2026), accuracyMeters: 5, segmentIndex: 0));
        throw StateError('boom');
      }),
      throwsStateError,
    );
    expect(await db.select(db.routePoints).get(), isEmpty);
  });

  test('multiple completed workouts on one day are all returned', () async {
    for (final id in ['a', 'b']) {
      await repo.create(id, DateTime.utc(2026, 1, 1, 6));
      await repo.finish(id, 100, 500, 300, const []);
    }
    final rows = await repo.watchCompleted().first;
    expect(rows.length, 2);
    expect(rows.every((r) => r.localDate == rows.first.localDate), isTrue);
  });

  test('unfinished workouts are found for recovery, completed ones are not', () async {
    await repo.create('open', DateTime.utc(2026, 1, 1, 6));
    await repo.saveProgress('open', 'paused', 5, 30, 20, const []);
    await repo.create('done', DateTime.utc(2026, 1, 1, 7));
    await repo.finish('done', 1, 1, 1, const []);
    final open = await repo.unfinished();
    expect(open.map((w) => w.id), ['open']);
    expect(open.first.status, 'paused');
  });

  test('resetAll clears user data and restores defaults', () async {
    await repo.create('w1', DateTime.utc(2026, 1, 1, 6));
    await db.resetAll();
    expect(await db.select(db.workouts).get(), isEmpty);
    expect((await db.select(db.routineTasks).get()).length, 6);
  });
}
