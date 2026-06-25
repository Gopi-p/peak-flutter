import 'package:drift/drift.dart';

/// Sessions are top-level rows. Entries and Sets live in their own tables and
/// reference the session by id. This is a normalized rewrite of the Mongoose
/// embedded shape — analytics (rollup-by-week, sets-per-muscle) run as
/// indexed SQL rather than iterating documents.
class Sessions extends Table {
  TextColumn get id => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  TextColumn get musclesTrained => text().withDefault(const Constant('[]'))(); // JSON-encoded list
  TextColumn get classification => text().nullable()();
  TextColumn get routineId => text().nullable()(); // routine this session was started from, if any
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ExerciseEntries extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text().references(Sessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class WorkoutSets extends Table {
  TextColumn get id => text()();
  TextColumn get entryId => text().references(ExerciseEntries, #id, onDelete: KeyAction.cascade)();
  TextColumn get sessionId => text().references(Sessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text()();
  RealColumn get weight => real()();
  IntColumn get reps => integer()();
  RealColumn get rpe => real().nullable()();
  BoolColumn get isWarmup => boolean().withDefault(const Constant(false))();
  TextColumn get tags => text().withDefault(const Constant('[]'))(); // JSON-encoded list
  DateTimeColumn get completedAt => dateTime()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class BodyWeights extends Table {
  TextColumn get id => text()();
  RealColumn get kg => real()();
  DateTimeColumn get measuredAt => dateTime()();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 120)();
  TextColumn get type => text()(); // 'lift-target' | 'weekly-sets' | 'bodyweight' | 'frequency'
  RealColumn get targetValue => real()();
  TextColumn get targetUnit => text().withDefault(const Constant(''))();
  TextColumn get exerciseId => text().nullable()();
  TextColumn get muscle => text().nullable()();
  DateTimeColumn get deadline => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PersonalRecords extends Table {
  TextColumn get id => text()();
  TextColumn get exerciseId => text()();
  TextColumn get kind => text()(); // 'weight-for-reps' | 'estimated-1rm'
  RealColumn get weight => real()();
  IntColumn get reps => integer()();
  RealColumn get estimated1Rm => real()();
  DateTimeColumn get achievedAt => dateTime()();
  TextColumn get sessionId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// A saved, reusable workout plan (e.g. "Push", "Pull", "Legs"). Ordered
/// exercises live in [RoutineEntries]. Soft-deleted via `deletedAt`, consistent
/// with sessions / goals.
class Routines extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One ordered slot in a routine. `alternatives` holds a JSON-encoded list of
/// interchangeable exercise ids (e.g. Pec Deck / Cable Fly / Dumbbell Fly) the
/// user can swap to in-session when a machine is taken.
class RoutineEntries extends Table {
  TextColumn get id => text()();
  TextColumn get routineId => text().references(Routines, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text()();
  TextColumn get alternatives => text().withDefault(const Constant('[]'))(); // JSON-encoded list of exercise ids
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AppSettings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get defaultRestSeconds => integer().withDefault(const Constant(90))();
  BoolColumn get rpeEnabled => boolean().withDefault(const Constant(true))();
  TextColumn get unit => text().withDefault(const Constant('kg'))();
  TextColumn get displayName => text().withDefault(const Constant(''))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
