import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../analytics/volume.dart';
import '../../../core/constants.dart';
import '../../../core/utils.dart';
import '../../../providers/providers.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/muscle_grid.dart';

class MusclePickerPage extends ConsumerWidget {
  const MusclePickerPage({super.key, required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekData = ref.watch(_weekSetsByMuscleProvider);
    return Scaffold(
      backgroundColor: PeakColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Pick a muscle', style: PeakType.overline()),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          PeakSpacing.edge,
          8,
          PeakSpacing.edge,
          PeakSpacing.edge,
        ),
        children: [
          Text(
            "What's the next muscle?",
            style: PeakType.headlineXl().copyWith(fontSize: 30, height: 1.05),
          ),
          const SizedBox(height: 20),
          weekData.when(
            loading: () => const Center(child: CircularProgressIndicator(color: PeakColors.primary)),
            error: (e, _) => Text('$e', style: PeakType.bodyMd()),
            data: (sets) => MuscleGrid(
              setsByMuscleThisWeek: sets,
              onSelect: (m) => context.push(
                '/session/$sessionId/exercise?muscle=${Uri.encodeComponent(m.label)}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final _weekSetsByMuscleProvider = FutureProvider.autoDispose<Map<MuscleGroup, double>>((ref) async {
  final repo = ref.watch(sessionRepositoryProvider);
  final catalog = await ref.watch(exerciseCatalogProvider.future);
  final since = startOfWeek(DateTime.now());
  final sessions = await repo.sessionLikesSince(since);
  final weeks = rollupByWeek(sessions, catalog);
  if (weeks.isEmpty) return {};
  return weeks.last.setsByMuscle;
});
