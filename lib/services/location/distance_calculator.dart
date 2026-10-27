import 'dart:math' as math;

const double _earthRadiusMeters = 6371008.8;

double _rad(double deg) => deg * math.pi / 180.0;

/// Great-circle distance in meters (Haversine formula).
double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(_rad(lat1)) * math.cos(_rad(lat2)) * math.pow(math.sin(dLon / 2), 2);
  return 2 * _earthRadiusMeters * math.asin(math.min(1.0, math.sqrt(a)));
}
