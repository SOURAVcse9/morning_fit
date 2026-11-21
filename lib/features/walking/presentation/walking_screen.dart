import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../domain/walking_controller.dart';

class WalkingScreen extends ConsumerWidget {
  const WalkingScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walkingControllerProvider);
    final controller = ref.read(walkingControllerProvider.notifier);
    final center = state.points.isNotEmpty
        ? state.points.last
        : const LatLng(
            22.7010, 90.3535); // Barishal fallback until GPS is acquired
    return Scaffold(
      appBar: AppBar(title: const Text('Morning Walk')),
      body: Column(children: [
        Expanded(
            flex: 5,
            child: FlutterMap(
                options: MapOptions(initialCenter: center, initialZoom: 15),
                children: [
                  TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.morningfit'),
                  if (state.points.length > 1)
                    PolylineLayer(polylines: [
                      Polyline(
                          points: state.points,
                          strokeWidth: 5,
                          color: Colors.green)
                    ]),
                  if (state.points.isNotEmpty)
                    MarkerLayer(markers: [
                      Marker(
                          point: state.points.last,
                          width: 36,
                          height: 36,
                          child: const Icon(Icons.my_location,
                              color: Colors.green, size: 32))
                    ]),
                ])),
        Expanded(
            flex: 4,
            child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(children: [
                  if (state.message != null)
                    Text(state.message!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  Row(children: [
                    Expanded(
                        child: _metric(context, 'Steps', '${state.steps}')),
                    Expanded(
                        child: _metric(context, 'Distance',
                            '${(state.distanceMeters / 1000).toStringAsFixed(2)} km'))
                  ]),
                  const SizedBox(height: 16),
                  if (!state.isActive)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => controller.start(),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Walk'),
                      ),
                    )
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: state.isPaused
                                ? controller.resume
                                : controller.pause,
                            icon: Icon(state.isPaused
                                ? Icons.play_arrow
                                : Icons.pause),
                            label: Text(state.isPaused ? 'Resume' : 'Pause'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: controller.finish,
                            icon: const Icon(Icons.stop),
                            label: const Text('Finish'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Text(
                      'GPS tracking works best outdoors. Keep the app notification visible when background tracking is enabled.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12)),
                ]))),
      ]),
    );
  }

  Widget _metric(BuildContext context, String title, String value) =>
      Column(children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(title)
      ]);
}
