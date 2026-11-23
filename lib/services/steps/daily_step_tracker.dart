import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'step_counter_service.dart';

class DailyStepState {
  const DailyStepState({
    this.todaySteps = 0,
    this.dailyGoal = 10000,
    this.isTracking = false,
    this.isAvailable = true,
    this.lastUpdated,
    this.statusMessage = 'Initializing...',
  });

  final int todaySteps;
  final int dailyGoal;
  final bool isTracking;
  final bool isAvailable;
  final DateTime? lastUpdated;
  final String statusMessage;

  double get progress => dailyGoal > 0 ? (todaySteps / dailyGoal).clamp(0.0, 1.0) : 0.0;
  bool get goalReached => todaySteps >= dailyGoal;

  DailyStepState copyWith({
    int? todaySteps,
    int? dailyGoal,
    bool? isTracking,
    bool? isAvailable,
    DateTime? lastUpdated,
    String? statusMessage,
  }) =>
      DailyStepState(
        todaySteps: todaySteps ?? this.todaySteps,
        dailyGoal: dailyGoal ?? this.dailyGoal,
        isTracking: isTracking ?? this.isTracking,
        isAvailable: isAvailable ?? this.isAvailable,
        lastUpdated: lastUpdated ?? this.lastUpdated,
        statusMessage: statusMessage ?? this.statusMessage,
      );
}

final dailyStepTrackerProvider =
    StateNotifierProvider<DailyStepTracker, DailyStepState>((ref) {
  final stepService = ref.watch(stepCounterServiceProvider);
  final tracker = DailyStepTracker(stepService);
  tracker.init();
  return tracker;
});

class DailyStepTracker extends StateNotifier<DailyStepState> {
  DailyStepTracker(this._stepService) : super(const DailyStepState());

  final StepCounterService _stepService;
  StreamSubscription<StepCount>? _stepSub;
  Timer? _midnightCheckTimer;
  SharedPreferences? _prefs;

  String _currentDateKey = '';
  int _baselineRawSteps = -1;
  int _rebootOffset = 0;
  int _lastRawSteps = -1;

  static String dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final goal = _prefs?.getInt('setting_daily_step_goal') ?? 10000;
    final enabled = _prefs?.getBool('setting_background_tracking_enabled') ?? true;

    final now = DateTime.now();
    _currentDateKey = dateKey(now);

    final savedTodaySteps = _prefs?.getInt('step_count_$_currentDateKey') ?? 0;
    _baselineRawSteps = _prefs?.getInt('step_baseline_$_currentDateKey') ?? -1;
    _rebootOffset = _prefs?.getInt('step_offset_$_currentDateKey') ?? 0;
    _lastRawSteps = _prefs?.getInt('step_last_raw') ?? -1;

    state = state.copyWith(
      todaySteps: savedTodaySteps,
      dailyGoal: goal,
      isTracking: enabled,
      statusMessage: enabled ? '24/7 background tracking active' : 'Tracking paused',
    );

    if (enabled) {
      await startTracking();
    }

    // Periodic timer to detect midnight (12:00 AM) rollover smoothly
    _midnightCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkMidnightRollover();
    });
  }

  Future<void> setDailyGoal(int newGoal) async {
    if (newGoal <= 0) return;
    await _prefs?.setInt('setting_daily_step_goal', newGoal);
    state = state.copyWith(dailyGoal: newGoal);
  }

  Future<void> toggleTracking(bool enable) async {
    await _prefs?.setBool('setting_background_tracking_enabled', enable);
    if (enable) {
      await startTracking();
      state = state.copyWith(
        isTracking: true,
        statusMessage: '24/7 background tracking active',
      );
    } else {
      await stopTracking();
      state = state.copyWith(
        isTracking: false,
        statusMessage: 'Tracking paused in settings',
      );
    }
  }

  Future<void> startTracking() async {
    try {
      if (!kIsWeb) {
        final status = await Permission.activityRecognition.request();
        if (status.isDenied || status.isPermanentlyDenied) {
          state = state.copyWith(
            statusMessage: 'Activity recognition permission needed',
          );
        }
      }

      await _stepSub?.cancel();
      _stepSub = _stepService.stepCounts.listen(
        _onStepCount,
        onError: (err) {
          debugPrint('Step sensor error or unavailable: $err');
          state = state.copyWith(
            isAvailable: false,
            statusMessage: 'Hardware step sensor unavailable',
          );
        },
      );
    } catch (e) {
      debugPrint('Error starting step tracker: $e');
      state = state.copyWith(
        isAvailable: false,
        statusMessage: 'Sensor initialization error',
      );
    }
  }

  void _onStepCount(StepCount event) {
    final raw = event.steps;
    final now = DateTime.now();
    _checkMidnightRollover();

    if (_lastRawSteps != -1 && raw < _lastRawSteps) {
      // Device rebooted! Raw step counter reset
      _rebootOffset = state.todaySteps;
      _baselineRawSteps = raw;
      _prefs?.setInt('step_offset_$_currentDateKey', _rebootOffset);
      _prefs?.setInt('step_baseline_$_currentDateKey', _baselineRawSteps);
    } else if (_baselineRawSteps < 0) {
      _baselineRawSteps = raw;
      _prefs?.setInt('step_baseline_$_currentDateKey', _baselineRawSteps);
    }

    _lastRawSteps = raw;
    _prefs?.setInt('step_last_raw', raw);

    final stepsSinceBaseline = max(0, raw - _baselineRawSteps);
    final calculatedToday = _rebootOffset + stepsSinceBaseline;

    _prefs?.setInt('step_count_$_currentDateKey', calculatedToday);

    state = state.copyWith(
      todaySteps: calculatedToday,
      isAvailable: true,
      lastUpdated: now,
      statusMessage: 'Tracking active • Continuous hardware sync',
    );
  }

  void _checkMidnightRollover() {
    final today = dateKey(DateTime.now());
    if (_currentDateKey.isNotEmpty && today != _currentDateKey) {
      // Midnight passed (12:00 AM)! Finalize previous day and start new day
      _currentDateKey = today;
      _baselineRawSteps = _lastRawSteps;
      _rebootOffset = 0;

      _prefs?.setInt('step_baseline_$_currentDateKey', _baselineRawSteps);
      _prefs?.setInt('step_offset_$_currentDateKey', 0);
      _prefs?.setInt('step_count_$_currentDateKey', 0);

      state = state.copyWith(
        todaySteps: 0,
        lastUpdated: DateTime.now(),
        statusMessage: 'New day started at midnight (12:00 AM)',
      );
    }
  }

  Future<int> getStepsForDate(DateTime date) async {
    final key = dateKey(date);
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs?.getInt('step_count_$key') ?? 0;
  }

  Future<void> stopTracking() async {
    await _stepSub?.cancel();
    _stepSub = null;
  }

  @override
  void dispose() {
    _stepSub?.cancel();
    _midnightCheckTimer?.cancel();
    super.dispose();
  }
}
