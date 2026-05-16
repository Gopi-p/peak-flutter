/// Domain constants — mirrors `peak-web/lib/constants.ts`.
library;

enum MuscleGroup {
  chest('Chest'),
  back('Back'),
  shoulders('Shoulders'),
  biceps('Biceps'),
  triceps('Triceps'),
  quads('Quads'),
  hamstrings('Hamstrings'),
  glutes('Glutes'),
  calves('Calves'),
  core('Core'),
  forearms('Forearms'),
  traps('Traps');

  const MuscleGroup(this.label);
  final String label;

  static MuscleGroup? fromLabel(String? label) {
    if (label == null) return null;
    for (final m in MuscleGroup.values) {
      if (m.label == label) return m;
    }
    return null;
  }
}

const muscleGroups = MuscleGroup.values;

enum Equipment {
  barbell('Barbell'),
  dumbbell('Dumbbell'),
  cable('Cable'),
  machine('Machine'),
  bodyweight('Bodyweight');

  const Equipment(this.label);
  final String label;

  static Equipment? fromLabel(String? label) {
    if (label == null) return null;
    for (final e in Equipment.values) {
      if (e.label == label) return e;
    }
    return null;
  }
}

enum MovementPattern {
  press('Press'),
  pull('Pull'),
  squat('Squat'),
  hinge('Hinge'),
  carry('Carry'),
  isolation('Isolation');

  const MovementPattern(this.label);
  final String label;

  static MovementPattern? fromLabel(String? label) {
    if (label == null) return null;
    for (final p in MovementPattern.values) {
      if (p.label == label) return p;
    }
    return null;
  }
}

enum Difficulty {
  beginner('Beginner'),
  intermediate('Intermediate'),
  advanced('Advanced');

  const Difficulty(this.label);
  final String label;

  static Difficulty? fromLabel(String? label) {
    if (label == null) return null;
    for (final d in Difficulty.values) {
      if (d.label == label) return d;
    }
    return null;
  }
}

enum CombinationLabel {
  push,
  pull,
  legs,
  upper,
  lower,
  fullBody('Full Body'),
  antagonist,
  unusual;

  const CombinationLabel([String? label]) : _label = label;
  final String? _label;
  String get label =>
      _label ?? '${name[0].toUpperCase()}${name.substring(1)}';
}

const defaultRestSeconds = 90;

/// Hypertrophy volume guidance (Renaissance Periodization simplified).
class VolumeGuidance {
  const VolumeGuidance({required this.mev, required this.mav, required this.mrv});
  final num mev;
  final num mav;
  final num mrv;
}

const volumeGuidance = <MuscleGroup, VolumeGuidance>{
  MuscleGroup.chest: VolumeGuidance(mev: 8, mav: 14, mrv: 22),
  MuscleGroup.back: VolumeGuidance(mev: 10, mav: 16, mrv: 24),
  MuscleGroup.shoulders: VolumeGuidance(mev: 8, mav: 14, mrv: 22),
  MuscleGroup.biceps: VolumeGuidance(mev: 6, mav: 12, mrv: 20),
  MuscleGroup.triceps: VolumeGuidance(mev: 6, mav: 12, mrv: 20),
  MuscleGroup.quads: VolumeGuidance(mev: 8, mav: 14, mrv: 20),
  MuscleGroup.hamstrings: VolumeGuidance(mev: 6, mav: 12, mrv: 20),
  MuscleGroup.glutes: VolumeGuidance(mev: 6, mav: 12, mrv: 20),
  MuscleGroup.calves: VolumeGuidance(mev: 6, mav: 12, mrv: 20),
  MuscleGroup.core: VolumeGuidance(mev: 6, mav: 12, mrv: 20),
  MuscleGroup.forearms: VolumeGuidance(mev: 4, mav: 8, mrv: 14),
  MuscleGroup.traps: VolumeGuidance(mev: 4, mav: 10, mrv: 18),
};
