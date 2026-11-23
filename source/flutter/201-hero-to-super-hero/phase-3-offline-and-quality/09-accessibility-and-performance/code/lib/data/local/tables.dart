import 'package:drift/drift.dart';

@DataClassName('TaskRow')
@TableIndex(name: 'tasks_by_project', columns: {#projectId, #createdAt})
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get projectId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get status => text()();
  TextColumn get priority => text()();
  TextColumn get dueDate => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get syncState => text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// One row per write the server has not accepted yet.
@DataClassName('OutboxRow')
@TableIndex(name: 'outbox_by_state', columns: {#state, #nextAttemptAt})
@TableIndex(name: 'outbox_by_entity', columns: {#entityId, #seq})
class Outbox extends Table {
  // SQLite allows AUTOINCREMENT only on the primary key, so seq is the key
  // and id (the Idempotency-Key) is unique.
  IntColumn get seq => integer().autoIncrement()();
  TextColumn get id => text().unique()();
  TextColumn get kind => text()();
  TextColumn get entityId => text()();
  TextColumn get payload => text()();
  IntColumn get baseVersion => integer().nullable()();
  TextColumn get state => text().withDefault(const Constant('pending'))();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  IntColumn get nextAttemptAt => integer().withDefault(const Constant(0))();
  TextColumn get lastProblemType => text().nullable()();
  IntColumn get createdAt => integer()();
}
