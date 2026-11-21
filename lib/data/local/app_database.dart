import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tables/workouts.dart';
import 'tables/route_points.dart';
import 'tables/routine_tasks.dart';
import 'tables/task_completions.dart';
import 'tables/exercises.dart';
import 'tables/exercise_sessions.dart';
import 'tables/app_settings.dart';

part 'app_database.g.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

@DriftDatabase(tables: [
  Workouts,
  RoutePoints,
  RoutineTasks,
  TaskCompletions,
  Exercises,
  ExerciseSessions,
  AppSettings
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'morningfit_db'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await batch((b) {
            b.insertAll(exercises, _starterExercises);
            b.insertAll(routineTasks, _starterRoutineTasks);
          });
        },
        onUpgrade: (m, from, to) async {
          // Add explicit, tested migrations here when schemaVersion changes.
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  List<ExercisesCompanion> get _starterExercises => [
        const ExercisesCompanion(
            id: Value('squat'),
            name: Value('Squats'),
            category: Value('Legs'),
            difficulty: Value('Beginner'),
            description: Value('Sit hips back and stand up with control.'),
            instructions: Value(
                'Keep feet shoulder-width apart. Lower comfortably, then stand.')),
        const ExercisesCompanion(
            id: Value('wall_pushup'),
            name: Value('Wall Push-ups'),
            category: Value('Upper body'),
            difficulty: Value('Beginner'),
            description: Value('A gentle push-up variation.'),
            instructions:
                Value('Place hands on a wall, bend elbows, and push away.')),
        const ExercisesCompanion(
            id: Value('glute_bridge'),
            name: Value('Glute Bridge'),
            category: Value('Legs'),
            difficulty: Value('Beginner'),
            description: Value('Strengthens glutes and posterior chain.'),
            instructions: Value(
                'Lie on your back with knees bent and lift hips comfortably.')),
        const ExercisesCompanion(
            id: Value('calf_raise'),
            name: Value('Calf Raises'),
            category: Value('Legs'),
            difficulty: Value('Beginner'),
            description: Value('Strengthens calf muscles.'),
            instructions:
                Value('Rise onto toes slowly and lower with control.')),
        const ExercisesCompanion(
            id: Value('plank'),
            name: Value('Plank'),
            category: Value('Core'),
            difficulty: Value('Beginner'),
            description: Value('Builds core stability.'),
            instructions:
                Value('Keep a straight body line and stop if you feel pain.')),
        const ExercisesCompanion(
            id: Value('biceps_curl'),
            name: Value('Water Bottle Biceps Curl'),
            category: Value('Arms'),
            difficulty: Value('Beginner'),
            description: Value('Use two light water bottles.'),
            instructions:
                Value('Keep elbows close to your body and lift slowly.')),
      ];

  List<RoutineTasksCompanion> get _starterRoutineTasks => [
        const RoutineTasksCompanion(
            id: Value('hydration'),
            title: Value('Drink Water'),
            description: Value('Start the day with a glass of water.'),
            scheduledTime: Value('06:00'),
            durationMinutes: Value(5)),
        const RoutineTasksCompanion(
            id: Value('morning_walk'),
            title: Value('Morning Walk'),
            description: Value('Walk at a comfortable pace.'),
            scheduledTime: Value('06:10'),
            durationMinutes: Value(20)),
        const RoutineTasksCompanion(
            id: Value('stretch'),
            title: Value('Full-body Stretch'),
            description: Value('Mobility and gentle stretching.'),
            scheduledTime: Value('06:35'),
            durationMinutes: Value(10)),
      ];
}
