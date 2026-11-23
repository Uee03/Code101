import 'package:material_ui/material_ui.dart';

import '../data/repositories/task_repository.dart';
import '../data/services/fake_task_service.dart';
import '../features/tasks/view/tasks_screen.dart';
import '../features/tasks/view_model/tasks_view_model.dart';

class TasksApp extends StatefulWidget {
  const TasksApp({super.key});

  @override
  State<TasksApp> createState() => _TasksAppState();
}

class _TasksAppState extends State<TasksApp> {
  late final TasksViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    final repository = TaskRepository(FakeTaskService());
    _viewModel = TasksViewModel(
      repository: repository,
      projectId: demoProjectId,
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tasks and Teams',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff17467c)),
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
      home: TasksScreen(viewModel: _viewModel),
    );
  }
}
