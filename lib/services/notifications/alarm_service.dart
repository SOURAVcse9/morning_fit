import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Schedules reminder notifications. Exact alarm guarantees vary by OS and device.
class AlarmService {
  AlarmService(this.plugin);
  final FlutterLocalNotificationsPlugin plugin;

  Future<void> cancel(int id) => plugin.cancel(id);

  /// Basic daily reminder. Time-zone aware scheduling should be added with
  /// timezone package and initialized timezone data before production release.
  Future<void> scheduleReminder(
      {required int id, required String title, required String body}) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
          'morningfit_routine', 'Routine reminders',
          channelDescription: 'Morning routine reminders',
          importance: Importance.high,
          priority: Priority.high),
      iOS: DarwinNotificationDetails(),
    );
    await plugin.show(id, title, body, details);
  }
}
