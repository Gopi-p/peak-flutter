import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/db/database.dart';

/// Single-file JSON export/import. The shape is intentionally simple:
/// a flat object with one array per table. Stable across schema versions
/// thanks to per-row defensive parsing.
class ExportImportService {
  ExportImportService(this._db);
  final PeakDatabase _db;

  static const _exportVersion = 2;

  Future<Map<String, dynamic>> _buildPayload() async {
    final sessions = await _db.select(_db.sessions).get();
    final entries = await _db.select(_db.exerciseEntries).get();
    final sets = await _db.select(_db.workoutSets).get();
    final bw = await _db.select(_db.bodyWeights).get();
    final goals = await _db.select(_db.goals).get();
    final prs = await _db.select(_db.personalRecords).get();
    final routines = await _db.select(_db.routines).get();
    final routineEntries = await _db.select(_db.routineEntries).get();
    final settings = await _db.select(_db.appSettings).getSingleOrNull();

    return {
      'version': _exportVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'sessions': sessions.map(_sessionToJson).toList(),
      'entries': entries.map(_entryToJson).toList(),
      'sets': sets.map(_setToJson).toList(),
      'bodyWeights': bw.map(_bwToJson).toList(),
      'goals': goals.map(_goalToJson).toList(),
      'personalRecords': prs.map(_prToJson).toList(),
      'routines': routines.map(_routineToJson).toList(),
      'routineEntries': routineEntries.map(_routineEntryToJson).toList(),
      'settings': settings == null ? null : _settingsToJson(settings),
    };
  }

  /// Writes a `peak-export-YYYY-MM-DD.json` to a temp file and triggers the
  /// system share sheet.
  Future<File> exportAndShare() async {
    final payload = await _buildPayload();
    final json = const JsonEncoder.withIndent('  ').convert(payload);
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().split('T').first;
    final file = File(p.join(dir.path, 'peak-export-$stamp.json'));
    await file.writeAsString(json);
    try {
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        text: 'Peak data export',
      );
    } catch (e) {
      debugPrint('share failed (file is still on disk): $e');
    }
    return file;
  }

  /// Picks a JSON file and replaces all on-device data with its contents.
  /// Returns the number of sessions imported, or null if the user canceled.
  Future<ImportResult?> pickAndImport({bool replace = true}) async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (res == null || res.files.isEmpty) return null;
    final path = res.files.single.path;
    if (path == null) return null;
    final raw = await File(path).readAsString();
    return importFromString(raw, replace: replace);
  }

  /// For the onboarding "Sample" flow: imports the bundled sample JSON.
  Future<ImportResult> importBundledSample() async {
    final raw = await rootBundle.loadString('assets/data/sample-export.json');
    return importFromString(raw, replace: true);
  }

  Future<ImportResult> importFromString(String raw, {required bool replace}) async {
    final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
    final version = data['version'] as int? ?? 0;
    if (version > _exportVersion) {
      throw StateError(
        'Export is from a newer version of Peak ($version) than this build ($_exportVersion). '
        'Upgrade the app and try again.',
      );
    }

    return _db.transaction<ImportResult>(() async {
      if (replace) {
        await _db.delete(_db.workoutSets).go();
        await _db.delete(_db.exerciseEntries).go();
        await _db.delete(_db.personalRecords).go();
        await _db.delete(_db.sessions).go();
        await _db.delete(_db.bodyWeights).go();
        await _db.delete(_db.goals).go();
        await _db.delete(_db.routineEntries).go();
        await _db.delete(_db.routines).go();
      }

      final sessions = (data['sessions'] as List? ?? const []).cast<Map<String, dynamic>>();
      final entries = (data['entries'] as List? ?? const []).cast<Map<String, dynamic>>();
      final sets = (data['sets'] as List? ?? const []).cast<Map<String, dynamic>>();
      final bw = (data['bodyWeights'] as List? ?? const []).cast<Map<String, dynamic>>();
      final goals = (data['goals'] as List? ?? const []).cast<Map<String, dynamic>>();
      final prs = (data['personalRecords'] as List? ?? const []).cast<Map<String, dynamic>>();
      final routines = (data['routines'] as List? ?? const []).cast<Map<String, dynamic>>();
      final routineEntries =
          (data['routineEntries'] as List? ?? const []).cast<Map<String, dynamic>>();

      for (final s in sessions) {
        await _db.into(_db.sessions).insertOnConflictUpdate(_sessionFromJson(s));
      }
      for (final e in entries) {
        await _db.into(_db.exerciseEntries).insertOnConflictUpdate(_entryFromJson(e));
      }
      for (final s in sets) {
        await _db.into(_db.workoutSets).insertOnConflictUpdate(_setFromJson(s));
      }
      for (final b in bw) {
        await _db.into(_db.bodyWeights).insertOnConflictUpdate(_bwFromJson(b));
      }
      for (final g in goals) {
        await _db.into(_db.goals).insertOnConflictUpdate(_goalFromJson(g));
      }
      for (final pr in prs) {
        await _db.into(_db.personalRecords).insertOnConflictUpdate(_prFromJson(pr));
      }
      for (final r in routines) {
        await _db.into(_db.routines).insertOnConflictUpdate(_routineFromJson(r));
      }
      for (final re in routineEntries) {
        await _db.into(_db.routineEntries).insertOnConflictUpdate(_routineEntryFromJson(re));
      }
      final settingsJson = data['settings'];
      if (settingsJson is Map<String, dynamic>) {
        await _db.update(_db.appSettings).write(_settingsCompanion(settingsJson));
      }

      return ImportResult(
        sessions: sessions.length,
        sets: sets.length,
        bodyWeights: bw.length,
        goals: goals.length,
      );
    });
  }

  // --- toJson helpers --------------------------------------------------------

  Map<String, dynamic> _sessionToJson(Session s) => {
        'id': s.id,
        'startedAt': s.startedAt.toIso8601String(),
        'endedAt': s.endedAt?.toIso8601String(),
        'musclesTrained': jsonDecode(s.musclesTrained),
        'classification': s.classification,
        'routineId': s.routineId,
        'notes': s.notes,
        'deletedAt': s.deletedAt?.toIso8601String(),
      };

  Map<String, dynamic> _entryToJson(ExerciseEntry e) => {
        'id': e.id,
        'sessionId': e.sessionId,
        'exerciseId': e.exerciseId,
        'notes': e.notes,
        'sortOrder': e.sortOrder,
      };

  Map<String, dynamic> _setToJson(WorkoutSet s) => {
        'id': s.id,
        'entryId': s.entryId,
        'sessionId': s.sessionId,
        'exerciseId': s.exerciseId,
        'weight': s.weight,
        'reps': s.reps,
        'rpe': s.rpe,
        'isWarmup': s.isWarmup,
        'tags': jsonDecode(s.tags),
        'completedAt': s.completedAt.toIso8601String(),
        'sortOrder': s.sortOrder,
      };

  Map<String, dynamic> _bwToJson(BodyWeight b) => {
        'id': b.id,
        'kg': b.kg,
        'measuredAt': b.measuredAt.toIso8601String(),
        'note': b.note,
        'deletedAt': b.deletedAt?.toIso8601String(),
      };

  Map<String, dynamic> _goalToJson(Goal g) => {
        'id': g.id,
        'title': g.title,
        'type': g.type,
        'targetValue': g.targetValue,
        'targetUnit': g.targetUnit,
        'exerciseId': g.exerciseId,
        'muscle': g.muscle,
        'deadline': g.deadline?.toIso8601String(),
        'completedAt': g.completedAt?.toIso8601String(),
        'deletedAt': g.deletedAt?.toIso8601String(),
      };

  Map<String, dynamic> _prToJson(PersonalRecord p) => {
        'id': p.id,
        'exerciseId': p.exerciseId,
        'kind': p.kind,
        'weight': p.weight,
        'reps': p.reps,
        'estimated1Rm': p.estimated1Rm,
        'achievedAt': p.achievedAt.toIso8601String(),
        'sessionId': p.sessionId,
      };

  Map<String, dynamic> _routineToJson(Routine r) => {
        'id': r.id,
        'name': r.name,
        'sortOrder': r.sortOrder,
        'deletedAt': r.deletedAt?.toIso8601String(),
      };

  Map<String, dynamic> _routineEntryToJson(RoutineEntry e) => {
        'id': e.id,
        'routineId': e.routineId,
        'exerciseId': e.exerciseId,
        'alternatives': jsonDecode(e.alternatives),
        'sortOrder': e.sortOrder,
      };

  Map<String, dynamic> _settingsToJson(AppSetting s) => {
        'defaultRestSeconds': s.defaultRestSeconds,
        'rpeEnabled': s.rpeEnabled,
        'unit': s.unit,
        'displayName': s.displayName,
      };

  // --- fromJson helpers ------------------------------------------------------

  SessionsCompanion _sessionFromJson(Map<String, dynamic> j) => SessionsCompanion.insert(
        id: j['id'] as String,
        startedAt: DateTime.parse(j['startedAt'] as String),
        endedAt: Value(_optDate(j['endedAt'])),
        musclesTrained: Value(jsonEncode(j['musclesTrained'] ?? const [])),
        classification: Value(j['classification'] as String?),
        routineId: Value(j['routineId'] as String?),
        notes: Value((j['notes'] as String?) ?? ''),
        deletedAt: Value(_optDate(j['deletedAt'])),
      );

  ExerciseEntriesCompanion _entryFromJson(Map<String, dynamic> j) =>
      ExerciseEntriesCompanion.insert(
        id: j['id'] as String,
        sessionId: j['sessionId'] as String,
        exerciseId: j['exerciseId'] as String,
        notes: Value((j['notes'] as String?) ?? ''),
        sortOrder: Value((j['sortOrder'] as num?)?.toInt() ?? 0),
      );

  WorkoutSetsCompanion _setFromJson(Map<String, dynamic> j) => WorkoutSetsCompanion.insert(
        id: j['id'] as String,
        entryId: j['entryId'] as String,
        sessionId: j['sessionId'] as String,
        exerciseId: j['exerciseId'] as String,
        weight: (j['weight'] as num).toDouble(),
        reps: (j['reps'] as num).toInt(),
        rpe: Value((j['rpe'] as num?)?.toDouble()),
        isWarmup: Value((j['isWarmup'] as bool?) ?? false),
        tags: Value(jsonEncode(j['tags'] ?? const [])),
        completedAt: DateTime.parse(j['completedAt'] as String),
        sortOrder: Value((j['sortOrder'] as num?)?.toInt() ?? 0),
      );

  BodyWeightsCompanion _bwFromJson(Map<String, dynamic> j) => BodyWeightsCompanion.insert(
        id: j['id'] as String,
        kg: (j['kg'] as num).toDouble(),
        measuredAt: DateTime.parse(j['measuredAt'] as String),
        note: Value((j['note'] as String?) ?? ''),
        deletedAt: Value(_optDate(j['deletedAt'])),
      );

  GoalsCompanion _goalFromJson(Map<String, dynamic> j) => GoalsCompanion.insert(
        id: j['id'] as String,
        title: j['title'] as String,
        type: j['type'] as String,
        targetValue: (j['targetValue'] as num).toDouble(),
        targetUnit: Value((j['targetUnit'] as String?) ?? ''),
        exerciseId: Value(j['exerciseId'] as String?),
        muscle: Value(j['muscle'] as String?),
        deadline: Value(_optDate(j['deadline'])),
        completedAt: Value(_optDate(j['completedAt'])),
        deletedAt: Value(_optDate(j['deletedAt'])),
      );

  PersonalRecordsCompanion _prFromJson(Map<String, dynamic> j) => PersonalRecordsCompanion.insert(
        id: j['id'] as String,
        exerciseId: j['exerciseId'] as String,
        kind: j['kind'] as String,
        weight: (j['weight'] as num).toDouble(),
        reps: (j['reps'] as num).toInt(),
        estimated1Rm: (j['estimated1Rm'] as num).toDouble(),
        achievedAt: DateTime.parse(j['achievedAt'] as String),
        sessionId: Value(j['sessionId'] as String?),
      );

  RoutinesCompanion _routineFromJson(Map<String, dynamic> j) => RoutinesCompanion.insert(
        id: j['id'] as String,
        name: j['name'] as String,
        sortOrder: Value((j['sortOrder'] as num?)?.toInt() ?? 0),
        deletedAt: Value(_optDate(j['deletedAt'])),
      );

  RoutineEntriesCompanion _routineEntryFromJson(Map<String, dynamic> j) =>
      RoutineEntriesCompanion.insert(
        id: j['id'] as String,
        routineId: j['routineId'] as String,
        exerciseId: j['exerciseId'] as String,
        alternatives: Value(jsonEncode(j['alternatives'] ?? const [])),
        sortOrder: Value((j['sortOrder'] as num?)?.toInt() ?? 0),
      );

  AppSettingsCompanion _settingsCompanion(Map<String, dynamic> j) => AppSettingsCompanion(
        id: const Value(1),
        defaultRestSeconds: Value((j['defaultRestSeconds'] as num?)?.toInt() ?? 90),
        rpeEnabled: Value((j['rpeEnabled'] as bool?) ?? true),
        unit: Value((j['unit'] as String?) ?? 'kg'),
        displayName: Value((j['displayName'] as String?) ?? ''),
      );

  static DateTime? _optDate(Object? v) => v == null ? null : DateTime.parse(v as String);
}

class ImportResult {
  const ImportResult({
    required this.sessions,
    required this.sets,
    required this.bodyWeights,
    required this.goals,
  });
  final int sessions;
  final int sets;
  final int bodyWeights;
  final int goals;
}
