import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morning_fit/features/dashboard/presentation/dashboard_page.dart';
import 'package:morning_fit/shared/models/app_settings_model.dart';
import 'package:morning_fit/shared/models/workout_record.dart';
import 'package:morning_fit/shared/providers/providers.dart';

class _FakeSettings extends SettingsNotifier {
  @override
  Future<AppSettingsModel> build() async => const AppSettingsModel();
}

Widget host(List<WorkoutRecord> records) => ProviderScope(
      overrides: [
        settingsProvider.overrideWith(_FakeSettings.new),
        workoutRecordsProvider.overrideWith((ref) => Stream.value(records)),
        routineTasksProvider.overrideWith((ref) => Stream.value(const [])),
        completionsProvider.overrideWith((ref) => Stream.value(const [])),
      ],
      child: const MaterialApp(home: DashboardPage()),
    );

void main() {
  testWidgets('empty database shows zero values and a start action, no fake data', (tester) async {
    await tester.pumpWidget(host(const []));
    await tester.pumpAndSettle();
    expect(find.text('0.00 km'), findsOneWidget);
    expect(find.text('0 / 8000 steps'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Start Morning Walk'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Start Morning Walk'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('No walks yet'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('No walks yet'), findsOneWidget);
  });

  testWidgets("today's saved walks are summed on the dashboard", (tester) async {
    final now = DateTime.now();
    final key = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    WorkoutRecord rec(String id, int steps, double m) => WorkoutRecord(
        id: id, startedAt: now, localDate: key, durationSeconds: 600, distanceMeters: m, steps: steps, calories: 50);
    await tester.pumpWidget(host([rec('a', 1000, 800), rec('b', 500, 400)]));
    await tester.pumpAndSettle();
    expect(find.text('1500'), findsOneWidget);
    expect(find.text('1.20 km'), findsOneWidget);
  });
}
