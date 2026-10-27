String two(int v) => v.toString().padLeft(2, '0');

String formatDistance(double meters, {bool miles = false}) {
  if (miles) return '${(meters / 1609.344).toStringAsFixed(2)} mi';
  return '${(meters / 1000).toStringAsFixed(2)} km';
}

String formatDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

String formatMinutes(int seconds) => '${(seconds / 60).round()} min';

/// [secPerKm] is null when pace cannot be computed reliably.
String formatPace(double? secPerKm, {bool miles = false}) {
  if (secPerKm == null || secPerKm.isNaN || secPerKm.isInfinite) return '--';
  final s = miles ? secPerKm * 1.609344 : secPerKm;
  final m = s ~/ 60;
  final r = two((s % 60).round());
  return "$m'$r\"/${miles ? 'mi' : 'km'}";
}

String formatMinuteOfDay(int minutes, {bool use24h = true}) {
  final h = minutes ~/ 60, m = minutes % 60;
  if (use24h) return '${two(h)}:${two(m)}';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${two(m)} ${h < 12 ? 'AM' : 'PM'}';
}
