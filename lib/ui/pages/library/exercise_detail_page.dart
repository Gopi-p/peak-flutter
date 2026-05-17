import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils.dart';
import '../../../data/exercise_catalog.dart';
import '../../../providers/providers.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_card.dart';

class ExerciseDetailPage extends ConsumerWidget {
  const ExerciseDetailPage({super.key, required this.exerciseId});
  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogAsync = ref.watch(exerciseCatalogProvider);
    return Scaffold(
      backgroundColor: PeakColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('Exercise guide', style: PeakType.overline()),
      ),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: PeakColors.primary)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(PeakSpacing.edge),
            child: Text(
              "Couldn't load the exercise library.",
              style: PeakType.bodyMd(color: PeakColors.mutedForeground),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (catalog) {
          final ex = catalog.byId(exerciseId);
          if (ex == null) {
            return Center(child: Text('Exercise not found.', style: PeakType.bodyMd()));
          }
          return _Detail(exercise: ex);
        },
      ),
    );
  }
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.exercise});
  final Exercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(_progressProvider(exercise.id));
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PeakSpacing.edge,
        8,
        PeakSpacing.edge,
        PeakSpacing.edge,
      ),
      children: [
        Text(
          exercise.name,
          style: PeakType.headlineXl().copyWith(fontSize: 28, height: 1.05),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PeakBadge(label: '★' * exercise.evidenceRating),
            PeakBadge(label: exercise.equipment.label, variant: PeakBadgeVariant.secondary),
            PeakBadge(label: exercise.movementPattern.label, variant: PeakBadgeVariant.secondary),
            PeakBadge(label: exercise.difficulty.label, variant: PeakBadgeVariant.tertiary),
          ],
        ),
        const SizedBox(height: 16),
        _VideoSlot(exercise: exercise),
        if (exercise.description.isNotEmpty) ...[
          const SizedBox(height: 16),
          PeakCard(
            title: 'What it does',
            child: Text(
              exercise.description,
              style: PeakType.bodyMd().copyWith(height: 1.5),
            ),
          ),
        ],
        const SizedBox(height: 12),
        PeakCard(
          title: 'Muscles trained',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (exercise.primaryMuscles.isNotEmpty) ...[
                Text('PRIMARY', style: PeakType.overline()),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final m in exercise.primaryMuscles) PeakBadge(label: m.label),
                  ],
                ),
              ],
              if (exercise.secondaryMuscles.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('SECONDARY', style: PeakType.overline()),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final m in exercise.secondaryMuscles)
                      PeakBadge(label: m.label, variant: PeakBadgeVariant.secondary),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (exercise.steps.isNotEmpty) ...[
          const SizedBox(height: 12),
          PeakCard(
            title: 'Step by step',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < exercise.steps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _NumberedStep(index: i + 1, text: exercise.steps[i]),
                  ),
              ],
            ),
          ),
        ],
        if (exercise.mindMuscleCue.isNotEmpty) ...[
          const SizedBox(height: 12),
          _MindMuscleCard(text: exercise.mindMuscleCue),
        ],
        if (exercise.commonMistakes.isNotEmpty) ...[
          const SizedBox(height: 12),
          PeakCard(
            title: 'Common mistakes',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final m in exercise.commonMistakes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _IconBullet(
                      icon: Icons.warning_amber_rounded,
                      iconColor: PeakColors.destructive,
                      text: m,
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (exercise.tips.isNotEmpty) ...[
          const SizedBox(height: 12),
          PeakCard(
            title: 'Tips',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final t in exercise.tips)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _IconBullet(
                      icon: Icons.lightbulb_outline_rounded,
                      iconColor: PeakColors.primary,
                      text: t,
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (exercise.cue.isNotEmpty) ...[
          const SizedBox(height: 12),
          PeakCard(
            title: 'Quick cue',
            child: Text(
              exercise.cue,
              style: PeakType.bodyMd(color: PeakColors.mutedForeground)
                  .copyWith(fontStyle: FontStyle.italic, height: 1.4),
            ),
          ),
        ],
        const SizedBox(height: 12),
        progressAsync.when(
          loading: () => const SizedBox(height: 80),
          error: (e, _) => const SizedBox.shrink(),
          data: (p) {
            if (p.pr == null && p.recent.isEmpty) {
              return PeakCard(
                title: 'Your progress',
                child: Text(
                  'No sessions with this exercise yet. Your first set will appear here.',
                  style: PeakType.bodyMd(color: PeakColors.mutedForeground),
                ),
              );
            }
            return PeakCard(
              title: 'Your progress',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.pr != null) ...[
                    Text('BEST EST. 1RM', style: PeakType.overline()),
                    const SizedBox(height: 2),
                    Text(
                      '${p.pr!.toStringAsFixed(1)} kg',
                      style: PeakType.numericDisplay(),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (p.recent.isNotEmpty) ...[
                    Text('RECENT', style: PeakType.overline()),
                    const SizedBox(height: 4),
                    for (final r in p.recent.take(8))
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(child: Text(r.label, style: PeakType.bodyMd())),
                            Text(
                              '${epley1RM(r.weight, r.reps).toStringAsFixed(1)} 1RM',
                              style: PeakType.overline(),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: PeakSpacing.edge),
      ],
    );
  }
}

/// 16:9 hero block at the top of the detail page. Uses the **short clip**
/// for an in-gym quick reference, with the long-form tutorial behind a
/// separate "Detailed explanation" button rendered just below.
///
/// Hero-source priority:
///   1. [Exercise.videoUrl] (short clip / Short) — primary in-gym reference.
///   2. [Exercise.animationAsset] (bundled GIF) — fallback when no short.
///   3. [Exercise.detailedVideoUrl] — last-resort hero if no short or GIF.
///   4. Neither — placeholder over a YouTube search URL.
class _VideoSlot extends StatelessWidget {
  const _VideoSlot({required this.exercise});
  final Exercise exercise;

  /// Picks the URL the hero (and its tap target) opens.
  String? get _heroUrl =>
      exercise.videoUrl ?? exercise.detailedVideoUrl;

  String? get _heroSource =>
      exercise.videoUrl != null ? exercise.videoSource : exercise.detailedVideoSource;

  bool get _heroIsShort => exercise.videoUrl != null;

  Future<void> _openHero(BuildContext context) async {
    HapticFeedback.selectionClick();
    final url = _heroUrl != null
        ? Uri.parse(_heroUrl!)
        : ExerciseVideo.searchUrl(exercise.name);
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open YouTube.")),
      );
    }
  }

  Future<void> _openDetailed(BuildContext context) async {
    final raw = exercise.detailedVideoUrl;
    if (raw == null) return;
    HapticFeedback.selectionClick();
    final ok = await launchUrl(Uri.parse(raw), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open YouTube.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final thumbnail = ExerciseVideo.thumbnailUrl(_heroUrl);
    final hasHero = _heroUrl != null;
    final hasAnimation = exercise.animationAsset != null;
    final hasDetailed = exercise.detailedVideoUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => _openHero(context),
          behavior: HitTestBehavior.opaque,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: PeakColors.surfaceContainerLow,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          PeakColors.surfaceContainer,
                          PeakColors.surfaceContainerLow,
                        ],
                      ),
                    ),
                  ),
                  if (thumbnail != null)
                    Image.network(
                      thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _Placeholder(
                        label: hasHero
                            ? 'Tap to watch on YouTube'
                            : 'Tap to search YouTube',
                      ),
                    )
                  else if (hasAnimation)
                    Image.asset(
                      exercise.animationAsset!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const _Placeholder(label: 'Animation missing'),
                    )
                  else
                    _Placeholder(
                      label: hasHero
                          ? 'Tap to watch on YouTube'
                          : 'Tap to search YouTube',
                    ),
                  // Dim + play badge overlay
                  if (thumbnail != null || hasAnimation)
                    Container(color: Colors.black.withValues(alpha: 0.18)),
                  // "SHORT" pill chip in the top-right when this is a short clip.
                  if (_heroIsShort)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: PeakColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'SHORT',
                          style: PeakType.overline(color: PeakColors.primaryForeground)
                              .copyWith(fontSize: 10, letterSpacing: 1.0),
                        ),
                      ),
                    ),
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.55),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.85),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                hasHero
                    ? (_heroSource != null
                        ? '${_heroIsShort ? "Short" : "YouTube"} · $_heroSource'
                        : 'YouTube tutorial')
                    : 'No curated video yet. Tap above to search YouTube.',
                style: PeakType.overline(),
              ),
            ),
            TextButton.icon(
              onPressed: () => _openHero(context),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(
                hasHero ? 'Watch' : 'Search',
                style: PeakType.labelMd(color: PeakColors.primary),
              ),
              style: TextButton.styleFrom(
                foregroundColor: PeakColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        // "Detailed explanation" button — only shown when the long-form
        // tutorial is *separate* from the hero. If the hero already is the
        // detailed video (no short available), don't show a redundant button.
        if (hasDetailed && _heroIsShort) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _openDetailed(context),
            icon: const Icon(Icons.menu_book_rounded, size: 18),
            label: Text(
              exercise.detailedVideoSource != null
                  ? 'Detailed explanation · ${exercise.detailedVideoSource}'
                  : 'Detailed explanation',
              style: PeakType.labelMd(),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: PeakColors.foreground,
              side: BorderSide(
                color: PeakColors.outlineVariant.withValues(alpha: 0.6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              minimumSize: const Size(0, 44),
            ),
          ),
        ],
      ],
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: PeakColors.surfaceContainerLow,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_circle_outline_rounded,
              size: 48,
              color: PeakColors.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 8),
            Text(label, style: PeakType.overline()),
          ],
        ),
      ),
    );
  }
}

class _NumberedStep extends StatelessWidget {
  const _NumberedStep({required this.index, required this.text});
  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: PeakColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: PeakColors.primary.withValues(alpha: 0.4)),
          ),
          child: Text(
            '$index',
            style: PeakType.tabular(PeakType.labelMd(color: PeakColors.primary)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: PeakType.bodyMd().copyWith(height: 1.45),
            ),
          ),
        ),
      ],
    );
  }
}

class _MindMuscleCard extends StatelessWidget {
  const _MindMuscleCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: PeakColors.primary.withValues(alpha: 0.08),
        border: Border.all(color: PeakColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_rounded, color: PeakColors.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                'MIND–MUSCLE CUE',
                style: PeakType.overline(color: PeakColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: PeakType.bodyMd().copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _IconBullet extends StatelessWidget {
  const _IconBullet({
    required this.icon,
    required this.iconColor,
    required this.text,
  });
  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: PeakType.bodyMd().copyWith(height: 1.45),
          ),
        ),
      ],
    );
  }
}

class _ExerciseProgress {
  _ExerciseProgress({required this.pr, required this.recent});
  final double? pr;
  final List<_RecentSet> recent;
}

class _RecentSet {
  _RecentSet({required this.label, required this.weight, required this.reps});
  final String label;
  final double weight;
  final int reps;
}

final _progressProvider =
    FutureProvider.autoDispose.family<_ExerciseProgress, String>((ref, id) async {
  final prRepo = ref.watch(prRepositoryProvider);
  final sessRepo = ref.watch(sessionRepositoryProvider);
  final best = await prRepo.bestEstimated1RM(id);
  final lastSets = await sessRepo.lastWorkingSetsFor(id);
  return _ExerciseProgress(
    pr: best?.estimated1Rm,
    recent: lastSets
        .map((s) => _RecentSet(label: '${s.weight} kg × ${s.reps}', weight: s.weight, reps: s.reps))
        .toList(),
  );
});
