import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide DistanceCalculator;
import 'package:uuid/uuid.dart';
import '../../../services/location/location_service.dart';
import '../../../services/location/distance_calculator.dart';
import '../../../services/steps/step_counter_service.dart';
import '../../../data/local/app_database.dart';

final locationServiceProvider = Provider((ref) => LocationService());
final stepCounterServiceProvider = Provider((ref) => StepCounterService());
final walkingControllerProvider =
    StateNotifierProvider<WalkingController, WalkingState>(
        (ref) => WalkingController(ref));

class WalkingState {
  const WalkingState(
      {this.isActive = false,
      this.isPaused = false,
      this.workoutId,
      this.steps = 0,
      this.distanceMeters = 0,
      this.elapsedSeconds = 0,
      this.points = const [],
      this.message});
  final bool isActive;
  final bool isPaused;
  final String? workoutId;
  final int steps;
  final int distanceMeters;
  final int elapsedSeconds;
  final List<LatLng> points;
  final String? message;
  WalkingState copyWith(
          {bool? isActive,
          bool? isPaused,
          String? workoutId,
          int? steps,
          int? distanceMeters,
          int? elapsedSeconds,
          List<LatLng>? points,
          String? message}) =>
      WalkingState(
          isActive: isActive ?? this.isActive,
          isPaused: isPaused ?? this.isPaused,
          workoutId: workoutId ?? this.workoutId,
          steps: steps ?? this.steps,
          distanceMeters: distanceMeters ?? this.distanceMeters,
          elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
          points: points ?? this.points,
          message: message);
}

/// Foreground prototype controller. A production background recorder must be
/// backed by native Android foreground-service and iOS Core Location handling.
class WalkingController extends StateNotifier<WalkingState> {
  WalkingController(this.ref) : super(const WalkingState());
  final Ref ref;
  StreamSubscription<Position>? _locationSub;
  StreamSubscription<dynamic>? _stepSub;
  DateTime? _startedAt;
  DateTime? _lastTick;
  LatLng? _lastAccepted;
  Timer? _durationTimer;
  int _baselineSteps = 0;

  Future<void> start() async {
    if (state.isActive) return;
    final location = ref.read(locationServiceProvider);
    if (!await location.ensurePermission()) {
      state = state.copyWith(
          message: 'Location permission or location service is unavailable.');
      return;
    }
    _startedAt = DateTime.now();
    _lastTick = _startedAt;
    final id = const Uuid().v4();
    final db = ref.read(appDatabaseProvider);
    await db.into(db.workouts).insert(WorkoutsCompanion.insert(
        id: id,
        startedAt: _startedAt!.toUtc(),
        status: const Value('recording')));
    state = WalkingState(isActive: true, workoutId: id);
    _startDurationTimer();
    _locationSub = location.positions().listen(_onPosition,
        onError: (_) =>
            state = state.copyWith(message: 'GPS updates unavailable.'));
    _stepSub = ref.read(stepCounterServiceProvider).stepCounts.listen((event) {
      final current = event.steps;
      if (_baselineSteps == 0) _baselineSteps = current;
      final delta = current - _baselineSteps;
      if (delta >= 0) state = state.copyWith(steps: delta);
    },
        onError: (_) => state =
            state.copyWith(message: 'Step sensor unavailable on this device.'));
  }

  void _onPosition(Position p) {
    if (state.isPaused || !state.isActive) return;
    if (p.accuracy > 35) return;
    final point = LatLng(p.latitude, p.longitude);
    final previous = _lastAccepted;
    var distance = state.distanceMeters;
    if (previous != null) {
      final segment = DistanceCalculator.metersBetween(previous, point);
      final elapsed = _lastTick == null
          ? 1
          : DateTime.now()
              .difference(_lastTick!)
              .inSeconds
              .clamp(1, 60)
              .toInt();
      final speed = segment / elapsed;
      if (segment > 0.8 && speed < 8) distance += segment.round();
      if (segment > 250) return;
    }
    _lastAccepted = point;
    _lastTick = DateTime.now();
    state = state
        .copyWith(distanceMeters: distance, points: [...state.points, point]);
    _persistProgress();
  }

  Future<void> _persistProgress() async {
    final id = state.workoutId;
    if (id == null) return;
    final db = ref.read(appDatabaseProvider);
    await db.into(db.workouts).insertOnConflictUpdate(WorkoutsCompanion(
        id: Value(id),
        steps: Value(state.steps),
        distanceMeters: Value(state.distanceMeters),
        durationSeconds: Value(state.elapsedSeconds),
        updatedAt: Value(DateTime.now().toUtc())));
    final point = state.points.isEmpty ? null : state.points.last;
    if (point != null) {
      await db.into(db.routePoints).insertOnConflictUpdate(RoutePointsCompanion(
          workoutId: Value(id),
          latitude: Value(point.latitude),
          longitude: Value(point.longitude),
          recordedAt: Value(DateTime.now().toUtc()),
          accuracyMeters: const Value(null)));
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isActive && !state.isPaused) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });
  }

  void pause() {
    if (state.isActive) {
      state = state.copyWith(isPaused: true);
      _durationTimer?.cancel();
    }
  }

  void resume() {
    if (state.isActive) {
      _lastAccepted = null;
      _lastTick = DateTime.now();
      state = state.copyWith(isPaused: false);
      _startDurationTimer();
    }
  }

  Future<void> finish() async {
    final id = state.workoutId;
    if (id == null) return;
    _durationTimer?.cancel();
    await _locationSub?.cancel();
    await _stepSub?.cancel();
    final db = ref.read(appDatabaseProvider);
    await (db.update(db.workouts)..where((t) => t.id.equals(id))).write(
        WorkoutsCompanion(
            endedAt: Value(DateTime.now().toUtc()),
            status: const Value('completed'),
            steps: Value(state.steps),
            distanceMeters: Value(state.distanceMeters),
            durationSeconds: Value(state.elapsedSeconds),
            updatedAt: Value(DateTime.now().toUtc())));
    state = const WalkingState();
    _baselineSteps = 0;
    _lastAccepted = null;
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _locationSub?.cancel();
    _stepSub?.cancel();
    super.dispose();
  }
}
