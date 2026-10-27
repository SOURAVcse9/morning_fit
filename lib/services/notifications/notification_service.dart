import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/utils/notification_ids.dart';
import '../../data/local/app_database.dart';

enum ReminderPermission { granted, denied, unknown }

/// Local reminders. Uses inexact scheduling on purpose (no exact-alarm
/// permission needed); delivery can be delayed by battery optimisation, Doze or
/// Do Not Disturb, and iOS does not offer a guaranteed system alarm.
class NotificationService {
  NotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  static const _channel = AndroidNotificationDetails(
    'morningfit_reminders',
    'Reminders',
    channelDescription: 'Routine, exercise and summary reminders',
    importance: Importance.high,
    priority: Priority.high,
  );
  static const _details = NotificationDetails(android: _channel, iOS: DarwinNotificationDetails());

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC); // fall back; reminders then use UTC
    }
    await _plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ));
    _ready = true;
  }

  /// Ask only when the user enables reminders.
  Future<ReminderPermission> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    bool? ok;
    if (android != null) ok = await android.requestNotificationsPermission();
    if (ios != null) ok = await ios.requestPermissions(alert: true, badge: true, sound: true);
    return ok == null ? ReminderPermission.unknown : (ok ? ReminderPermission.granted : ReminderPermission.denied);
  }

  Future<ReminderPermission> permissionStatus() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final enabled = await android.areNotificationsEnabled();
      return enabled == null ? ReminderPermission.unknown : (enabled ? ReminderPermission.granted : ReminderPermission.denied);
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final p = await ios?.checkPermissions();
    if (p == null) return ReminderPermission.unknown;
    return p.isEnabled ? ReminderPermission.granted : ReminderPermission.denied;
  }

  Future<void> showTest() async {
    await init();
    await _plugin.show(NotificationIds.test, 'MorningFit', 'Test notification: reminders are working.', _details);
  }

  Future<void> showGoalReached() async {
    await init();
    await _plugin.show(NotificationIds.goalReached, 'Goal reached!', 'You completed today\'s walking goal. Great job!', _details);
  }

  tz.TZDateTime _next(int isoWeekday, int minutes) {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, minutes ~/ 60, minutes % 60);
    while (t.weekday != isoWeekday || !t.isAfter(now)) {
      t = t.add(const Duration(days: 1));
    }
    return t;
  }

  /// Cancels every task notification and recreates them from [tasks].
  /// Safe to call repeatedly: IDs are stable, so no duplicates are created.
  /// Call after edits, app start, and time-zone changes.
  Future<void> rescheduleRoutine(List<RoutineTask> tasks, {required bool enabled}) async {
    await init();
    for (final t in tasks) {
      for (var d = 1; d <= 7; d++) {
        await _plugin.cancel(NotificationIds.forTask(t.id, d));
      }
    }
    if (!enabled) return;
    for (final t in tasks.where((t) => t.isEnabled)) {
      final days = t.repeatDays.split(',').where((s) => s.isNotEmpty).map(int.parse);
      for (final d in days) {
        await _plugin.zonedSchedule(
          NotificationIds.forTask(t.id, d),
          t.title,
          t.description.isEmpty ? 'MorningFit reminder' : t.description,
          _next(d, t.scheduledMinutes),
          _details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    }
  }

  /// Static-text reminders: content cannot be computed at schedule time, so they
  /// invite the user to open the Progress tab.
  Future<void> scheduleSummaries({required bool enabled}) async {
    await init();
    await _plugin.cancel(NotificationIds.weeklySummary);
    await _plugin.cancel(NotificationIds.monthlySummary);
    if (!enabled) return;
    await _plugin.zonedSchedule(
      NotificationIds.weeklySummary,
      'Your weekly summary',
      'See how your week went in the Progress tab.',
      _next(DateTime.sunday, 20 * 60),
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
    final now = tz.TZDateTime.now(tz.local);
    var first = tz.TZDateTime(tz.local, now.year, now.month, 1, 9);
    if (!first.isAfter(now)) first = tz.TZDateTime(tz.local, now.year, now.month + 1, 1, 9);
    await _plugin.zonedSchedule(
      NotificationIds.monthlySummary,
      'Your monthly summary',
      'Review last month\'s walking in the Progress tab.',
      first,
      _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }
}
