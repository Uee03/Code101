// Exercise 01: layers without Flutter. Run with: dart run main.dart

sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.error);

  final Object error;
}

class Task {
  const Task({required this.id, required this.title, required this.done});

  final String id;
  final String title;
  final bool done;
}

class FakeService {
  FakeService({this.fail = false});

  final bool fail;

  Future<List<Map<String, Object?>>> fetch() async {
    if (fail) {
      throw Exception('service unavailable');
    }
    return [
      {'id': 'a', 'title': 'Write notes', 'done': true},
      {'id': 'b', 'title': 'Call Sam', 'done': false},
      {'id': 'c', 'title': 'Plan trip', 'done': false},
    ];
  }
}

class TaskRepository {
  TaskRepository(this._service);

  final FakeService _service;

  Future<Result<List<Task>>> load() async {
    try {
      final rows = await _service.fetch();
      return Ok([
        for (final row in rows)
          Task(
            id: row['id'] as String,
            title: row['title'] as String,
            done: row['done'] as bool,
          ),
      ]);
    } on Exception catch (error) {
      return Err(error);
    }
  }
}

class SummaryViewModel {
  SummaryViewModel(this._repository);

  final TaskRepository _repository;
  String text = 'not loaded';

  Future<void> load() async {
    final result = await _repository.load();
    switch (result) {
      case Ok(value: final tasks):
        final open = tasks.where((task) => !task.done).length;
        text = '$open open of ${tasks.length}';
      case Err(error: final failure):
        text = 'Error: $failure';
    }
  }
}

Future<void> main() async {
  final good = SummaryViewModel(TaskRepository(FakeService()));
  await good.load();
  print(good.text);
  final bad = SummaryViewModel(TaskRepository(FakeService(fail: true)));
  await bad.load();
  print(bad.text);
}
