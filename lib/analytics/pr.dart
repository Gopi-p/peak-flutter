import '../core/utils.dart';

enum PrKind { weightForReps, estimated1Rm }

class PrCheck {
  const PrCheck({required this.isPr, this.kind, required this.estimated1Rm});
  final bool isPr;
  final PrKind? kind;
  final double estimated1Rm;
}

class HistoricalSet {
  const HistoricalSet({required this.weight, required this.reps});
  final double weight;
  final int reps;
}

/// A new set is a PR if either:
///   - same rep target hit at a higher weight (weight-for-reps), or
///   - estimated 1RM exceeds previous best 1RM by ≥ 0.5kg.
PrCheck checkPr(
  ({double weight, int reps}) newSet,
  List<HistoricalSet> history,
) {
  final newE1rm = epley1RM(newSet.weight, newSet.reps);
  double sameRepBest = 0;
  double e1rmBest = 0;
  for (final s in history) {
    if (s.reps == newSet.reps && s.weight > sameRepBest) {
      sameRepBest = s.weight;
    }
    final e = epley1RM(s.weight, s.reps);
    if (e > e1rmBest) e1rmBest = e;
  }
  if (newSet.weight > sameRepBest) {
    return PrCheck(isPr: true, kind: PrKind.weightForReps, estimated1Rm: newE1rm);
  }
  if (newE1rm >= e1rmBest + 0.5) {
    return PrCheck(isPr: true, kind: PrKind.estimated1Rm, estimated1Rm: newE1rm);
  }
  return PrCheck(isPr: false, estimated1Rm: newE1rm);
}
