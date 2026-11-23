import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick notes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
      ),
      home: const NotesScreen(),
    );
  }
}

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final List<String> _notes = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Write something';
    }
    if (text.length > 40) {
      return 'Keep it under 40 characters';
    }
    return null;
  }

  void _addNote() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _notes.add(_controller.text.trim());
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quick notes (${_notes.length})')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                ),
                validator: _validate,
                onFieldSubmitted: (_) => _addNote(),
              ),
            ),
          ),
          FilledButton(onPressed: _addNote, child: const Text('Add note')),
          Expanded(
            child: _notes.isEmpty
                ? const Center(child: Text('No notes yet.'))
                : ListView.builder(
                    itemCount: _notes.length,
                    itemBuilder: (context, index) {
                      return ListTile(title: Text(_notes[index]));
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
