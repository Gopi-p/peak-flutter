import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../core/constants.dart';

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.equipment,
    required this.movementPattern,
    required this.evidenceRating,
    required this.cue,
    required this.difficulty,
  });

  final String id;
  final String name;
  final List<MuscleGroup> primaryMuscles;
  final List<MuscleGroup> secondaryMuscles;
  final Equipment equipment;
  final MovementPattern movementPattern;
  final int evidenceRating; // 1..5
  final String cue;
  final Difficulty difficulty;

  factory Exercise.fromJson(Map<String, dynamic> j) {
    List<MuscleGroup> parseMuscles(dynamic v) =>
        (v as List?)
            ?.map((s) => MuscleGroup.fromLabel(s as String))
            .whereType<MuscleGroup>()
            .toList(growable: false) ??
        const [];

    return Exercise(
      id: j['id'] as String,
      name: j['name'] as String,
      primaryMuscles: parseMuscles(j['primaryMuscles']),
      secondaryMuscles: parseMuscles(j['secondaryMuscles']),
      equipment: Equipment.fromLabel(j['equipment'] as String?) ?? Equipment.barbell,
      movementPattern:
          MovementPattern.fromLabel(j['movementPattern'] as String?) ??
              MovementPattern.isolation,
      evidenceRating: (j['evidenceRating'] as num).toInt().clamp(1, 5),
      cue: (j['cue'] as String?) ?? '',
      difficulty:
          Difficulty.fromLabel(j['difficulty'] as String?) ?? Difficulty.intermediate,
    );
  }
}

class ExerciseCatalog {
  ExerciseCatalog._(this.all) : _byId = {for (final e in all) e.id: e};

  final List<Exercise> all;
  final Map<String, Exercise> _byId;

  Exercise? byId(String id) => _byId[id];

  List<Exercise> forMuscle(MuscleGroup m, {bool includeSecondary = false}) {
    return all.where((e) {
      if (e.primaryMuscles.contains(m)) return true;
      if (includeSecondary && e.secondaryMuscles.contains(m)) return true;
      return false;
    }).toList(growable: false);
  }

  /// Rank for picker:
  /// 1) evidence rating desc
  /// 2) demote top-3 most-used in last 14 days for variety
  /// 3) alphabetical
  List<Exercise> rank(
    List<Exercise> candidates,
    Map<String, int> recentUsageById,
  ) {
    final sortedByUsage = recentUsageById.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final recentSet = sortedByUsage.take(3).map((e) => e.key).toSet();
    final out = [...candidates];
    out.sort((a, b) {
      final aPen = recentSet.contains(a.id) ? -0.4 : 0.0;
      final bPen = recentSet.contains(b.id) ? -0.4 : 0.0;
      final aScore = a.evidenceRating + aPen;
      final bScore = b.evidenceRating + bPen;
      if (aScore != bScore) return bScore.compareTo(aScore);
      return a.name.compareTo(b.name);
    });
    return out;
  }

  static Future<ExerciseCatalog> load() async {
    final raw = await rootBundle.loadString('assets/data/exercises.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final items = (decoded['exercises'] as List)
        .cast<Map<String, dynamic>>()
        .map(Exercise.fromJson)
        .toList(growable: false);
    return ExerciseCatalog._(items);
  }
}
