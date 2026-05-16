import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/db/database.dart';
import '../../../providers/providers.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/stepper_pad.dart';

class BodyWeightPage extends ConsumerStatefulWidget {
  const BodyWeightPage({super.key});
  @override
  ConsumerState<BodyWeightPage> createState() => _BodyWeightPageState();
}

class _BodyWeightPageState extends ConsumerState<BodyWeightPage> {
  double _kg = 72;
  bool _busy = false;

  Future<void> _add() async {
    setState(() => _busy = true);
    try {
      await ref.read(bodyWeightRepositoryProvider).add(kg: _kg);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(_entriesProvider);
    return Scaffold(
      backgroundColor: PeakColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Body weight', style: PeakType.overline()),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: PeakColors.primary)),
        error: (e, _) => Center(child: Text('$e', style: PeakType.bodyMd())),
        data: (entries) => ListView(
          padding: const EdgeInsets.fromLTRB(
            PeakSpacing.edge,
            8,
            PeakSpacing.edge,
            PeakSpacing.edge,
          ),
          children: [
            PeakCard(
              title: 'Today',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StepperPad(
                    value: _kg,
                    step: 0.1,
                    min: 20,
                    max: 300,
                    label: 'kg',
                    format: (v) => v.toStringAsFixed(1),
                    onChanged: (v) => setState(() => _kg = v),
                  ),
                  const SizedBox(height: 12),
                  PeakButton(
                    label: 'Log weight',
                    icon: Icons.add_rounded,
                    size: PeakButtonSize.xl,
                    busy: _busy,
                    onPressed: _busy ? null : _add,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PeakCard(
              title: 'Trend',
              child: SizedBox(
                height: 200,
                child: _BwTrend(entries: entries),
              ),
            ),
            const SizedBox(height: 16),
            PeakCard(
              title: 'Recent',
              padding: EdgeInsets.zero,
              child: entries.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        'Nothing logged yet.',
                        style: PeakType.bodyMd(color: PeakColors.mutedForeground),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < entries.length && i < 10; i++) ...[
                          ListTile(
                            title: Text(
                              '${entries[i].kg.toStringAsFixed(1)} kg',
                              style: PeakType.tabular(PeakType.bodyLg()),
                            ),
                            subtitle: Text(
                              DateFormat('EEE, MMM d').format(entries[i].measuredAt),
                              style: PeakType.overline(),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: PeakColors.destructive,
                              ),
                              onPressed: () async {
                                await ref.read(bodyWeightRepositoryProvider).softDelete(entries[i].id);
                              },
                            ),
                          ),
                          if (i != (entries.length < 10 ? entries.length - 1 : 9))
                            const Divider(height: 1, color: PeakColors.outlineVariant),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

final _entriesProvider = StreamProvider<List<BodyWeight>>((ref) {
  return ref.watch(bodyWeightRepositoryProvider).watch();
});

class _BwTrend extends StatelessWidget {
  const _BwTrend({required this.entries});
  final List<BodyWeight> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.length < 2) {
      return Center(
        child: Text(
          'Need at least two entries to plot a trend.',
          style: PeakType.bodyMd(color: PeakColors.mutedForeground),
        ),
      );
    }
    final sorted = [...entries]..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
    final spots = [
      for (var i = 0; i < sorted.length; i++) FlSpot(i.toDouble(), sorted[i].kg),
    ];
    final maxY = spots.map((s) => s.y).fold<double>(0, (a, b) => a > b ? a : b);
    final minY = spots.map((s) => s.y).fold<double>(maxY, (a, b) => a < b ? a : b);
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        minY: minY - 2,
        maxY: maxY + 2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: PeakColors.primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: PeakColors.primary.withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }
}
