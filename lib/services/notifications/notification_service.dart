import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
  }

  Future<bool?> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final androidGranted = await android?.requestNotificationsPermission();
    final iosGranted =
        await ios?.requestPermissions(alert: true, badge: true, sound: true);
    return iosGranted ?? androidGranted;
  }

  Future<void> showTestNotification() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
          'morningfit_general', 'MorningFit reminders',
          channelDescription: 'Routine and workout reminders',
          importance: Importance.high,
          priority: Priority.high),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
        1001, 'MorningFit', 'Your fitness journey is waiting.', details);
  }
}
