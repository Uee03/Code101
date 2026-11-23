import 'package:drift/drift.dart';

import '../local/database.dart';

/// Queries on the teams and projects tables. The server replaces them on every refresh.
class CatalogLocalService {
  CatalogLocalService(this._db);

  final AppDatabase _db;

  Stream<List<TeamRow>> watchTeams() {
    final query = _db.select(_db.teams)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch();
  }

  Future<void> replaceTeams(List<TeamsCompanion> rows) {
    return _db.transaction(() async {
      await _db.delete(_db.teams).go();
      await _db.batch((batch) => batch.insertAll(_db.teams, rows));
    });
  }

  Stream<List<ProjectRow>> watchProjects(String teamId) {
    final query = _db.select(_db.projects)
      ..where((p) => p.teamId.equals(teamId))
      ..orderBy([(p) => OrderingTerm.asc(p.name)]);
    return query.watch();
  }

  Future<void> replaceProjects(String teamId, List<ProjectsCompanion> rows) {
    return _db.transaction(() async {
      await (_db.delete(_db.projects)..where((p) => p.teamId.equals(teamId)))
          .go();
      await _db.batch((batch) => batch.insertAll(_db.projects, rows));
    });
  }
}
