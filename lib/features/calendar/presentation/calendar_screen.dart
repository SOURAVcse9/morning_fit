import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../walking/data/workout_repository.dart';
import '../../../services/steps/daily_step_tracker.dart';
import '../../hydration/domain/hydration_tracker.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();
  int _selectedDateSteps = 0;
  int _selectedDateWater = 0;

  @override
  void initState() {
    super.initState();
    _loadDateMetrics(_selected);
  }

  Future<void> _loadDateMetrics(DateTime date) async {
    final stepTracker = ref.read(dailyStepTrackerProvider.notifier);
    final hydrationTracker = ref.read(hydrationTrackerProvider.notifier);
    final steps = await stepTracker.getStepsForDate(date);
    final water = await hydrationTracker.getGlassesForDate(date);
    if (mounted) {
      setState(() {
        _selectedDateSteps = steps;
        _selectedDateWater = water;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(workoutRepositoryProvider);
    final start = DateTime(_focused.year, _focused.month, 1);
    final end = DateTime(_focused.year, _focused.month + 1, 1);

    return Scaffold(
      appBar: AppBar(title: const Text('Walking & Activity History')),
      body: FutureBuilder(
        future: repo.workoutsForRange(start, end),
        builder: (context, snapshot) {
          final workouts = snapshot.data ?? [];
          final activeDates = workouts.map((w) {
            final d = w.startedAt.toLocal();
            return DateTime(d.year, d.month, d.day);
          }).toSet();

          final selectedWorkouts = workouts.where((w) {
            final d = w.startedAt.toLocal();
            return d.year == _selected.year &&
                d.month == _selected.month &&
                d.day == _selected.day;
          }).toList();

          final formattedDate =
              '${_selected.year}-${_selected.month.toString().padLeft(2, '0')}-${_selected.day.toString().padLeft(2, '0')}';

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              TableCalendar<void>(
                firstDay: DateTime(2020),
                lastDay: DateTime(2100),
                focusedDay: _focused,
                selectedDayPredicate: (d) => isSameDay(d, _selected),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selected = selected;
                    _focused = focused;
                  });
                  _loadDateMetrics(selected);
                },
                onPageChanged: (focused) => setState(() => _focused = focused),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) =>
                      activeDates.any((d) => isSameDay(d, day))
                          ? const Positioned(
                              bottom: 2,
                              child: CircleAvatar(
                                radius: 3,
                                backgroundColor: Colors.green,
                              ),
                            )
                          : null,
                ),
              ),
              const SizedBox(height: 16),

              // Date-wise 24/7 Activity Card
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Daily Summary: $formattedDate',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.directions_walk,
                                    color: Colors.green),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Daily Steps',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                    Text('$_selectedDateSteps',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.water_drop,
                                    color: Colors.teal),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Hydration',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                    Text('$_selectedDateWater glasses',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Text(
                'Recorded Walks',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              if (selectedWorkouts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text('No GPS walks recorded on this date.'),
                  ),
                ),
              ...selectedWorkouts.map(
                (w) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.directions_walk, color: Colors.green),
                    title: Text(
                      '${(w.distanceMeters / 1000).toStringAsFixed(2)} km',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${w.steps} steps • ${w.durationSeconds ~/ 60} minutes',
                    ),
                    trailing: Text(
                      TimeOfDay.fromDateTime(w.startedAt.toLocal())
                          .format(context),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
