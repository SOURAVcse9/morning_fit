import 'package:flutter_test/flutter_test.dart';
import 'package:morningfit/features/walking/domain/workout_metrics.dart';
import 'package:morningfit/features/hydration/domain/hydration_tracker.dart';
import 'package:morningfit/services/steps/daily_step_tracker.dart';

void main() {
  group('DailyStepTracker helper tests', () {
    test('dateKey formats correctly as YYYY-MM-DD', () {
      final date = DateTime(2026, 11, 23);
      expect(DailyStepTracker.dateKey(date), '2026-11-23');

      final singleDigitDate = DateTime(2026, 5, 4);
      expect(DailyStepTracker.dateKey(singleDigitDate), '2026-05-04');
    });

    test('DailyStepState progress and goal computation', () {
      const state = DailyStepState(todaySteps: 5000, dailyGoal: 10000);
      expect(state.progress, 0.5);
      expect(state.goalReached, false);

      const reachedState = DailyStepState(todaySteps: 12000, dailyGoal: 10000);
      expect(reachedState.progress, 1.0);
      expect(reachedState.goalReached, true);
    });
  });

  group('HydrationState tests', () {
    test('computes milliliters and progress correctly', () {
      const state = HydrationState(glasses: 4, targetGlasses: 8);
      expect(state.milliliters, 1000);
      expect(state.targetMilliliters, 2000);
      expect(state.progress, 0.5);
      expect(state.targetReached, false);

      const fullState = HydrationState(glasses: 8, targetGlasses: 8);
      expect(fullState.milliliters, 2000);
      expect(fullState.progress, 1.0);
      expect(fullState.targetReached, true);
    });
  });

  group('WorkoutMetrics tests', () {
    test('estimates calories accurately based on distance and steps', () {
      const workout = WorkoutMetrics(
        steps: 5000,
        distanceMeters: 3000, // 3 km
        durationSeconds: 1800,
      );
      expect(workout.distanceKm, 3.0);
      expect(workout.estimatedCalories, (3.0 * 65).round()); // 195 kcal
    });

    test('estimates calories from steps when distance is 0', () {
      const workout = WorkoutMetrics(
        steps: 2000,
        distanceMeters: 0,
        durationSeconds: 900,
      );
      expect(workout.estimatedCalories, (2000 * 0.045).round()); // 90 kcal
    });
  });
}
