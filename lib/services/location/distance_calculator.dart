import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

class DistanceCalculator {
  static const double _earthRadiusMeters = 6371000;

  static double metersBetween(LatLng a, LatLng b) {
    final lat1 = _radians(a.latitude);
    final lat2 = _radians(b.latitude);
    final dLat = _radians(b.latitude - a.latitude);
    final dLon = _radians(b.longitude - a.longitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return 2 * _earthRadiusMeters * math.asin(math.min(1, math.sqrt(h)));
  }

  static double _radians(double degrees) => degrees * math.pi / 180;
}
