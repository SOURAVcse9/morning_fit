import '../../../core/utils/date_utils.dart';
import '../../../shared/models/workout_record.dart';

class DayTotals {
  DayTotals(this.date);
  final String date;
  int steps = 0;
  double meters = 0;
  int seconds = 0;
  int count = 0;
}

/// Sums every completed workout into its local day. Multiple walks on one day
/// add up; each workout is counted exactly once.
Map<String, DayTotals> groupByDay(Iterable<WorkoutRecord> workouts) {
  final out = <String, DayTotals>{};
  for (final w in workouts) {
    final d = out.putIfAbsent(w.localDate, () => DayTotals(w.localDate));
    d.steps += w.steps;
    d.meters += w.distanceMeters;
    d.seconds += w.durationSeconds;
    d.count += 1;
  }
  return out;
}

bool goalMet(DayTotals? d, {required int stepGoal, required double distanceGoalMeters}) =>
    d != null && (d.steps >= stepGoal || d.meters >= distanceGoalMeters);

/// Consecutive goal days ending today. If today's goal is not met yet the
/// streak is counted up to yesterday. Rest weekdays with no activity neither
/// extend nor break the streak.
int currentStreak(
  Map<String, DayTotals> days,
  DateTime today, {
  required bool Function(DayTotals?) met,
  Set<int> restWeekdays = const {},
}) {
  var day = dateOnly(today);
  var streak = 0;
  if (!met(days[localDateKey(day)])) day = day.subtract(const Duration(days: 1));
  for (var i = 0; i < 3660; i++) {
    final d = days[localDateKey(day)];
    if (met(d)) {
      streak++;
    } else if (restWeekdays.contains(day.weekday) && (d == null || d.count == 0)) {
      // rest day: skipped
    } else {
      break;
    }
    day = DateTime(day.year, day.month, day.day - 1);
  }
  return streak;
}

class MonthStats {
  const MonthStats({
    required this.calendarDays,
    required this.activeDays,
    required this.goalDays,
    required this.workouts,
    required this.meters,
    required this.seconds,
    required this.steps,
    required this.longestWalkMeters,
  });
  final int calendarDays; // days of the month elapsed so far
  final int activeDays; // days with at least one recorded walk
  final int goalDays; // days where the goal was met
  final int workouts;
  final double meters;
  final int seconds;
  final int steps;
  final double longestWalkMeters;

  double? get avgMetersPerActiveDay => activeDays == 0 ? null : meters / activeDays;
  double? get avgSecondsPerActiveDay => activeDays == 0 ? null : seconds / activeDays;
  double? get goalRate => calendarDays == 0 ? null : goalDays / calendarDays;
}

MonthStats monthStats(
  Iterable<WorkoutRecord> all,
  DateTime month,
  DateTime today, {
  required int stepGoal,
  required double distanceGoalMeters,
}) {
  final start = monthStart(month);
  final end = nextMonthStart(month);
  final inMonth = all.where((w) {
    final t = w.startedAt.toLocal();
    return !t.isBefore(start) && t.isBefore(end);
  }).toList();
  final days = groupByDay(inMonth);
  final isCurrent = today.year == month.year && today.month == month.month;
  final elapsed = isCurrent ? today.day : daysInMonth(month);
  return MonthStats(
    calendarDays: elapsed,
    activeDays: days.length,
    goalDays: days.values.where((d) => goalMet(d, stepGoal: stepGoal, distanceGoalMeters: distanceGoalMeters)).length,
    workouts: inMonth.length,
    meters: inMonth.fold(0.0, (s, w) => s + w.distanceMeters),
    seconds: inMonth.fold(0, (s, w) => s + w.durationSeconds),
    steps: inMonth.fold(0, (s, w) => s + w.steps),
    longestWalkMeters: inMonth.fold(0.0, (m, w) => w.distanceMeters > m ? w.distanceMeters : m),
  );
}
