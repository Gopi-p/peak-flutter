import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils.dart';
import '../../../data/exercise_catalog.dart';
import '../../../providers/providers.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_card.dart';

class ExerciseDetailPage extends ConsumerWidget {
  const ExerciseDetailPage({super.key, required this.exerciseId});
  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(exerciseCatalogProvider);
    return Scaffold(
      backgroundColor: PeakColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Library', style: PeakType.overline()),
      ),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: PeakColors.primary)),
        error: (e, _) => Center(child: Text('$e', style: PeakType.bodyMd())),
        data: (catalog) {
          final ex = catalog.byId(exerciseId);
          if (ex == null) {
            return Center(child: Text('Exercise not found', style: PeakType.bodyMd()));
          }
          return _Detail(exercise: ex);
        },
      ),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.exercise});
  final Exercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(_progressProvider(exercise.id));
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PeakSpacing.edge,
        8,
        PeakSpacing.edge,
        PeakSpacing.edge,
      ),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PeakBadge(label: '★' * exercise.evidenceRating),
            PeakBadge(label: exercise.equipment.label, variant: PeakBadgeVariant.secondary),
            PeakBadge(label: exercise.movementPattern.label, variant: PeakBadgeVariant.secondary),
            PeakBadge(label: exercise.difficulty.label, variant: PeakBadgeVariant.tertiary),
          ],
        ),
        const SizedBox(height: 10),
        Text(exercise.name, style: PeakType.headlineXl().copyWith(fontSize: 28, height: 1.05)),
        if (exercise.cue.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(exercise.cue, style: PeakType.bodyMd(color: PeakColors.mutedForeground)),
        ],
        const SizedBox(height: 16),
        PeakCard(
          title: 'Muscles',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (exercise.primaryMuscles.isNotEmpty) ...[
                Text('PRIMARY', style: PeakType.overline()),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final m in exercise.primaryMuscles) PeakBadge(label: m.label),
                  ],
                ),
              ],
              if (exercise.secondaryMuscles.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('SECONDARY', style: PeakType.overline()),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final m in exercise.secondaryMuscles)
                      PeakBadge(label: m.label, variant: PeakBadgeVariant.secondary),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        progressAsync.when(
          loading: () => const SizedBox(height: 80),
          error: (e, _) => const SizedBox.shrink(),
          data: (p) {
            if (p.pr == null && p.recent.isEmpty) {
              return PeakCard(
                title: 'Progress',
                child: Text(
                  'No sessions yet.',
                  style: PeakType.bodyMd(color: PeakColors.mutedForeground),
                ),
              );
            }
            return PeakCard(
              title: 'Progress',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.pr != null) ...[
                    Text('BEST EST. 1RM', style: PeakType.overline()),
                    const SizedBox(height: 2),
                    Text(
                      '${p.pr!.toStringAsFixed(1)} kg',
                      style: PeakType.numericDisplay(),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (p.recent.isNotEmpty) ...[
                    Text('RECENT', style: PeakType.overline()),
                    const SizedBox(height: 4),
                    for (final r in p.recent.take(8))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(child: Text(r.label, style: PeakType.bodyMd())),
                            Text(
                              '${epley1RM(r.weight, r.reps).toStringAsFixed(1)} 1RM',
                              style: PeakType.overline(),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ExerciseProgress {
  _ExerciseProgress({required this.pr, required this.recent});
  final double? pr;
  final List<_RecentSet> recent;
}

class _RecentSet {
  _RecentSet({required this.label, required this.weight, required this.reps});
  final String label;
  final double weight;
  final int reps;
}

final _progressProvider =
    FutureProvider.autoDispose.family<_ExerciseProgress, String>((ref, id) async {
  final prRepo = ref.watch(prRepositoryProvider);
  final sessRepo = ref.watch(sessionRepositoryProvider);
  final best = await prRepo.bestEstimated1RM(id);
  final lastSets = await sessRepo.lastWorkingSetsFor(id);
  return _ExerciseProgress(
    pr: best?.estimated1Rm,
    recent: lastSets
        .map((s) => _RecentSet(label: '${s.weight} kg × ${s.reps}', weight: s.weight, reps: s.reps))
        .toList(),
  );
});
