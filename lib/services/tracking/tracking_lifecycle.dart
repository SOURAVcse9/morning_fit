import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/failures.dart';
import '../../features/analytics/domain/stats.dart';
import '../../features/walking/domain/calories.dart';
import '../../shared/providers/providers.dart';
import '../location/location_service.dart';
import '../location/route_recorder.dart';
import '../steps/step_counter_service.dart';

enum WalkStatus { idle, recording, paused, saving }
enum GpsStatus { unknown, good, weak, lost }

class TrackingState {
  const TrackingState({
    this.status = WalkStatus.idle,
    this.workoutId,
    this.elapsedSeconds = 0,
    this.distanceMeters = 0,
    this.steps = 0,
    this.stepAvailability,
    this.accuracyMeters,
    this.gps = GpsStatus.unknown,
    this.segments = const [],
    this.current,
    this.message,
    this.access,
    this.recovered = false,
    this.finishedId,
  });

  final WalkStatus status;
  final String? workoutId;
  final int elapsedSeconds;
  final double distanceMeters;
  final int steps;
  final StepAvailability? stepAvailability;
  final double? accuracyMeters;
  final GpsStatus gps;
  final List<List<LatLng>> segments;
  final LatLng? current;
  final String? message;
  final LocationAccess? access;
  final bool recovered;
  final String? finishedId;

  double? get paceSecPerKm => averagePace(distanceMeters, elapsedSeconds);
  bool get active => status == WalkStatus.recording || status == WalkStatus.paused;

  TrackingState copyWith({
    WalkStatus? status,
    String? workoutId,
    int? elapsedSeconds,
    double? distanceMeters,
    int? steps,
    StepAvailability? stepAvailability,
    double? accuracyMeters,
    GpsStatus? gps,
    List<List<LatLng>>? segments,
    LatLng? current,
    String? message,
    bool clearMessage = false,
    LocationAccess? access,
    bool? recovered,
    String? finishedId,
  }) =>
      TrackingState(
        status: status ?? this.status,
        workoutId: workoutId ?? this.workoutId,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        distanceMeters: distanceMeters ?? this.distanceMeters,
        steps: steps ?? this.steps,
        stepAvailability: stepAvailability ?? this.stepAvailability,
        accuracyMeters: accuracyMeters ?? this.accuracyMeters,
        gps: gps ?? this.gps,
        segments: segments ?? this.segments,
        current: current ?? this.current,
        message: clearMessage ? null : (message ?? this.message),
        access: access ?? this.access,
        recovered: recovered ?? this.recovered,
        finishedId: finishedId ?? this.finishedId,
      );
}

/// Owns the GPS and step subscriptions (never widgets).
/// State machine: idle -> recording <-> paused -> idle (saved) or idle (cancelled).
/// UI state is published once per second (throttled); location events only
/// update the recorder.
class TrackingController extends Notifier<TrackingState> {
  RouteRecorder _recorder = RouteRecorder();
  StepDeltaTracker _steps = StepDeltaTracker();
  StreamSubscription<LocationSample>? _locSub;
  StreamSubscription<int>? _stepSub;
  Timer? _ticker;
  int _accSeconds = 0;
  DateTime? _resumedAt;
  DateTime? _lastAccepted;
  double? _lastAccuracy;
  LatLng? _lastLatLng;
  int _publishedPoints = -1;
  DateTime _lastFlush = DateTime.now();
  bool _flushing = false;

  @override
  TrackingState build() {
    ref.onDispose(_stopStreams);
    return const TrackingState();
  }

  int get _elapsed =>
      _accSeconds + (_resumedAt == null ? 0 : DateTime.now().difference(_resumedAt!).inSeconds);

  Future<void> start() async {
    if (state.status != WalkStatus.idle) return;
    final access = await ref.read(locationServiceProvider).ensureAccess();
    if (access != LocationAccess.granted) {
      state = TrackingState(
        access: access,
        message: switch (access) {
          LocationAccess.serviceDisabled => Messages.locationDisabled,
          LocationAccess.deniedForever => Messages.locationDeniedForever,
          _ => Messages.locationDenied,
        },
      );
      return;
    }
    final id = const Uuid().v4();
    try {
      await ref.read(workoutRepositoryProvider).create(id, DateTime.now().toUtc());
    } catch (_) {
      state = const TrackingState(message: Messages.dbFailure);
      return;
    }
    _recorder = RouteRecorder();
    _steps = StepDeltaTracker();
    _accSeconds = 0;
    _lastAccepted = null;
    _publishedPoints = -1;
    state = TrackingState(status: WalkStatus.recording, workoutId: id, access: access);
    _activate();
    await _startSteps();
  }

  Future<void> _startSteps() async {
    final src = ref.read(stepSourceProvider);
    final avail = await src.check();
    state = state.copyWith(stepAvailability: avail);
    if (avail != StepAvailability.available) {
      state = state.copyWith(
          message: avail == StepAvailability.permissionDenied
              ? Messages.stepPermissionDenied
              : Messages.sensorUnavailable);
      return;
    }
    await _stepSub?.cancel();
    _stepSub = src.stepCounts().listen(
      (v) => _steps.onReading(v, counting: state.status == WalkStatus.recording),
      onError: (Object _) {
        state = state.copyWith(stepAvailability: StepAvailability.unavailable, message: Messages.sensorUnavailable);
      },
    );
  }

  void _activate() {
    _resumedAt = DateTime.now();
    _lastAccepted = DateTime.now();
    _locSub?.cancel();
    _locSub = ref.read(locationServiceProvider).track().listen(
      _onSample,
      onError: (Object _) => state = state.copyWith(gps: GpsStatus.lost, message: Messages.gpsLost),
    );
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _onSample(LocationSample s) {
    _lastAccuracy = s.accuracyMeters;
    final v = _recorder.add(s);
    if (v == SampleVerdict.accepted || v == SampleVerdict.firstOfSegment) {
      _lastAccepted = DateTime.now();
      _lastLatLng = LatLng(s.latitude, s.longitude);
    }
  }

  void _tick() {
    if (state.status != WalkStatus.recording) return;
    final sinceFix = _lastAccepted == null ? 0 : DateTime.now().difference(_lastAccepted!).inSeconds;
    final gps = sinceFix > 15
        ? GpsStatus.lost
        : (_lastAccuracy != null && _lastAccuracy! > _recorder.maxAccuracyMeters ? GpsStatus.weak : GpsStatus.good);
    final changed = _recorder.points.length != _publishedPoints;
    if (changed) _publishedPoints = _recorder.points.length;
    state = state.copyWith(
      elapsedSeconds: _elapsed,
      distanceMeters: _recorder.totalMeters,
      steps: _steps.sessionSteps,
      accuracyMeters: _lastAccuracy,
      gps: gps,
      current: _lastLatLng,
      segments: changed ? _segments() : null,
    );
    if (DateTime.now().difference(_lastFlush).inSeconds >= 10) _flush();
  }

  List<List<LatLng>> _segments() {
    final out = <int, List<LatLng>>{};
    for (final p in _recorder.points) {
      out.putIfAbsent(p.segmentIndex, () => []).add(LatLng(p.sample.latitude, p.sample.longitude));
    }
    final keys = out.keys.toList()..sort();
    return [for (final k in keys) out[k]!];
  }

  Future<void> _flush({String? status}) async {
    final id = state.workoutId;
    if (id == null || _flushing) return;
    _flushing = true;
    _lastFlush = DateTime.now();
    final pts = _recorder.drainUnsaved();
    try {
      await ref.read(workoutRepositoryProvider).saveProgress(
            id,
            status ?? (state.status == WalkStatus.paused ? 'paused' : 'recording'),
            _steps.sessionSteps,
            _recorder.totalMeters,
            _elapsed,
            pts,
          );
    } catch (_) {
      _recorder.requeue(pts); // retry on next flush; nothing silently dropped
      state = state.copyWith(message: Messages.dbFailure);
    } finally {
      _flushing = false;
    }
  }

  Future<void> pause() async {
    if (state.status != WalkStatus.recording) return;
    _accSeconds = _elapsed;
    _resumedAt = null;
    await _locSub?.cancel(); // stops GPS + Android foreground service while paused
    _locSub = null;
    _ticker?.cancel();
    state = state.copyWith(status: WalkStatus.paused, elapsedSeconds: _accSeconds, distanceMeters: _recorder.totalMeters, steps: _steps.sessionSteps);
    await _flush(status: 'paused');
  }

  Future<void> resume() async {
    if (state.status != WalkStatus.paused) return;
    final access = await ref.read(locationServiceProvider).ensureAccess();
    if (access != LocationAccess.granted) {
      state = state.copyWith(access: access, message: Messages.locationDenied);
      return;
    }
    _recorder.startNewSegment();
    state = state.copyWith(status: WalkStatus.recording, clearMessage: true);
    _activate();
    if (_stepSub == null) await _startSteps();
  }

  /// Saves the walk. Returns the workout id, or null if saving failed.
  Future<String?> finish() async {
    final id = state.workoutId;
    if (id == null || !state.active) return null;
    final seconds = state.status == WalkStatus.recording ? _elapsed : _accSeconds;
    _stopStreams();
    state = state.copyWith(status: WalkStatus.saving);
    final pts = _recorder.drainUnsaved();
    final settings = ref.read(settingsProvider).valueOrNull;
    try {
      await ref.read(workoutRepositoryProvider).finish(id, _steps.sessionSteps, _recorder.totalMeters, seconds, pts,
          weightKg: settings?.weightKg ?? 70);
    } catch (_) {
      _recorder.requeue(pts);
      state = state.copyWith(status: WalkStatus.paused, message: Messages.dbFailure);
      return null;
    }
    await _maybeNotifyGoal(settings?.stepGoal ?? 8000, settings?.distanceGoalMeters ?? 5000);
    state = TrackingState(finishedId: id);
    return id;
  }

  Future<void> _maybeNotifyGoal(int stepGoal, double meterGoal) async {
    try {
      final records = await ref.read(workoutRepositoryProvider).watchCompleted().first;
      final today = DateTime.now();
      final key = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final totals = DayTotals(key);
      for (final w in records.where((w) => w.localDate == key)) {
        totals.steps += w.steps;
        totals.meters += w.distanceMeters;
      }
      if (goalMet(totals, stepGoal: stepGoal, distanceGoalMeters: meterGoal) &&
          (ref.read(settingsProvider).valueOrNull?.remindersEnabled ?? false)) {
        await ref.read(notificationServiceProvider).showGoalReached();
      }
    } catch (_) {
      // Notification is optional; the workout is already saved.
    }
  }

  Future<void> cancel() async {
    final id = state.workoutId;
    _stopStreams();
    if (id != null) {
      try {
        await ref.read(workoutRepositoryProvider).delete(id);
      } catch (_) {
        state = state.copyWith(message: Messages.dbFailure);
        return;
      }
    }
    state = const TrackingState();
  }

  /// Interrupted-walk rule: a recovered walk always comes back PAUSED with its
  /// saved distance/steps/time. The user chooses Resume (new segment, so no
  /// straight line is drawn across the gap), Finish (keep saved data) or Discard.
  Future<void> recover() async {
    if (state.status != WalkStatus.idle) return;
    final repo = ref.read(workoutRepositoryProvider);
    final open = await repo.unfinished();
    if (open.isEmpty) return;
    final w = open.first;
    final pts = await repo.routePoints(w.id);
    final saved = [
      for (final p in pts)
        RecordedPoint(
          LocationSample(latitude: p.latitude, longitude: p.longitude, accuracyMeters: p.accuracyMeters, time: p.recordedAt),
          p.segmentIndex,
        )
    ];
    _recorder = RouteRecorder()..restore(saved, w.distanceMeters);
    _steps = StepDeltaTracker(initialSteps: w.steps);
    _accSeconds = w.durationSeconds;
    _resumedAt = null;
    _publishedPoints = -1;
    state = TrackingState(
      status: WalkStatus.paused,
      workoutId: w.id,
      elapsedSeconds: w.durationSeconds,
      distanceMeters: w.distanceMeters,
      steps: w.steps,
      segments: _segments(),
      recovered: true,
      message: Messages.interrupted,
    );
    await ref.read(workoutRepositoryProvider).saveProgress(w.id, 'paused', w.steps, w.distanceMeters, w.durationSeconds, const []);
  }

  void clearMessage() => state = state.copyWith(clearMessage: true);

  void _stopStreams() {
    _locSub?.cancel();
    _locSub = null;
    _stepSub?.cancel();
    _stepSub = null;
    _ticker?.cancel();
    _ticker = null;
  }
}

final trackingProvider = NotifierProvider<TrackingController, TrackingState>(TrackingController.new);
