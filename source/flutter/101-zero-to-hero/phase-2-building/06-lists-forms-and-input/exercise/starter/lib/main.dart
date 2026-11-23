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
    // TODO 1: return 'Write something' when the value is null or empty after trim(),
    //         and 'Keep it under 40 characters' when it is longer than 40; otherwise null
    return null;
  }

  void _addNote() {
    // TODO 2: stop when the form is not valid, then add the trimmed text to _notes
    //         inside setState and clear the controller
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
            // TODO 3: show a ListView.builder of ListTile widgets with the note text,
            //         or the text 'No notes yet.' when the list is empty
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
