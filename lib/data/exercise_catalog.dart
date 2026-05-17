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
    this.description = '',
    this.steps = const [],
    this.mindMuscleCue = '',
    this.commonMistakes = const [],
    this.tips = const [],
    this.animationAsset,
    this.videoUrl,
    this.videoSource,
    this.detailedVideoUrl,
    this.detailedVideoSource,
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

  /// 2–3 sentences in plain English. What the exercise does and why train it.
  final String description;

  /// 5–7 imperative steps, beginner-friendly.
  final List<String> steps;

  /// One sentence: what to *feel* and where, for mind-muscle connection.
  final String mindMuscleCue;

  /// 3 common errors with their fix, in one short sentence each.
  final List<String> commonMistakes;

  /// 1–3 practical tips (Indian-gym-specific where relevant).
  final List<String> tips;

  /// Optional bundled asset path for an animation/GIF, e.g.
  /// `assets/anim/barbell-bench-press.gif`. Null when no animation ships yet —
  /// the UI shows a placeholder in that case.
  final String? animationAsset;

  /// Short-form YouTube reference — Shorts URL (`/shorts/<id>`) or a sub-2min
  /// tutorial. Used as the inline hero on the exercise detail page for a quick
  /// in-gym look. When null, falls back to [detailedVideoUrl] in the hero, or
  /// to a YouTube search URL if both are absent.
  final String? videoUrl;

  /// Channel attribution for the short clip (e.g. "Jeff Nippard").
  final String? videoSource;

  /// Long-form tutorial deep-link, behind a "Detailed explanation" button on
  /// the detail page. Kept separate from [videoUrl] so the in-gym hero stays
  /// quick + concise, and the deeper dive stays one tap away.
  final String? detailedVideoUrl;

  /// Channel attribution for the detailed tutorial.
  final String? detailedVideoSource;

  bool get hasRichContent =>
      description.isNotEmpty || steps.isNotEmpty || mindMuscleCue.isNotEmpty;

  factory Exercise.fromJson(Map<String, dynamic> j) {
    List<MuscleGroup> parseMuscles(dynamic v) =>
        (v as List?)
            ?.map((s) => MuscleGroup.fromLabel(s as String))
            .whereType<MuscleGroup>()
            .toList(growable: false) ??
        const [];

    List<String> parseStrings(dynamic v) =>
        (v as List?)?.map((s) => s as String).toList(growable: false) ?? const [];

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
      description: (j['description'] as String?) ?? '',
      steps: parseStrings(j['steps']),
      mindMuscleCue: (j['mindMuscleCue'] as String?) ?? '',
      commonMistakes: parseStrings(j['commonMistakes']),
      tips: parseStrings(j['tips']),
      animationAsset: j['animationAsset'] as String?,
      videoUrl: j['videoUrl'] as String?,
      videoSource: j['videoSource'] as String?,
      detailedVideoUrl: j['detailedVideoUrl'] as String?,
      detailedVideoSource: j['detailedVideoSource'] as String?,
    );
  }
}

/// Helpers for the URL handling on the detail page. Pure utility — keep
/// here so both the page and any future video-card widget can reuse them.
class ExerciseVideo {
  ExerciseVideo._();

  /// Pulls the YouTube video id out of any of the common URL shapes:
  /// `youtube.com/watch?v=ID`, `youtu.be/ID`, `youtube.com/shorts/ID`,
  /// `youtube.com/embed/ID`. Returns null if no id is present.
  static String? extractYouTubeId(String? url) {
    if (url == null || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final host = uri.host.replaceFirst('www.', '');
    if (host == 'youtu.be') {
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      return _validId(id);
    }
    if (host.endsWith('youtube.com') || host == 'm.youtube.com') {
      final v = uri.queryParameters['v'];
      if (v != null) return _validId(v);
      final segs = uri.pathSegments;
      if (segs.length >= 2 && (segs.first == 'embed' || segs.first == 'shorts')) {
        return _validId(segs[1]);
      }
    }
    return null;
  }

  /// YouTube serves thumbnails publicly at this URL pattern — embedding the
  /// image is allowed for any public video.
  static String? thumbnailUrl(String? videoUrl) {
    final id = extractYouTubeId(videoUrl);
    if (id == null) return null;
    return 'https://img.youtube.com/vi/$id/hqdefault.jpg';
  }

  /// Search URL used as a fallback when an exercise has no curated [videoUrl].
  /// Opens in the YouTube app on mobile when present.
  static Uri searchUrl(String exerciseName) {
    final q = Uri.encodeQueryComponent('$exerciseName form tutorial');
    return Uri.parse('https://www.youtube.com/results?search_query=$q');
  }

  static String? _validId(String? raw) {
    if (raw == null) return null;
    final id = raw.split('?').first.split('&').first;
    return id.isEmpty ? null : id;
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
