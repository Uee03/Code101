---
track: flutter
level: 101
phase: 3
phase_name: data-and-polish
lesson: "09"
title: "HTTP and JSON"
time: "75-90 min"
prerequisites: ["flutter-101-03", "flutter-101-05"]
versions: { flutter: "3.50.1", dart: "3.14.0", material_ui: "1.11.1", http: "1.6.0" }
verified: not yet run
source: source/flutter/101-zero-to-hero/phase-3-data-and-polish/09-http-and-json/
assets: []
---

# 09. HTTP and JSON

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Explain what an HTTP request, a status code and JSON are.
- Fetch a list from a web address with the `http` package and turn the JSON into Dart objects.
- Show three states on screen: loading, error with a retry button, and data.
- Allow internet access for an Android app in `AndroidManifest.xml`.

## Recap
1. What does `await` do? <details><summary>Answer</summary>It pauses the current async function until a `Future` completes.</details>
2. Why check `mounted` after an `await` in a State class? <details><summary>Answer</summary>The screen may be gone; calling `setState` then is a bug.</details>

## Why it matters
Ordering at a restaurant: you (the app, the **client**) send an order to the kitchen (the **server**) and later get a plate (the **response**). **HTTP** is the language of that conversation on the web. The response often arrives as **JSON**, a plain-text format for lists and records. Most apps load their data this way.

## What you will build
A screen that loads ten sample todos from a free public test server (`jsonplaceholder.typicode.com`), shows a spinner while waiting, a message with **Try again** when it fails, and pull-to-refresh when it works.

## Before you start
- Lessons 03 (async), 05 (state) and 06 (lists) finished.
- Internet access. The sample server is a third-party test service and may change or be slow; the lesson works the same with any JSON list.
- Time: 75-90 minutes. Five ideas: HTTP request and status code, JSON, a model's `fromJson`, three screen states, the Android internet permission.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/flutter/101-zero-to-hero/phase-3-data-and-polish/09-http-and-json/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).

## Steps
### Step 1. Create the project
**File: `terminal (Windows PowerShell)`**
```powershell
Set-Location "$HOME\code101\flutter101"
flutter create --platforms=android todo_http
Set-Location todo_http
Remove-Item -Recurse -Force test
```

**File: `terminal (macOS or Linux)`**
```bash
cd ~/code101/flutter101
flutter create --platforms=android todo_http
cd todo_http
rm -rf test
```

### Step 2. Replace `pubspec.yaml`, then run `flutter pub get`
The new package is `http`, the standard Dart package for web requests.

**File: `pubspec.yaml`**
```yaml
name: todo_http
description: Loading JSON over HTTP for Code101.
publish_to: none
version: 1.0.0+1

environment:
  sdk: ^3.14.0

dependencies:
  flutter:
    sdk: flutter
  material_ui: 1.11.1
  http: 1.6.0

dev_dependencies:
  flutter_lints: 6.0.0

flutter:
  uses-material-design: true
```

### Step 3. Allow internet access on Android
Android apps may only use the network if the manifest says so. Flutter's debug builds add this permission automatically, which is why a debug run works even without it; a **release** build (the one you would publish) would silently have no internet. So add it now. Open `android/app/src/main/AndroidManifest.xml`, select everything and replace it. The only line added to the generated file is `uses-permission ... INTERNET`; `android:label` is the name under the app icon.

**File: `android/app/src/main/AndroidManifest.xml`**
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <application
        android:label="Todo HTTP"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
    <queries>
        <intent>
            <action android:name="android.intent.action.PROCESS_TEXT" />
            <data android:mimeType="text/plain" />
        </intent>
    </queries>
</manifest>
```

### Step 4. The model
A **model** class describes one record of the server's answer. `fromJson` is a **factory constructor**: a constructor that builds an object from other data. `json['id'] as int` reads the field named `id` and tells Dart it is an `int`.

**File: `lib/todo.dart`**
```dart
class Todo {
  const Todo({
    required this.id,
    required this.title,
    required this.completed,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as int,
      title: json['title'] as String,
      completed: json['completed'] as bool,
    );
  }

  final int id;
  final String title;
  final bool completed;
}
```

### Step 5. The API class
Putting network code in its own class keeps the screen free of HTTP details.

**File: `lib/todo_api.dart`**
```dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'todo.dart';

class TodoApiException implements Exception {
  const TodoApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TodoApi {
  TodoApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Todo>> fetchTodos({int limit = 10}) async {
    final uri = Uri.https(
      'jsonplaceholder.typicode.com',
      '/todos',
      {'_limit': '$limit'},
    );
    final response = await _client.get(uri).timeout(
          const Duration(seconds: 10),
        );
    if (response.statusCode != 200) {
      throw TodoApiException('The server answered ${response.statusCode}.');
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return [
      for (final entry in data) Todo.fromJson(entry as Map<String, dynamic>),
    ];
  }

  void close() => _client.close();
}
```

### Step 6. The screen
**File: `lib/main.dart`**
```dart
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import 'todo.dart';
import 'todo_api.dart';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo HTTP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final _api = TodoApi();
  List<Todo> _todos = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    String? error;
    List<Todo> todos = _todos;
    try {
      todos = await _api.fetchTodos();
    } on TodoApiException catch (e) {
      error = e.message;
    } on TimeoutException {
      error = 'The server took too long. Try again.';
    } on http.ClientException {
      error = 'No connection. Check your internet and try again.';
    } on FormatException {
      error = 'The answer was not valid data.';
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _todos = todos;
      _error = error;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todos from the internet')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        itemCount: _todos.length,
        itemBuilder: (context, index) {
          final todo = _todos[index];
          return ListTile(
            title: Text(todo.title),
            subtitle: Text(todo.completed ? 'Done' : 'Open'),
          );
        },
      ),
    );
  }
}
```

## Run it
**File: `terminal (folder todo_http)`**
```text
flutter run
```
Expected behaviour (described from the code, not yet seen): a spinner for a moment, then ten rows. Each row shows a todo title in Latin-looking sample text and `Done` or `Open` below it. The server's first todo is usually titled "delectus aut autem" and open; the data belongs to the test server and may change. Pull down to reload.

Test the error path: switch the emulator or phone to flight mode, then pull down or restart the app. You should see a message such as "No connection. Check your internet and try again." and a **Try again** button.

## How it works
**HTTP.** A request has a **method** (`GET` means "give me this"), an address (**URL**) and a response with a **status code**: 200 means success, 404 "not found", 500 "the server broke". We only accept 200 and turn everything else into a `TodoApiException`.

**`Uri.https(host, path, queryParameters)`** builds a safe web address. `{'_limit': '10'}` becomes `?_limit=10`, which this server understands as "at most ten".

**JSON.** The answer body is text like `[{"id": 1, "title": "...", "completed": false}, ...]`. `jsonDecode` turns it into Dart lists and maps. We then convert each map to a `Todo` with `Todo.fromJson`. Keeping typed models instead of raw maps lets the analyzer catch typos like `todo.titel`.

**Timeouts and failures.** `.timeout(Duration(seconds: 10))` stops waiting after ten seconds with a `TimeoutException`. `http.ClientException` means the network failed (no internet, unknown host). `FormatException` means the text was not valid JSON. Each gets a human message; users should never see a stack trace.

**Three states.** `_loading`, `_error` and `_todos` are the whole state of the screen. `_buildBody` shows exactly one of: spinner, error with retry, list. Every screen that loads data needs these states; forgetting the error state is the classic beginner gap.

**`RefreshIndicator`** wraps the list and calls `_load` on pull-down. **`initState`** starts the first load. **`dispose`** closes the HTTP client so connections are released.

**Security note.** Always use `https://` for real data. Plain `http://` is blocked by default on Android 9 and newer apps, and nothing secret should be sent unencrypted.

Common misconception: "The JSON gives me ready Dart objects." It gives text; you decide how to turn it into typed objects, and the server can send surprises (a missing field, a different type), which is why we catch errors.

## Try it
Make a project `try09` as in Step 1 (use this lesson's `pubspec.yaml`, change `name:` to `try09`) and use the starter. It parses a built-in JSON text, so it works offline. The manifest edit is not needed for it.

**File: `exercise/starter/lib/main.dart`**
```dart
import 'dart:convert';

import 'package:material_ui/material_ui.dart';

// A pretend server answer, so this exercise works without internet.
const String bookJson = '''
[
  {"id": 1, "title": "The Little Prince", "pages": 96, "read": true},
  {"id": 2, "title": "Dune", "pages": 612, "read": false},
  {"id": 3, "title": "Emma", "pages": 474, "read": false}
]
''';

class Book {
  const Book({
    required this.id,
    required this.title,
    required this.pages,
    required this.read,
  });

  // TODO 1: add a factory constructor Book.fromJson(Map<String, dynamic> json)
  //         that reads id, title, pages and read with the right casts

  final int id;
  final String title;
  final int pages;
  final bool read;
}

List<Book> parseBooks(String source) {
  // TODO 2: decode the text with jsonDecode, cast it to List<dynamic>
  //         and turn every entry into a Book
  return [];
}

void main() {
  runApp(const BookApp());
}

class BookApp extends StatelessWidget {
  const BookApp({super.key});

  @override
  Widget build(BuildContext context) {
    final books = parseBooks(bookJson);
    return MaterialApp(
      title: 'Books',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
      ),
      home: Scaffold(
        appBar: AppBar(title: Text('Books (${books.length})')),
        body: ListView(
          children: [
            for (final book in books)
              ListTile(
                title: Text(book.title),
                // TODO 3: show '<pages> pages, read' or '<pages> pages, not read yet'
                subtitle: const Text(''),
              ),
          ],
        ),
      ),
    );
  }
}
```

1. **Guided:** complete the three TODOs. The app bar should say "Books (3)" and the rows show "96 pages, read", "612 pages, not read yet", "474 pages, not read yet".
2. **Change:** show only unread books.
3. **Stretch (optional):** what should `parseBooks` do when the JSON text is broken? Decide, and show a message instead of crashing.

<details><summary>Solution</summary>

**File: `exercise/solution/lib/main.dart`**
```dart
import 'dart:convert';

import 'package:material_ui/material_ui.dart';

// A pretend server answer, so this exercise works without internet.
const String bookJson = '''
[
  {"id": 1, "title": "The Little Prince", "pages": 96, "read": true},
  {"id": 2, "title": "Dune", "pages": 612, "read": false},
  {"id": 3, "title": "Emma", "pages": 474, "read": false}
]
''';

class Book {
  const Book({
    required this.id,
    required this.title,
    required this.pages,
    required this.read,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as int,
      title: json['title'] as String,
      pages: json['pages'] as int,
      read: json['read'] as bool,
    );
  }

  final int id;
  final String title;
  final int pages;
  final bool read;
}

List<Book> parseBooks(String source) {
  final data = jsonDecode(source) as List<dynamic>;
  return [
    for (final entry in data) Book.fromJson(entry as Map<String, dynamic>),
  ];
}

void main() {
  runApp(const BookApp());
}

class BookApp extends StatelessWidget {
  const BookApp({super.key});

  @override
  Widget build(BuildContext context) {
    final books = parseBooks(bookJson);
    return MaterialApp(
      title: 'Books',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
      ),
      home: Scaffold(
        appBar: AppBar(title: Text('Books (${books.length})')),
        body: ListView(
          children: [
            for (final book in books)
              ListTile(
                title: Text(book.title),
                subtitle: Text(
                  book.read
                      ? '${book.pages} pages, read'
                      : '${book.pages} pages, not read yet',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

`entry as Map<String, dynamic>` tells Dart each list entry is a record with text keys.

</details>

## Check yourself
1. What does status code 404 mean? <details><summary>Answer</summary>The server could not find what you asked for.</details>
2. Why is network code in `TodoApi` and not in the widget? <details><summary>Answer</summary>The widget stays about drawing; the data code can change without touching it.</details>
3. The app works in debug but shows no data in a release build. Likely cause? <details><summary>Answer</summary>The `INTERNET` permission is missing from the main manifest.</details>
4. Predict: what shows on screen when the server answers 500? <details><summary>Answer</summary>"The server answered 500." with a **Try again** button.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Failed host lookup: 'jsonplaceholder.typicode.com'` (typical message) | No internet on the emulator or phone | Check the device's connection, then **Try again** |
| `type 'String' is not a subtype of type 'int' in type cast` (typical message) | The JSON field has another type than the cast | Read the real JSON and fix the model |
| `Unhandled Exception: SocketException ...` (typical wording) | An error type that is not caught | Catch it, or add the matching `on` clause |
| App shows nothing in a release build | `INTERNET` permission missing | Add it in `AndroidManifest.xml` as in Step 3 |
| `Target of URI doesn't exist: 'package:http/http.dart'.` (typical message) | `http` not in `pubspec.yaml`, or `flutter pub get` not run | Add it and run `flutter pub get` |

## Best practice
Treat every network call as something that can be slow, wrong or absent, and design all three screen states. Source: [Flutter: Fetch data from the internet](https://docs.flutter.dev/cookbook/networking/fetch-data) and [Flutter: JSON and serialization](https://docs.flutter.dev/data-and-backend/serialization/json)

## Going further
- Level 201 lesson 04 generates the whole network client from an API description instead of writing `TodoApi` by hand.

## Summary
- You sent a GET request with the `http` package and checked the status code.
- You decoded JSON into typed `Todo` objects with a factory constructor.
- You showed loading, error and data states and added the Android internet permission.

## Next lesson
10. Local storage: keep data on the phone when the app closes.
