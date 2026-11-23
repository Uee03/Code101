import 'task_dto.dart';

const demoProjectId = 'demo-project';

class FakeTaskService {
  final List<TaskDto> _tasks = [
    TaskDto(
      id: 't1',
      projectId: demoProjectId,
      title: 'Read the Flutter architecture guide',
      description: 'Views, view models, repositories and services.',
      status: 'todo',
      priority: 'high',
      dueDate: null,
      version: 1,
      createdAt: DateTime.utc(2026, 11, 1),
    ),
    TaskDto(
      id: 't2',
      projectId: demoProjectId,
      title: 'Sketch the screens',
      description: '',
      status: 'in_progress',
      priority: 'medium',
      dueDate: '2026-12-01',
      version: 2,
      createdAt: DateTime.utc(2026, 11, 2),
    ),
    TaskDto(
      id: 't3',
      projectId: demoProjectId,
      title: 'Set up the project folders',
      description: '',
      status: 'done',
      priority: 'low',
      dueDate: null,
      version: 3,
      createdAt: DateTime.utc(2026, 11, 3),
    ),
  ];
  int _nextId = 4;

  Future<void> _pause() {
    return Future<void>.delayed(const Duration(milliseconds: 300));
  }

  Future<List<TaskDto>> listTasks(String projectId) async {
    await _pause();
    return [
      for (final task in _tasks)
        if (task.projectId == projectId) task,
    ];
  }

  Future<TaskDto> getTask(String id) async {
    await _pause();
    final found = _tasks.where((task) => task.id == id);
    if (found.isEmpty) {
      throw Exception('Task $id was not found.');
    }
    return found.first;
  }

  Future<TaskDto> createTask(
    String projectId, {
    required String title,
    required String description,
  }) async {
    await _pause();
    final task = TaskDto(
      id: 't${_nextId++}',
      projectId: projectId,
      title: title,
      description: description,
      status: 'todo',
      priority: 'medium',
      dueDate: null,
      version: 1,
      createdAt: DateTime.now().toUtc(),
    );
    _tasks.insert(0, task);
    return task;
  }

  Future<TaskDto> completeTask(String id) async {
    await _pause();
    final index = _tasks.indexWhere((task) => task.id == id);
    if (index == -1) {
      throw Exception('Task $id was not found.');
    }
    final old = _tasks[index];
    final done = TaskDto(
      id: old.id,
      projectId: old.projectId,
      title: old.title,
      description: old.description,
      status: 'done',
      priority: old.priority,
      dueDate: old.dueDate,
      version: old.version + 1,
      createdAt: old.createdAt,
    );
    _tasks[index] = done;
    return done;
  }
}
