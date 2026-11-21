import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:morningfit/app.dart';
import 'package:morningfit/data/local/app_database.dart';

void main() {
  testWidgets('app builds and displays MorningFit', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: const MorningFitApp(),
    ));
    await tester.pump();
    expect(find.text('MorningFit'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
    await database.close();
  });
}
