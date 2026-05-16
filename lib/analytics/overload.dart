import '../core/utils.dart';

class SetSnapshot {
  const SetSnapshot({
    required this.weight,
    required this.reps,
    this.rpe,
    this.isWarmup = false,
  });
  final double weight;
  final int reps;
  final double? rpe;
  final bool isWarmup;
}

class Suggestion {
  const Suggestion({required this.weight, required this.reps, required this.rationale});
  final double weight;
  final int reps;
  final String rationale;
}

/// RPE-aware progression — mirrors `peak-web/lib/analytics/overload.ts`.
///   - RPE ≤ 7 → bump 2.5 kg, same reps.
///   - RPE = 8 → repeat weight, +1 rep on top set.
///   - RPE 9–10 → hold and consolidate.
///   - No RPE: if reps matched across sets, bump; else repeat.
Suggestion? suggestNext(List<SetSnapshot> lastWorkingSets) {
  final sets = lastWorkingSets.where((s) => !s.isWarmup).toList();
  if (sets.isEmpty) return null;
  final top = sets.reduce(
    (a, b) => epley1RM(a.weight, a.reps) > epley1RM(b.weight, b.reps) ? a : b,
  );
  final rpe = top.rpe;
  if (rpe != null) {
    if (rpe <= 7) {
      return Suggestion(
        weight: roundToPlate(top.weight + 2.5),
        reps: top.reps,
        rationale: 'Last set felt easy (RPE ≤ 7). Add a small jump.',
      );
    }
    if (rpe == 8) {
      return Suggestion(
        weight: top.weight,
        reps: top.reps + 1,
        rationale: 'RPE 8 last time — try one more rep at the same weight.',
      );
    }
    return Suggestion(
      weight: top.weight,
      reps: top.reps,
      rationale: 'RPE 9+ last time. Hold and consolidate.',
    );
  }
  final allEqual = sets.every((s) => s.reps == sets.first.reps);
  if (allEqual) {
    return Suggestion(
      weight: roundToPlate(top.weight + 2.5),
      reps: top.reps,
      rationale: 'All sets hit the same reps last time. Time to add weight.',
    );
  }
  return Suggestion(
    weight: top.weight,
    reps: top.reps,
    rationale: 'Reps dropped last time. Repeat and stabilize first.',
  );
}
