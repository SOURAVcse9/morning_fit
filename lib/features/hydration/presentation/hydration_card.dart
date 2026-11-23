import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/hydration_tracker.dart';

class HydrationCard extends ConsumerWidget {
  const HydrationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hydration = ref.watch(hydrationTrackerProvider);
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: hydration.targetReached
              ? Colors.teal.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.water_drop, color: Colors.teal, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Hydration',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${hydration.glasses} / ${hydration.targetGlasses} glasses (${hydration.milliliters} ml)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: hydration.targetReached
                        ? Colors.teal
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: hydration.targetReached
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Glasses row indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(hydration.targetGlasses, (index) {
                final isFilled = index < hydration.glasses;
                return Icon(
                  isFilled ? Icons.water_drop : Icons.water_drop_outlined,
                  size: 20,
                  color: isFilled
                      ? Colors.teal
                      : theme.colorScheme.outlineVariant,
                );
              }),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  hydration.targetReached
                      ? 'Goal achieved today! 🎉'
                      : 'Stay refreshed this morning',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                IconButton.filledTonal(
                  visualDensity: VisualDensity.compact,
                  onPressed: hydration.glasses > 0
                      ? () => ref.read(hydrationTrackerProvider.notifier).removeGlass()
                      : null,
                  icon: const Icon(Icons.remove, size: 18),
                  tooltip: 'Remove 1 glass',
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      ref.read(hydrationTrackerProvider.notifier).addGlass(),
                  icon: const Icon(Icons.add, size: 18),
                  tooltip: 'Drink 1 glass (250 ml)',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
