import 'package:dio/dio.dart' show DioException;
import 'package:drift/drift.dart' show Value;

import '../../core/api_problem.dart';
import '../../core/result.dart';
import '../local/database.dart';
import '../models/team.dart';
import '../services/api_service.dart';
import '../services/catalog_local_service.dart';

class TeamRepository {
  TeamRepository(this._api, this._local);

  final ApiService _api;
  final CatalogLocalService _local;

  Stream<List<Team>> watchTeams() {
    return _local.watchTeams().map(
          (rows) => [
            for (final row in rows)
              Team(
                id: row.id,
                name: row.name,
                description: row.description,
                memberCount: row.memberCount,
              ),
          ],
        );
  }

  Future<Result<void>> refresh() async {
    try {
      final page = await _api.listTeams();
      await _local.replaceTeams([
        for (final item in page.items)
          TeamsCompanion.insert(
            id: item.id,
            name: item.name,
            description: Value(item.description),
            memberCount: Value(item.memberCount),
            version: Value(item.version),
          ),
      ]);
      return const Ok(null);
    } on DioException catch (error) {
      return Err(ApiProblem.of(error));
    }
  }
}
