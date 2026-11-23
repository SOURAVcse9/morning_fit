import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/notifications/notification_service.dart';
import '../../../services/steps/daily_step_tracker.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showStepGoalDialog(BuildContext context, WidgetRef ref, int currentGoal) {
    const goals = [5000, 8000, 10000, 12000, 15000];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Daily Step Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: goals
              .map(
                (g) => ListTile(
                  title: Text('$g steps'),
                  trailing: g == currentGoal
                      ? Icon(Icons.check,
                          color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    ref.read(dailyStepTrackerProvider.notifier).setDailyGoal(g);
                    Navigator.of(ctx).pop();
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepState = ref.watch(dailyStepTrackerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Step Tracking section
          Text(
            'Activity & Tracking',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            secondary: const Icon(Icons.all_inclusive),
            title: const Text('24/7 Background Tracking'),
            subtitle: Text(
              stepState.isTracking
                  ? 'Active midnight-to-midnight (12 AM – 12 PM)'
                  : 'Tracking is paused',
            ),
            value: stepState.isTracking,
            onChanged: (val) =>
                ref.read(dailyStepTrackerProvider.notifier).toggleTracking(val),
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Daily Step Goal'),
            subtitle: Text('${stepState.dailyGoal} steps'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showStepGoalDialog(context, ref, stepState.dailyGoal),
          ),
          ListTile(
            leading: const Icon(Icons.sensors),
            title: const Text('Step Sensor Status'),
            subtitle: Text(stepState.statusMessage),
          ),
          const ListTile(
            leading: Icon(Icons.straighten),
            title: Text('Distance Unit'),
            subtitle: Text('Kilometers (km)'),
          ),

          const Divider(height: 32),

          // Notifications & Reminders section
          Text(
            'Notifications & Reminders',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          const ListTile(
            leading: Icon(Icons.alarm),
            title: Text('Morning Routine Alarm'),
            subtitle: Text('Default: 6:00 AM daily'),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Send Test Notification'),
            subtitle: const Text('Test device notification delivery'),
            onTap: () async {
              try {
                final service = ref.read(notificationServiceProvider);
                await service.requestPermissions();
                await service.showTestNotification();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test notification delivered successfully.'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Notification test notice: $e'),
                    ),
                  );
                }
              }
            },
          ),

          const Divider(height: 32),

          // About & Privacy section
          Text(
            'About MorningFit',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          const ListTile(
            leading: Icon(Icons.verified),
            title: Text('Version'),
            subtitle: Text('MorningFit v2.0 (v2.0.0+2)'),
          ),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Offline & Private'),
            subtitle: Text(
              'All step counts, hydration, routes, and statistics stay 100% offline on your device.',
            ),
          ),
        ],
      ),
    );
  }
}
