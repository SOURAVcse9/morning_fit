import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'data/local/app_database.dart';
import 'services/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase();
  final notifications = NotificationService();
  await notifications.initialize();
  runApp(ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      notificationServiceProvider.overrideWithValue(notifications),
    ],
    child: const MorningFitApp(),
  ));
}
