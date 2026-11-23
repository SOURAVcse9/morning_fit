import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HydrationState {
  const HydrationState({
    this.glasses = 0,
    this.targetGlasses = 8,
    this.dateKey = '',
  });

  final int glasses;
  final int targetGlasses;
  final String dateKey;

  double get progress => (glasses / targetGlasses).clamp(0.0, 1.0);
  int get milliliters => glasses * 250;
  int get targetMilliliters => targetGlasses * 250;
  bool get targetReached => glasses >= targetGlasses;

  HydrationState copyWith({
    int? glasses,
    int? targetGlasses,
    String? dateKey,
  }) =>
      HydrationState(
        glasses: glasses ?? this.glasses,
        targetGlasses: targetGlasses ?? this.targetGlasses,
        dateKey: dateKey ?? this.dateKey,
      );
}

final hydrationTrackerProvider =
    StateNotifierProvider<HydrationTracker, HydrationState>((ref) {
  final tracker = HydrationTracker();
  tracker.init();
  return tracker;
});

class HydrationTracker extends StateNotifier<HydrationState> {
  HydrationTracker() : super(const HydrationState());

  SharedPreferences? _prefs;

  static String dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final today = dateKey(DateTime.now());
    final savedGlasses = _prefs?.getInt('water_intake_$today') ?? 0;
    final target = _prefs?.getInt('setting_target_glasses') ?? 8;

    state = state.copyWith(
      glasses: savedGlasses,
      targetGlasses: target,
      dateKey: today,
    );
  }

  void _checkDateRollover() {
    final today = dateKey(DateTime.now());
    if (state.dateKey.isNotEmpty && today != state.dateKey) {
      final savedGlasses = _prefs?.getInt('water_intake_$today') ?? 0;
      state = state.copyWith(
        glasses: savedGlasses,
        dateKey: today,
      );
    }
  }

  Future<void> addGlass() async {
    _checkDateRollover();
    final current = state.glasses;
    if (current >= 24) return; // reasonable daily safety cap
    final next = current + 1;
    await _prefs?.setInt('water_intake_${state.dateKey}', next);
    state = state.copyWith(glasses: next);
  }

  Future<void> removeGlass() async {
    _checkDateRollover();
    final current = state.glasses;
    if (current <= 0) return;
    final next = current - 1;
    await _prefs?.setInt('water_intake_${state.dateKey}', next);
    state = state.copyWith(glasses: next);
  }

  Future<int> getGlassesForDate(DateTime date) async {
    final key = dateKey(date);
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs?.getInt('water_intake_$key') ?? 0;
  }
}
