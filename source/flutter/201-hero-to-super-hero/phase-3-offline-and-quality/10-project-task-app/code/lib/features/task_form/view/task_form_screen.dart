import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../../core/problem_messages.dart';
import '../../../data/models/task.dart';
import '../../../data/models/task_draft.dart';
import '../../task_detail/view_model/task_detail_view_model.dart';
import '../view_model/task_form_view_model.dart';
import '../view_model/task_validation.dart';

/// One screen for both jobs: pass [projectId] to create a task, or [taskId] to edit one.
class TaskFormScreen extends ConsumerWidget {
  const TaskFormScreen({super.key, this.projectId, this.taskId})
      : assert(
          (projectId == null) != (taskId == null),
          'Pass either projectId or taskId',
        );

  final String? projectId;
  final String? taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = taskId;
    if (id == null) {
      return _TaskForm(projectId: projectId!);
    }
    final task = ref.watch(taskDetailProvider(id));
    return task.when(
      loading: () => const _Frame(
        title: 'Edit task',
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => const _Frame(
        title: 'Edit task',
        child: Center(child: Text('The saved task could not be read.')),
      ),
      data: (item) {
        if (item == null) {
          return const _Frame(
            title: 'Edit task',
            child: Center(child: Text('That task is not available.')),
          );
        }
        return _TaskForm(projectId: item.projectId, original: item);
      },
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(title)), body: child);
  }
}

class _TaskForm extends ConsumerStatefulWidget {
  const _TaskForm({required this.projectId, this.original});

  final String projectId;
  final Task? original;

  @override
  ConsumerState<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends ConsumerState<_TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _dueDate;
  late TaskPriority _priority;

  // Taken once, when the form opens. A task that changes on the server or in the
  // database while the person types does not move the version we send in If-Match.
  late final Task? _original;
  late final String _requestId;
  bool _busy = false;
  String? _failure;

  @override
  void initState() {
    super.initState();
    final original = widget.original;
    _original = original;
    final start = original == null ? null : TaskDraft.fromTask(original);
    _title = TextEditingController(text: start?.title ?? '');
    _description = TextEditingController(text: start?.description ?? '');
    _dueDate = TextEditingController(text: start?.dueDate ?? '');
    _priority = start?.priority ?? TaskPriority.medium;
    _requestId = const Uuid().v4();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _dueDate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final due = _dueDate.text.trim();
    final draft = TaskDraft(
      title: _title.text.trim(),
      description: _description.text,
      priority: _priority,
      dueDate: due.isEmpty ? null : due,
    );
    setState(() {
      _busy = true;
      _failure = null;
    });
    final viewModel = ref.read(taskFormViewModelProvider);
    final original = _original;
    final failure = original == null
        ? await viewModel.create(
            widget.projectId,
            draft,
            requestId: _requestId,
          )
        : await viewModel.update(original, draft);
    if (!mounted) {
      return;
    }
    if (failure == null) {
      context.pop();
      return;
    }
    setState(() {
      _busy = false;
      _failure = describeError(failure);
    });
  }

  static String _label(TaskPriority priority) {
    final name = priority.name;
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final original = _original;
    return _Frame(
      title: original == null ? 'New task' : 'Edit task',
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (original != null) ...[
              Text(
                'You are editing version ${original.version}. If someone else '
                'saves first, the sync queue asks what to do.',
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: validateTitle,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              minLines: 3,
              maxLines: 8,
              validator: validateDescription,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dueDate,
              decoration: const InputDecoration(
                labelText: 'Due date (yyyy-MM-dd, empty for none)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.datetime,
              validator: validateDueDate,
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: Text(
                'Priority',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final priority in TaskPriority.values)
                  ChoiceChip(
                    label: Text(_label(priority)),
                    selected: priority == _priority,
                    onSelected: (_) => setState(() => _priority = priority),
                  ),
              ],
            ),
            if (_failure != null) ...[
              const SizedBox(height: 16),
              Semantics(liveRegion: true, child: Text(_failure!)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: _busy ? null : _save,
              child: Text(_busy ? 'Saving...' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
