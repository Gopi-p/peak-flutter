import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../analytics/volume.dart';
import '../../../core/constants.dart';
import '../../../core/utils.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../providers/providers.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsStreamProvider);
    final dataAsync = ref.watch(_todayDataProvider);
    final name = settingsAsync.maybeWhen(
      data: (s) => s.displayName,
      orElse: () => '',
    );

    return Scaffold(
      backgroundColor: PeakColors.background,
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: PeakColors.primary)),
        error: (e, _) => Center(child: Text('$e', style: PeakType.bodyMd())),
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(_todayDataProvider);
          },
          color: PeakColors.primary,
          backgroundColor: PeakColors.surfaceContainer,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              PeakSpacing.edge,
              PeakSpacing.edge,
              PeakSpacing.edge,
              PeakSpacing.edge + 80,
            ),
            children: [
              _Header(name: name, active: data.active != null),
              const SizedBox(height: 20),
              if (data.active != null)
                _ActiveSessionCard(active: data.active!)
              else
                _StartWorkoutCard(),
              const SizedBox(height: 16),
              _WeekCard(data: data),
              const SizedBox(height: 16),
              _RecentSessionsCard(sessions: data.recent),
              const SizedBox(height: 16),
              _QuickLinks(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayData {
  _TodayData({required this.active, required this.recent, required this.thisWeek});
  final ActiveSummary? active;
  final List<SessionSummary> recent;
  final WeekRollup? thisWeek;
}

class ActiveSummary {
  ActiveSummary({required this.id, required this.muscles, required this.entriesCount, required this.setsCount});
  final String id;
  final List<MuscleGroup> muscles;
  final int entriesCount;
  final int setsCount;
}

class SessionSummary {
  SessionSummary({
    required this.id,
    required this.startedAt,
    required this.muscles,
    required this.setsCount,
    required this.classification,
  });
  final String id;
  final DateTime startedAt;
  final List<MuscleGroup> muscles;
  final int setsCount;
  final String? classification;
}

final _todayDataProvider = FutureProvider.autoDispose<_TodayData>((ref) async {
  final repo = ref.watch(sessionRepositoryProvider);
  final since = startOfWeek(DateTime.now()).subtract(const Duration(days: 28));
  final sessions = await repo.recentSessions(limit: 60, since: since);
  final allSets = await repo.sessionLikesSince(since);
  final catalog = await ref.watch(exerciseCatalogProvider.future);
  final weeks = rollupByWeek(allSets, catalog);
  final thisWeek = weeks.isEmpty ? null : weeks.last;

  ActiveSummary? active;
  final activeMatches = sessions.where((s) => s.endedAt == null).toList();
  if (activeMatches.isNotEmpty) {
    final s = activeMatches.first;
    final setsCount = (await repo.setsForSession(s.id)).length;
    final entries = await repo.entriesFor(s.id);
    active = ActiveSummary(
      id: s.id,
      muscles: s.muscles,
      entriesCount: entries.length,
      setsCount: setsCount,
    );
  }

  final recentSummaries = <SessionSummary>[];
  for (final s in sessions.where((s) => s.endedAt != null).take(5)) {
    final setsCount = (await repo.setsForSession(s.id)).length;
    recentSummaries.add(SessionSummary(
      id: s.id,
      startedAt: s.startedAt,
      muscles: s.muscles,
      setsCount: setsCount,
      classification: s.classification,
    ));
  }

  return _TodayData(active: active, recent: recentSummaries, thisWeek: thisWeek);
});

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.active});
  final String name;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final greet = active ? 'Session in progress' : 'Ready when you are';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name.isEmpty ? 'Today' : 'Hi, $name'.toUpperCase(),
          style: PeakType.overline(),
        ),
        const SizedBox(height: 6),
        Text(greet, style: PeakType.headlineXl().copyWith(fontSize: 32, height: 1.05)),
      ],
    );
  }
}

class _StartWorkoutCard extends ConsumerWidget {
  Future<void> _start(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(sessionRepositoryProvider);
    final id = await repo.startSession();
    if (context.mounted) context.go('/session/$id');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PeakCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Press start when you reach the rack.', style: PeakType.bodyMd(color: PeakColors.mutedForeground)),
          const SizedBox(height: 16),
          PeakButton(
            label: 'Start workout',
            icon: Icons.play_arrow_rounded,
            size: PeakButtonSize.xl,
            onPressed: () => _start(context, ref),
          ),
        ],
      ),
    );
  }
}

class _ActiveSessionCard extends ConsumerWidget {
  const _ActiveSessionCard({required this.active});
  final ActiveSummary active;

  Future<void> _confirmDiscard(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: PeakColors.surfaceContainerHigh,
        title: Text('Discard this session?', style: PeakType.headlineLg()),
        content: Text(
          'Started but going nowhere? This will remove the session and any sets logged inside it. Cannot be undone.',
          style: PeakType.bodyMd(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: PeakColors.destructive),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(sessionRepositoryProvider).softDeleteSession(active.id);
    ref.invalidate(_todayDataProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PeakCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${active.entriesCount} ${active.entriesCount == 1 ? 'exercise' : 'exercises'} · ${active.setsCount} sets',
            style: PeakType.bodyMd(color: PeakColors.mutedForeground),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in active.muscles) PeakBadge(label: m.label),
            ],
          ),
          const SizedBox(height: 16),
          PeakButton(
            label: 'Resume session',
            icon: Icons.bolt_rounded,
            size: PeakButtonSize.xl,
            onPressed: () => context.go('/session/${active.id}'),
          ),
          const SizedBox(height: 8),
          PeakButton(
            label: 'Discard session',
            icon: Icons.delete_outline_rounded,
            variant: PeakButtonVariant.ghost,
            onPressed: () => _confirmDiscard(context, ref),
          ),
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.data});
  final _TodayData data;

  @override
  Widget build(BuildContext context) {
    final sessionsCount = data.thisWeek?.sessionsCount ?? 0;
    final undertrained = (data.thisWeek == null
        ? <MapEntry<MuscleGroup, num>>[]
        : volumeGuidance.entries
            .map((e) => MapEntry(e.key, (data.thisWeek!.setsByMuscle[e.key] ?? 0)))
            .where((e) => e.value < (volumeGuidance[e.key]!.mev))
            .toList())
      ..sort((a, b) => a.value.compareTo(b.value));

    return PeakCard(
      title: 'This week',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('$sessionsCount', style: PeakType.numericDisplay()),
              const SizedBox(width: 8),
              Text(
                sessionsCount == 1 ? 'session' : 'sessions',
                style: PeakType.bodyMd(color: PeakColors.mutedForeground),
              ),
            ],
          ),
          if (undertrained.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('UNDERTRAINED', style: PeakType.overline()),
            const SizedBox(height: 6),
            for (final u in undertrained.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: PeakColors.tertiary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${u.key.label}: ${(u.value * 10).round() / 10} of ${volumeGuidance[u.key]!.mev} sets',
                        style: PeakType.bodyMd(),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _RecentSessionsCard extends StatelessWidget {
  const _RecentSessionsCard({required this.sessions});
  final List<SessionSummary> sessions;

  @override
  Widget build(BuildContext context) {
    return PeakCard(
      title: 'Recent sessions',
      child: sessions.isEmpty
          ? Text(
              'Nothing here yet. Your first set is one tap away.',
              style: PeakType.bodyMd(color: PeakColors.mutedForeground),
            )
          : Column(
              children: [
                for (final s in sessions)
                  GestureDetector(
                    onTap: () => context.push('/history/${s.id}'),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('EEE, MMM d').format(s.startedAt),
                                  style: PeakType.bodyMd(),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  s.muscles.map((m) => m.label).join(' · ').isEmpty
                                      ? 'no muscles tagged'
                                      : s.muscles.map((m) => m.label).join(' · '),
                                  style: PeakType.overline(),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${s.setsCount} sets',
                            style: PeakType.tabular(PeakType.bodyMd(color: PeakColors.mutedForeground)),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _QuickLinks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LinkTile(
            label: 'Plate calc',
            icon: Icons.calculate_rounded,
            onTap: () => context.push('/plate-calc'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _LinkTile(
            label: 'Goals',
            icon: Icons.flag_rounded,
            onTap: () => context.push('/goals'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _LinkTile(
            label: 'Weight',
            icon: Icons.monitor_weight_rounded,
            onTap: () => context.push('/bodyweight'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _LinkTile(
            label: 'Settings',
            icon: Icons.settings_rounded,
            onTap: () => context.push('/settings'),
          ),
        ),
      ],
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: PeakColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: PeakColors.outlineVariant.withValues(alpha: 0.35), width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: PeakColors.primary),
            const SizedBox(height: 4),
            Text(label, style: PeakType.overline().copyWith(letterSpacing: 0.8)),
          ],
        ),
      ),
    );
  }
}
