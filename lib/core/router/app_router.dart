import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/analytics/presentation/progress_page.dart';
import '../../features/calendar/presentation/history_page.dart';
import '../../features/calendar/presentation/workout_detail_page.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/exercises/presentation/exercises_page.dart';
import '../../features/routine/presentation/routine_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/walking/presentation/walk_page.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});
  final StatefulNavigationShell shell;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: shell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.directions_walk_outlined), selectedIcon: Icon(Icons.directions_walk), label: 'Walk'),
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'History'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      );
}

GoRoute _branch(String path, Widget page) => GoRoute(path: path, builder: (_, __) => page);

final routerProvider = Provider<GoRouter>((ref) => GoRouter(
      initialLocation: '/',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, __, shell) => HomeShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [_branch('/', const DashboardPage())]),
            StatefulShellBranch(routes: [_branch('/walk', const WalkPage())]),
            StatefulShellBranch(routes: [_branch('/history', const HistoryPage())]),
            StatefulShellBranch(routes: [_branch('/settings', const SettingsPage())]),
          ],
        ),
        _branch('/exercises', const ExercisesPage()),
        _branch('/routine', const RoutinePage()),
        _branch('/progress', const ProgressPage()),
        GoRoute(path: '/workout/:id', builder: (_, s) => WorkoutDetailPage(id: s.pathParameters['id']!)),
      ],
    ));
