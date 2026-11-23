import 'package:material_ui/material_ui.dart';

import '../data/services/fake_task_service.dart';
import '../features/tasks/view/tasks_screen.dart';

class TasksApp extends StatelessWidget {
  const TasksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tasks and Teams',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff17467c)),
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
      home: const TasksScreen(projectId: demoProjectId),
    );
  }
}
