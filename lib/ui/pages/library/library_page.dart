import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants.dart';
import '../../../providers/providers.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_card.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(exerciseCatalogProvider);
    return Scaffold(
      backgroundColor: PeakColors.background,
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: PeakColors.primary)),
        error: (e, _) => Center(child: Text('$e', style: PeakType.bodyMd())),
        data: (catalog) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              PeakSpacing.edge,
              PeakSpacing.edge,
              PeakSpacing.edge,
              PeakSpacing.edge + 80,
            ),
            children: [
              Text('LIBRARY', style: PeakType.overline()),
              const SizedBox(height: 4),
              Text('Exercises', style: PeakType.headlineXl().copyWith(fontSize: 30)),
              const SizedBox(height: 4),
              Text(
                '${catalog.all.length} exercises · evidence-ranked',
                style: PeakType.bodyMd(color: PeakColors.mutedForeground),
              ),
              const SizedBox(height: 18),
              for (final m in MuscleGroup.values) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    m.label,
                    style: PeakType.headlineLg().copyWith(fontSize: 22),
                  ),
                ),
                PeakCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final e in catalog.forMuscle(m)
                        ..sort((a, b) {
                          final r = b.evidenceRating.compareTo(a.evidenceRating);
                          if (r != 0) return r;
                          return a.name.compareTo(b.name);
                        }))
                        InkWell(
                          onTap: () => context.push('/library/${e.id}'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e.name, style: PeakType.bodyLg()),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${e.equipment.label} · ${e.movementPattern.label}',
                                        style: PeakType.overline(),
                                      ),
                                    ],
                                  ),
                                ),
                                PeakBadge(label: '★' * e.evidenceRating),
                              ],
                            ),
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
}
