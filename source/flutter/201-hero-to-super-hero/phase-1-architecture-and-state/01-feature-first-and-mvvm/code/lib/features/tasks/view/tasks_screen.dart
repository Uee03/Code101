import 'package:material_ui/material_ui.dart';

import '../../../data/models/task.dart';
import '../view_model/tasks_view_model.dart';
import 'task_composer.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.viewModel});

  final TasksViewModel viewModel;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  void _showMessage(String? message) {
    if (message == null || !mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _add(String title) async {
    _showMessage(await widget.viewModel.add(title));
  }

  Future<void> _complete(Task task) async {
    _showMessage(await widget.viewModel.complete(task));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: Column(
        children: [
          TaskComposer(onSubmit: _add),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.viewModel,
              builder: (context, _) => _buildBody(widget.viewModel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(TasksViewModel viewModel) {
    if (viewModel.loading && viewModel.tasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (viewModel.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(viewModel.error!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: viewModel.load,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }
    if (viewModel.tasks.isEmpty) {
      return const Center(child: Text('No tasks yet.'));
    }
    return ListView.builder(
      itemCount: viewModel.tasks.length,
      itemBuilder: (context, index) {
        final task = viewModel.tasks[index];
        return ListTile(
          title: Text(task.title),
          subtitle: Text(task.status.label),
          trailing: task.isDone
              ? null
              : TextButton(
                  onPressed: () => _complete(task),
                  child: const Text('Complete'),
                ),
        );
      },
    );
  }
}
