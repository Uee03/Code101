import 'package:dio/dio.dart';

import '../generated/tasks_api.dart' as dto;

/// The only file that knows the generated client. It returns generated DTOs.
class ApiService {
  ApiService(this._dio) : _api = dto.TasksApi(_dio);

  final Dio _dio;
  final dto.TasksApi _api;

  Future<dto.Health> health() => _api.platform.getHealth();

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

  Future<dto.Task$Response> createTask(
    String projectId, {
    required String title,
    required String description,
    required String idempotencyKey,
  }) {
    return _api.tasks.createTask(
      projectId: projectId,
      idempotencyKey: idempotencyKey,
      body: dto.TaskCreate(title: title, description: description),
    );
  }

  Future<dto.Task$Response> completeTask(String taskId, int version) {
    return _api.tasks.completeTask(taskId: taskId, ifMatch: '"$version"');
  }

  void close() => _dio.close();
}
