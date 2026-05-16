import '../core/constants.dart';
import '../core/utils.dart';
import '../data/exercise_catalog.dart';

class WorkingSet {
  const WorkingSet({
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

class SessionLike {
  const SessionLike({required this.startedAt, required this.entries});
  final DateTime startedAt;
  final List<EntryLike> entries;
}

class EntryLike {
  const EntryLike({required this.exerciseId, required this.sets});
  final String exerciseId;
  final List<WorkingSet> sets;
}

/// Volume = Σ weight × reps, excluding warmups.
double sessionVolume(SessionLike s) {
  double acc = 0;
  for (final entry in s.entries) {
    for (final set in entry.sets) {
      if (set.isWarmup) continue;
      acc += set.weight * set.reps;
    }
  }
  return acc;
}

Map<MuscleGroup, double> setsByMuscleForSession(
  SessionLike s,
  ExerciseCatalog catalog,
) {
  final out = <MuscleGroup, double>{};
  for (final entry in s.entries) {
    final ex = catalog.byId(entry.exerciseId);
    if (ex == null) continue;
    final working = entry.sets.where((set) => !set.isWarmup).length;
    for (final m in ex.primaryMuscles) {
      out[m] = (out[m] ?? 0) + working;
    }
    // Secondary muscles count at 0.5 — common heuristic.
    for (final m in ex.secondaryMuscles) {
      out[m] = (out[m] ?? 0) + working * 0.5;
    }
  }
  return out;
}

class WeekRollup {
  WeekRollup({required this.weekStart});

  final DateTime weekStart;
  final Map<MuscleGroup, double> setsByMuscle = {};
  final Map<MuscleGroup, double> volumeByMuscle = {};
  int sessionsCount = 0;
  double? avgRpe;
}

List<WeekRollup> rollupByWeek(List<SessionLike> sessions, ExerciseCatalog catalog) {
  final buckets = <String, WeekRollup>{};
  for (final s in sessions) {
    final ws = startOfWeek(s.startedAt);
    final key = ws.toIso8601String();
    final bucket = buckets.putIfAbsent(key, () => WeekRollup(weekStart: ws));
    bucket.sessionsCount += 1;
    double rpeTotal = 0;
    int rpeCount = 0;
    for (final entry in s.entries) {
      final ex = catalog.byId(entry.exerciseId);
      if (ex == null) continue;
      for (final set in entry.sets) {
        if (set.isWarmup) continue;
        final vol = set.weight * set.reps;
        for (final m in ex.primaryMuscles) {
          bucket.setsByMuscle[m] = (bucket.setsByMuscle[m] ?? 0) + 1;
          bucket.volumeByMuscle[m] = (bucket.volumeByMuscle[m] ?? 0) + vol;
        }
        for (final m in ex.secondaryMuscles) {
          bucket.setsByMuscle[m] = (bucket.setsByMuscle[m] ?? 0) + 0.5;
          bucket.volumeByMuscle[m] = (bucket.volumeByMuscle[m] ?? 0) + vol * 0.5;
        }
        if (set.rpe != null) {
          rpeTotal += set.rpe!;
          rpeCount += 1;
        }
      }
    }
    if (rpeCount > 0) {
      final priorAvg = bucket.avgRpe ?? 0;
      bucket.avgRpe = ((priorAvg) * (bucket.sessionsCount - 1) + rpeTotal / rpeCount) /
          bucket.sessionsCount;
    }
  }
  final list = buckets.values.toList();
  list.sort((a, b) => a.weekStart.compareTo(b.weekStart));
  return list;
}

class UndertrainedMuscle {
  const UndertrainedMuscle({required this.muscle, required this.sets, required this.mev});
  final MuscleGroup muscle;
  final double sets;
  final num mev;
}

List<UndertrainedMuscle> undertrainedMuscles(
  WeekRollup? weekRollup,
  Map<MuscleGroup, VolumeGuidance> guidance,
) {
  if (weekRollup == null) {
    return guidance.entries
        .map((e) => UndertrainedMuscle(muscle: e.key, sets: 0, mev: e.value.mev))
        .toList();
  }
  final list = guidance.entries
      .map(
        (e) => UndertrainedMuscle(
          muscle: e.key,
          sets: weekRollup.setsByMuscle[e.key] ?? 0,
          mev: e.value.mev,
        ),
      )
      .where((u) => u.sets < u.mev)
      .toList();
  list.sort((a, b) => a.sets.compareTo(b.sets));
  return list;
}
