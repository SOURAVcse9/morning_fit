import 'package:drift/drift.dart';
import 'app_database.dart';

/// Default routine and exercise library inserted on first run.
Future<void> seedDefaults(AppDatabase db) async {
  final tasks = <(String, String, int, int)>[
    ('Wake up & drink water', 'Start the day with a glass of water.', 6 * 60, 5),
    ('Warm-up', 'Gentle mobility to prepare your body.', 6 * 60 + 5, 5),
    ('Morning Walk', 'Open the Walk tab and press Start.', 6 * 60 + 10, 30),
    ('Home Workout', 'Pick exercises from the library.', 6 * 60 + 40, 15),
    ('Stretching', 'Cool down and stretch.', 6 * 60 + 55, 10),
    ('Breakfast reminder', 'Time for a healthy breakfast.', 7 * 60 + 5, 0),
  ];
  for (final t in tasks) {
    final id = await db.into(db.routineTasks).insert(RoutineTasksCompanion.insert(
          title: t.$1,
          description: Value(t.$2),
          scheduledMinutes: t.$3,
          durationMinutes: Value(t.$4),
        ));
    await (db.update(db.routineTasks)..where((r) => r.id.equals(id)))
        .write(RoutineTasksCompanion(notificationId: Value(id)));
  }

  Future<void> ex(String id, String name, String desc, String cat, String diff,
      List<String> steps, int sets, int reps, int rest) {
    return db.into(db.exercises).insertOnConflictUpdate(ExercisesCompanion.insert(
          id: id,
          name: name,
          description: desc,
          category: cat,
          difficulty: diff,
          instructions: steps.join('\n'),
          defaultSets: sets,
          defaultReps: reps,
          restSeconds: rest,
        ));
  }

  await ex('squats', 'Squats', 'Strengthens thighs and glutes.', 'Legs', 'Beginner', [
    'Stand with feet shoulder-width apart.',
    'Push hips back and bend knees as if sitting on a chair.',
    'Keep chest up and knees in line with toes.',
    'Press through heels to stand up.'
  ], 3, 12, 45);
  await ex('wall-pushups', 'Wall push-ups', 'Easiest push-up variation for chest, shoulders and arms.', 'Upper body', 'Beginner', [
    'Stand an arm\'s length from a wall, palms on the wall at shoulder height.',
    'Bend elbows and bring your chest toward the wall.',
    'Keep your body in a straight line.',
    'Push back to the start.'
  ], 3, 10, 45);
  await ex('incline-pushups', 'Incline push-ups', 'Push-ups with hands on a sturdy raised surface.', 'Upper body', 'Intermediate', [
    'Place hands on a stable bench or table edge, wider than shoulders.',
    'Keep a straight line from head to heels.',
    'Lower your chest toward the surface.',
    'Press up without sagging the hips.'
  ], 3, 8, 60);
  await ex('glute-bridges', 'Glute bridges', 'Targets glutes and the back of the legs.', 'Legs', 'Beginner', [
    'Lie on your back, knees bent, feet flat on the floor.',
    'Squeeze glutes and lift hips until shoulders, hips and knees align.',
    'Hold one second at the top.',
    'Lower slowly.'
  ], 3, 12, 45);
  await ex('bottle-curls', 'Biceps curls (water bottles)', 'Arm strengthening using filled water bottles.', 'Arms', 'Beginner', [
    'Hold a filled bottle in each hand, arms at your sides.',
    'Curl the bottles toward your shoulders, elbows fixed.',
    'Lower slowly under control.'
  ], 3, 12, 45);
  await ex('calf-raises', 'Calf raises', 'Builds calf strength and ankle stability.', 'Legs', 'Beginner', [
    'Stand tall, holding a wall for balance if needed.',
    'Rise onto the balls of your feet.',
    'Pause briefly, then lower slowly.'
  ], 3, 15, 30);
  await ex('planks', 'Planks', 'Core stability hold (reps = seconds per set).', 'Core', 'Beginner', [
    'Place forearms on the floor, elbows under shoulders.',
    'Extend legs, body in a straight line.',
    'Tighten abs and glutes; breathe steadily.',
    'Hold for the target time, drop to knees if form breaks.'
  ], 3, 20, 45);
  await ex('stretching', 'Gentle stretching', 'Full-body cool-down stretches (reps = seconds per stretch).', 'Mobility', 'Beginner', [
    'Hamstring stretch: reach toward toes, seated, 20 seconds.',
    'Quad stretch: standing, heel to glutes, 20 seconds per leg.',
    'Chest opener: clasp hands behind back, 20 seconds.',
    'Calf stretch against a wall, 20 seconds per leg.'
  ], 1, 20, 15);
}
