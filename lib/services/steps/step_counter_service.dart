import 'package:pedometer/pedometer.dart';

class StepCounterService {
  Stream<StepCount> get stepCounts => Pedometer.stepCountStream;
  Stream<PedestrianStatus> get pedestrianStatus =>
      Pedometer.pedestrianStatusStream;
}
