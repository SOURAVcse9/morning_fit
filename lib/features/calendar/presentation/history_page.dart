import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common.dart';
import '../../../shared/models/workout_record.dart';
import '../../../shared/providers/providers.dart';
import '../../analytics/domain/stats.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});
  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final miles = settingsOf(ref).useMiles;
    final async = ref.watch(workoutRecordsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: Icons.error_outline, message: 'Could not load history.\n$e'),
        data: (list) {
          final byDate = <String, List<WorkoutRecord>>{};
          for (final w in list) {
            byDate.putIfAbsent(w.localDate, () => []).add(w);
          }
          final days = groupByDay(list);
          final dayList = (byDate[localDateKey(_selected)] ?? const <WorkoutRecord>[]).toList()
            ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
          final totals = days[localDateKey(_selected)];
          return ListView(children: [
            TableCalendar<WorkoutRecord>(
              firstDay: DateTime(2020),
              lastDay: DateTime(2100),
              focusedDay: _focused,
              selectedDayPredicate: (d) => isSameDay(d, _selected),
              eventLoader: (d) => byDate[localDateKey(d)] ?? const [],
              onDaySelected: (sel, foc) => setState(() {
                _selected = sel;
                _focused = foc;
              }),
              onPageChanged: (f) => _focused = f,
              calendarStyle: CalendarStyle(
                markerDecoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
              ),
              headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            ),
            const Divider(),
            if (dayList.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: EmptyState(icon: Icons.event_busy, message: 'No walks on ${DateFormat('MMM d').format(_selected)}.', actionLabel: 'Start a walk', onAction: () => context.go('/walk')),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(spacing: 16, runSpacing: 8, children: [
                  Text('Distance ${formatDistance(totals!.meters, miles: miles)}'),
                  Text('Steps ${totals.steps}'),
                  Text('Duration ${formatMinutes(totals.seconds)}'),
                  Text('Sessions ${totals.count}'),
                ]),
              ),
              for (final w in dayList)
                ListTile(
                  leading: const Icon(Icons.directions_walk),
                  title: Text('${formatDistance(w.distanceMeters, miles: miles)} · ${formatDuration(w.durationSeconds)}'),
                  subtitle: Text('${DateFormat('HH:mm').format(w.startedAt.toLocal())} · ${w.steps} steps'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/workout/${w.id}'),
                ),
            ],
          ]);
        },
      ),
    );
  }
}
