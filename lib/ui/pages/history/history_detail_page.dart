import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/db/database.dart';
import '../../../data/exercise_catalog.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../providers/providers.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_card.dart';

class HistoryDetailPage extends ConsumerWidget {
  const HistoryDetailPage({super.key, required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(_detailProvider(sessionId));
    return Scaffold(
      backgroundColor: PeakColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('History', style: PeakType.overline()),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: PeakColors.destructive),
            tooltip: 'Delete session',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
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
              Text(
                DateFormat('EEEE, MMM d').format(data.session.startedAt).toUpperCase(),
                style: PeakType.overline(),
              ),
              const SizedBox(height: 4),
              Text(
                data.session.classification ?? 'Session',
                style: PeakType.headlineXl().copyWith(fontSize: 30, height: 1.05),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final m in data.session.muscles) PeakBadge(label: m.label)],
              ),
              const SizedBox(height: 16),
              PeakCard(
                child: Row(
                  children: [
                    Expanded(child: _Stat(label: 'Minutes', value: '${data.minutes}')),
                    Expanded(child: _Stat(label: 'Sets', value: '${data.totalSets}')),
                    Expanded(child: _Stat(label: 'Volume', value: '${data.volume.round()}')),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              for (final entry in data.entries) ...[
                PeakCard(
                  title: data.catalog.byId(entry.exerciseId)?.name ?? entry.exerciseId,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      for (final set in (data.setsByEntry[entry.id] ?? const <WorkoutSet>[]))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${_fmt(set.weight)} kg × ${set.reps}'
                                  '${set.rpe != null ? '  @${set.rpe!.toInt()}' : ''}',
                                  style: PeakType.tabular(PeakType.bodyMd()),
                                ),
                              ),
                              if (set.isWarmup)
                                const PeakBadge(label: 'warmup', variant: PeakBadgeVariant.outline),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PeakColors.surfaceContainerHigh,
        title: Text('Delete this session?', style: PeakType.headlineLg()),
        content: Text(
          'It will disappear from history and any PRs from it will be removed.',
          style: PeakType.bodyMd(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: PeakColors.destructive),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(sessionRepositoryProvider).softDeleteSession(sessionId);
      if (context.mounted) context.go('/history');
    }
  }

  String _fmt(num n) => n == n.toInt() ? '${n.toInt()}' : n.toStringAsFixed(1);
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: PeakType.numericDisplay()),
        const SizedBox(height: 2),
        Text(label.toUpperCase(), style: PeakType.overline()),
      ],
    );
  }
}

class _DetailData {
  _DetailData({
    required this.session,
    required this.entries,
    required this.setsByEntry,
    required this.totalSets,
    required this.volume,
    required this.minutes,
    required this.catalog,
  });
  final Session session;
  final List<ExerciseEntry> entries;
  final Map<String, List<WorkoutSet>> setsByEntry;
  final int totalSets;
  final double volume;
  final int minutes;
  final ExerciseCatalog catalog;
}

final _detailProvider =
    FutureProvider.autoDispose.family<_DetailData?, String>((ref, id) async {
  final repo = ref.watch(sessionRepositoryProvider);
  final catalog = await ref.watch(exerciseCatalogProvider.future);
  final session = await repo.sessionById(id);
  if (session == null) return null;
  final entries = await repo.entriesFor(id);
  final allSets = await repo.setsForSession(id);
  final setsByEntry = <String, List<WorkoutSet>>{};
  double volume = 0;
  for (final s in allSets) {
    setsByEntry.putIfAbsent(s.entryId, () => []).add(s);
    if (!s.isWarmup) volume += s.weight * s.reps;
  }
  final ended = session.endedAt ?? DateTime.now();
  final minutes = ((ended.difference(session.startedAt)).inSeconds / 60).round().clamp(1, 999);
  return _DetailData(
    session: session,
    entries: entries,
    setsByEntry: setsByEntry,
    totalSets: allSets.length,
    volume: volume,
    minutes: minutes,
    catalog: catalog,
  );
});
