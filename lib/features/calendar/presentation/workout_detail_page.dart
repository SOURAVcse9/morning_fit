import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/utils/format.dart';
import '../../../core/widgets/common.dart';
import '../../../shared/providers/providers.dart';

class WorkoutDetailPage extends ConsumerWidget {
  const WorkoutDetailPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref.watch(workoutProvider(id));
    final route = ref.watch(routeProvider(id));
    final miles = settingsOf(ref).useMiles;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Walk details'),
        actions: [
          IconButton(
            tooltip: 'Delete walk',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Delete this walk?'),
                  content: const Text('The workout and its route will be removed. This cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (ok == true) {
                await ref.read(workoutRepositoryProvider).delete(id);
                if (context.mounted) context.pop();
              }
            },
          ),
        ],
      ),
      body: workout.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: Icons.error_outline, message: '$e'),
        data: (w) {
          if (w == null) return const EmptyState(icon: Icons.search_off, message: 'This walk no longer exists.');
          final segs = route.valueOrNull ?? const <List<LatLng>>[];
          final all = segs.expand((s) => s).toList();
          return ListView(padding: const EdgeInsets.all(16), children: [
            Text(DateFormat('EEEE, MMM d · HH:mm').format(w.startedAt.toLocal()), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: all.length < 2
                    ? const EmptyState(icon: Icons.map_outlined, message: 'No GPS route was recorded for this walk.')
                    : FlutterMap(
                        options: MapOptions(
                          initialCameraFit: CameraFit.bounds(bounds: LatLngBounds.fromPoints(all), padding: const EdgeInsets.all(32)),
                        ),
                        children: [
                          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.example.morning_fit'),
                          PolylineLayer(polylines: [for (final s in segs) Polyline(points: s, strokeWidth: 5, color: Theme.of(context).colorScheme.primary)]),
                          MarkerLayer(markers: [
                            Marker(point: all.first, width: 24, height: 24, child: const Icon(Icons.trip_origin, color: Colors.green)),
                            Marker(point: all.last, width: 24, height: 24, child: const Icon(Icons.flag, color: Colors.red)),
                          ]),
                          const RichAttributionWidget(attributions: [TextSourceAttribution('© OpenStreetMap contributors')]),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.9,
              children: [
                StatTile(icon: Icons.route, value: formatDistance(w.distanceMeters, miles: miles), label: 'Distance'),
                StatTile(icon: Icons.timer_outlined, value: formatDuration(w.durationSeconds), label: 'Active time'),
                StatTile(icon: Icons.directions_walk, value: '${w.steps}', label: 'Steps'),
                StatTile(icon: Icons.speed, value: formatPace(w.averagePace, miles: miles), label: 'Average pace'),
                StatTile(icon: Icons.local_fire_department_outlined, value: '${w.caloriesEstimate.round()} kcal', label: 'Calories (estimate)'),
              ],
            ),
          ]);
        },
      ),
    );
  }
}
