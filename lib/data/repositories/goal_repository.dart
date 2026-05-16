import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';

class GoalRepository {
  GoalRepository(this._db);
  final PeakDatabase _db;
  final _uuid = const Uuid();

  Future<List<Goal>> all() {
    final q = _db.select(_db.goals)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return q.get();
  }

  Stream<List<Goal>> watchAll() {
    final q = _db.select(_db.goals)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return q.watch();
  }

  Future<String> add({
    required String title,
    required String type,
    required double targetValue,
    String targetUnit = '',
    String? exerciseId,
    String? muscle,
    DateTime? deadline,
  }) async {
    final id = _uuid.v4();
    await _db.into(_db.goals).insert(
          GoalsCompanion.insert(
            id: id,
            title: title,
            type: type,
            targetValue: targetValue,
            targetUnit: Value(targetUnit),
            exerciseId: Value(exerciseId),
            muscle: Value(muscle),
            deadline: Value(deadline),
          ),
        );
    return id;
  }

  Future<void> softDelete(String id) async {
    await (_db.update(_db.goals)..where((t) => t.id.equals(id))).write(
      GoalsCompanion(deletedAt: Value(DateTime.now())),
    );
  }
}
