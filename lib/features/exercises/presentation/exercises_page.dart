import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/widgets/common.dart';
import '../../../data/local/app_database.dart';
import '../../../shared/providers/providers.dart';

IconData _iconFor(String category) => switch (category) {
      'Legs' => Icons.directions_run,
      'Upper body' => Icons.accessibility_new,
      'Arms' => Icons.fitness_center,
      'Core' => Icons.self_improvement,
      _ => Icons.spa,
    };

class ExercisesPage extends ConsumerWidget {
  const ExercisesPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(exercisesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Exercises')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: Icons.error_outline, message: '$e'),
        data: (list) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final e = list[i];
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Icon(_iconFor(e.category))),
                title: Text(e.name),
                subtitle: Text('${e.difficulty} · ${e.defaultSets} × ${e.defaultReps} · rest ${e.restSeconds}s'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ExerciseDetailPage(exercise: e))),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ExerciseDetailPage extends ConsumerStatefulWidget {
  const ExerciseDetailPage({super.key, required this.exercise});
  final Exercise exercise;
  @override
  ConsumerState<ExerciseDetailPage> createState() => _ExerciseDetailState();
}

class _ExerciseDetailState extends ConsumerState<ExerciseDetailPage> {
  int _setsDone = 0;
  int _rest = 0;
  Timer? _timer;
  late final DateTime _started = DateTime.now().toUtc();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _completeSet() {
    setState(() {
      _setsDone++;
      _rest = widget.exercise.restSeconds;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_rest <= 1) {
        t.cancel();
        setState(() => _rest = 0);
      } else {
        setState(() => _rest--);
      }
    });
  }

  Future<void> _save() async {
    final e = widget.exercise;
    final now = DateTime.now().toUtc();
    try {
      await ref.read(routineDaoProvider).addExerciseSession(ExerciseSessionsCompanion.insert(
            id: const Uuid().v4(),
            exerciseId: e.id,
            startedAt: _started,
            endedAt: now,
            durationSeconds: now.difference(_started).inSeconds,
            setsCompleted: _setsDone,
            repsCompleted: _setsDone * e.defaultReps,
          ));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save this session.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.exercise;
    final steps = e.instructions.split('\n');
    return Scaffold(
      appBar: AppBar(title: Text(e.name)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(e.description),
        const SizedBox(height: 12),
        Wrap(spacing: 8, children: [
          Chip(label: Text(e.difficulty)),
          Chip(label: Text(e.category)),
          Chip(label: Text('${e.defaultSets} sets × ${e.defaultReps}')),
          Chip(label: Text('Rest ${e.restSeconds}s')),
        ]),
        const SizedBox(height: 12),
        SectionCard(title: 'How to do it', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (var i = 0; i < steps.length; i++) Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('${i + 1}. ${steps[i]}')),
        ])),
        const SizedBox(height: 12),
        SectionCard(
          title: 'Track it',
          child: Column(children: [
            Text('Sets completed: $_setsDone / ${e.defaultSets}', style: Theme.of(context).textTheme.titleMedium),
            if (_rest > 0) Padding(padding: const EdgeInsets.all(8), child: Text('Rest: $_rest s', style: Theme.of(context).textTheme.headlineSmall)),
            const SizedBox(height: 8),
            FilledButton(onPressed: _rest > 0 ? null : _completeSet, child: const Text('Complete a set')),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: _setsDone == 0 ? null : _save, child: const Text('Save session')),
          ]),
        ),
      ]),
    );
  }
}
