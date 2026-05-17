import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/db/database.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../providers/providers.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(_historyProvider);
    return Scaffold(
      backgroundColor: PeakColors.background,
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: PeakColors.primary)),
        error: (e, _) => Center(child: Text('$e', style: PeakType.bodyMd())),
        data: (data) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              PeakSpacing.edge,
              PeakSpacing.edge,
              PeakSpacing.edge,
              PeakSpacing.edge + 80,
            ),
            children: [
              Text('HISTORY', style: PeakType.overline()),
              const SizedBox(height: 4),
              Text('Past sessions', style: PeakType.headlineXl().copyWith(fontSize: 30)),
              const SizedBox(height: 18),
              if (data.isEmpty)
                PeakCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'No sessions yet. Your history fills up one workout at a time.',
                        textAlign: TextAlign.center,
                        style: PeakType.bodyMd(color: PeakColors.mutedForeground),
                      ),
                      const SizedBox(height: 14),
                      PeakButton(
                        label: 'Start a workout',
                        size: PeakButtonSize.xl,
                        onPressed: () => context.go('/today'),
                      ),
                    ],
                  ),
                )
              else
                PeakCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < data.length; i++) ...[
                        _HistoryRow(item: data[i]),
                        if (i != data.length - 1)
                          const Divider(height: 1, color: PeakColors.outlineVariant),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _HistoryItem {
  _HistoryItem({required this.session, required this.setsCount});
  final Session session;
  final int setsCount;
}

final _historyProvider = FutureProvider.autoDispose<List<_HistoryItem>>((ref) async {
  final repo = ref.watch(sessionRepositoryProvider);
  final sessions = await repo.recentSessions(limit: 60);
  final out = <_HistoryItem>[];
  for (final s in sessions) {
    final setsCount = (await repo.setsForSession(s.id)).length;
    out.add(_HistoryItem(session: s, setsCount: setsCount));
  }
  return out;
});

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item});
  final _HistoryItem item;
  @override
  Widget build(BuildContext context) {
    final muscles = item.session.muscles.map((m) => m.label).join(' · ');
    return InkWell(
      onTap: () => context.push('/history/${item.session.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEE, MMM d').format(item.session.startedAt),
                    style: PeakType.bodyMd(),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    muscles.isEmpty ? 'no muscles tagged' : muscles,
                    style: PeakType.overline(),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.setsCount} sets',
                  style: PeakType.tabular(PeakType.bodyMd()),
                ),
                if (item.session.classification != null)
                  Text(
                    item.session.classification!.toUpperCase(),
                    style: PeakType.overline(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
