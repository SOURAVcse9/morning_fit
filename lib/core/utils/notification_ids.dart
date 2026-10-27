/// Stable notification IDs: one per (routine task, weekday) plus fixed IDs.
class NotificationIds {
  static const weeklySummary = 9001;
  static const monthlySummary = 9002;
  static const goalReached = 9003;
  static const test = 9999;

  /// [taskId] is the routine task's database id, [isoWeekday] is 1 (Mon) .. 7 (Sun).
  static int forTask(int taskId, int isoWeekday) {
    assert(isoWeekday >= 1 && isoWeekday <= 7);
    return 10000 + taskId * 10 + isoWeekday;
  }
}
