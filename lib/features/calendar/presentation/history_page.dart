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
    final settings = settingsOf(ref);
    final miles = settings.useMiles;
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

          // Monthly totals for the currently focused calendar month
          final curMonth = monthStats(
            list,
            _focused,
            DateTime.now(),
            stepGoal: settings.stepGoal,
            distanceGoalMeters: settings.distanceGoalMeters,
          );

          // Last 7 days for the weekly distance chart
          final now = DateTime.now();
          final last7 = [for (var i = 6; i >= 0; i--) DateTime(now.year, now.month, now.day - i)];
          final chartLabels = [for (final d in last7) DateFormat('E').format(d).substring(0, 1)];
          final chartValues = [
            for (final d in last7)
              (days[localDateKey(d)]?.meters ?? 0) / (miles ? 1609.344 : 1000)
          ];

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // Monthly Calendar Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TableCalendar<WorkoutRecord>(
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2100),
                    focusedDay: _focused,
                    selectedDayPredicate: (d) => isSameDay(d, _selected),
                    eventLoader: (d) => byDate[localDateKey(d)] ?? const [],
                    onDaySelected: (sel, foc) => setState(() {
                      _selected = sel;
                      _focused = foc;
                    }),
                    onPageChanged: (f) => setState(() => _focused = f),
                    calendarStyle: CalendarStyle(
                      markerDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Monthly Statistics Card
              SectionCard(
                title: '${DateFormat('MMMM yyyy').format(_focused)} Totals',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _HistoryStat(
                      label: 'Distance',
                      value: formatDistance(curMonth.meters, miles: miles),
                      icon: Icons.route,
                    ),
                    _HistoryStat(
                      label: 'Walking Time',
                      value: formatMinutes(curMonth.seconds),
                      icon: Icons.timer_outlined,
                    ),
                    _HistoryStat(
                      label: 'Sessions',
                      value: '${curMonth.workouts}',
                      icon: Icons.directions_walk,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Weekly Distance Chart
              SectionCard(
                title: 'Past 7 Days (${miles ? 'miles' : 'km'})',
                child: BarSeries(
                  labels: chartLabels,
                  values: chartValues,
                  height: 130,
                ),
              ),
              const SizedBox(height: 12),

              // Selected Date Walk Details
              SectionCard(
                title: DateFormat('EEEE, MMM d').format(_selected),
                child: dayList.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'No walks recorded on this day.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () => context.go('/walk'),
                                icon: const Icon(Icons.play_arrow, size: 18),
                                label: const Text('Start Walk'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (totals != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Text(
                                    '${totals.steps} steps',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    formatDistance(totals.meters, miles: miles),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    formatDuration(totals.seconds),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          const Divider(),
                          for (final w in dayList)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                child: Icon(Icons.directions_walk, color: Theme.of(context).colorScheme.primary),
                              ),
                              title: Text(
                                '${formatDistance(w.distanceMeters, miles: miles)} · ${formatDuration(w.durationSeconds)}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${DateFormat('HH:mm').format(w.startedAt.toLocal())} · ${w.steps} steps · ${w.calories.round()} kcal',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push('/workout/${w.id}'),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _HistoryStat extends StatelessWidget {
  const _HistoryStat({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
      ],
    );
  }
}
