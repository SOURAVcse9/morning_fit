import 'package:flutter/material.dart';

class AppSettingsModel {
  const AppSettingsModel({
    this.stepGoal = 8000,
    this.distanceGoalKm = 5.0,
    this.useMiles = false,
    this.use24h = true,
    this.themeMode = ThemeMode.system,
    this.wakeMinutes = 6 * 60,
    this.remindersEnabled = false,
    this.summariesEnabled = false,
    this.restWeekdays = const {},
    this.weightKg = 70,
  });

  final int stepGoal;
  final double distanceGoalKm;
  final bool useMiles;
  final bool use24h;
  final ThemeMode themeMode;
  final int wakeMinutes;
  final bool remindersEnabled;
  final bool summariesEnabled;
  final Set<int> restWeekdays; // ISO weekdays
  final double weightKg; // only used for the calorie estimate

  double get distanceGoalMeters => distanceGoalKm * 1000;

  factory AppSettingsModel.fromMap(Map<String, String> m) {
    const d = AppSettingsModel();
    return AppSettingsModel(
      stepGoal: int.tryParse(m['stepGoal'] ?? '') ?? d.stepGoal,
      distanceGoalKm: double.tryParse(m['distanceGoalKm'] ?? '') ?? d.distanceGoalKm,
      useMiles: m['useMiles'] == '1',
      use24h: (m['use24h'] ?? '1') == '1',
      themeMode: ThemeMode.values.firstWhere((t) => t.name == m['themeMode'], orElse: () => ThemeMode.system),
      wakeMinutes: int.tryParse(m['wakeMinutes'] ?? '') ?? d.wakeMinutes,
      remindersEnabled: m['remindersEnabled'] == '1',
      summariesEnabled: m['summariesEnabled'] == '1',
      restWeekdays: (m['restWeekdays'] ?? '').split(',').where((s) => s.isNotEmpty).map(int.parse).toSet(),
      weightKg: double.tryParse(m['weightKg'] ?? '') ?? d.weightKg,
    );
  }

  Map<String, String> toMap() => {
        'stepGoal': '$stepGoal',
        'distanceGoalKm': '$distanceGoalKm',
        'useMiles': useMiles ? '1' : '0',
        'use24h': use24h ? '1' : '0',
        'themeMode': themeMode.name,
        'wakeMinutes': '$wakeMinutes',
        'remindersEnabled': remindersEnabled ? '1' : '0',
        'summariesEnabled': summariesEnabled ? '1' : '0',
        'restWeekdays': restWeekdays.join(','),
        'weightKg': '$weightKg',
      };

  AppSettingsModel copyWith({
    int? stepGoal,
    double? distanceGoalKm,
    bool? useMiles,
    bool? use24h,
    ThemeMode? themeMode,
    int? wakeMinutes,
    bool? remindersEnabled,
    bool? summariesEnabled,
    Set<int>? restWeekdays,
    double? weightKg,
  }) =>
      AppSettingsModel(
        stepGoal: stepGoal ?? this.stepGoal,
        distanceGoalKm: distanceGoalKm ?? this.distanceGoalKm,
        useMiles: useMiles ?? this.useMiles,
        use24h: use24h ?? this.use24h,
        themeMode: themeMode ?? this.themeMode,
        wakeMinutes: wakeMinutes ?? this.wakeMinutes,
        remindersEnabled: remindersEnabled ?? this.remindersEnabled,
        summariesEnabled: summariesEnabled ?? this.summariesEnabled,
        restWeekdays: restWeekdays ?? this.restWeekdays,
        weightKg: weightKg ?? this.weightKg,
      );
}
