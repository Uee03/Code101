import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Tasks, Outbox])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'tasksteams'));

  @override
  int get schemaVersion => 2;

  /// Numbered steps: a phone that has version 1 runs only the steps after it.
  /// Never edit a step that has shipped; add a new one.
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (migrator) => migrator.createAll(),
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          await migrator.createTable(outbox);
          await migrator.createIndex(outboxByState);
          await migrator.createIndex(outboxByEntity);
        }
      },
    );
  }

  /// Deletes every row of every table, in one transaction.
  Future<void> clearAll() {
    return transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }
}
