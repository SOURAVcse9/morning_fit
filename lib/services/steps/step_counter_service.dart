import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pedometer/pedometer.dart';

final stepCounterServiceProvider =
    Provider<StepCounterService>((ref) => StepCounterService());

class StepCounterService {
  Stream<StepCount> get stepCounts => Pedometer.stepCountStream;
  Stream<PedestrianStatus> get pedestrianStatus =>
      Pedometer.pedestrianStatusStream;
}

