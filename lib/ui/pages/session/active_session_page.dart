import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/db/database.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../providers/providers.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

class ActiveSessionPage extends ConsumerWidget {
  const ActiveSessionPage({super.key, required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionStream = ref.watch(_sessionStreamProvider(sessionId));
    final entriesStream = ref.watch(_entriesStreamProvider(sessionId));

    return Scaffold(
      backgroundColor: PeakColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/today'),
        ),
        title: Text('Active session', style: PeakType.overline()),
        elevation: 0,
      ),
      body: sessionStream.when(
        loading: () => const Center(child: CircularProgressIndicator(color: PeakColors.primary)),
        error: (e, _) => Center(child: Text('$e', style: PeakType.bodyMd())),
        data: (session) {
          if (session == null) {
            return Center(child: Text('Session not found', style: PeakType.bodyMd()));
          }
          return entriesStream.when(
            loading: () => const Center(child: CircularProgressIndicator(color: PeakColors.primary)),
            error: (e, _) => Center(child: Text('$e', style: PeakType.bodyMd())),
            data: (entries) => _Content(session: session, entries: entries),
          );
        },
      ),
    );
  }
}

final _sessionStreamProvider =
    StreamProvider.autoDispose.family<Session?, String>((ref, id) {
  return ref.watch(sessionRepositoryProvider).watchSession(id);
});

final _entriesStreamProvider =
    StreamProvider.autoDispose.family<List<ExerciseEntry>, String>((ref, id) {
  return ref.watch(sessionRepositoryProvider).watchEntriesFor(id);
});

class _Content extends ConsumerWidget {
  const _Content({required this.session, required this.entries});
  final Session session;
  final List<ExerciseEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muscles = session.muscles;
    final elapsedMin = session.elapsedMinutes();

    return FutureBuilder<_VolStats>(
      future: _loadStats(ref),
      builder: (context, snap) {
        final stats = snap.data;
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            PeakSpacing.edge,
            8,
            PeakSpacing.edge,
            120,
          ),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ELAPSED', style: PeakType.overline()),
                      const SizedBox(height: 4),
                      Text('$elapsedMin min', style: PeakType.headlineXl().copyWith(fontSize: 36)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${(stats?.volume ?? 0).round()} kg·reps',
                      style: PeakType.tabular(PeakType.bodyLg()),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${stats?.totalSets ?? 0} sets total',
                      style: PeakType.overline(),
                    ),
                  ],
                ),
              ],
            ),
            if (muscles.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final m in muscles) PeakBadge(label: m.label)],
              ),
            ],
            const SizedBox(height: 18),
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _EntryCard(sessionId: session.id, entry: entry),
              ),
            if (entries.isEmpty)
              PeakCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No exercises yet.', style: PeakType.bodyMd()),
                    const SizedBox(height: 4),
                    Text(
                      'Tap "Add exercise" to start logging.',
                      style: PeakType.bodyMd(color: PeakColors.mutedForeground),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            PeakButton(
              label: 'Add exercise',
              icon: Icons.add_rounded,
              size: PeakButtonSize.xl,
              onPressed: () => context.push('/session/${session.id}/muscle'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: PeakButton(
                    label: "What's next?",
                    variant: PeakButtonVariant.outline,
                    onPressed: () => context.push('/session/${session.id}/whats-next'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PeakButton(
                    label: 'Finish',
                    variant: PeakButtonVariant.secondary,
                    onPressed: () async {
                      await ref.read(sessionRepositoryProvider).finishSession(session.id);
                      if (context.mounted) context.go('/session/${session.id}/summary');
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<_VolStats> _loadStats(WidgetRef ref) async {
    final repo = ref.read(sessionRepositoryProvider);
    final sets = await repo.setsForSession(session.id);
    double vol = 0;
    for (final s in sets) {
      if (s.isWarmup) continue;
      vol += s.weight * s.reps;
    }
    return _VolStats(totalSets: sets.length, volume: vol);
  }
}

class _VolStats {
  const _VolStats({required this.totalSets, required this.volume});
  final int totalSets;
  final double volume;
}

class _EntryCard extends ConsumerWidget {
  const _EntryCard({required this.sessionId, required this.entry});
  final String sessionId;
  final ExerciseEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(exerciseCatalogProvider);
    final setsStream = ref.watch(_setsForEntryProvider(entry.id));
    final ex = catalogAsync.maybeWhen(
      data: (c) => c.byId(entry.exerciseId),
      orElse: () => null,
    );
    return PeakCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ex?.name ?? entry.exerciseId,
                  style: PeakType.headlineLg().copyWith(fontSize: 20),
                ),
              ),
              if (ex != null)
                Text(ex.equipment.label, style: PeakType.overline()),
            ],
          ),
          const SizedBox(height: 8),
          setsStream.when(
            loading: () => const SizedBox(height: 16),
            error: (e, _) => Text('$e', style: PeakType.bodyMd()),
            data: (sets) {
              if (sets.isEmpty) {
                return Text(
                  'No sets yet.',
                  style: PeakType.bodyMd(color: PeakColors.mutedForeground),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < sets.length; i++)
                    _SetRow(set: sets[i], index: i + 1, sessionId: sessionId),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          PeakButton(
            label: 'Add set',
            icon: Icons.add_rounded,
            variant: PeakButtonVariant.secondary,
            onPressed: () => context.push('/session/$sessionId/log?entryId=${entry.id}'),
          ),
        ],
      ),
    );
  }
}

final _setsForEntryProvider =
    StreamProvider.autoDispose.family<List<WorkoutSet>, String>((ref, id) {
  return ref.watch(sessionRepositoryProvider).watchSetsForEntry(id);
});

class _SetRow extends ConsumerWidget {
  const _SetRow({required this.set, required this.index, required this.sessionId});
  final WorkoutSet set;
  final int index;
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(set.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: PeakColors.destructive.withValues(alpha: 0.18),
        child: const Icon(Icons.delete_outline_rounded, color: PeakColors.destructive),
      ),
      onDismissed: (_) async {
        await ref.read(sessionRepositoryProvider).deleteSet(set.id);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text(
                '$index',
                style: PeakType.tabular(PeakType.bodyMd(color: PeakColors.mutedForeground)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${_fmt(set.weight)} kg × ${set.reps}'
                '${set.rpe != null ? '  @${_fmt(set.rpe!)}' : ''}',
                style: PeakType.tabular(PeakType.bodyLg()),
              ),
            ),
            if (set.isWarmup) const PeakBadge(label: 'warmup', variant: PeakBadgeVariant.outline),
          ],
        ),
      ),
    );
  }

  String _fmt(num n) => n == n.toInt() ? '${n.toInt()}' : n.toStringAsFixed(1);
}
