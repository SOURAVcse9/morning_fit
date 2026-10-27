import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../data/local/app_database.dart';
import '../../data/local/daos/routine_dao.dart';
import '../../data/local/daos/workout_dao.dart';
import '../../features/settings/data/export_service.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/walking/data/workout_repository.dart';
import '../../services/location/location_service.dart';
import '../../services/notifications/notification_service.dart';
import '../../services/steps/step_counter_service.dart';
import '../models/app_settings_model.dart';
import '../models/workout_record.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final workoutRepositoryProvider =
    Provider((ref) => WorkoutRepository(WorkoutDao(ref.watch(databaseProvider))));
final routineDaoProvider = Provider((ref) => RoutineDao(ref.watch(databaseProvider)));
final settingsRepositoryProvider =
    Provider((ref) => SettingsRepository(ref.watch(routineDaoProvider)));
final exportServiceProvider = Provider((ref) => ExportService(ref.watch(databaseProvider)));

final locationServiceProvider = Provider<LocationService>((ref) => GeolocatorLocationService());
final stepSourceProvider = Provider<StepSource>((ref) => PedometerStepSource());
final notificationServiceProvider = Provider((ref) => NotificationService());

/// Settings, persisted in the appSettings table.
class SettingsNotifier extends AsyncNotifier<AppSettingsModel> {
  @override
  Future<AppSettingsModel> build() => ref.read(settingsRepositoryProvider).load();

  Future<void> change(AppSettingsModel Function(AppSettingsModel) change) async {
    final next = change(state.valueOrNull ?? const AppSettingsModel());
    state = AsyncData(next);
    await ref.read(settingsRepositoryProvider).save(next);
    await rescheduleReminders();
  }

  /// Rebuilds all scheduled reminders from the database and current settings.
  Future<void> rescheduleReminders() async {
    final s = state.valueOrNull ?? const AppSettingsModel();
    final tasks = await ref.read(routineDaoProvider).tasks();
    final n = ref.read(notificationServiceProvider);
    try {
      await n.rescheduleRoutine(tasks, enabled: s.remindersEnabled);
      await n.scheduleSummaries(enabled: s.summariesEnabled);
    } catch (e) {
      // Surfaced in Settings via reminderError.
      ref.read(reminderErrorProvider.notifier).state = 'Could not schedule reminders: $e';
    }
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettingsModel>(SettingsNotifier.new);
final reminderErrorProvider = StateProvider<String?>((ref) => null);

AppSettingsModel settingsOf(WidgetRef ref) =>
    ref.watch(settingsProvider).valueOrNull ?? const AppSettingsModel();

ThemeMode themeModeOf(WidgetRef ref) => settingsOf(ref).themeMode;

/// All completed workouts as plain records (single query, reactive).
final workoutRecordsProvider = StreamProvider<List<WorkoutRecord>>((ref) {
  return ref.watch(workoutRepositoryProvider).watchCompleted().map((rows) => [
        for (final w in rows)
          WorkoutRecord(
            id: w.id,
            startedAt: w.startedAt,
            localDate: w.localDate,
            durationSeconds: w.durationSeconds,
            distanceMeters: w.distanceMeters,
            steps: w.steps,
            calories: w.caloriesEstimate,
          )
      ]);
});

final routineTasksProvider = StreamProvider<List<RoutineTask>>((ref) => ref.watch(routineDaoProvider).watchTasks());
final exercisesProvider = StreamProvider<List<Exercise>>((ref) => ref.watch(routineDaoProvider).watchExercises());

final completionsProvider = StreamProvider<List<TaskCompletion>>((ref) {
  final from = DateTime.now().subtract(const Duration(days: 14));
  final key = '${from.year}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}';
  return ref.watch(routineDaoProvider).watchCompletionsSince(key);
});

final workoutProvider = FutureProvider.family<Workout?, String>(
    (ref, id) => ref.watch(workoutRepositoryProvider).byId(id));

final routeProvider = FutureProvider.family<List<List<LatLng>>, String>((ref, id) async {
  final pts = await ref.watch(workoutRepositoryProvider).routePoints(id);
  final segs = <int, List<LatLng>>{};
  for (final p in pts) {
    segs.putIfAbsent(p.segmentIndex, () => []).add(LatLng(p.latitude, p.longitude));
  }
  final keys = segs.keys.toList()..sort();
  return [for (final k in keys) segs[k]!];
});
