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

  static String _greeting(DateTime now) {
    final hour = now.hour;
    if (hour < 12) return 'Good morning!';
    if (hour < 17) return 'Good afternoon!';
    return 'Good evening!';
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
        title: const Text('MorningFit'),
        actions: [
          IconButton(
            tooltip: 'Home Exercises',
            icon: const Icon(Icons.fitness_center_outlined),
            onPressed: () => context.push('/exercises'),
          ),
          IconButton(
            tooltip: 'Edit Routine',
            icon: const Icon(Icons.checklist),
            onPressed: () => context.push('/routine'),
          ),
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
          final stepProgress = (steps / settings.stepGoal).clamp(0.0, 1.0);
          final distProgress = (meters / settings.distanceGoalMeters).clamp(0.0, 1.0);
          final progress = stepProgress > distProgress ? stepProgress : distProgress;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Greeting Header
              Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(now),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('EEEE, MMMM d').format(now),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),

              // Essential Metrics Cards (Large, readable numbers)
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _EssentialStat(
                        value: '$steps',
                        label: 'Steps',
                        icon: Icons.directions_walk,
                      ),
                      _EssentialStat(
                        value: formatDistance(meters, miles: settings.useMiles),
                        label: 'Distance',
                        icon: Icons.route,
                      ),
                      _EssentialStat(
                        value: formatMinutes(seconds),
                        label: 'Duration',
                        icon: Icons.timer_outlined,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Daily Goal Progress
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Today's Goal", style: Theme.of(context).textTheme.titleMedium),
                          Text(
                            '${(progress * 100).round()}%',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$steps / ${settings.stepGoal} steps'),
                          Text('${formatDistance(meters, miles: settings.useMiles)} / ${formatDistance(settings.distanceGoalMeters, miles: settings.useMiles)}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Prominent Start Walk Button
              FilledButton.icon(
                onPressed: () => context.go('/walk'),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Morning Walk'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                ),
              ),
              const SizedBox(height: 14),

              // Empty state card for new users
              if (list.isEmpty) ...[
                const SectionCard(
                  title: 'No walks yet',
                  child: Text('Your first walk will show up here. Tap Start Morning Walk to begin.'),
                ),
                const SizedBox(height: 14),
              ],

              // Today's Routine Checklist
              SectionCard(
                title: "Today's Routine",
                trailing: TextButton(
                  onPressed: () => context.push('/routine'),
                  child: const Text('Edit'),
                ),
                child: _RoutineChecklist(
                  tasks: tasks,
                  completions: completions,
                  todayKey: todayKey,
                  weekday: now.weekday,
                  use24h: settings.use24h,
                ),
              ),
              const SizedBox(height: 12),

              // Home Exercises shortcut card
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(Icons.fitness_center, color: Theme.of(context).colorScheme.primary),
                  ),
                  title: const Text('Home Exercises'),
                  subtitle: const Text('8 guided exercises with timers'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/exercises'),
                ),
              ),
              const SizedBox(height: 12),

              // Recent Walks
              if (list.isNotEmpty) ...[
                SectionCard(
                  title: 'Recent Walks',
                  child: _Recent(list.take(3).toList(), settings.useMiles),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _EssentialStat extends StatelessWidget {
  const _EssentialStat({required this.value, required this.label, required this.icon});
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 22, color: theme.colorScheme.primary),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }
}

class _RoutineChecklist extends ConsumerWidget {
  const _RoutineChecklist({
    required this.tasks,
    required this.completions,
    required this.todayKey,
    required this.weekday,
    required this.use24h,
  });

  final List<RoutineTask> tasks;
  final List<TaskCompletion> completions;
  final String todayKey;
  final int weekday;
  final bool use24h;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todays = tasks.where((t) => t.repeatDays.split(',').contains('$weekday')).toList();
    if (todays.isEmpty) return const Text('No routine tasks scheduled for today.');

    return Column(
      children: [
        for (final t in todays)
          Builder(builder: (_) {
            final c = completions.where((c) => c.taskId == t.id && c.localDate == todayKey).firstOrNull;
            final isDone = c?.status == 'done';
            return CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: isDone,
              title: Text(
                t.title,
                style: c?.status == 'skipped'
                    ? const TextStyle(decoration: TextDecoration.lineThrough)
                    : (isDone ? const TextStyle(fontWeight: FontWeight.w500) : null),
              ),
              subtitle: Text(formatMinuteOfDay(t.scheduledMinutes, use24h: use24h)),
              onChanged: (v) => ref.read(routineDaoProvider).setCompletion(t.id, todayKey, v == true ? 'done' : null),
            );
          }),
      ],
    );
  }
}

class _Recent extends StatelessWidget {
  const _Recent(this.items, this.miles);
  final List<WorkoutRecord> items;
  final bool miles;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Text('Nothing recorded yet.');
    return Column(
      children: [
        for (final w in items)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.directions_walk),
            title: Text('${formatDistance(w.distanceMeters, miles: miles)} · ${formatMinutes(w.durationSeconds)}'),
            subtitle: Text(DateFormat('EEE, MMM d · HH:mm').format(w.startedAt.toLocal())),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/workout/${w.id}'),
          ),
      ],
    );
  }
}
