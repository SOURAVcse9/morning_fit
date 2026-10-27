import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/date_utils.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common.dart';
import '../../../shared/providers/providers.dart';
import '../domain/stats.dart';

class ProgressPage extends ConsumerWidget {
  const ProgressPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = settingsOf(ref);
    final async = ref.watch(workoutRecordsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: Icons.error_outline, message: '$e'),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(icon: Icons.insights, message: 'Finish a walk to see charts and trends here.');
          }
          final now = DateTime.now();
          final days = groupByDay(list);
          bool met(DayTotals? d) => goalMet(d, stepGoal: s.stepGoal, distanceGoalMeters: s.distanceGoalMeters);
          final streak = currentStreak(days, now, met: met, restWeekdays: s.restWeekdays);
          final cur = monthStats(list, now, now, stepGoal: s.stepGoal, distanceGoalMeters: s.distanceGoalMeters);
          final prev = monthStats(list, DateTime(now.year, now.month - 1), now, stepGoal: s.stepGoal, distanceGoalMeters: s.distanceGoalMeters);
          final last14 = [for (var i = 13; i >= 0; i--) DateTime(now.year, now.month, now.day - i)];
          final labels = [for (final d in last14) '${d.day}'];
          final delta = prev.meters == 0 ? null : (cur.meters - prev.meters) / prev.meters * 100;
          final miles = s.useMiles;

          return ListView(padding: const EdgeInsets.all(16), children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.7,
              children: [
                StatTile(icon: Icons.local_fire_department, value: '$streak days', label: 'Goal streak'),
                StatTile(icon: Icons.directions_walk, value: '${list.length}', label: 'Total workouts'),
                StatTile(icon: Icons.route, value: formatDistance(cur.meters, miles: miles), label: 'Distance this month'),
                StatTile(icon: Icons.timer_outlined, value: formatMinutes(cur.seconds), label: 'Walking time this month'),
              ],
            ),
            const SizedBox(height: 12),
            SectionCard(title: 'Distance, last 14 days (${miles ? 'mi' : 'km'})', child: BarSeries(labels: labels, values: [for (final d in last14) (days[localDateKey(d)]?.meters ?? 0) / (miles ? 1609.344 : 1000)])),
            const SizedBox(height: 12),
            SectionCard(title: 'Steps, last 14 days', child: BarSeries(labels: labels, values: [for (final d in last14) (days[localDateKey(d)]?.steps ?? 0).toDouble()])),
            const SizedBox(height: 12),
            SectionCard(
              title: DateFormat('MMMM yyyy').format(now),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Calendar days so far: ${cur.calendarDays}'),
                Text('Days with recorded walks: ${cur.activeDays}'),
                Text('Days goal was met: ${cur.goalDays}'
                    '${cur.goalRate == null ? '' : ' (${(cur.goalRate! * 100).round()}% of calendar days)'}'),
                Text('Average per active day: ${cur.avgMetersPerActiveDay == null ? '--' : formatDistance(cur.avgMetersPerActiveDay!, miles: miles)}'
                    ' · ${cur.avgSecondsPerActiveDay == null ? '--' : formatMinutes(cur.avgSecondsPerActiveDay!.round())}'),
                Text('Longest walk: ${formatDistance(cur.longestWalkMeters, miles: miles)}'),
                const SizedBox(height: 8),
                Text(delta == null
                    ? 'No walks recorded last month to compare with.'
                    : 'Distance vs last month: ${delta >= 0 ? '+' : ''}${delta.round()}% (${formatDistance(prev.meters, miles: miles)} last month)'),
                const SizedBox(height: 4),
                Text('Days without a recorded walk are shown as "no data", not as zero steps.', style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
          ]);
        },
      ),
    );
  }
}
