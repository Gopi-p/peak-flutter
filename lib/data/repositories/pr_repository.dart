import 'package:drift/drift.dart';

import '../db/database.dart';

class PrRepository {
  PrRepository(this._db);
  final PeakDatabase _db;

  Future<List<PersonalRecord>> forExercise(String exerciseId) {
    final q = _db.select(_db.personalRecords)
      ..where((t) => t.exerciseId.equals(exerciseId))
      ..orderBy([(t) => OrderingTerm.desc(t.achievedAt)]);
    return q.get();
  }

  Future<PersonalRecord?> bestEstimated1RM(String exerciseId) async {
    final q = _db.select(_db.personalRecords)
      ..where((t) => t.exerciseId.equals(exerciseId))
      ..orderBy([(t) => OrderingTerm.desc(t.estimated1Rm)])
      ..limit(1);
    return (await q.get()).firstOrNull;
  }
}
