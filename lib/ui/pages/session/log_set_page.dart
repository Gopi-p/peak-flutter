import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../analytics/overload.dart';
import '../../../analytics/pr.dart';
import '../../../analytics/volume.dart';
import '../../../core/utils.dart';
import '../../../data/exercise_catalog.dart';
import '../../../providers/providers.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/pr_flash.dart';
import '../../widgets/rest_timer.dart';
import '../../widgets/stepper_pad.dart';

class LogSetPage extends ConsumerStatefulWidget {
  const LogSetPage({super.key, required this.sessionId, required this.entryId});
  final String sessionId;
  final String entryId;

  @override
  ConsumerState<LogSetPage> createState() => _LogSetPageState();
}

class _LogSetPageState extends ConsumerState<LogSetPage> {
  late Future<_LogContext> _loadCtx;

  double _weight = 60;
  int _reps = 10;
  double? _rpe;
  bool _isWarmup = false;
  bool _pending = false;
  bool _resting = false;
  String? _prLabel;
  bool _showPr = false;

  @override
  void initState() {
    super.initState();
    _loadCtx = _load();
  }

  Future<_LogContext> _load() async {
    final repo = ref.read(sessionRepositoryProvider);
    final catalog = await ref.read(exerciseCatalogProvider.future);
    final settings = await ref.read(settingsRepositoryProvider).read();
    final entries = await repo.entriesFor(widget.sessionId);
    final entry = entries.firstWhere(
      (e) => e.id == widget.entryId,
      orElse: () => throw StateError('Entry not found'),
    );
    final ex = catalog.byId(entry.exerciseId);
    final priorWorking = await repo.lastWorkingSetsFor(
      entry.exerciseId,
      excludeSessionId: widget.sessionId,
    );
    final currentSets = await repo.setsForEntry(entry.id);
    final lastSets = priorWorking
        .map((s) => SetSnapshot(weight: s.weight, reps: s.reps, rpe: s.rpe))
        .toList();
    final suggestion = suggestNext(lastSets);

    final currentWorking = currentSets.where((s) => !s.isWarmup).toList();
    final justLogged = currentWorking.isNotEmpty ? currentWorking.last : null;

    setState(() {
      _weight = justLogged?.weight ?? suggestion?.weight ?? priorWorking.firstOrNull?.weight ?? 60;
      _reps = justLogged?.reps ?? suggestion?.reps ?? priorWorking.firstOrNull?.reps ?? 10;
    });

    return _LogContext(
      exercise: ex,
      exerciseId: entry.exerciseId,
      lastSets: priorWorking,
      suggestion: suggestion,
      restDefault: settings.defaultRestSeconds,
      rpeEnabled: settings.rpeEnabled,
    );
  }

  Future<void> _logSet(_LogContext ctx) async {
    if (_reps < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reps must be at least 1.')),
      );
      return;
    }
    setState(() => _pending = true);
    try {
      final repo = ref.read(sessionRepositoryProvider);
      final result = await repo.logSet(
        sessionId: widget.sessionId,
        entryId: widget.entryId,
        exerciseId: ctx.exerciseId,
        weight: _weight,
        reps: _reps,
        rpe: _rpe,
        isWarmup: _isWarmup,
      );
      HapticFeedback.mediumImpact();
      if (result.pr.isPr) {
        setState(() {
          _prLabel = result.pr.kind == PrKind.weightForReps ? 'Rep PR' : 'Estimated 1RM PR';
          _showPr = true;
        });
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted) setState(() => _showPr = false);
        });
      }
      if (!_isWarmup) {
        setState(() => _resting = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't log set: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }

  void _sameAsLast(_LogContext ctx) {
    final last = ctx.lastSets.firstOrNull;
    if (last == null) return;
    setState(() {
      _weight = last.weight;
      _reps = last.reps;
      if (last.rpe != null) _rpe = last.rpe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_LogContext>(
      future: _loadCtx,
      builder: (context, snap) {
        final ctx = snap.data;
        return Scaffold(
          backgroundColor: PeakColors.background,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.go('/session/${widget.sessionId}'),
            ),
            title: Text('Log set', style: PeakType.overline()),
          ),
          body: ctx == null
              ? const Center(child: CircularProgressIndicator(color: PeakColors.primary))
              : Stack(
                  children: [
                    ListView(
                      padding: const EdgeInsets.fromLTRB(
                        PeakSpacing.edge,
                        8,
                        PeakSpacing.edge,
                        120,
                      ),
                      children: [
                        Text(
                          ctx.exercise?.name ?? 'Exercise',
                          style: PeakType.headlineXl().copyWith(fontSize: 28, height: 1.05),
                        ),
                        if ((ctx.exercise?.cue ?? '').isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            ctx.exercise!.cue,
                            style: PeakType.bodyMd(color: PeakColors.mutedForeground),
                          ),
                        ],
                        if (ctx.lastSets.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _LastTimeCard(
                            sets: ctx.lastSets,
                            suggestion: ctx.suggestion,
                            onSame: () => _sameAsLast(ctx),
                          ),
                        ],
                        const SizedBox(height: 14),
                        PeakCard(
                          title: 'Weight',
                          child: StepperPad(
                            value: _weight,
                            step: 2.5,
                            min: 0,
                            label: 'kg',
                            format: (v) => v == v.toInt() ? '${v.toInt()}' : v.toStringAsFixed(1),
                            onChanged: (v) => setState(() => _weight = v),
                          ),
                        ),
                        const SizedBox(height: 12),
                        PeakCard(
                          title: 'Reps',
                          child: StepperPad(
                            value: _reps,
                            step: 1,
                            min: 0,
                            max: 50,
                            label: 'reps',
                            format: (v) => '${v.toInt()}',
                            onChanged: (v) => setState(() => _reps = v.toInt()),
                          ),
                        ),
                        if (ctx.rpeEnabled) ...[
                          const SizedBox(height: 12),
                          PeakCard(
                            title: 'RPE (optional)',
                            child: Wrap(
                              spacing: 8,
                              children: [
                                for (final n in const [6, 7, 8, 9, 10])
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _rpe = _rpe == n.toDouble() ? null : n.toDouble());
                                    },
                                    child: Container(
                                      height: 48,
                                      width: 48,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: _rpe == n.toDouble()
                                            ? PeakColors.primary
                                            : PeakColors.surfaceContainerHigh,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$n',
                                        style: PeakType.headlineLg(
                                          color: _rpe == n.toDouble()
                                              ? PeakColors.primaryForeground
                                              : PeakColors.foreground,
                                        ).copyWith(fontSize: 18),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: PeakColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(child: Text('Warmup set', style: PeakType.bodyMd())),
                              Switch.adaptive(
                                value: _isWarmup,
                                onChanged: (v) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _isWarmup = v);
                                },
                                activeThumbColor: PeakColors.primary,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        PeakButton(
                          label: _pending ? 'Logging…' : 'Log set',
                          size: PeakButtonSize.xl,
                          busy: _pending,
                          onPressed: _pending ? null : () => _logSet(ctx),
                        ),
                        if (_resting) ...[
                          const SizedBox(height: 14),
                          RestTimer(
                            defaultSeconds: ctx.restDefault,
                            onComplete: () => setState(() => _resting = false),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: PeakButton(
                                label: 'Done with this exercise',
                                variant: PeakButtonVariant.outline,
                                onPressed: () => context.go('/session/${widget.sessionId}'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: PeakButton(
                                label: "What's next?",
                                variant: PeakButtonVariant.ghost,
                                onPressed: () => context.push('/session/${widget.sessionId}/whats-next'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      top: 12,
                      left: 0,
                      right: 0,
                      child: PrFlash(visible: _showPr, label: _prLabel ?? ''),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _LogContext {
  _LogContext({
    required this.exercise,
    required this.exerciseId,
    required this.lastSets,
    required this.suggestion,
    required this.restDefault,
    required this.rpeEnabled,
  });
  final Exercise? exercise;
  final String exerciseId;
  final List<WorkingSet> lastSets;
  final Suggestion? suggestion;
  final int restDefault;
  final bool rpeEnabled;
}

class _LastTimeCard extends StatelessWidget {
  const _LastTimeCard({
    required this.sets,
    required this.suggestion,
    required this.onSame,
  });
  final List<WorkingSet> sets;
  final Suggestion? suggestion;
  final VoidCallback onSame;

  @override
  Widget build(BuildContext context) {
    final preview = sets.take(5).map((s) {
      return '${formatWeight(s.weight)} × ${s.reps}${s.rpe != null ? '@${s.rpe!.toInt()}' : ''}';
    }).join('   ');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PeakColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LAST TIME', style: PeakType.overline()),
          const SizedBox(height: 4),
          Text(preview, style: PeakType.tabular(PeakType.bodyLg())),
          if (suggestion != null) ...[
            const SizedBox(height: 4),
            Text(
              suggestion!.rationale,
              style: PeakType.bodyMd(color: PeakColors.tertiary),
            ),
          ],
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onSame,
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(
                'Same as last set',
                style: PeakType.labelMd(color: PeakColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
