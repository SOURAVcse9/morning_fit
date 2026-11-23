import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/steps/daily_step_tracker.dart';
import '../../hydration/domain/hydration_tracker.dart';

class VitalityData {
  const VitalityData({
    required this.score,
    required this.statusLabel,
    required this.color,
    required this.stepsContribution,
    required this.walkContribution,
    required this.waterContribution,
    required this.routineContribution,
  });

  final int score;
  final String statusLabel;
  final Color color;
  final int stepsContribution;
  final int walkContribution;
  final int waterContribution;
  final int routineContribution;
}

final vitalityDataProvider = Provider<VitalityData>((ref) {
  final stepState = ref.watch(dailyStepTrackerProvider);
  final hydrationState = ref.watch(hydrationTrackerProvider);

  // 1. Steps (up to 40 pts)
  final stepRatio = stepState.dailyGoal > 0
      ? (stepState.todaySteps / stepState.dailyGoal).clamp(0.0, 1.0)
      : 0.0;
  final stepsPts = (stepRatio * 40).round();

  // 2. Hydration (up to 20 pts)
  final waterRatio = hydrationState.targetGlasses > 0
      ? (hydrationState.glasses / hydrationState.targetGlasses).clamp(0.0, 1.0)
      : 0.0;
  final waterPts = (waterRatio * 20).round();

  // 3. Walks (up to 25 pts)
  // Estimated from today's completed workouts if available
  // Fallback to active steps proportion if no workout logged yet
  final activeMinutes = (stepState.todaySteps / 100).clamp(0, 30).toDouble();
  final walkRatio = (activeMinutes / 30).clamp(0.0, 1.0);
  final walkPts = (walkRatio * 25).round();

  // 4. Routine completion (up to 15 pts) - default starter routines
  final routinePts = (stepState.todaySteps > 1000 ? 15 : (stepState.todaySteps > 200 ? 8 : 0));

  final totalScore = min(100, stepsPts + waterPts + walkPts + routinePts);

  String label;
  Color color;
  if (totalScore >= 90) {
    label = 'Peak Vitality ⚡';
    color = const Color(0xFF2E7D32); // deep vibrant green
  } else if (totalScore >= 70) {
    label = 'Thriving 🌿';
    color = const Color(0xFF43A047);
  } else if (totalScore >= 40) {
    label = 'Good Pace 🚶';
    color = const Color(0xFF66BB6A);
  } else {
    label = 'Recharging 🌅';
    color = const Color(0xFF81C784);
  }

  return VitalityData(
    score: totalScore,
    statusLabel: label,
    color: color,
    stepsContribution: stepsPts,
    walkContribution: walkPts,
    waterContribution: waterPts,
    routineContribution: routinePts,
  );
});
