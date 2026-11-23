// Lesson 03: collections, classes and async. Run with: dart run main.dart

enum Priority { low, normal, high }

class Task {
  Task(this.title, {this.priority = Priority.normal, this.done = false});

  final String title;
  final Priority priority;
  bool done;

  void complete() {
    done = true;
  }

  @override
  String toString() => '${done ? '[x]' : '[ ]'} $title (${priority.name})';
}

Future<String> fetchTitle(int id) async {
  await Future.delayed(const Duration(milliseconds: 100));
  if (id < 0) {
    throw ArgumentError('id must be positive');
  }
  return 'Task #$id';
}

Future<void> main() async {
  // Lists
  final titles = ['Buy milk', 'Write notes', 'Call Sam'];
  titles.add('Plan trip');
  print('First: ${titles.first}, count: ${titles.length}');
  print(titles);

  // Maps and sets
  final points = {'Ana': 3, 'Ben': 5};
  points['Cy'] = 2;
  points.forEach((name, score) {
    print('$name has $score');
  });
  final tags = {'home', 'work', 'home'};
  print('Distinct tags: ${tags.length}');

  // Classes
  final tasks = [
    Task('Buy milk'),
    Task('Write notes', priority: Priority.high),
    Task('Call Sam'),
  ];
  tasks[0].complete();
  for (final task in tasks) {
    print(task);
  }
  final open = tasks.where((task) => !task.done).toList();
  print('Open tasks: ${open.length}');
  final names = tasks.map((task) => task.title.toUpperCase()).toList();
  print(names);
  tasks.sort((a, b) => b.priority.index.compareTo(a.priority.index));
  print('Most urgent: ${tasks.first}');

  // Async
  print('Loading...');
  final title = await fetchTitle(7);
  print(title);
  try {
    await fetchTitle(-1);
  } catch (error) {
    print('Failed: $error');
  }
  final results = await Future.wait([fetchTitle(1), fetchTitle(2)]);
  print(results);
  print('Done');
}
