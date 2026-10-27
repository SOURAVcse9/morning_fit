import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/utils/format.dart';
import '../../../core/widgets/common.dart';
import '../../../services/location/location_service.dart';
import '../../../services/steps/step_counter_service.dart';
import '../../../services/tracking/tracking_lifecycle.dart';
import '../../../shared/providers/providers.dart';

class WalkPage extends ConsumerStatefulWidget {
  const WalkPage({super.key});
  @override
  ConsumerState<WalkPage> createState() => _WalkPageState();
}

class _WalkPageState extends ConsumerState<WalkPage> {
  final _map = MapController();
  bool _mapReady = false;
  bool _follow = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(trackingProvider.notifier).recover());
  }

  Future<bool> _confirm(String title, String body, String yes) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep going')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(yes)),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(trackingProvider);
    final ctrl = ref.read(trackingProvider.notifier);
    final settings = settingsOf(ref);

    ref.listen(trackingProvider.select((t) => t.current), (_, cur) {
      if (cur != null && _mapReady && _follow) _map.move(cur, _map.camera.zoom < 15 ? 17 : _map.camera.zoom);
    });

    final idle = s.status == WalkStatus.idle;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Walk')),
      body: Column(children: [
        if (s.message != null || (idle && s.access != null && s.access != LocationAccess.granted))
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ErrorBanner(
              s.message ?? 'Location is not available.',
              actionLabel: s.access == LocationAccess.deniedForever || s.access == LocationAccess.serviceDisabled ? 'Settings' : null,
              onAction: () => ref.read(locationServiceProvider).openSettings(),
            ),
          ),
        Expanded(
          child: Stack(children: [
            FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: s.current ?? const LatLng(0, 0),
                initialZoom: s.current == null ? 2 : 17,
                onMapReady: () => _mapReady = true,
                onPositionChanged: (_, byGesture) {
                  if (byGesture && _follow) setState(() => _follow = false);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.morning_fit',
                ),
                PolylineLayer(polylines: [
                  for (final seg in s.segments) Polyline(points: seg, strokeWidth: 5, color: scheme.primary),
                ]),
                if (s.current != null)
                  MarkerLayer(markers: [
                    Marker(point: s.current!, width: 28, height: 28, child: Icon(Icons.my_location, color: scheme.tertiary)),
                  ]),
                const RichAttributionWidget(attributions: [TextSourceAttribution('© OpenStreetMap contributors')]),
              ],
            ),
            Positioned(
              right: 12,
              top: 12,
              child: FloatingActionButton.small(
                heroTag: 'recenter',
                tooltip: 'Recenter',
                onPressed: () {
                  setState(() => _follow = true);
                  if (s.current != null && _mapReady) _map.move(s.current!, 17);
                },
                child: const Icon(Icons.gps_fixed),
              ),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            if (!idle) ...[
              Text(formatDuration(s.elapsedSeconds), style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _Metric(formatDistance(s.distanceMeters, miles: settings.useMiles), 'Distance'),
                _Metric(
                  s.stepAvailability == StepAvailability.available ? '${s.steps}' : 'n/a',
                  s.stepAvailability == StepAvailability.available ? 'Steps' : 'Steps unavailable',
                ),
                _Metric(formatPace(s.paceSecPerKm, miles: settings.useMiles), 'Avg pace'),
              ]),
              const SizedBox(height: 8),
              _GpsChip(s),
              const SizedBox(height: 12),
            ],
            _Controls(
              s: s,
              onStart: ctrl.start,
              onPause: ctrl.pause,
              onResume: ctrl.resume,
              onFinish: () async {
                if (!await _confirm('Finish walk?', 'Your walk will be saved to History.', 'Finish')) return;
                final id = await ctrl.finish();
                if (id != null && context.mounted) context.push('/workout/$id');
              },
              onCancel: () async {
                if (await _confirm('Discard this walk?', 'The recorded route and stats will be deleted.', 'Discard')) {
                  await ctrl.cancel();
                }
              },
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.value, this.label);
  final String value, label;
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ]);
}

class _GpsChip extends StatelessWidget {
  const _GpsChip(this.s);
  final TrackingState s;
  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (s.gps) {
      GpsStatus.good => ('GPS good${s.accuracyMeters == null ? '' : ' · ±${s.accuracyMeters!.round()} m'}', Icons.gps_fixed),
      GpsStatus.weak => ('GPS weak · ignoring inaccurate points', Icons.gps_not_fixed),
      GpsStatus.lost => ('GPS signal lost · no distance added', Icons.gps_off),
      GpsStatus.unknown => (s.status == WalkStatus.paused ? 'Paused' : 'Searching for GPS...', Icons.gps_not_fixed),
    };
    return Chip(avatar: Icon(icon, size: 18), label: Text(s.status == WalkStatus.paused ? 'Paused' : label));
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.s, required this.onStart, required this.onPause, required this.onResume, required this.onFinish, required this.onCancel});
  final TrackingState s;
  final VoidCallback onStart, onPause, onResume, onFinish, onCancel;
  @override
  Widget build(BuildContext context) {
    switch (s.status) {
      case WalkStatus.idle:
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(onPressed: onStart, icon: const Icon(Icons.play_arrow), label: const Text('Start Walk')),
        );
      case WalkStatus.saving:
        return const CircularProgressIndicator();
      case WalkStatus.recording:
      case WalkStatus.paused:
        final rec = s.status == WalkStatus.recording;
        return Row(children: [
          IconButton.outlined(tooltip: 'Cancel walk', onPressed: onCancel, icon: const Icon(Icons.close)),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: rec ? onPause : onResume,
              icon: Icon(rec ? Icons.pause : Icons.play_arrow),
              label: Text(rec ? 'Pause' : 'Resume'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: FilledButton.icon(onPressed: onFinish, icon: const Icon(Icons.flag), label: const Text('Finish'))),
        ]);
    }
  }
}
