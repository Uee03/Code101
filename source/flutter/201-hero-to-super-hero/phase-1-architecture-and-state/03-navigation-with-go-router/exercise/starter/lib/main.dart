import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

const notes = ['Buy milk', 'Call Sam', 'Plan trip'];

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const NoteListScreen()),
    GoRoute(path: '/secret', builder: (context, state) => const SecretScreen()),
    // TODO 1: add a GoRoute with the path '/note/:index' that builds
    //         NoteScreen(index: ...) using int.parse(state.pathParameters['index']!)
  ],
  // TODO 3: add a redirect that sends the location '/secret' to '/'
  //         (compare state.uri.path; return null for every other location)
);

void main() {
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Router notes',
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
    );
  }
}

class NoteListScreen extends StatelessWidget {
  const NoteListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: ListView(
        children: [
          for (var index = 0; index < notes.length; index++)
            ListTile(
              title: Text(notes[index]),
              // TODO 2: open '/note/$index' with context.push
              onTap: () {},
            ),
          ListTile(
            title: const Text('Open the secret page'),
            onTap: () => context.go('/secret'),
          ),
        ],
      ),
    );
  }
}

class NoteScreen extends StatelessWidget {
  const NoteScreen({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Note ${index + 1}')),
      body: Center(child: Text(notes[index])),
    );
  }
}

class SecretScreen extends StatelessWidget {
  const SecretScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('You should not see this.')));
  }
}
