import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Sessions,
  ExerciseEntries,
  WorkoutSets,
  BodyWeights,
  Goals,
  PersonalRecords,
  AppSettings,
  Routines,
  RoutineEntries,
])
class PeakDatabase extends _$PeakDatabase {
  PeakDatabase() : super(_openConnection());

  PeakDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Seed singleton settings row with an explicit id so insertOrIgnore
          // collides against the same row every time.
          await into(appSettings).insert(
            AppSettingsCompanion.insert(id: const Value(1)),
            mode: InsertMode.insertOrIgnore,
          );
        },
        onUpgrade: (m, from, to) async {
          // v1 → v2: routines feature. Add the two routine tables and the
          // nullable `routineId` link on sessions.
          if (from < 2) {
            await m.createTable(routines);
            await m.createTable(routineEntries);
            await m.addColumn(sessions, sessions.routineId);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          // Dedupe AppSettings — earlier builds could land in a state with
          // two rows; downstream code (settingsStreamProvider.watchSingle())
          // throws "Expected exactly one element, but got 2" the moment it
          // observes that state. Keep the lowest rowid, drop the rest.
          await customStatement(
            'DELETE FROM app_settings WHERE rowid NOT IN '
            '(SELECT MIN(rowid) FROM app_settings)',
          );
          await into(appSettings).insert(
            AppSettingsCompanion.insert(id: const Value(1)),
            mode: InsertMode.insertOrIgnore,
          );
        },
      );

  /// Returns the on-disk file path. Used by export to share the raw DB if needed.
  static Future<File> dbFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'peak.sqlite'));
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'peak',
    native: const DriftNativeOptions(
      shareAcrossIsolates: true,
    ),
  );
}
