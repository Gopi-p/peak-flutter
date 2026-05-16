import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../analytics/combo.dart';
import '../../../analytics/volume.dart';
import '../../../data/db/database.dart';
import '../../../data/exercise_catalog.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../providers/providers.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

class SummaryPage extends ConsumerWidget {
  const SummaryPage({super.key, required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(_summaryDataProvider(sessionId));
    return Scaffold(
      backgroundColor: PeakColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/today'),
        ),
        title: Text('Summary', style: PeakType.overline()),
      ),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: PeakColors.primary)),
        error: (e, _) => Center(child: Text('$e', style: PeakType.bodyMd())),
        data: (data) {
          if (data == null) {
            return Center(child: Text('Session not found', style: PeakType.bodyMd()));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              PeakSpacing.edge,
              8,
              PeakSpacing.edge,
              PeakSpacing.edge,
            ),
            children: [
              Text('Done.', style: PeakType.headlineXl().copyWith(fontSize: 38, height: 1)),
              const SizedBox(height: 18),
              PeakCard(
                child: Row(
                  children: [
                    Expanded(child: _Stat(label: 'Minutes', value: '${data.minutes}')),
                    Expanded(child: _Stat(label: 'Sets', value: '${data.totalSets}')),
                    Expanded(child: _Stat(label: 'Volume', value: '${data.volume.round()}', unit: 'kg·reps')),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PeakCard(
                title: '${data.combo.label.label} day',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.combo.note, style: PeakType.bodyMd(color: PeakColors.mutedForeground)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final m in data.session.muscles)
                          PeakBadge(
                            label:
                                '${m.label} · ${((data.setsByMuscle[m] ?? 0) * 10).round() / 10}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PeakCard(
                title: 'Exercises',
                child: Column(
                  children: [
                    for (final entry in data.entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                data.catalog.byId(entry.exerciseId)?.name ?? entry.exerciseId,
                                style: PeakType.bodyMd(),
                              ),
                            ),
                            Text(
                              '${data.setsByEntry[entry.id] ?? 0} sets · ${data.volumeByEntry[entry.id]?.round() ?? 0} kg·reps',
                              style: PeakType.tabular(PeakType.bodyMd(color: PeakColors.mutedForeground)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              PeakButton(
                label: 'Back to Today',
                size: PeakButtonSize.xl,
                onPressed: () => context.go('/today'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.unit});
  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: PeakType.numericDisplay()),
        const SizedBox(height: 2),
        Text(
          unit == null ? label : '$label ($unit)',
          style: PeakType.overline(),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SummaryData {
  _SummaryData({
    required this.session,
    required this.entries,
    required this.minutes,
    required this.totalSets,
    required this.volume,
    required this.combo,
    required this.setsByMuscle,
    required this.setsByEntry,
    required this.volumeByEntry,
    required this.catalog,
  });
  final Session session;
  final List<ExerciseEntry> entries;
  final int minutes;
  final int totalSets;
  final double volume;
  final ComboResult combo;
  final Map setsByMuscle;
  final Map<String, int> setsByEntry;
  final Map<String, double> volumeByEntry;
  final ExerciseCatalog catalog;
}

final _summaryDataProvider =
    FutureProvider.autoDispose.family<_SummaryData?, String>((ref, id) async {
  final repo = ref.watch(sessionRepositoryProvider);
  final catalog = await ref.watch(exerciseCatalogProvider.future);
  final session = await repo.sessionById(id);
  if (session == null) return null;
  final entries = await repo.entriesFor(id);
  final allSets = await repo.setsForSession(id);
  final setsByEntry = <String, int>{};
  final volumeByEntry = <String, double>{};
  double volume = 0;
  for (final s in allSets) {
    setsByEntry[s.entryId] = (setsByEntry[s.entryId] ?? 0) + 1;
    if (!s.isWarmup) {
      volume += s.weight * s.reps;
      volumeByEntry[s.entryId] = (volumeByEntry[s.entryId] ?? 0) + s.weight * s.reps;
    }
  }
  final sessLike = (await repo.sessionLike(id))!;
  final setsByMuscle = setsByMuscleForSession(sessLike, catalog);
  final combo = classifyCombination(session.muscles);
  final ended = session.endedAt ?? DateTime.now();
  final minutes = ((ended.difference(session.startedAt)).inSeconds / 60).round().clamp(1, 999);

  return _SummaryData(
    session: session,
    entries: entries,
    minutes: minutes,
    totalSets: allSets.length,
    volume: volume,
    combo: combo,
    setsByMuscle: setsByMuscle,
    setsByEntry: setsByEntry,
    volumeByEntry: volumeByEntry,
    catalog: catalog,
  );
});
