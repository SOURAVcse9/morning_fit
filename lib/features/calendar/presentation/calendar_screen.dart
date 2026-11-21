import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../walking/data/workout_repository.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();
  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(workoutRepositoryProvider);
    final start = DateTime(_focused.year, _focused.month, 1);
    final end = DateTime(_focused.year, _focused.month + 1, 1);
    return Scaffold(
        appBar: AppBar(title: const Text('Walking History')),
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
            return ListView(padding: const EdgeInsets.all(12), children: [
              TableCalendar<void>(
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2100),
                  focusedDay: _focused,
                  selectedDayPredicate: (d) => isSameDay(d, _selected),
                  onDaySelected: (selected, focused) => setState(() {
                        _selected = selected;
                        _focused = focused;
                      }),
                  onPageChanged: (focused) =>
                      setState(() => _focused = focused),
                  calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, events) =>
                          activeDates.any((d) => isSameDay(d, day))
                              ? const Positioned(
                                  bottom: 2,
                                  child: CircleAvatar(
                                      radius: 3, backgroundColor: Colors.green))
                              : null)),
              const SizedBox(height: 16),
              Text(
                  'Workouts on ${_selected.year}-${_selected.month.toString().padLeft(2, '0')}-${_selected.day.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.titleMedium),
              if (selectedWorkouts.isEmpty)
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No completed walks recorded for this date.')),
              ...selectedWorkouts.map((w) => Card(
                  child: ListTile(
                      leading: const Icon(Icons.directions_walk),
                      title: Text(
                          '${(w.distanceMeters / 1000).toStringAsFixed(2)} km'),
                      subtitle: Text(
                          '${w.steps} steps • ${w.durationSeconds ~/ 60} minutes'),
                      trailing: Text(
                          TimeOfDay.fromDateTime(w.startedAt.toLocal())
                              .format(context))))),
            ]);
          },
        ));
  }
}
