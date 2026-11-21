import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/walking/data/workout_repository.dart';
import '../../../core/widgets/stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts =
        ref.watch(workoutRepositoryProvider).watchCompletedWorkouts();
    return Scaffold(
      appBar: AppBar(title: const Text('MorningFit'), actions: [
        IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined))
      ]),
      body: StreamBuilder(
        stream: workouts,
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          final today = DateTime.now();
          final todays = items
              .where((w) =>
                  w.startedAt.toLocal().year == today.year &&
                  w.startedAt.toLocal().month == today.month &&
                  w.startedAt.toLocal().day == today.day)
              .toList();
          final steps = todays.fold<int>(0, (sum, w) => sum + w.steps);
          final meters =
              todays.fold<int>(0, (sum, w) => sum + w.distanceMeters);
          final seconds =
              todays.fold<int>(0, (sum, w) => sum + w.durationSeconds);
          return ListView(padding: const EdgeInsets.all(16), children: [
            Text('Good morning!',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Small steps build healthy habits.'),
            const SizedBox(height: 20),
            GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  StatCard(
                      icon: Icons.directions_walk,
                      title: 'Steps',
                      value: '$steps'),
                  StatCard(
                      icon: Icons.route,
                      title: 'Distance',
                      value: '${(meters / 1000).toStringAsFixed(2)} km'),
                  StatCard(
                      icon: Icons.timer_outlined,
                      title: 'Walking time',
                      value: '${seconds ~/ 60} min'),
                  const StatCard(
                      icon: Icons.local_fire_department_outlined,
                      title: 'Calories',
                      value: 'Estimate unavailable'),
                ]),
            const SizedBox(height: 20),
            FilledButton.icon(
                onPressed: () => context.push('/walk'),
                icon: const Icon(Icons.play_arrow),
                label: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('Start Morning Walk'))),
            const SizedBox(height: 12),
            OutlinedButton.icon(
                onPressed: () => context.push('/routine'),
                icon: const Icon(Icons.checklist),
                label: const Text('My Daily Routine')),
            const SizedBox(height: 12),
            OutlinedButton.icon(
                onPressed: () => context.push('/exercises'),
                icon: const Icon(Icons.fitness_center),
                label: const Text('Home Exercise Library')),
            const SizedBox(height: 12),
            OutlinedButton.icon(
                onPressed: () => context.push('/history'),
                icon: const Icon(Icons.calendar_month),
                label: const Text('Walking History')),
            const SizedBox(height: 12),
            OutlinedButton.icon(
                onPressed: () => context.push('/progress'),
                icon: const Icon(Icons.bar_chart),
                label: const Text('Progress & Analytics')),
          ]);
        },
      ),
    );
  }
}
