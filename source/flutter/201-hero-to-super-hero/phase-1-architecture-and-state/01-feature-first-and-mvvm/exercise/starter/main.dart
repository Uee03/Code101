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
    // TODO 1: call _service.fetch(), turn each map into a Task and return Ok(list).
    //         When the service throws an Exception, return Err(error) instead.
    return const Ok([]);
  }
}

class SummaryViewModel {
  SummaryViewModel(this._repository);

  final TaskRepository _repository;
  String text = 'not loaded';

  Future<void> load() async {
    final result = await _repository.load();
    // TODO 2: switch on result. For Ok set text to '<open> open of <total>'
    //         (open means not done). For Err set text to 'Error: <error>'.
    text = '$result';
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
