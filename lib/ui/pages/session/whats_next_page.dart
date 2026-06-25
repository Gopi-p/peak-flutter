import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../providers/providers.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

class WhatsNextPage extends ConsumerWidget {
  const WhatsNextPage({super.key, required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(_whatsNextProvider(sessionId));
    return Scaffold(
      backgroundColor: PeakColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text("What's next?", style: PeakType.overline()),
      ),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: PeakColors.primary)),
        error: (e, _) => Center(child: Text('$e', style: PeakType.bodyMd())),
        data: (data) {
          final lastMuscle = data.lastMuscle;
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              PeakSpacing.edge,
              8,
              PeakSpacing.edge,
              PeakSpacing.edge,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Where do we go from here?',
                  style: PeakType.headlineXl().copyWith(fontSize: 28, height: 1.05),
                ),
                const SizedBox(height: 16),
                if (data.nextEntryId != null)
                  PeakCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('NEXT IN YOUR ROUTINE', style: PeakType.overline()),
                        const SizedBox(height: 6),
                        Text(
                          data.nextExerciseName ?? '',
                          style: PeakType.headlineLg().copyWith(fontSize: 22),
                        ),
                        const SizedBox(height: 12),
                        PeakButton(
                          label: 'Log this exercise',
                          icon: Icons.arrow_forward_rounded,
                          size: PeakButtonSize.xl,
                          onPressed: () => context.push(
                            '/session/$sessionId/log?entryId=${data.nextEntryId}',
                          ),
                        ),
                      ],
                    ),
                  ),
                if (data.nextEntryId != null) const SizedBox(height: 12),
                PeakCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (lastMuscle != null)
                        PeakButton(
                          label: 'Same muscle (${lastMuscle.label})',
                          icon: Icons.refresh_rounded,
                          size: PeakButtonSize.xl,
                          variant: PeakButtonVariant.secondary,
                          onPressed: () => context.push(
                            '/session/$sessionId/exercise?muscle=${Uri.encodeComponent(lastMuscle.label)}',
                          ),
                        ),
                      const SizedBox(height: 10),
                      PeakButton(
                        label: 'Different muscle',
                        icon: Icons.shuffle_rounded,
                        size: PeakButtonSize.xl,
                        variant: PeakButtonVariant.secondary,
                        onPressed: () => context.push('/session/$sessionId/muscle'),
                      ),
                      const SizedBox(height: 10),
                      PeakButton(
                        label: 'Finish session',
                        icon: Icons.flag_rounded,
                        size: PeakButtonSize.xl,
                        variant: PeakButtonVariant.outline,
                        onPressed: () async {
                          await ref.read(sessionRepositoryProvider).finishSession(sessionId);
                          if (context.mounted) context.go('/session/$sessionId/summary');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WhatsNextData {
  const _WhatsNextData({this.lastMuscle, this.nextEntryId, this.nextExerciseName});
  final MuscleGroup? lastMuscle;
  final String? nextEntryId;
  final String? nextExerciseName;
}

final _whatsNextProvider =
    FutureProvider.autoDispose.family<_WhatsNextData, String>((ref, id) async {
  final repo = ref.watch(sessionRepositoryProvider);
  final session = await repo.sessionById(id);
  if (session == null) return const _WhatsNextData();

  String? nextEntryId;
  String? nextName;
  if (session.routineId != null) {
    final entries = await repo.entriesFor(id);
    final catalog = await ref.watch(exerciseCatalogProvider.future);
    for (final e in entries) {
      final sets = await repo.setsForEntry(e.id);
      if (sets.isEmpty) {
        nextEntryId = e.id;
        nextName = catalog.byId(e.exerciseId)?.name ?? e.exerciseId;
        break;
      }
    }
  }
  return _WhatsNextData(
    lastMuscle: session.muscles.lastOrNull,
    nextEntryId: nextEntryId,
    nextExerciseName: nextName,
  );
});
