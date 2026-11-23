import 'package:dio/dio.dart';

import '../generated/tasks_api.dart' as dto;

/// The only file that knows the generated client. It returns generated DTOs.
class ApiService {
  ApiService(this._dio) : _api = dto.TasksApi(_dio);

  final Dio _dio;
  final dto.TasksApi _api;

  Future<dto.Health> health() => _api.platform.getHealth();

  Future<dto.TeamPage$Response> listTeams() {
    return _api.teams.listTeams(limit: 25);
  }

  Future<dto.ProjectPage$Response> listProjects(String teamId) {
    return _api.projects.listProjects(teamId: teamId, limit: 25);
  }

  Future<dto.TaskPage$Response> listTasks(String projectId, {String? cursor}) {
    return _api.tasks.listTasks(
      projectId: projectId,
      limit: 25,
      cursor: cursor,
      sort: dto.ListTasksSort.createdAt,
    );
  }

  Future<dto.Task$Response> getTask(String taskId) {
    return _api.tasks.getTask(taskId: taskId);
  }

  /// [body] holds title, description, priority and dueDate (never projectId).
  Future<dto.Task$Response> createTask(
    String projectId, {
    required Map<String, Object?> body,
    required String idempotencyKey,
  }) {
    return _api.tasks.createTask(
      projectId: projectId,
      idempotencyKey: idempotencyKey,
      body: dto.TaskCreate.fromJson(body),
    );
  }

  /// A JSON Merge Patch. The generated TaskUpdate class cannot tell "absent" from
  /// "null", and null is how a client clears the due date, so this one request is hand-written.
  /// [version] is the version the person edited; the server answers 412 if it moved on.
  Future<dto.Task$Response> updateTask(
    String taskId,
    int version,
    Map<String, Object?> patch,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/v1/tasks/${Uri.encodeComponent(taskId)}',
      data: patch,
      options: Options(
        contentType: 'application/merge-patch+json',
        headers: {'If-Match': '"$version"'},
      ),
    );
    return dto.Task$Response.fromJson(response.data!);
  }

  Future<dto.Task$Response> completeTask(String taskId, int version) {
    return _api.tasks.completeTask(taskId: taskId, ifMatch: '"$version"');
  }

  void close() => _dio.close();
}
