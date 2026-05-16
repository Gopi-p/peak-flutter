import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../analytics/deload.dart';
import '../../../analytics/volume.dart';
import '../../../core/constants.dart';
import '../../../providers/providers.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_card.dart';

class InsightsPage extends ConsumerWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(_insightsProvider);
    return Scaffold(
      backgroundColor: PeakColors.background,
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: PeakColors.primary)),
        error: (e, _) => Center(child: Text('$e', style: PeakType.bodyMd())),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(_insightsProvider),
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
              Text('INSIGHTS', style: PeakType.overline()),
              const SizedBox(height: 4),
              Text('This week', style: PeakType.headlineXl().copyWith(fontSize: 32, height: 1.05)),
              if (data.deload.isDeload && data.deload.dropPct != null) ...[
                const SizedBox(height: 16),
                PeakCard(
                  child: Text(
                    'Volume dropped ${(data.deload.dropPct! * 100).round()}% week-over-week. Was this an intentional deload?',
                    style: PeakType.bodyMd(color: PeakColors.tertiary),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              PeakCard(
                title: 'Weekly sets per muscle',
                child: SizedBox(
                  height: 220,
                  child: _WeeklySetsChart(setsByMuscle: data.setsByMuscle),
                ),
              ),
              const SizedBox(height: 16),
              PeakCard(
                title: 'Volume trend (8 weeks)',
                child: SizedBox(
                  height: 200,
                  child: _VolumeTrendChart(points: data.volumeTrend),
                ),
              ),
              const SizedBox(height: 16),
              if (data.undertrained.isNotEmpty)
                PeakCard(
                  title: 'Undertrained',
                  child: Column(
                    children: [
                      for (final u in data.undertrained.take(6))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(child: Text(u.muscle.label, style: PeakType.bodyMd())),
                              PeakBadge(
                                label:
                                    '${(u.sets * 10).round() / 10} / ${u.mev} sets',
                                variant: PeakBadgeVariant.outline,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightsData {
  _InsightsData({
    required this.setsByMuscle,
    required this.volumeTrend,
    required this.deload,
    required this.undertrained,
  });
  final List<MapEntry<MuscleGroup, double>> setsByMuscle;
  final List<({DateTime weekStart, double volume})> volumeTrend;
  final DeloadResult deload;
  final List<UndertrainedMuscle> undertrained;
}

final _insightsProvider = FutureProvider.autoDispose<_InsightsData>((ref) async {
  final repo = ref.watch(sessionRepositoryProvider);
  final catalog = await ref.watch(exerciseCatalogProvider.future);
  final since = DateTime.now().subtract(const Duration(days: 8 * 7));
  final sessions = await repo.sessionLikesSince(since);
  final weeks = rollupByWeek(sessions, catalog);
  final thisWeek = weeks.isEmpty ? null : weeks.last;
  final setsByMuscle = MuscleGroup.values
      .map((m) => MapEntry(m, (thisWeek?.setsByMuscle[m] ?? 0).toDouble()))
      .toList();
  final volumeTrend = weeks
      .map((w) => (
            weekStart: w.weekStart,
            volume: w.volumeByMuscle.values.fold<double>(0, (a, b) => a + b),
          ))
      .toList();
  final deload = detectDeload(weeks);
  final undertrained = undertrainedMuscles(thisWeek, volumeGuidance);
  return _InsightsData(
    setsByMuscle: setsByMuscle,
    volumeTrend: volumeTrend,
    deload: deload,
    undertrained: undertrained,
  );
});

class _WeeklySetsChart extends StatelessWidget {
  const _WeeklySetsChart({required this.setsByMuscle});
  final List<MapEntry<MuscleGroup, double>> setsByMuscle;

  @override
  Widget build(BuildContext context) {
    if (setsByMuscle.every((e) => e.value == 0)) {
      return Center(
        child: Text(
          'Log a few sets to see the breakdown.',
          style: PeakType.bodyMd(color: PeakColors.mutedForeground),
        ),
      );
    }
    final maxY = setsByMuscle.map((e) => e.value).fold<double>(0, (a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (maxY < 6 ? 6 : maxY * 1.15),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= setsByMuscle.length) return const SizedBox.shrink();
                final m = setsByMuscle[i].key;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    m.label.substring(0, 3).toUpperCase(),
                    style: PeakType.overline().copyWith(fontSize: 9),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(enabled: false),
        barGroups: [
          for (var i = 0; i < setsByMuscle.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: setsByMuscle[i].value,
                  color: PeakColors.primary,
                  width: 12,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _VolumeTrendChart extends StatelessWidget {
  const _VolumeTrendChart({required this.points});
  final List<({DateTime weekStart, double volume})> points;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return Center(
        child: Text(
          'Need at least two weeks of data.',
          style: PeakType.bodyMd(color: PeakColors.mutedForeground),
        ),
      );
    }
    final spots = [
      for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].volume),
    ];
    final maxY = spots.map((s) => s.y).fold<double>(0, (a, b) => a > b ? a : b);
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        minY: 0,
        maxY: maxY < 1 ? 100 : maxY * 1.15,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: PeakColors.primary,
            barWidth: 2,
            isStrokeCapRound: true,
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
