import 'package:drift/drift.dart';

import '../db/database.dart';

class SettingsRepository {
  SettingsRepository(this._db);
  final PeakDatabase _db;

  /// Returns the singleton settings row, creating it if missing.
  ///
  /// Defensive: uses `get().first` rather than `getSingle()` so that a stale
  /// duplicate row (legacy state from earlier builds) doesn't crash callers.
  /// `database.dart` dedupes on open, so this is belt-and-braces.
  Future<AppSetting> read() async {
    final rows = await (_db.select(_db.appSettings)..limit(1)).get();
    if (rows.isNotEmpty) return rows.first;
    await _db.into(_db.appSettings).insert(
          AppSettingsCompanion.insert(id: const Value(1)),
        );
    return (await (_db.select(_db.appSettings)..limit(1)).get()).first;
  }

  /// Streams the singleton settings row. Tolerates the legacy two-row state
  /// by emitting the first row of a `watch()` stream instead of `watchSingle()`.
  Stream<AppSetting> watch() {
    return (_db.select(_db.appSettings)..limit(1))
        .watch()
        .where((rows) => rows.isNotEmpty)
        .map((rows) => rows.first);
  }

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
