import '../core/constants.dart';

const _push = <MuscleGroup>{MuscleGroup.chest, MuscleGroup.shoulders, MuscleGroup.triceps};
const _pull = <MuscleGroup>{
  MuscleGroup.back,
  MuscleGroup.biceps,
  MuscleGroup.traps,
  MuscleGroup.forearms,
};
const _legs = <MuscleGroup>{
  MuscleGroup.quads,
  MuscleGroup.hamstrings,
  MuscleGroup.glutes,
  MuscleGroup.adductors,
  MuscleGroup.calves,
};

class ComboResult {
  const ComboResult({required this.label, required this.note});
  final CombinationLabel label;
  final String note;
}

ComboResult classifyCombination(List<MuscleGroup> muscles) {
  final set = muscles.toSet();
  final inPush = set.where(_push.contains).length;
  final inPull = set.where(_pull.contains).length;
  final inLegs = set.where(_legs.contains).length;
  final total = set.length;

  if (total == 0) {
    return const ComboResult(
      label: CombinationLabel.unusual,
      note: 'No muscles trained yet.',
    );
  }
  if (inPush == total && total >= 2) {
    return const ComboResult(
      label: CombinationLabel.push,
      note: 'Classic push pairing. Chest, shoulders, and triceps share the press pattern.',
    );
  }
  if (inPull == total && total >= 2) {
    return const ComboResult(
      label: CombinationLabel.pull,
      note: 'Classic pull pairing. Back and biceps move together.',
    );
  }
  if (inLegs == total && total >= 2) {
    return const ComboResult(
      label: CombinationLabel.legs,
      note: 'Lower body day. Recovery cost is high. Eat and sleep.',
    );
  }
  if (inPush > 0 && inPull > 0 && inLegs == 0) {
    if (set.contains(MuscleGroup.chest) && set.contains(MuscleGroup.back)) {
      return const ComboResult(
        label: CombinationLabel.antagonist,
        note: 'Chest + Back is a classic antagonist pairing. Fatigue interference is low.',
      );
    }
    return const ComboResult(
      label: CombinationLabel.upper,
      note: 'Upper body session mixing push and pull patterns.',
    );
  }
  if (inLegs > 0 && inPush == 0 && inPull == 0) {
    return const ComboResult(label: CombinationLabel.lower, note: 'Lower-only session.');
  }
  if (inPush + inPull >= 2 && inLegs >= 1) {
    return const ComboResult(
      label: CombinationLabel.fullBody,
      note: 'Full body session. High systemic fatigue. Keep volume modest per muscle.',
    );
  }
  return const ComboResult(
    label: CombinationLabel.unusual,
    note: 'Unusual pairing. Not synergistic, but viable if intentional.',
  );
}
