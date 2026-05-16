import 'package:flutter_test/flutter_test.dart';

import 'package:peak/analytics/combo.dart';
import 'package:peak/analytics/overload.dart';
import 'package:peak/analytics/pr.dart';
import 'package:peak/analytics/plate_calc.dart';
import 'package:peak/core/constants.dart';

void main() {
  group('analytics', () {
    test('classifyCombination labels Push correctly', () {
      final r = classifyCombination([
        MuscleGroup.chest,
        MuscleGroup.triceps,
        MuscleGroup.shoulders,
      ]);
      expect(r.label, CombinationLabel.push);
    });

    test('checkPr flags weight-for-reps PR', () {
      final r = checkPr(
        (weight: 100, reps: 5),
        const [HistoricalSet(weight: 95, reps: 5)],
      );
      expect(r.isPr, isTrue);
      expect(r.kind, PrKind.weightForReps);
    });

    test('suggestNext bumps weight when last RPE ≤ 7', () {
      final s = suggestNext([
        const SetSnapshot(weight: 60, reps: 8, rpe: 7),
      ]);
      expect(s, isNotNull);
      expect(s!.weight, 62.5);
    });

    test('platesPerSide returns exact load when achievable', () {
      final r = platesPerSide(60, barKg: 20);
      expect(r.plates, [20]);
      expect(r.achievableKg, 60);
    });
  });
}
