import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/providers.dart';

class MorningFitApp extends ConsumerStatefulWidget {
  const MorningFitApp({super.key});
  @override
  ConsumerState<MorningFitApp> createState() => _MorningFitAppState();
}

class _MorningFitAppState extends ConsumerState<MorningFitApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Recreate schedules on every launch (covers reboots and time-zone changes).
    Future.microtask(() async {
      final s = await ref.read(settingsProvider.future);
      if (s.remindersEnabled || s.summariesEnabled) {
        await ref.read(settingsProvider.notifier).rescheduleReminders();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(settingsProvider.notifier).rescheduleReminders();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MorningFit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeModeOf(ref),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
