import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/walking/presentation/walking_screen.dart';
import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/exercises/presentation/exercises_screen.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/routine/presentation/routine_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
        GoRoute(path: '/walk', builder: (_, __) => const WalkingScreen()),
        GoRoute(path: '/history', builder: (_, __) => const CalendarScreen()),
        GoRoute(
            path: '/exercises', builder: (_, __) => const ExercisesScreen()),
        GoRoute(path: '/progress', builder: (_, __) => const AnalyticsScreen()),
        GoRoute(path: '/routine', builder: (_, __) => const RoutineScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      ],
    ));
