import 'dart:async';
import 'dart:math';

import 'package:material_ui/material_ui.dart';

import 'art_icon.dart';
import 'task.dart';
import 'task_edit_screen.dart';
import 'task_store.dart';

enum TaskFilter { all, open, done }

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _store = TaskStore();
  final List<Task> _tasks = [];
  TaskFilter _filter = TaskFilter.all;
  int _nextId = 1;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final saved = await _store.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _tasks.addAll(saved);
      for (final task in saved) {
        if (task.id >= _nextId) {
          _nextId = task.id + 1;
        }
      }
      _loaded = true;
    });
  }

  void _save() {
    unawaited(_store.save(List.of(_tasks)));
  }

  List<Task> get _visible {
    switch (_filter) {
      case TaskFilter.all:
        return _tasks;
      case TaskFilter.open:
        return [
          for (final task in _tasks)
            if (!task.done) task,
        ];
      case TaskFilter.done:
        return [
          for (final task in _tasks)
            if (task.done) task,
        ];
    }
  }

  Future<void> _openEditor({Task? task}) async {
    final result = await Navigator.of(context).push<Task>(
      MaterialPageRoute(
        builder: (context) => TaskEditScreen(task: task, nextId: _nextId),
      ),
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() {
      final index = _tasks.indexWhere((item) => item.id == result.id);
      if (index == -1) {
        _tasks.add(result);
        _nextId = result.id + 1;
      } else {
        _tasks[index] = result;
      }
    });
    _save();
  }

  void _setDone(Task task, bool done) {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) {
      return;
    }
    setState(() {
      _tasks[index] = task.copyWith(done: done);
    });
    _save();
  }

  void _delete(Task task) {
    final index = _tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) {
      return;
    }
    setState(() {
      _tasks.removeAt(index);
    });
    _save();
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Deleted "${task.title}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              _tasks.insert(min(index, _tasks.length), task);
            });
            _save();
          },
        ),
      ),
    );
  }

  String _priorityLabel(Priority priority) {
    switch (priority) {
      case Priority.low:
        return 'Low';
      case Priority.normal:
        return 'Normal';
      case Priority.high:
        return 'High';
    }
  }

  Widget _buildEmpty(ColorScheme colors) {
    final allDone = _filter == TaskFilter.open && _tasks.isNotEmpty;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ArtIcon(
            allDone ? 'check-circle' : 'list',
            size: 48,
            color: colors.outline,
          ),
          const SizedBox(height: 8),
          Text(allDone ? 'Everything is done.' : 'No tasks here yet.'),
        ],
      ),
    );
  }

  Widget _buildTile(Task task, ColorScheme colors) {
    final subtitle = task.notes.isEmpty
        ? 'Priority: ${_priorityLabel(task.priority)}'
        : 'Priority: ${_priorityLabel(task.priority)} - ${task.notes}';
    return ListTile(
      leading: Checkbox(
        value: task.done,
        semanticLabel: 'Done: ${task.title}',
        onChanged: (value) => _setDone(task, value ?? false),
      ),
      title: Text(
        task.title,
        style: TextStyle(
          decoration:
              task.done ? TextDecoration.lineThrough : TextDecoration.none,
        ),
      ),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: IconButton(
        tooltip: 'Delete ${task.title}',
        onPressed: () => _delete(task),
        icon: ArtIcon('trash', color: colors.onSurfaceVariant),
      ),
      onTap: () => _openEditor(task: task),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final openCount = _tasks.where((task) => !task.done).length;
    final visible = _visible;
    return Scaffold(
      appBar: AppBar(
        title: Text('Tasks ($openCount open)'),
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const ArtIcon('plus'),
        label: const Text('New task'),
      ),
      body: SafeArea(
        child: !_loaded
            ? const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Loading your tasks',
                ),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SegmentedButton<TaskFilter>(
                          segments: const [
                            ButtonSegment(
                              value: TaskFilter.all,
                              label: Text('All'),
                            ),
                            ButtonSegment(
                              value: TaskFilter.open,
                              label: Text('Open'),
                            ),
                            ButtonSegment(
                              value: TaskFilter.done,
                              label: Text('Done'),
                            ),
                          ],
                          selected: {_filter},
                          onSelectionChanged: (selection) {
                            setState(() {
                              _filter = selection.first;
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: visible.isEmpty
                            ? _buildEmpty(colors)
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 88),
                                itemCount: visible.length,
                                itemBuilder: (context, index) {
                                  return _buildTile(visible[index], colors);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
