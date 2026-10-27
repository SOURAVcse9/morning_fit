import 'package:flutter_test/flutter_test.dart';
import 'package:morning_fit/services/location/distance_calculator.dart';
import 'package:morning_fit/services/location/route_recorder.dart';

LocationSample s(double lat, double lon, int sec, {double acc = 5}) => LocationSample(
      latitude: lat,
      longitude: lon,
      accuracyMeters: acc,
      time: DateTime.utc(2026, 1, 1, 6, 0, sec),
    );

void main() {
  group('haversine', () {
    test('one degree of latitude is about 111.19 km', () {
      expect(haversineMeters(0, 0, 1, 0), closeTo(111195, 150));
    });
    test('same point is zero and distance is symmetric', () {
      expect(haversineMeters(23.8, 90.4, 23.8, 90.4), 0);
      expect(haversineMeters(23.8, 90.4, 23.81, 90.41), closeTo(haversineMeters(23.81, 90.41, 23.8, 90.4), 1e-6));
    });
  });

  group('RouteRecorder', () {
    test('accumulates distance between valid points', () {
      final r = RouteRecorder();
      expect(r.add(s(0, 0, 0)), SampleVerdict.firstOfSegment);
      // ~11 m north in 10 s (1.1 m/s walking speed)
      expect(r.add(s(0.0001, 0, 10)), SampleVerdict.accepted);
      expect(r.totalMeters, closeTo(11.1, 0.3));
    });

    test('rejects low accuracy points', () {
      final r = RouteRecorder();
      r.add(s(0, 0, 0));
      expect(r.add(s(0.0001, 0, 10, acc: 80)), SampleVerdict.lowAccuracy);
      expect(r.totalMeters, 0);
    });

    test('rejects implausible jumps and keeps the previous anchor', () {
      final r = RouteRecorder();
      r.add(s(0, 0, 0));
      expect(r.add(s(0.01, 0, 2)), SampleVerdict.implausibleJump); // ~1.1 km in 2 s
      expect(r.totalMeters, 0);
      expect(r.add(s(0.0001, 0, 12)), SampleVerdict.accepted);
    });

    test('ignores GPS jitter (duplicates) and out-of-order samples', () {
      final r = RouteRecorder();
      r.add(s(0, 0, 10));
      expect(r.add(s(0.000005, 0, 12)), SampleVerdict.duplicate);
      expect(r.add(s(0.0001, 0, 5)), SampleVerdict.outOfOrder);
      expect(r.totalMeters, 0);
    });

    test('pause/resume starts a new segment and adds no gap distance', () {
      final r = RouteRecorder();
      r.add(s(0, 0, 0));
      r.add(s(0.0001, 0, 10));
      final before = r.totalMeters;
      r.startNewSegment();
      expect(r.add(s(0.01, 0, 600)), SampleVerdict.firstOfSegment); // far away after the pause
      expect(r.totalMeters, before);
      expect(r.points.last.segmentIndex, 1);
    });

    test('drainUnsaved returns each point once and requeue restores them', () {
      final r = RouteRecorder();
      r.add(s(0, 0, 0));
      r.add(s(0.0001, 0, 10));
      final first = r.drainUnsaved();
      expect(first.length, 2);
      expect(r.drainUnsaved(), isEmpty);
      r.requeue(first);
      expect(r.drainUnsaved().length, 2);
    });
  });
}
