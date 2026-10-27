import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/common.dart';
import '../../../services/location/location_service.dart';
import '../../../services/notifications/notification_service.dart';
import '../../../shared/providers/providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  ReminderPermission _notif = ReminderPermission.unknown;
  LocationAccess? _loc;

  @override
  void initState() {
    super.initState();
    _refreshPermissions();
  }

  Future<void> _refreshPermissions() async {
    final n = await ref.read(notificationServiceProvider).permissionStatus();
    final l = await ref.read(locationServiceProvider).currentAccess();
    if (mounted) {
      setState(() {
        _notif = n;
        _loc = l;
      });
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _numberDialog(String title, num current, void Function(num) onSave, {bool decimal = false}) async {
    final c = TextEditingController(text: '$current');
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, keyboardType: TextInputType.numberWithOptions(decimal: decimal), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Save')),
        ],
      ),
    );
    final v = num.tryParse(c.text);
    if (ok == true && v != null && v > 0) onSave(v);
  }

  @override
  Widget build(BuildContext context) {
    final s = settingsOf(ref);
    final notifier = ref.read(settingsProvider.notifier);
    final err = ref.watch(reminderErrorProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(children: [
        const _Header('Goals'),
        ListTile(title: const Text('Daily step goal'), trailing: Text('${s.stepGoal}'), onTap: () => _numberDialog('Daily step goal', s.stepGoal, (v) => notifier.change((m) => m.copyWith(stepGoal: v.toInt())))),
        ListTile(title: const Text('Daily distance goal (km)'), trailing: Text(s.distanceGoalKm.toStringAsFixed(1)), onTap: () => _numberDialog('Daily distance goal (km)', s.distanceGoalKm, (v) => notifier.change((m) => m.copyWith(distanceGoalKm: v.toDouble())), decimal: true)),
        ListTile(title: const Text('Body weight (kg)'), subtitle: const Text('Only used for the calorie estimate'), trailing: Text(s.weightKg.toStringAsFixed(0)), onTap: () => _numberDialog('Body weight (kg)', s.weightKg, (v) => notifier.change((m) => m.copyWith(weightKg: v.toDouble())), decimal: true)),
        const _Header('Display'),
        SwitchListTile(title: const Text('Use miles'), value: s.useMiles, onChanged: (v) => notifier.change((m) => m.copyWith(useMiles: v))),
        SwitchListTile(title: const Text('24-hour time'), value: s.use24h, onChanged: (v) => notifier.change((m) => m.copyWith(use24h: v))),
        ListTile(
          title: const Text('Theme'),
          trailing: DropdownButton<ThemeMode>(
            value: s.themeMode,
            onChanged: (v) => v == null ? null : notifier.change((m) => m.copyWith(themeMode: v)),
            items: const [
              DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
              DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
              DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
            ],
          ),
        ),
        const _Header('Reminders'),
        ListTile(
          title: const Text('Wake-up time'),
          subtitle: const Text('Used as the default for new routine tasks'),
          trailing: Text(formatMinuteOfDay(s.wakeMinutes, use24h: s.use24h)),
          onTap: () async {
            final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: s.wakeMinutes ~/ 60, minute: s.wakeMinutes % 60));
            if (t != null) notifier.change((m) => m.copyWith(wakeMinutes: t.hour * 60 + t.minute));
          },
        ),
        SwitchListTile(
          title: const Text('Routine reminders'),
          subtitle: const Text('Scheduled local notifications. Timing can be delayed by battery saver or Do Not Disturb; not a guaranteed alarm.'),
          value: s.remindersEnabled,
          onChanged: (v) async {
            if (v) {
              final p = await ref.read(notificationServiceProvider).requestPermission();
              await _refreshPermissions();
              if (p == ReminderPermission.denied) {
                _snack('Notification permission denied. Enable it in system settings to get reminders.');
                return;
              }
            }
            await notifier.change((m) => m.copyWith(remindersEnabled: v));
          },
        ),
        SwitchListTile(title: const Text('Weekly & monthly summary reminders'), value: s.summariesEnabled, onChanged: (v) async {
          if (v) await ref.read(notificationServiceProvider).requestPermission();
          await notifier.change((m) => m.copyWith(summariesEnabled: v));
          await _refreshPermissions();
        }),
        ListTile(
          title: const Text('Send test notification'),
          leading: const Icon(Icons.notifications_active_outlined),
          onTap: () async {
            try {
              await ref.read(notificationServiceProvider).requestPermission();
              await ref.read(notificationServiceProvider).showTest();
            } catch (e) {
              _snack('Could not show notification: $e');
            }
            _refreshPermissions();
          },
        ),
        if (err != null) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: ErrorBanner(err)),
        const _Header('Permissions'),
        ListTile(title: const Text('Notifications'), trailing: Text(_notif.name)),
        ListTile(
          title: const Text('Location'),
          trailing: Text(_loc == null ? '...' : _loc!.name),
          subtitle: const Text('Requested only when you start a walk'),
          onTap: () => ref.read(locationServiceProvider).openSettings(),
        ),
        const _Header('Data'),
        ListTile(
          leading: const Icon(Icons.file_download_outlined),
          title: const Text('Export data (JSON)'),
          subtitle: const Text('Includes workouts, GPS route coordinates, routine and exercise sessions. Saved on this device only.'),
          onTap: () async {
            try {
              final f = await ref.read(exportServiceProvider).exportJson();
              _snack('Exported to ${f.path}');
            } catch (e) {
              _snack('Export failed: $e');
            }
          },
        ),
        ListTile(
          leading: Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
          title: const Text('Reset all data'),
          onTap: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (d) => AlertDialog(
                title: const Text('Reset all data?'),
                content: const Text('All walks, routes, history and settings will be permanently deleted from this device.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
                  FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Delete everything')),
                ],
              ),
            );
            if (ok == true) {
              try {
                await ref.read(databaseProvider).resetAll();
                ref.invalidate(settingsProvider);
                await ref.read(settingsProvider.notifier).rescheduleReminders();
                _snack('All data deleted.');
              } catch (_) {
                _snack(Messages.dbFailure);
              }
            }
          },
        ),
        const _Header('About'),
        const ListTile(title: Text('MorningFit 1.0.0'), subtitle: Text('Walk Better. Live Healthier.')),
        const ListTile(
          title: Text('Privacy'),
          subtitle: Text('Everything stays on this device. GPS coordinates are stored locally in SQLite and never uploaded. Map tiles are downloaded from OpenStreetMap when you view a map, so maps need internet unless tiles are cached.'),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
        child: Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
      );
}
