import 'package:flutter_test/flutter_test.dart';
import 'package:morning_fit/core/utils/notification_ids.dart';
import 'package:morning_fit/features/analytics/domain/stats.dart';
import 'package:morning_fit/features/walking/domain/calories.dart';
import 'package:morning_fit/services/steps/step_counter_service.dart';
import 'package:morning_fit/shared/models/workout_record.dart';

WorkoutRecord w(String id, DateTime start, {int steps = 1000, double meters = 800, int secs = 600}) => WorkoutRecord(
      id: id,
      startedAt: start,
      localDate: '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}',
      durationSeconds: secs,
      distanceMeters: meters,
      steps: steps,
      calories: 40,
    );

void main() {
  group('StepDeltaTracker', () {
    test('first reading is a baseline, not session steps', () {
      final t = StepDeltaTracker();
      t.onReading(50000, counting: true);
      expect(t.sessionSteps, 0);
      t.onReading(50120, counting: true);
      expect(t.sessionSteps, 120);
    });
    test('counter reset never produces negative steps', () {
      final t = StepDeltaTracker();
      t.onReading(1000, counting: true);
      t.onReading(1100, counting: true);
      t.onReading(30, counting: true); // reboot: counter restarted
      expect(t.sessionSteps, 130);
      expect(t.sessionSteps, greaterThanOrEqualTo(0));
    });
    test('steps while paused are ignored but baseline keeps moving', () {
      final t = StepDeltaTracker();
      t.onReading(100, counting: true);
      t.onReading(160, counting: false); // paused
      t.onReading(175, counting: true);
      expect(t.sessionSteps, 15);
    });
    test('recovered walk keeps its saved steps', () {
      final t = StepDeltaTracker(initialSteps: 500);
      t.onReading(10, counting: true);
      t.onReading(20, counting: true);
      expect(t.sessionSteps, 510);
    });
  });

  group('stats', () {
    final day1 = DateTime(2026, 3, 10, 6);
    test('two walks on one day are summed once each', () {
      final days = groupByDay([w('a', day1), w('b', day1.add(const Duration(hours: 10)), steps: 500, meters: 400, secs: 300)]);
      expect(days.length, 1);
      final d = days['2026-03-10']!;
      expect(d.steps, 1500);
      expect(d.meters, 1200);
      expect(d.seconds, 900);
      expect(d.count, 2);
    });

    test('goal met by steps OR distance', () {
      final d = DayTotals('x')..steps = 9000..meters = 100;
      expect(goalMet(d, stepGoal: 8000, distanceGoalMeters: 5000), isTrue);
      final e = DayTotals('y')..steps = 100..meters = 5200;
      expect(goalMet(e, stepGoal: 8000, distanceGoalMeters: 5000), isTrue);
      expect(goalMet(DayTotals('z')..steps = 100, stepGoal: 8000, distanceGoalMeters: 5000), isFalse);
      expect(goalMet(null, stepGoal: 1, distanceGoalMeters: 1), isFalse);
    });

    test('streak counts consecutive goal days and ignores unfinished today', () {
      final today = DateTime(2026, 3, 10);
      final recs = [for (var i = 1; i <= 3; i++) w('r$i', DateTime(2026, 3, 10 - i, 6), steps: 9000)];
      final days = groupByDay(recs);
      bool met(DayTotals? d) => goalMet(d, stepGoal: 8000, distanceGoalMeters: 99999);
      expect(currentStreak(days, today, met: met), 3);
    });

    test('rest day with no activity does not break the streak', () {
      final today = DateTime(2026, 3, 10); // Tuesday
      // Monday (rest) has no walk; Sunday and Saturday met the goal.
      final days = groupByDay([w('s', DateTime(2026, 3, 8, 6), steps: 9000), w('t', DateTime(2026, 3, 7, 6), steps: 9000)]);
      bool met(DayTotals? d) => goalMet(d, stepGoal: 8000, distanceGoalMeters: 99999);
      expect(currentStreak(days, today, met: met, restWeekdays: {1}), 2);
      expect(currentStreak(days, today, met: met), 0);
    });

    test('month boundary: late-night walk on the 31st stays in its month', () {
      final all = [w('jan', DateTime(2026, 1, 31, 23, 30)), w('feb', DateTime(2026, 2, 1, 0, 10))];
      final jan = monthStats(all, DateTime(2026, 1), DateTime(2026, 2, 15), stepGoal: 500, distanceGoalMeters: 99999);
      final feb = monthStats(all, DateTime(2026, 2), DateTime(2026, 2, 15), stepGoal: 500, distanceGoalMeters: 99999);
      expect(jan.workouts, 1);
      expect(feb.workouts, 1);
      expect(jan.calendarDays, 31);
      expect(feb.calendarDays, 15);
      expect(feb.activeDays, 1);
      expect(feb.goalRate, closeTo(1 / 15, 1e-9));
    });
  });

  test('average pace is null for tiny distances', () {
    expect(averagePace(20, 60), isNull);
    expect(averagePace(1000, 600), 600);
  });

  test('notification ids are stable and unique per task/weekday', () {
    expect(NotificationIds.forTask(3, 2), NotificationIds.forTask(3, 2));
    final ids = {for (var t = 1; t <= 20; t++) for (var d = 1; d <= 7; d++) NotificationIds.forTask(t, d)};
    expect(ids.length, 140);
  });
}
