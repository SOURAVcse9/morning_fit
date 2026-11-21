import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' hide DistanceCalculator;
import 'package:morningfit/services/location/distance_calculator.dart';

void main() {
  test('same coordinate has zero distance', () {
    const point = LatLng(22.7, 90.35);
    expect(DistanceCalculator.metersBetween(point, point), closeTo(0, 0.001));
  });

  test('nearby coordinates produce a positive distance', () {
    const a = LatLng(22.7, 90.35);
    const b = LatLng(22.701, 90.35);
    expect(DistanceCalculator.metersBetween(a, b), greaterThan(100));
    expect(DistanceCalculator.metersBetween(a, b), lessThan(120));
  });
}
