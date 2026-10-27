import 'distance_calculator.dart';

class LocationSample {
  const LocationSample({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.time,
  });
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime time;
}

class RecordedPoint {
  const RecordedPoint(this.sample, this.segmentIndex);
  final LocationSample sample;
  final int segmentIndex;
}

enum SampleVerdict { accepted, firstOfSegment, lowAccuracy, duplicate, implausibleJump, outOfOrder }

/// Pure-Dart route validation and distance accumulation (no Flutter imports).
///
/// Distance is only added between consecutive accepted points in the SAME
/// segment, so pauses and GPS gaps between segments never add distance.
class RouteRecorder {
  RouteRecorder({
    this.maxAccuracyMeters = 30,
    this.minStepMeters = 2,
    this.maxSpeedMetersPerSecond = 8,
  });

  final double maxAccuracyMeters;
  final double minStepMeters;
  final double maxSpeedMetersPerSecond;

  final List<RecordedPoint> points = [];
  final List<RecordedPoint> _unsaved = [];
  int segmentIndex = 0;
  double totalMeters = 0;
  LocationSample? _last;

  /// Rebuilds state from points persisted before an interruption.
  void restore(List<RecordedPoint> saved, double savedMeters) {
    points
      ..clear()
      ..addAll(saved);
    totalMeters = savedMeters;
    segmentIndex = saved.isEmpty ? 0 : saved.last.segmentIndex;
    _last = null; // next point after recovery starts a fresh segment
    startNewSegment();
  }

  void startNewSegment() {
    if (points.isNotEmpty || segmentIndex > 0) segmentIndex++;
    _last = null;
  }

  SampleVerdict add(LocationSample s) {
    if (s.accuracyMeters.isNaN || s.accuracyMeters > maxAccuracyMeters) {
      return SampleVerdict.lowAccuracy;
    }
    final last = _last;
    if (last == null) {
      _accept(s);
      return SampleVerdict.firstOfSegment;
    }
    final dtMs = s.time.difference(last.time).inMilliseconds;
    if (dtMs <= 0) return SampleVerdict.outOfOrder;
    final d = haversineMeters(last.latitude, last.longitude, s.latitude, s.longitude);
    if (d < minStepMeters) return SampleVerdict.duplicate;
    if (d / (dtMs / 1000.0) > maxSpeedMetersPerSecond) return SampleVerdict.implausibleJump;
    totalMeters += d;
    _accept(s);
    return SampleVerdict.accepted;
  }

  void _accept(LocationSample s) {
    _last = s;
    final p = RecordedPoint(s, segmentIndex);
    points.add(p);
    _unsaved.add(p);
  }

  /// Returns and clears points not yet persisted.
  List<RecordedPoint> drainUnsaved() {
    final out = List<RecordedPoint>.from(_unsaved);
    _unsaved.clear();
    return out;
  }

  /// Puts points back after a failed save so they are retried.
  void requeue(List<RecordedPoint> failed) => _unsaved.insertAll(0, failed);
}
