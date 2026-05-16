import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../data/exercise_catalog.dart';
import '../../../providers/providers.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/app_badge.dart';

class ExercisePickerPage extends ConsumerWidget {
  const ExercisePickerPage({super.key, required this.sessionId, required this.muscle});
  final String sessionId;
  final String muscle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muscleGroup = MuscleGroup.fromLabel(muscle);
    if (muscleGroup == null) {
      return Scaffold(body: Center(child: Text('Unknown muscle: $muscle')));
    }
    final exercisesAsync = ref.watch(_rankedExercisesProvider(muscleGroup));

    return Scaffold(
      backgroundColor: PeakColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(muscle.toUpperCase(), style: PeakType.overline()),
      ),
      body: exercisesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: PeakColors.primary)),
        error: (e, _) => Center(child: Text('$e', style: PeakType.bodyMd())),
        data: (data) => ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            PeakSpacing.edge,
            8,
            PeakSpacing.edge,
            PeakSpacing.edge,
          ),
          itemCount: data.exercises.length + 1,
          separatorBuilder: (_, __) => const Divider(height: 1, color: PeakColors.outlineVariant),
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Pick an exercise',
                  style: PeakType.headlineXl().copyWith(fontSize: 30, height: 1.05),
                ),
              );
            }
            final ex = data.exercises[i - 1];
            final usage = data.usage[ex.id] ?? 0;
            return InkWell(
              onTap: () async {
                final repo = ref.read(sessionRepositoryProvider);
                final entryId = await repo.addEntry(
                  sessionId: sessionId,
                  exerciseId: ex.id,
                  muscle: muscleGroup,
                );
                if (context.mounted) {
                  context.go('/session/$sessionId/log?entryId=$entryId');
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ex.name, style: PeakType.bodyLg()),
                          const SizedBox(height: 2),
                          Text(
                            '${ex.equipment.label} · ${ex.movementPattern.label} · ${ex.difficulty.label}',
                            style: PeakType.overline(),
                          ),
                          if (ex.cue.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              ex.cue,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: PeakType.bodyMd(color: PeakColors.mutedForeground),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        PeakBadge(label: '★' * ex.evidenceRating),
                        if (usage > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('$usage× recent', style: PeakType.overline()),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PickerData {
  _PickerData({required this.exercises, required this.usage});
  final List<Exercise> exercises;
  final Map<String, int> usage;
}

final _rankedExercisesProvider =
    FutureProvider.autoDispose.family<_PickerData, MuscleGroup>((ref, m) async {
  final repo = ref.watch(sessionRepositoryProvider);
  final catalog = await ref.watch(exerciseCatalogProvider.future);
  final usage = await repo.recentExerciseUsage(days: 14);
  final ranked = catalog.rank(catalog.forMuscle(m), usage);
  return _PickerData(exercises: ranked, usage: usage);
});
