import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../analytics/combo.dart';
import '../../analytics/pr.dart';
import '../../analytics/volume.dart' as vol;
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../db/database.dart';
import '../exercise_catalog.dart';

class SessionRepository {
  SessionRepository(this._db, this._catalog);

  final PeakDatabase _db;
  // ignore: unused_field
  final ExerciseCatalog _catalog;
  final _uuid = const Uuid();

  /// Returns the most recent active session (no `endedAt`, not soft-deleted),
  /// or null.
  Future<Session?> activeSession() async {
    final q = _db.select(_db.sessions)
      ..where((t) => t.endedAt.isNull() & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
      ..limit(1);
    final rows = await q.get();
    return rows.firstOrNull;
  }

  Future<String> startSession({DateTime? startedAt}) async {
    final id = _uuid.v4();
    await _db.into(_db.sessions).insert(
          SessionsCompanion.insert(
            id: id,
            startedAt: startedAt ?? DateTime.now(),
          ),
        );
    return id;
  }

  Future<Session?> sessionById(String id) async {
    final q = _db.select(_db.sessions)
      ..where((t) => t.id.equals(id) & t.deletedAt.isNull());
    return (await q.get()).firstOrNull;
  }

  Future<List<Session>> recentSessions({int limit = 60, DateTime? since}) async {
    final q = _db.select(_db.sessions)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
      ..limit(limit);
    if (since != null) {
      q.where((t) => t.startedAt.isBiggerOrEqualValue(since));
    }
    return q.get();
  }

  Stream<List<Session>> watchRecentSessions({int limit = 60}) {
    final q = _db.select(_db.sessions)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)])
      ..limit(limit);
    return q.watch();
  }

  Stream<Session?> watchSession(String id) {
    final q = _db.select(_db.sessions)
      ..where((t) => t.id.equals(id) & t.deletedAt.isNull());
    return q.watchSingleOrNull();
  }

  Future<List<ExerciseEntry>> entriesFor(String sessionId) async {
    final q = _db.select(_db.exerciseEntries)
      ..where((t) => t.sessionId.equals(sessionId))
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
    return q.get();
  }

  Stream<List<ExerciseEntry>> watchEntriesFor(String sessionId) {
    final q = _db.select(_db.exerciseEntries)
      ..where((t) => t.sessionId.equals(sessionId))
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
    return q.watch();
  }

  Future<List<WorkoutSet>> setsForEntry(String entryId) async {
    final q = _db.select(_db.workoutSets)
      ..where((t) => t.entryId.equals(entryId))
      ..orderBy([
        (t) => OrderingTerm.asc(t.sortOrder),
        (t) => OrderingTerm.asc(t.completedAt),
      ]);
    return q.get();
  }

  Stream<List<WorkoutSet>> watchSetsForEntry(String entryId) {
    final q = _db.select(_db.workoutSets)
      ..where((t) => t.entryId.equals(entryId))
      ..orderBy([
        (t) => OrderingTerm.asc(t.sortOrder),
        (t) => OrderingTerm.asc(t.completedAt),
      ]);
    return q.watch();
  }

  Future<List<WorkoutSet>> setsForSession(String sessionId) async {
    final q = _db.select(_db.workoutSets)
      ..where((t) => t.sessionId.equals(sessionId))
      ..orderBy([
        (t) => OrderingTerm.asc(t.sortOrder),
        (t) => OrderingTerm.asc(t.completedAt),
      ]);
    return q.get();
  }

  /// Adds an exercise entry to a session and ensures the chosen muscle is
  /// recorded in the session's musclesTrained list. Returns the new entry id.
  Future<String> addEntry({
    required String sessionId,
    required String exerciseId,
    MuscleGroup? muscle,
  }) async {
    final id = _uuid.v4();
    return _db.transaction(() async {
      final existing = await entriesFor(sessionId);
      await _db.into(_db.exerciseEntries).insert(
            ExerciseEntriesCompanion.insert(
              id: id,
              sessionId: sessionId,
              exerciseId: exerciseId,
              sortOrder: Value(existing.length + 1),
            ),
          );
      if (muscle != null) {
        final session = await sessionById(sessionId);
        if (session != null) {
          final muscles = (jsonDecode(session.musclesTrained) as List).cast<String>();
          if (!muscles.contains(muscle.label)) {
            muscles.add(muscle.label);
            await (_db.update(_db.sessions)..where((t) => t.id.equals(sessionId))).write(
              SessionsCompanion(
                musclesTrained: Value(jsonEncode(muscles)),
                updatedAt: Value(DateTime.now()),
              ),
            );
          }
        }
      }
      return id;
    });
  }

  /// Logs a set within an entry. Detects PRs server-side-style (here: just
  /// before commit) and writes a PersonalRecord row when triggered.
  ///
  /// Returns the inserted set + whether it triggered a PR (and which kind).
  Future<({String setId, PrCheck pr})> logSet({
    required String sessionId,
    required String entryId,
    required String exerciseId,
    required double weight,
    required int reps,
    double? rpe,
    bool isWarmup = false,
    List<String> tags = const [],
    DateTime? completedAt,
  }) async {
    final id = _uuid.v4();
    final now = completedAt ?? DateTime.now();
    return _db.transaction(() async {
      final existing = await setsForEntry(entryId);
      await _db.into(_db.workoutSets).insert(
            WorkoutSetsCompanion.insert(
              id: id,
              entryId: entryId,
              sessionId: sessionId,
              exerciseId: exerciseId,
              weight: weight,
              reps: reps,
              rpe: Value(rpe),
              isWarmup: Value(isWarmup),
              tags: Value(jsonEncode(tags)),
              completedAt: now,
              sortOrder: Value(existing.length + 1),
            ),
          );
      await (_db.update(_db.sessions)..where((t) => t.id.equals(sessionId))).write(
        SessionsCompanion(updatedAt: Value(DateTime.now())),
      );

      PrCheck pr = const PrCheck(isPr: false, estimated1Rm: 0);
      if (!isWarmup) {
        // Pull all historical working sets for this exercise (excluding this session).
        final hist = await (_db.select(_db.workoutSets)
              ..where((t) =>
                  t.exerciseId.equals(exerciseId) &
                  t.isWarmup.equals(false) &
                  t.sessionId.equals(sessionId).not()))
            .get();
        final historicalSets = hist
            .map((s) => HistoricalSet(weight: s.weight, reps: s.reps))
            .toList();
        pr = checkPr((weight: weight, reps: reps), historicalSets);
        if (pr.isPr) {
          await _db.into(_db.personalRecords).insert(
                PersonalRecordsCompanion.insert(
                  id: _uuid.v4(),
                  exerciseId: exerciseId,
                  kind: pr.kind == PrKind.weightForReps ? 'weight-for-reps' : 'estimated-1rm',
                  weight: weight,
                  reps: reps,
                  estimated1Rm: pr.estimated1Rm,
                  achievedAt: now,
                  sessionId: Value(sessionId),
                ),
              );
        }
      }
      return (setId: id, pr: pr);
    });
  }

  Future<void> deleteSet(String setId) async {
    await (_db.delete(_db.workoutSets)..where((t) => t.id.equals(setId))).go();
  }

  /// Hard-deletes an exercise entry. Sets cascade via the FK in `tables.dart`.
  /// Used by the active-session UI when removing an exercise mid-session.
  Future<void> deleteEntry(String entryId) async {
    await (_db.delete(_db.exerciseEntries)..where((t) => t.id.equals(entryId))).go();
  }

  /// Finishes a session — stamps endedAt and writes the combination classification.
  Future<void> finishSession(String sessionId) async {
    final session = await sessionById(sessionId);
    if (session == null) return;
    final muscles = (jsonDecode(session.musclesTrained) as List)
        .cast<String>()
        .map(MuscleGroup.fromLabel)
        .whereType<MuscleGroup>()
        .toList();
    final combo = classifyCombination(muscles);
    await (_db.update(_db.sessions)..where((t) => t.id.equals(sessionId))).write(
      SessionsCompanion(
        endedAt: Value(DateTime.now()),
        classification: Value(combo.label.label),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> softDeleteSession(String sessionId) async {
    await (_db.update(_db.sessions)..where((t) => t.id.equals(sessionId))).write(
      SessionsCompanion(deletedAt: Value(DateTime.now())),
    );
    await (_db.delete(_db.personalRecords)
          ..where((t) => t.sessionId.equals(sessionId)))
        .go();
  }

  /// Builds a SessionLike for analytics (volume math) from a session id.
  Future<vol.SessionLike?> sessionLike(String sessionId) async {
    final session = await sessionById(sessionId);
    if (session == null) return null;
    final entries = await entriesFor(sessionId);
    final entryLikes = <vol.EntryLike>[];
    for (final e in entries) {
      final sets = await setsForEntry(e.id);
      entryLikes.add(
        vol.EntryLike(
          exerciseId: e.exerciseId,
          sets: sets
              .map((s) => vol.WorkingSet(
                    weight: s.weight,
                    reps: s.reps,
                    rpe: s.rpe,
                    isWarmup: s.isWarmup,
                  ))
              .toList(),
        ),
      );
    }
    return vol.SessionLike(startedAt: session.startedAt, entries: entryLikes);
  }

  /// Bulk-loads SessionLike for a date range — used by Insights and Today.
  Future<List<vol.SessionLike>> sessionLikesSince(DateTime since) async {
    final sessions = await (_db.select(_db.sessions)
          ..where((t) =>
              t.deletedAt.isNull() & t.startedAt.isBiggerOrEqualValue(since))
          ..orderBy([(t) => OrderingTerm.asc(t.startedAt)]))
        .get();
    final allSets = await (_db.select(_db.workoutSets)
          ..where((t) => t.completedAt.isBiggerOrEqualValue(since)))
        .get();
    final setsBySession = <String, List<WorkoutSet>>{};
    for (final s in allSets) {
      setsBySession.putIfAbsent(s.sessionId, () => []).add(s);
    }
    return sessions.map((s) {
      final sets = setsBySession[s.id] ?? const [];
      final byEntry = <String, List<WorkoutSet>>{};
      for (final set in sets) {
        byEntry.putIfAbsent(set.entryId, () => []).add(set);
      }
      final entries = byEntry.entries
          .map((e) => vol.EntryLike(
                exerciseId: e.value.first.exerciseId,
                sets: e.value
                    .map((set) => vol.WorkingSet(
                          weight: set.weight,
                          reps: set.reps,
                          rpe: set.rpe,
                          isWarmup: set.isWarmup,
                        ))
                    .toList(),
              ))
          .toList();
      return vol.SessionLike(startedAt: s.startedAt, entries: entries);
    }).toList();
  }

  /// For the exercise picker — counts how many times each exercise was used
  /// in the last `days`. Used to demote the top-3 for variety.
  Future<Map<String, int>> recentExerciseUsage({int days = 14}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final rows = await (_db.select(_db.exerciseEntries).join([
      innerJoin(_db.sessions, _db.sessions.id.equalsExp(_db.exerciseEntries.sessionId)),
    ])
          ..where(_db.sessions.deletedAt.isNull() &
              _db.sessions.startedAt.isBiggerOrEqualValue(since)))
        .get();
    final usage = <String, int>{};
    for (final row in rows) {
      final entry = row.readTable(_db.exerciseEntries);
      usage[entry.exerciseId] = (usage[entry.exerciseId] ?? 0) + 1;
    }
    return usage;
  }

  /// Pulls the most recent prior session that contains this exercise — used to
  /// preview "Last time" numbers in the set logger.
  Future<List<vol.WorkingSet>> lastWorkingSetsFor(
    String exerciseId, {
    String? excludeSessionId,
  }) async {
    final q = _db.select(_db.workoutSets).join([
      innerJoin(_db.sessions, _db.sessions.id.equalsExp(_db.workoutSets.sessionId)),
    ])
      ..where(_db.workoutSets.exerciseId.equals(exerciseId) &
          _db.workoutSets.isWarmup.equals(false) &
          _db.sessions.deletedAt.isNull())
      ..orderBy([OrderingTerm.desc(_db.sessions.startedAt)]);
    if (excludeSessionId != null) {
      q.where(_db.workoutSets.sessionId.equals(excludeSessionId).not());
    }
    final rows = await q.get();
    if (rows.isEmpty) return const [];
    final priorSessionId = rows.first.readTable(_db.workoutSets).sessionId;
    return rows
        .where((r) => r.readTable(_db.workoutSets).sessionId == priorSessionId)
        .map((r) {
      final s = r.readTable(_db.workoutSets);
      return vol.WorkingSet(
        weight: s.weight,
        reps: s.reps,
        rpe: s.rpe,
        isWarmup: s.isWarmup,
      );
    }).toList();
  }
}

/// Convenience — used to derive elapsed time + total volume on the active page.
class SessionStats {
  const SessionStats({
    required this.totalSets,
    required this.volume,
    required this.elapsedMinutes,
  });
  final int totalSets;
  final double volume;
  final int elapsedMinutes;
}

extension SessionMuscles on Session {
  List<MuscleGroup> get muscles {
    final raw = jsonDecode(musclesTrained) as List;
    return raw
        .cast<String>()
        .map(MuscleGroup.fromLabel)
        .whereType<MuscleGroup>()
        .toList();
  }
}

extension SessionStatsExt on Session {
  int elapsedMinutes() {
    final end = endedAt ?? DateTime.now();
    return ((end.difference(startedAt)).inSeconds / 60).floor();
  }
}

// Borrowed: epley1RM is in core/utils.dart. Re-export for convenience.
double epleyEstimate(num weight, num reps) => epley1RM(weight, reps);
