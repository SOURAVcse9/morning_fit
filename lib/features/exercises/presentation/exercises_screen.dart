import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../data/local/app_database.dart';

class ExercisesScreen extends ConsumerWidget {
  const ExercisesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Home Exercises')),
      body: StreamBuilder<List<Exercise>>(
        stream: (db.select(db.exercises)
              ..orderBy([(t) => OrderingTerm.asc(t.category)]))
            .watch(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No exercises available.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final e = items[i];
              return Card(
                child: ExpansionTile(
                  leading:
                      const CircleAvatar(child: Icon(Icons.fitness_center)),
                  title: Text(e.name),
                  subtitle: Text('${e.category} • ${e.difficulty}'),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text(e.description)),
                    const SizedBox(height: 8),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text(e.instructions)),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                          '${e.defaultSets} sets • ${e.defaultReps} reps • ${e.restSeconds}s rest'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
