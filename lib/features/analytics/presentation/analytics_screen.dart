import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../walking/data/workout_repository.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final repo = ref.watch(workoutRepositoryProvider);
    return Scaffold(
        appBar: AppBar(title: const Text('Progress')),
        body: FutureBuilder(
          future: repo.workoutsForRange(DateTime(now.year, now.month, 1),
              DateTime(now.year, now.month + 1, 1)),
          builder: (context, snapshot) {
            final data = snapshot.data ?? [];
            final totalMeters =
                data.fold<int>(0, (s, w) => s + w.distanceMeters);
            final totalSeconds =
                data.fold<int>(0, (s, w) => s + w.durationSeconds);
            final totalSteps = data.fold<int>(0, (s, w) => s + w.steps);
            final daily = List<double>.generate(
                DateTime(now.year, now.month + 1, 0).day,
                (i) =>
                    data
                        .where((w) => w.startedAt.toLocal().day == i + 1)
                        .fold<int>(0, (s, w) => s + w.distanceMeters)
                        .toDouble() /
                    1000);
            return ListView(padding: const EdgeInsets.all(16), children: [
              Text('This month',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        Text('${(totalMeters / 1000).toStringAsFixed(2)} km',
                            style: Theme.of(context).textTheme.headlineMedium),
                        const Text('Total walking distance'),
                        const SizedBox(height: 14),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _stat(context, '$totalSteps', 'Steps'),
                              _stat(
                                  context,
                                  '${totalSeconds ~/ 3600}h ${(totalSeconds % 3600) ~/ 60}m',
                                  'Duration'),
                              _stat(context, '${data.length}', 'Walks')
                            ])
                      ]))),
              const SizedBox(height: 24),
              Text('Daily distance (km)',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              SizedBox(
                height: 240,
                child: BarChart(
                  BarChartData(
                    barGroups: [
                      for (var i = 0; i < daily.length; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: daily[i],
                              width: 5,
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ],
                        ),
                    ],
                    titlesData: const FlTitlesData(
                      show: true,
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: true),
                  ),
                ),
              ),
              if (data.isEmpty)
                const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                        'Complete a walk to start building your progress history.')),
            ]);
          },
        ));
  }

  Widget _stat(BuildContext context, String value, String label) =>
      Column(children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall)
      ]);
}
