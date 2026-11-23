import 'package:material_ui/material_ui.dart';

class TaskComposer extends StatefulWidget {
  const TaskComposer({super.key, required this.onSubmit});

  final Future<void> Function(String title) onSubmit;

  @override
  State<TaskComposer> createState() => _TaskComposerState();
}

class _TaskComposerState extends State<TaskComposer> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _controller.text.trim();
    if (title.isEmpty) {
      setState(() {
        _error = 'Enter a title';
      });
      return;
    }
    setState(() {
      _error = null;
    });
    await widget.onSubmit(title);
    if (!mounted) {
      return;
    }
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'New task',
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(onPressed: _submit, child: const Text('Add')),
        ],
      ),
    );
  }
}
