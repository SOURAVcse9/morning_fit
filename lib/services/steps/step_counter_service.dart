import 'dart:io' show Platform;

import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

enum StepAvailability { available, permissionDenied, unavailable }

/// Converts raw sensor readings into session steps.
///
/// Android reports a cumulative count since boot; iOS reports steps since
/// listening started. Either way the first reading is only a baseline.
/// A lower value than the previous one means the counter reset (reboot), so the
/// new value is treated as steps since the reset. Deltas are never negative and
/// are ignored while [counting] is false (paused).
class StepDeltaTracker {
  StepDeltaTracker({int initialSteps = 0}) : sessionSteps = initialSteps;

  int sessionSteps;
  int? _last;

  int onReading(int cumulative, {required bool counting}) {
    final last = _last;
    _last = cumulative;
    if (last == null) return 0;
    var delta = cumulative >= last ? cumulative - last : cumulative;
    if (delta < 0) delta = 0;
    if (counting) sessionSteps += delta;
    return delta;
  }
}

abstract class StepSource {
  Future<StepAvailability> check();
  Stream<int> stepCounts();
}

class PedometerStepSource implements StepSource {
  @override
  Future<StepAvailability> check() async {
    if (!Platform.isAndroid && !Platform.isIOS) return StepAvailability.unavailable;
    final perm = Platform.isAndroid ? Permission.activityRecognition : Permission.sensors;
    final status = await perm.request();
    if (!status.isGranted) return StepAvailability.permissionDenied;
    return StepAvailability.available;
  }

  @override
  Stream<int> stepCounts() => Pedometer.stepCountStream.map((e) => e.steps);
}
