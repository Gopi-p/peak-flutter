import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/database.dart';

class BodyWeightRepository {
  BodyWeightRepository(this._db);
  final PeakDatabase _db;
  final _uuid = const Uuid();

  Future<List<BodyWeight>> recent({int limit = 180}) {
    final q = _db.select(_db.bodyWeights)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.measuredAt)])
      ..limit(limit);
    return q.get();
  }

  Stream<List<BodyWeight>> watch({int limit = 180}) {
    final q = _db.select(_db.bodyWeights)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.measuredAt)])
      ..limit(limit);
    return q.watch();
  }

  Future<String> add({required double kg, DateTime? measuredAt, String note = ''}) async {
    final id = _uuid.v4();
    await _db.into(_db.bodyWeights).insert(
          BodyWeightsCompanion.insert(
            id: id,
            kg: kg,
            measuredAt: measuredAt ?? DateTime.now(),
            note: Value(note),
          ),
        );
    return id;
  }

  Future<void> softDelete(String id) async {
    await (_db.update(_db.bodyWeights)..where((t) => t.id.equals(id))).write(
      BodyWeightsCompanion(deletedAt: Value(DateTime.now())),
    );
  }
}
