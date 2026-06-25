import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';
import '../exercise_catalog.dart';

class RoutineRepository {
  RoutineRepository(this._db);
  final PeakDatabase _db;
  final _uuid = const Uuid();

  // --- Routines --------------------------------------------------------------

  Stream<List<Routine>> watchAll() {
    final q = _db.select(_db.routines)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.createdAt)]);
    return q.watch();
  }

  Future<List<Routine>> all() {
    final q = _db.select(_db.routines)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder), (t) => OrderingTerm.asc(t.createdAt)]);
    return q.get();
  }

  Future<Routine?> byId(String id) async {
    final q = _db.select(_db.routines)..where((t) => t.id.equals(id) & t.deletedAt.isNull());
    return (await q.get()).firstOrNull;
  }

  Stream<Routine?> watchById(String id) {
    final q = _db.select(_db.routines)..where((t) => t.id.equals(id) & t.deletedAt.isNull());
    return q.watchSingleOrNull();
  }

  Future<String> create({required String name}) async {
    final id = _uuid.v4();
    final existing = await all();
    await _db.into(_db.routines).insert(
          RoutinesCompanion.insert(
            id: id,
            name: name,
            sortOrder: Value(existing.length + 1),
          ),
        );
    return id;
  }

  Future<void> rename(String id, String name) async {
    await (_db.update(_db.routines)..where((t) => t.id.equals(id))).write(
      RoutinesCompanion(name: Value(name), updatedAt: Value(DateTime.now())),
    );
  }

  Future<void> softDelete(String id) async {
    await (_db.update(_db.routines)..where((t) => t.id.equals(id))).write(
      RoutinesCompanion(deletedAt: Value(DateTime.now())),
    );
  }

  /// Persists a new ordering for the routine list.
  Future<void> reorder(List<String> idsInOrder) async {
    await _db.transaction(() async {
      for (var i = 0; i < idsInOrder.length; i++) {
        await (_db.update(_db.routines)..where((t) => t.id.equals(idsInOrder[i]))).write(
          RoutinesCompanion(sortOrder: Value(i + 1), updatedAt: Value(DateTime.now())),
        );
      }
    });
  }

  // --- Entries ---------------------------------------------------------------

  Stream<List<RoutineEntry>> watchEntries(String routineId) {
    final q = _db.select(_db.routineEntries)
      ..where((t) => t.routineId.equals(routineId))
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
    return q.watch();
  }

  Future<List<RoutineEntry>> entriesFor(String routineId) {
    final q = _db.select(_db.routineEntries)
      ..where((t) => t.routineId.equals(routineId))
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
    return q.get();
  }

  Future<String> addEntry({
    required String routineId,
    required String exerciseId,
    List<String> alternatives = const [],
  }) async {
    final id = _uuid.v4();
    final existing = await entriesFor(routineId);
    await _db.into(_db.routineEntries).insert(
          RoutineEntriesCompanion.insert(
            id: id,
            routineId: routineId,
            exerciseId: exerciseId,
            alternatives: Value(jsonEncode(alternatives)),
            sortOrder: Value(existing.length + 1),
          ),
        );
    await _touch(routineId);
    return id;
  }

  Future<void> removeEntry(String entryId) async {
    final entry = await (_db.select(_db.routineEntries)..where((t) => t.id.equals(entryId)))
        .getSingleOrNull();
    await (_db.delete(_db.routineEntries)..where((t) => t.id.equals(entryId))).go();
    if (entry != null) await _touch(entry.routineId);
  }

  Future<void> setAlternatives(String entryId, List<String> alternatives) async {
    await (_db.update(_db.routineEntries)..where((t) => t.id.equals(entryId))).write(
      RoutineEntriesCompanion(alternatives: Value(jsonEncode(alternatives))),
    );
  }

  Future<void> reorderEntries(String routineId, List<String> entryIdsInOrder) async {
    await _db.transaction(() async {
      for (var i = 0; i < entryIdsInOrder.length; i++) {
        await (_db.update(_db.routineEntries)..where((t) => t.id.equals(entryIdsInOrder[i]))).write(
          RoutineEntriesCompanion(sortOrder: Value(i + 1)),
        );
      }
    });
    await _touch(routineId);
  }

  Future<void> _touch(String routineId) async {
    await (_db.update(_db.routines)..where((t) => t.id.equals(routineId))).write(
      RoutinesCompanion(updatedAt: Value(DateTime.now())),
    );
  }

  // --- Seeding ---------------------------------------------------------------

  /// Whether any non-deleted routines exist. Drives the "seed starter" CTA.
  Future<bool> hasAny() async => (await all()).isNotEmpty;

  /// Seeds a Push / Pull / Legs starter set, resolving exercises by display
  /// name against the bundled [catalog] so it stays robust to id changes.
  /// Names that don't resolve are skipped silently.
  Future<void> seedPplStarter(ExerciseCatalog catalog) async {
    String? idFor(String name) => catalog.all.firstWhereOrNull((e) => e.name == name)?.id;

    // Each slot: (primary exercise name, [alternative exercise names]).
    const plan = <String, List<(String, List<String>)>>{
      'Push': [
        ('Push-Up', []),
        ('Barbell Bench Press', []),
        ('Incline Dumbbell Press', []),
        ('Machine Shoulder Press', []),
        ('Dumbbell Lateral Raise', ['Cable Lateral Raise']),
        ('Pec Deck', ['Cable Fly', 'Dumbbell Fly']),
        ('Cable Tricep Pushdown', []),
        ('Overhead Tricep Extension (Cable)', []),
      ],
      'Pull': [
        ('Pull-Up', ['Assisted Pull-Up Machine']),
        ('Lat Pulldown', []),
        ('Seated Cable Row', []),
        ('Machine Row (Chest-Supported)', []),
        ('Reverse Pec Deck', ['Cable Reverse Fly']),
        ('Face Pull', []),
        ('EZ-Bar Curl', ['Barbell Curl']),
        ('Hammer Curl', []),
      ],
      'Legs': [
        ('Barbell Back Squat', []),
        ('Romanian Deadlift', []),
        ('Leg Extension', []),
        ('Lying Leg Curl', ['Seated Leg Curl']),
        ('Hip Adduction (Machine)', []),
        ('Hip Abduction (Machine)', []),
        ('Standing Calf Raise', ['Seated Calf Raise']),
        ('Hanging Leg Raise', ["Captain's Chair Knee Raise"]),
        ('Plank', []),
      ],
    };

    await _db.transaction(() async {
      for (final routineEntry in plan.entries) {
        final routineId = await create(name: routineEntry.key);
        for (final (exName, altNames) in routineEntry.value) {
          final exId = idFor(exName);
          if (exId == null) continue;
          final altIds = altNames.map(idFor).whereType<String>().toList();
          await addEntry(routineId: routineId, exerciseId: exId, alternatives: altIds);
        }
      }
    });
  }
}
