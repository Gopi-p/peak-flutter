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
])
class PeakDatabase extends _$PeakDatabase {
  PeakDatabase() : super(_openConnection());

  PeakDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Seed singleton settings row.
          await into(appSettings).insert(
            AppSettingsCompanion.insert(),
            mode: InsertMode.insertOrIgnore,
          );
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await into(appSettings).insert(
            AppSettingsCompanion.insert(),
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
