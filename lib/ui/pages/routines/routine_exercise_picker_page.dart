import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../data/exercise_catalog.dart';
import '../../../providers/providers.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/muscle_grid.dart';

/// Self-contained picker: tap a muscle, then an exercise. Pops with the chosen
/// exercise id (a `String`), or null if dismissed. Reused for adding routine
/// slots and for choosing alternatives.
class RoutineExercisePickerPage extends ConsumerStatefulWidget {
  const RoutineExercisePickerPage({super.key, this.title = 'Pick an exercise', this.excludeIds = const {}});

  final String title;

  /// Exercise ids to hide from the list (e.g. already-picked alternatives).
  final Set<String> excludeIds;

  @override
  ConsumerState<RoutineExercisePickerPage> createState() => _RoutineExercisePickerPageState();
}

class _RoutineExercisePickerPageState extends ConsumerState<RoutineExercisePickerPage> {
  MuscleGroup? _muscle;

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(exerciseCatalogProvider);
    return Scaffold(
      backgroundColor: PeakColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_muscle != null) {
              setState(() => _muscle = null);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          (_muscle?.label ?? widget.title).toUpperCase(),
          style: PeakType.overline(),
        ),
      ),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: PeakColors.primary)),
        error: (e, _) => Center(child: Text('$e', style: PeakType.bodyMd())),
        data: (catalog) => _muscle == null ? _muscleStep() : _exerciseStep(catalog, _muscle!),
      ),
    );
  }

  Widget _muscleStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(PeakSpacing.edge, 8, PeakSpacing.edge, PeakSpacing.edge),
      children: [
        Text(
          'Which muscle?',
          style: PeakType.headlineXl().copyWith(fontSize: 30, height: 1.05),
        ),
        const SizedBox(height: 20),
        MuscleGrid(onSelect: (m) => setState(() => _muscle = m)),
      ],
    );
  }

  Widget _exerciseStep(ExerciseCatalog catalog, MuscleGroup muscle) {
    final exercises = catalog.forMuscle(muscle, includeSecondary: true)
        .where((e) => !widget.excludeIds.contains(e.id))
        .toList()
      ..sort((a, b) => b.evidenceRating != a.evidenceRating
          ? b.evidenceRating.compareTo(a.evidenceRating)
          : a.name.compareTo(b.name));

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(PeakSpacing.edge, 8, PeakSpacing.edge, PeakSpacing.edge),
      itemCount: exercises.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: PeakColors.outlineVariant),
      itemBuilder: (context, i) {
        final ex = exercises[i];
        return InkWell(
          onTap: () => Navigator.pop(context, ex.id),
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
                    ],
                  ),
                ),
                PeakBadge(label: '★' * ex.evidenceRating),
              ],
            ),
          ),
        );
      },
    );
  }
}
