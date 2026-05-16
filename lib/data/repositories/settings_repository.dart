import 'package:drift/drift.dart';

import '../db/database.dart';

class SettingsRepository {
  SettingsRepository(this._db);
  final PeakDatabase _db;

  Future<AppSetting> read() async {
    final row = await _db.select(_db.appSettings).getSingleOrNull();
    if (row != null) return row;
    await _db.into(_db.appSettings).insert(AppSettingsCompanion.insert());
    return _db.select(_db.appSettings).getSingle();
  }

  Stream<AppSetting> watch() => _db.select(_db.appSettings).watchSingle();

  Future<void> update({
    int? defaultRestSeconds,
    bool? rpeEnabled,
    String? unit,
    String? displayName,
  }) async {
    await _db.update(_db.appSettings).write(
          AppSettingsCompanion(
            defaultRestSeconds: defaultRestSeconds == null
                ? const Value.absent()
                : Value(defaultRestSeconds),
            rpeEnabled: rpeEnabled == null ? const Value.absent() : Value(rpeEnabled),
            unit: unit == null ? const Value.absent() : Value(unit),
            displayName:
                displayName == null ? const Value.absent() : Value(displayName),
          ),
        );
  }
}
