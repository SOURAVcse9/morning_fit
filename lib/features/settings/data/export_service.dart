import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../data/local/app_database.dart';

/// User-initiated JSON export. Contains workouts, route coordinates, routine
/// tasks and exercise sessions. The file is written to the app's documents
/// folder on this device only; nothing is uploaded.
class ExportService {
  ExportService(this._db);
  final AppDatabase _db;

  Future<File> exportJson() async {
    final workouts = await _db.select(_db.workouts).get();
    final points = await _db.select(_db.routePoints).get();
    final tasks = await _db.select(_db.routineTasks).get();
    final sessions = await _db.select(_db.exerciseSessions).get();
    final data = {
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'workouts': [
        for (final w in workouts)
          {
            'id': w.id,
            'startedAt': w.startedAt.toUtc().toIso8601String(),
            'endedAt': w.endedAt?.toUtc().toIso8601String(),
            'status': w.status,
            'steps': w.steps,
            'distanceMeters': w.distanceMeters,
            'durationSeconds': w.durationSeconds,
            'caloriesEstimate': w.caloriesEstimate,
            'averagePaceSecPerKm': w.averagePace,
            'localDate': w.localDate,
          }
      ],
      'routePoints': [
        for (final p in points)
          {
            'workoutId': p.workoutId,
            'lat': p.latitude,
            'lon': p.longitude,
            'recordedAt': p.recordedAt.toUtc().toIso8601String(),
            'accuracyMeters': p.accuracyMeters,
            'segment': p.segmentIndex,
          }
      ],
      'routineTasks': [
        for (final t in tasks)
          {'title': t.title, 'minutes': t.scheduledMinutes, 'days': t.repeatDays, 'enabled': t.isEnabled}
      ],
      'exerciseSessions': [
        for (final s in sessions)
          {
            'exerciseId': s.exerciseId,
            'startedAt': s.startedAt.toUtc().toIso8601String(),
            'durationSeconds': s.durationSeconds,
            'sets': s.setsCompleted,
            'reps': s.repsCompleted,
          }
      ],
    };
    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${dir.path}/morningfit_export_$stamp.json');
    return file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));
  }
}
