import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/database.dart';
import '../data/exercise_catalog.dart';
import '../data/repositories/bodyweight_repository.dart';
import '../data/repositories/goal_repository.dart';
import '../data/repositories/pr_repository.dart';
import '../data/repositories/session_repository.dart';
import '../data/repositories/settings_repository.dart';

/// Singleton Drift database for the app's lifetime.
final databaseProvider = Provider<PeakDatabase>((ref) {
  final db = PeakDatabase();
  ref.onDispose(db.close);
  return db;
});

final exerciseCatalogProvider = FutureProvider<ExerciseCatalog>((ref) async {
  return ExerciseCatalog.load();
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final catalogAsync = ref.watch(exerciseCatalogProvider);
  // catalog is awaited at startup before the app paints UI, so this should be ready.
  final catalog = catalogAsync.requireValue;
  return SessionRepository(db, catalog);
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(databaseProvider));
});

final bodyWeightRepositoryProvider = Provider<BodyWeightRepository>((ref) {
  return BodyWeightRepository(ref.watch(databaseProvider));
});

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository(ref.watch(databaseProvider));
});

final prRepositoryProvider = Provider<PrRepository>((ref) {
  return PrRepository(ref.watch(databaseProvider));
});

final settingsStreamProvider = StreamProvider<AppSetting>((ref) {
  return ref.watch(settingsRepositoryProvider).watch();
});

final activeSessionProvider = FutureProvider.autoDispose<Session?>((ref) {
  return ref.watch(sessionRepositoryProvider).activeSession();
});
