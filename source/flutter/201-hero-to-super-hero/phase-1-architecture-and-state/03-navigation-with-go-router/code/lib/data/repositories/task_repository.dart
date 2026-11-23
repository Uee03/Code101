import '../../core/result.dart';
import '../models/task.dart';
import '../services/fake_task_service.dart';
import '../services/task_dto.dart';

class TaskRepository {
  TaskRepository(this._service);

  final FakeTaskService _service;

  Future<Result<List<Task>>> loadTasks(String projectId) async {
    try {
      final dtos = await _service.listTasks(projectId);
      return Ok([for (final dto in dtos) _toTask(dto)]);
    } on Exception catch (error) {
      return Err(error);
    }
  }

  Future<Result<Task>> getTask(String id) async {
    try {
      return Ok(_toTask(await _service.getTask(id)));
    } on Exception catch (error) {
      return Err(error);
    }
  }

  Future<Result<Task>> createTask(
    String projectId, {
    required String title,
    String description = '',
  }) async {
    try {
      final dto = await _service.createTask(
        projectId,
        title: title,
        description: description,
      );
      return Ok(_toTask(dto));
    } on Exception catch (error) {
      return Err(error);
    }
  }

  Future<Result<Task>> completeTask(Task task) async {
    try {
      return Ok(_toTask(await _service.completeTask(task.id)));
    } on Exception catch (error) {
      return Err(error);
    }
  }

  Task _toTask(TaskDto dto) {
    return Task(
      id: dto.id,
      projectId: dto.projectId,
      title: dto.title,
      description: dto.description,
      status: TaskStatus.fromWire(dto.status),
      priority: TaskPriority.fromWire(dto.priority),
      dueDate: dto.dueDate,
      version: dto.version,
      createdAt: dto.createdAt,
    );
  }
}
