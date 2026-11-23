import 'package:dio/dio.dart' show DioException;
import 'package:drift/drift.dart' show Value;

import '../../core/api_problem.dart';
import '../../core/result.dart';
import '../local/database.dart';
import '../models/project.dart';
import '../services/api_service.dart';
import '../services/catalog_local_service.dart';

class ProjectRepository {
  ProjectRepository(this._api, this._local);

  final ApiService _api;
  final CatalogLocalService _local;

  Stream<List<Project>> watchProjects(String teamId) {
    return _local.watchProjects(teamId).map(
          (rows) => [
            for (final row in rows)
              Project(
                id: row.id,
                teamId: row.teamId,
                key: row.key,
                name: row.name,
                description: row.description,
                archived: row.archived,
              ),
          ],
        );
  }

  Future<Result<void>> refresh(String teamId) async {
    try {
      final page = await _api.listProjects(teamId);
      await _local.replaceProjects(teamId, [
        for (final item in page.items)
          ProjectsCompanion.insert(
            id: item.id,
            teamId: item.teamId,
            key: item.key,
            name: item.name,
            description: Value(item.description),
            archived: Value(item.archived),
            version: Value(item.version),
          ),
      ]);
      return const Ok(null);
    } on DioException catch (error) {
      return Err(ApiProblem.of(error));
    }
  }
}
