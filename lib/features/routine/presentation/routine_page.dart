import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common.dart';
import '../../../data/local/app_database.dart';
import '../../../shared/providers/providers.dart';

const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class RoutinePage extends ConsumerWidget {
  const RoutinePage({super.key});

  Future<void> _afterChange(WidgetRef ref) => ref.read(settingsProvider.notifier).rescheduleReminders();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(routineTasksProvider);
    final completions = ref.watch(completionsProvider).valueOrNull ?? const [];
    final s = settingsOf(ref);
    final todayKey = localDateKey(DateTime.now());
    return Scaffold(
      appBar: AppBar(title: const Text('Daily routine')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await _edit(context, ref, null);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add task'),
      ),
      body: tasks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: Icons.error_outline, message: '$e'),
        data: (list) => list.isEmpty
            ? const EmptyState(icon: Icons.checklist, message: 'No routine tasks yet. Add your first one.')
            : ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Rest days: tap to toggle (rest days do not break your streak).', style: Theme.of(context).textTheme.bodySmall),
                ),
                Wrap(spacing: 6, children: [
                  for (var d = 1; d <= 7; d++)
                    FilterChip(
                      label: Text(_dayNames[d - 1]),
                      selected: s.restWeekdays.contains(d),
                      onSelected: (v) => ref.read(settingsProvider.notifier).change((m) {
                        final set = {...m.restWeekdays};
                        v ? set.add(d) : set.remove(d);
                        return m.copyWith(restWeekdays: set);
                      }),
                    ),
                ]),
                const SizedBox(height: 12),
                for (final t in list)
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(
                            child: Text('${formatMinuteOfDay(t.scheduledMinutes, use24h: s.use24h)}  ${t.title}', style: Theme.of(context).textTheme.titleSmall),
                          ),
                          Switch(
                            value: t.isEnabled,
                            onChanged: (v) async {
                              await ref.read(routineDaoProvider).saveTask(RoutineTasksCompanion(id: Value(t.id), title: Value(t.title), scheduledMinutes: Value(t.scheduledMinutes), isEnabled: Value(v)));
                              await _afterChange(ref);
                            },
                          ),
                        ]),
                        Text(t.repeatDays.split(',').where((e) => e.isNotEmpty).map((e) => _dayNames[int.parse(e) - 1]).join(' · ')),
                        Text('Done in last 14 days: ${completions.where((c) => c.taskId == t.id && c.status == 'done').length}', style: Theme.of(context).textTheme.bodySmall),
                        Builder(builder: (_) {
                          final st = completions.where((c) => c.taskId == t.id && c.localDate == todayKey).firstOrNull?.status;
                          return Row(children: [
                            TextButton(onPressed: () => ref.read(routineDaoProvider).setCompletion(t.id, todayKey, st == 'done' ? null : 'done'), child: Text(st == 'done' ? 'Undo done' : 'Mark done')),
                            TextButton(onPressed: () => ref.read(routineDaoProvider).setCompletion(t.id, todayKey, st == 'skipped' ? null : 'skipped'), child: Text(st == 'skipped' ? 'Undo skip' : 'Skip today')),
                            const Spacer(),
                            IconButton(tooltip: 'Edit', icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(context, ref, t)),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: Text('Delete "${t.title}"?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                      FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
                                    ],
                                  ),
                                );
                                if (ok == true) {
                                  final n = ref.read(notificationServiceProvider);
                                  await n.rescheduleRoutine([t], enabled: false); // cancels this task's schedules
                                  await ref.read(routineDaoProvider).deleteTask(t.id);
                                  await _afterChange(ref);
                                }
                              },
                            ),
                          ]);
                        }),
                      ]),
                    ),
                  ),
              ]),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, RoutineTask? t) async {
    final title = TextEditingController(text: t?.title ?? '');
    var minutes = t?.scheduledMinutes ?? 6 * 60;
    final days = <int>{...((t?.repeatDays ?? '1,2,3,4,5,6,7').split(',').where((e) => e.isNotEmpty).map(int.parse))};
    final saved = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setSt) => AlertDialog(
          title: Text(t == null ? 'New task' : 'Edit task'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Time'),
                trailing: Text(formatMinuteOfDay(minutes)),
                onTap: () async {
                  final p = await showTimePicker(context: c, initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60));
                  if (p != null) setSt(() => minutes = p.hour * 60 + p.minute);
                },
              ),
              Wrap(spacing: 4, children: [
                for (var d = 1; d <= 7; d++)
                  FilterChip(label: Text(_dayNames[d - 1]), selected: days.contains(d), onSelected: (v) => setSt(() => v ? days.add(d) : days.remove(d))),
              ]),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(c, title.text.trim().isNotEmpty && days.isNotEmpty), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (saved != true) return;
    final sortedDays = (days.toList()..sort()).join(',');
    await ref.read(routineDaoProvider).saveTask(RoutineTasksCompanion(
          id: t == null ? const Value.absent() : Value(t.id),
          title: Value(title.text.trim()),
          scheduledMinutes: Value(minutes),
          repeatDays: Value(sortedDays),
        ));
    await _afterChange(ref);
  }
}
