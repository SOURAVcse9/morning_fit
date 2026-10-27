import '../../../core/utils/date_utils.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/daos/workout_dao.dart';
import '../../../services/location/route_recorder.dart';
import '../domain/calories.dart';

class WorkoutRepository {
  WorkoutRepository(this._dao);
  final WorkoutDao _dao;

  Future<void> create(String id, DateTime startedAtUtc) =>
      _dao.insert(id, startedAtUtc, localDateKey(startedAtUtc));

  List<RoutePointsCompanion> _companions(String id, List<RecordedPoint> pts) => [
        for (final p in pts)
          RoutePointsCompanion.insert(
            workoutId: id,
            latitude: p.sample.latitude,
            longitude: p.sample.longitude,
            recordedAt: p.sample.time,
            accuracyMeters: p.sample.accuracyMeters,
            segmentIndex: p.segmentIndex,
          ),
      ];

  Future<void> saveProgress(String id, String status, int steps, double meters, int seconds,
          List<RecordedPoint> pts) =>
      _dao.saveProgress(
        id: id,
        status: status,
        steps: steps,
        distanceMeters: meters,
        durationSeconds: seconds,
        points: _companions(id, pts),
      );

  Future<void> finish(String id, int steps, double meters, int seconds, List<RecordedPoint> pts,
          {double weightKg = 70}) =>
      _dao.complete(
        id: id,
        endedAtUtc: DateTime.now().toUtc(),
        steps: steps,
        distanceMeters: meters,
        durationSeconds: seconds,
        calories: estimateCalories(meters, weightKg: weightKg),
        averagePace: averagePace(meters, seconds),
        points: _companions(id, pts),
      );

  Future<void> delete(String id) => _dao.delete(id);
  Stream<List<Workout>> watchCompleted() => _dao.watchCompleted();
  Future<Workout?> byId(String id) => _dao.byId(id);
  Future<List<Workout>> unfinished() => _dao.unfinished();
  Future<List<RoutePoint>> routePoints(String id) => _dao.routePoints(id);
}
