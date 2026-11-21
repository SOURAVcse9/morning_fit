import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/notifications/notification_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const ListTile(
            leading: Icon(Icons.flag_outlined),
            title: Text('Daily step goal'),
            subtitle: Text(
                'Default goal: 10,000 steps (editable settings UI planned)')),
        const ListTile(
            leading: Icon(Icons.straighten),
            title: Text('Distance unit'),
            subtitle: Text('Kilometers')),
        const ListTile(
            leading: Icon(Icons.alarm),
            title: Text('Wake-up time'),
            subtitle: Text(
                '6:00 AM (alarm scheduling needs timezone-aware implementation)')),
        const Divider(),
        ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Test notification'),
            subtitle: const Text('Check notification permission and delivery'),
            onTap: () async {
              final service = ref.read(notificationServiceProvider);
              await service.requestPermissions();
              await service.showTestNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                        'Test notification requested. Check your device notification settings.')));
              }
            }),
        const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy'),
            subtitle: Text(
                'Workout and route data are stored locally on this device.')),
      ]));
}
