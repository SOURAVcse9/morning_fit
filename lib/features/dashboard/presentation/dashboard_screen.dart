import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/walking/data/workout_repository.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../services/steps/daily_step_tracker.dart';
import '../../vitality/presentation/vitality_card.dart';
import '../../hydration/presentation/hydration_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning!';
    if (hour < 17) return 'Good afternoon!';
    return 'Good evening!';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsStream =
        ref.watch(workoutRepositoryProvider).watchCompletedWorkouts();
    final stepState = ref.watch(dailyStepTrackerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('MorningFit'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'v2',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: StreamBuilder(
        stream: workoutsStream,
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          final today = DateTime.now();
          final todays = items
              .where((w) =>
                  w.startedAt.toLocal().year == today.year &&
                  w.startedAt.toLocal().month == today.month &&
                  w.startedAt.toLocal().day == today.day)
              .toList();

          final workoutMeters =
              todays.fold<int>(0, (sum, w) => sum + w.distanceMeters);
          final seconds =
              todays.fold<int>(0, (sum, w) => sum + w.durationSeconds);

          // 24/7 background steps are prioritized for today's total steps
          final totalSteps = stepState.todaySteps > 0
              ? stepState.todaySteps
              : todays.fold<int>(0, (sum, w) => sum + w.steps);

          // Combined walking distance: logged GPS meters or stride estimation from daily steps
          final totalDistanceKm = workoutMeters > 0
              ? (workoutMeters / 1000)
              : (totalSteps * 0.00076);

          final estimatedCalories = totalDistanceKm > 0
              ? (totalDistanceKm * 65).round()
              : (totalSteps * 0.045).round();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                _getGreeting(),
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                stepState.statusMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),

              // Unique Feature: Daily Vitality Score
              const VitalityCard(),
              const SizedBox(height: 16),

              // Essential Metrics Grid
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
                    title: 'Today Steps',
                    value: '$totalSteps',
                  ),
                  StatCard(
                    icon: Icons.route,
                    title: 'Distance',
                    value: '${totalDistanceKm.toStringAsFixed(2)} km',
                  ),
                  StatCard(
                    icon: Icons.timer_outlined,
                    title: 'Active Walk',
                    value: '${seconds ~/ 60} min',
                  ),
                  StatCard(
                    icon: Icons.local_fire_department_outlined,
                    title: 'Calories',
                    value: '$estimatedCalories kcal',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Unique Feature: Daily Hydration Tracker
              const HydrationCard(),
              const SizedBox(height: 16),

              // Primary Action
              FilledButton.icon(
                onPressed: () => context.push('/walk'),
                icon: const Icon(Icons.play_arrow),
                label: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text(
                    'Start Morning Walk',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: () => context.push('/routine'),
                icon: const Icon(Icons.checklist),
                label: const Text('My Daily Routine'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.push('/exercises'),
                icon: const Icon(Icons.fitness_center),
                label: const Text('Home Exercise Library'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.push('/history'),
                icon: const Icon(Icons.calendar_month),
                label: const Text('Walking History'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.push('/progress'),
                icon: const Icon(Icons.bar_chart),
                label: const Text('Progress & Analytics'),
              ),
            ],
          );
        },
      ),
    );
  }
}
