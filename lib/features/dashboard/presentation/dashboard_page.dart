import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common.dart';
import '../../../data/local/app_database.dart';
import '../../../shared/models/workout_record.dart';
import '../../../shared/providers/providers.dart';
import '../../analytics/domain/stats.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  /// Next enabled reminder from now (today or the coming days), or null.
  static ({RoutineTask task, DateTime when})? nextReminder(List<RoutineTask> tasks, DateTime now) {
    ({RoutineTask task, DateTime when})? best;
    for (final t in tasks.where((t) => t.isEnabled)) {
      final days = t.repeatDays.split(',').where((s) => s.isNotEmpty).map(int.parse);
      for (final d in days) {
        for (var off = 0; off < 8; off++) {
          final day = DateTime(now.year, now.month, now.day + off);
          if (day.weekday != d) continue;
          final when = day.add(Duration(minutes: t.scheduledMinutes));
          if (when.isAfter(now)) {
            if (best == null || when.isBefore(best.when)) best = (task: t, when: when);
            break;
          }
        }
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = settingsOf(ref);
    final records = ref.watch(workoutRecordsProvider);
    final tasks = ref.watch(routineTasksProvider).valueOrNull ?? const [];
    final completions = ref.watch(completionsProvider).valueOrNull ?? const [];
    final now = DateTime.now();
    final todayKey = localDateKey(now);

    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('EEEE, MMM d').format(now)),
        actions: [
          IconButton(tooltip: 'Daily routine', icon: const Icon(Icons.checklist), onPressed: () => context.push('/routine')),
          IconButton(tooltip: 'Settings', icon: const Icon(Icons.settings_outlined), onPressed: () => context.push('/settings')),
        ],
      ),
      body: records.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: Icons.error_outline, message: 'Could not load your data.\n$e'),
        data: (list) {
          final days = groupByDay(list);
          final today = days[todayKey];
          final steps = today?.steps ?? 0;
          final meters = today?.meters ?? 0.0;
          final seconds = today?.seconds ?? 0;
          final kcal = list.where((w) => w.localDate == todayKey).fold(0.0, (s, w) => s + w.calories);
          final stepProgress = (steps / settings.stepGoal).clamp(0.0, 1.0);
          final distProgress = (meters / settings.distanceGoalMeters).clamp(0.0, 1.0);
          final progress = stepProgress > distProgress ? stepProgress : distProgress;
          final next = nextReminder(tasks, now);
          final weekDays = [for (var i = 6; i >= 0; i--) DateTime(now.year, now.month, now.day - i)];

          return ListView(padding: const EdgeInsets.all(16), children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  SizedBox(
                    width: 92,
                    height: 92,
                    child: Stack(alignment: Alignment.center, children: [
                      SizedBox.expand(child: CircularProgressIndicator(value: progress, strokeWidth: 9, strokeCap: StrokeCap.round)),
                      Text('${(progress * 100).round()}%', style: Theme.of(context).textTheme.titleMedium),
                    ]),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("Today's goal", style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('$steps / ${settings.stepGoal} steps'),
                      Text('${formatDistance(meters, miles: settings.useMiles)} / ${formatDistance(settings.distanceGoalMeters, miles: settings.useMiles)}'),
                      const SizedBox(height: 4),
                      Text('Goal is met by reaching either target.', style: Theme.of(context).textTheme.bodySmall),
                    ]),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.7,
              children: [
                StatTile(icon: Icons.directions_walk, value: '$steps', label: 'Steps (recorded in walks)'),
                StatTile(icon: Icons.route, value: formatDistance(meters, miles: settings.useMiles), label: 'Distance'),
                StatTile(icon: Icons.timer_outlined, value: formatMinutes(seconds), label: 'Walking time'),
                StatTile(icon: Icons.local_fire_department_outlined, value: '${kcal.round()} kcal', label: 'Calories (estimate)'),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.go('/walk'),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Morning Walk'),
            ),
            if (list.isEmpty) ...[
              const SizedBox(height: 12),
              const SectionCard(title: 'No walks yet', child: Text('Your first walk will show up here. Tap Start Morning Walk to begin.')),
            ],
            const SizedBox(height: 12),
            SectionCard(
              title: 'Next reminder',
              child: Text(next == null
                  ? 'No reminders scheduled. Enable them in Settings.'
                  : '${next.task.title} · ${DateFormat('EEE').format(next.when)} ${formatMinuteOfDay(next.task.scheduledMinutes, use24h: settings.use24h)}'
                      '${settings.remindersEnabled ? '' : ' (reminders are off)'}'),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: "Today's routine",
              trailing: TextButton(onPressed: () => context.push('/routine'), child: const Text('Edit')),
              child: _RoutineChecklist(tasks: tasks, completions: completions, todayKey: todayKey, weekday: now.weekday, use24h: settings.use24h),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'This week',
              child: BarSeries(
                labels: [for (final d in weekDays) DateFormat('E').format(d).substring(0, 1)],
                values: [for (final d in weekDays) (days[localDateKey(d)]?.meters ?? 0) / 1000],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Quick exercises',
              trailing: TextButton(onPressed: () => context.go('/exercises'), child: const Text('Open library')),
              child: const Text('Squats, wall push-ups, glute bridges, planks and more, with sets, reps and rest timers.'),
            ),
            const SizedBox(height: 12),
            SectionCard(title: 'Recent walks', child: _Recent(list.take(3).toList(), settings.useMiles)),
          ]);
        },
      ),
    );
  }
}

class _RoutineChecklist extends ConsumerWidget {
  const _RoutineChecklist({required this.tasks, required this.completions, required this.todayKey, required this.weekday, required this.use24h});
  final List<RoutineTask> tasks;
  final List<TaskCompletion> completions;
  final String todayKey;
  final int weekday;
  final bool use24h;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todays = tasks.where((t) => t.repeatDays.split(',').contains('$weekday')).toList();
    if (todays.isEmpty) return const Text('No routine tasks for today.');
    return Column(children: [
      for (final t in todays)
        Builder(builder: (_) {
          final c = completions.where((c) => c.taskId == t.id && c.localDate == todayKey).firstOrNull;
          return CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: c?.status == 'done',
            title: Text(t.title, style: c?.status == 'skipped' ? const TextStyle(decoration: TextDecoration.lineThrough) : null),
            subtitle: Text(formatMinuteOfDay(t.scheduledMinutes, use24h: use24h)),
            onChanged: (v) => ref.read(routineDaoProvider).setCompletion(t.id, todayKey, v == true ? 'done' : null),
          );
        }),
    ]);
  }
}

class _Recent extends StatelessWidget {
  const _Recent(this.items, this.miles);
  final List<WorkoutRecord> items;
  final bool miles;
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Text('Nothing recorded yet.');
    return Column(children: [
      for (final w in items)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.directions_walk),
          title: Text('${formatDistance(w.distanceMeters, miles: miles)} · ${formatMinutes(w.durationSeconds)}'),
          subtitle: Text(DateFormat('EEE, MMM d · HH:mm').format(w.startedAt.toLocal())),
          onTap: () => context.push('/workout/${w.id}'),
        ),
    ]);
  }
}
