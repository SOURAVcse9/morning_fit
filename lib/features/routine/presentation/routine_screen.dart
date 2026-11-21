import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../../data/local/app_database.dart';

class RoutineScreen extends ConsumerWidget {
  const RoutineScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);
    return Scaffold(
        appBar: AppBar(title: const Text('Daily Routine')),
        body: StreamBuilder<List<RoutineTask>>(
          stream: (db.select(db.routineTasks)
                ..orderBy([(t) => OrderingTerm.asc(t.scheduledTime)]))
              .watch(),
          builder: (context, snapshot) {
            final tasks = snapshot.data ?? [];
            return ListView(padding: const EdgeInsets.all(16), children: [
              const Text(
                  'A sample routine for a 6:00 AM start. Add tasks to personalize it.'),
              const SizedBox(height: 12),
              if (tasks.isEmpty)
                const Card(
                    child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                            'No routine tasks yet. The database is ready for routine editing in the next implementation stage.'))),
              ...tasks.map((t) => Card(
                  child: ListTile(
                      leading: const Icon(Icons.alarm),
                      title: Text(t.title),
                      subtitle:
                          Text('${t.scheduledTime} • ${t.durationMinutes} min'),
                      trailing: Switch(
                          value: t.isEnabled,
                          onChanged: (value) async {
                            await (db.update(db.routineTasks)
                                  ..where((r) => r.id.equals(t.id)))
                                .write(RoutineTasksCompanion(
                                    isEnabled: Value(value)));
                          })))),
            ]);
          },
        ));
  }
}
