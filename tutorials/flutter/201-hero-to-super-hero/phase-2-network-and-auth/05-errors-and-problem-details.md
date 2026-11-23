---
track: flutter
level: 201
phase: 2
phase_name: network-and-auth
lesson: "05"
title: "Errors and RFC 9457 problem details"
time: "70-90 min"
prerequisites: ["flutter-201-04"]
versions: { flutter: "3.50.1", dart: "3.14.0", dio: "5.11.1" }
verified: not yet run
source: source/flutter/201-hero-to-super-hero/phase-2-network-and-auth/05-errors-and-problem-details/
assets: [ui/list, ui/settings]
---

# 05. Errors and RFC 9457 problem details

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Read an RFC 9457 `application/problem+json` answer and explain each member.
- Parse every error into one `ApiProblem` type in a Dio interceptor, including field errors (`errors[]` pointers) and `Retry-After`.
- Map each problem type of the platform contract to one message a person can act on, with a safe fallback.
- Decide which failures are worth retrying, and show a validation message under the right field.

## Recap
1. Which file may import the generated client? <details><summary>Answer</summary>`api_service.dart` only.</details>
2. What does the header `If-Match: "3"` do? <details><summary>Answer</summary>Makes the change conditional on the task still being at version 3; otherwise 412.</details>
3. Why does the repository return `Result` instead of throwing? <details><summary>Answer</summary>Failure becomes visible in the type and a `switch` must handle it.</details>

## Why it matters
At the end of lesson 04 the Tasks tab showed Dio's raw text for a 401. Real apps meet a dozen different failures: no network, an expired token, an invalid field, a stale edit, a rate limit, a server fault. Each needs a different reaction (retry, sign in again, fix the field, reload, wait). If every screen guesses from status codes, the guesses disagree. The platform answers with **problem details** ([RFC 9457](https://www.rfc-editor.org/rfc/rfc9457.html)), a standard JSON error format, so the app can handle all errors in one place.

## What you will build
One `ApiProblem` class, one interceptor that creates it, one function that turns it into a message, and small changes in the views so that: a failed list shows a human message and a retry button, a rejected title shows the server's field message under the text field, and a 429 says how many seconds to wait.

## Before you start
- Lesson 04 finished: continue in `tasks_app`.
- Time: 70-90 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/flutter/201-hero-to-super-hero/phase-2-network-and-auth/05-errors-and-problem-details/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Unchanged from lesson 04 and not repeated: `pubspec.yaml`, `swagger_parser.yaml`, `contract/openapi.yaml`, `config/dev.json`, the Android files, `lib/main.dart`, `lib/core/config.dart`, `lib/core/url_policy.dart`, `lib/core/result.dart`, `lib/core/widgets/art_icon.dart`, `lib/data/models/task.dart`, `lib/data/services/api_service.dart`, the router and shell files, the login files, `lib/features/settings/view_model/settings_view_model.dart`, `lib/features/task_detail/view_model/task_detail_view_model.dart` and the icons.
- Capstone link: [mobile-flutter chapter 04, errors](../../../../capstones/mobile-flutter/tutorials/phase-4-offline/04-offline.md) maps the same types to localized messages and shows the conflict sheet.

## Steps
### Step 1. Know what the server sends
The platform's error answers have the media type `application/problem+json`. A validation failure looks like this (illustrative shape taken from the contract, not a captured answer):

```json
{
  "type": "https://code101.example/problems/validation-error",
  "title": "Validation failed",
  "status": 422,
  "detail": "One or more fields are invalid.",
  "instance": "/v1/projects/9a00.../tasks",
  "traceId": "abc123",
  "errors": [
    { "pointer": "/title", "detail": "Title must be 1 to 200 characters." }
  ]
}
```
- `type` is a URI that names the *kind* of problem; **we branch on it, not on the human text**. The platform lists ten: `bad-request` (400), `unauthorized` (401), `forbidden` (403), `not-found` (404), `conflict` (409), `precondition-failed` (412), `validation-error` (422), `precondition-required` (428), `rate-limited` (429) and `internal-error` (500). See the platform TDD, section "API design".
- `title` is a short summary, `detail` explains this occurrence, `instance` is the request path, `traceId` is the number to quote to support.
- `errors[]` appears on validation problems: `pointer` is a JSON Pointer to the field (`/title`), `detail` is the message for it.
- A 429 also carries the header `Retry-After` (seconds, or a date).

### Step 2. The problem type
`ApiProblem` is also an `Exception`, so it can travel as the error of a Dio call. Create `lib/core/api_problem.dart`. Read `fromDio`: when there is **no response** (no network, a timeout) we invent a problem of kind `network` with status 0, so the rest of the app has one type to handle. `of` returns the problem the interceptor attached or builds one.

**File: `lib/core/api_problem.dart`**
```dart
import 'dart:io';

import 'package:dio/dio.dart';

/// An RFC 9457 problem details answer, or a failure before any answer arrived.
class ApiProblem implements Exception {
  const ApiProblem({
    required this.type,
    required this.title,
    required this.status,
    this.detail,
    this.fieldErrors = const {},
    this.retryAfter,
    this.traceId,
  });

  factory ApiProblem.fromDio(DioException error) {
    final response = error.response;
    if (response == null) {
      return ApiProblem(
        type: 'network',
        title: 'No connection',
        status: 0,
        detail: error.type.name,
      );
    }
    final data = response.data;
    final body = data is Map ? data : const <String, Object?>{};
    final status = response.statusCode ?? 0;
    return ApiProblem(
      type: _text(body['type']) ?? 'about:blank',
      title: _text(body['title']) ?? 'Request failed ($status)',
      status: status,
      detail: _text(body['detail']),
      fieldErrors: _fieldErrors(body['errors']),
      retryAfter: _retryAfter(response.headers.value('retry-after')),
      traceId: _text(body['traceId']),
    );
  }

  /// Returns the problem the interceptor attached, or builds one.
  static ApiProblem of(DioException error) {
    final attached = error.error;
    return attached is ApiProblem ? attached : ApiProblem.fromDio(error);
  }

  final String type;
  final String title;
  final int status;
  final String? detail;

  /// JSON Pointer (for example /title) to the message for that field.
  final Map<String, String> fieldErrors;
  final Duration? retryAfter;
  final String? traceId;

  /// The last part of the type URI, for example validation-error.
  String get kind => type.split('/').last;

  bool get retryable {
    return status == 0 ||
        status >= 500 ||
        status == 408 ||
        status == 425 ||
        status == 429;
  }

  static String? _text(Object? value) => value is String ? value : null;

  static Map<String, String> _fieldErrors(Object? value) {
    if (value is! List) {
      return const {};
    }
    return {
      for (final entry in value)
        if (entry is Map && entry['pointer'] is String && entry['detail'] is String)
          entry['pointer'] as String: entry['detail'] as String,
    };
  }

  static Duration? _retryAfter(String? header) {
    if (header == null) {
      return null;
    }
    final seconds = int.tryParse(header);
    if (seconds != null) {
      return Duration(seconds: seconds);
    }
    try {
      final wait = HttpDate.parse(header).difference(DateTime.now().toUtc());
      return wait.isNegative ? Duration.zero : wait;
    } on HttpException {
      return null;
    } on FormatException {
      return null;
    }
  }

  @override
  String toString() => 'ApiProblem($kind, status $status, trace $traceId)';
}
```

### Step 3. The messages
One function holds all user-facing text for problem kinds. An unknown kind falls back to the server's `title`, so a new server problem type degrades gracefully instead of showing nothing. Create `lib/core/problem_messages.dart`.

**File: `lib/core/problem_messages.dart`**
```dart
import 'package:dio/dio.dart';

import 'api_problem.dart';

/// One person-readable message for every problem type of the platform contract.
String problemMessage(ApiProblem problem) {
  switch (problem.kind) {
    case 'network':
      return 'No connection. Check your network and try again.';
    case 'bad-request':
      return 'The request was not understood. Update the app and try again.';
    case 'unauthorized':
      return 'Your session ended. Please sign in again.';
    case 'forbidden':
      return 'You are not allowed to do that.';
    case 'not-found':
      return 'That item does not exist, or you cannot see it.';
    case 'conflict':
      return 'That conflicts with something that already exists.';
    case 'precondition-failed':
      return 'Someone changed this item. Reload it and try again.';
    case 'validation-error':
      return 'Please fix the highlighted fields.';
    case 'precondition-required':
      return 'The app sent an incomplete request. Update the app.';
    case 'rate-limited':
      final wait = problem.retryAfter;
      if (wait == null) {
        return 'Too many requests. Try again in a moment.';
      }
      return 'Too many requests. Try again in ${wait.inSeconds} seconds.';
    case 'internal-error':
      return 'The server had a problem. Try again later.';
    default:
      return problem.title;
  }
}

/// A message for any failure a repository or provider may hand to a view.
String describeError(Object error) {
  if (error is DioException) {
    return problemMessage(ApiProblem.of(error));
  }
  if (error is ApiProblem) {
    return problemMessage(error);
  }
  return 'Something went wrong. Try again.';
}

/// The message the server attached to one field (a JSON Pointer such as /title), if any.
String? fieldMessage(Object? failure, String pointer) {
  if (failure is ApiProblem) {
    return failure.fieldErrors[pointer];
  }
  return null;
}
```

### Step 4. The interceptor
An **interceptor** is code Dio runs for every request or error. This one converts each `DioException` into an `ApiProblem` once and logs the method, path, status and trace id in debug builds only: **never headers, tokens or bodies**. Create `lib/data/services/problem_interceptor.dart`.

**File: `lib/data/services/problem_interceptor.dart`**
```dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/api_problem.dart';

/// Parses every error answer once and logs method, path and status, never headers or bodies.
class ProblemInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final problem = ApiProblem.fromDio(err);
    if (kDebugMode) {
      final request = err.requestOptions;
      debugPrint(
        '${request.method} ${request.uri.path} -> ${problem.status} '
        '${problem.kind} trace=${problem.traceId}',
      );
    }
    handler.next(err.copyWith(error: problem));
  }
}
```

### Step 5. Register it and use it in the repository
Replace `lib/app/providers.dart` (adds one line: `dio.interceptors.add(ProblemInterceptor())`) and `lib/data/repositories/task_repository.dart` (every `on DioException` now returns `Err(ApiProblem.of(error))`).

**File: `lib/app/providers.dart`**
```dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config.dart';
import '../core/url_policy.dart';
import '../data/repositories/task_repository.dart';
import '../data/services/api_service.dart';
import '../data/services/problem_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  final base = UrlPolicy.validate(Config.apiBase, debug: kDebugMode);
  final dio = Dio(
    BaseOptions(
      baseUrl: base.toString().replaceFirst(RegExp(r'/$'), ''),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      followRedirects: false,
    ),
  );
  dio.interceptors.add(ProblemInterceptor());
  ref.onDispose(dio.close);
  return dio;
});

final apiServiceProvider = Provider<ApiService>(
  (ref) => ApiService(ref.watch(dioProvider)),
);

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(ref.watch(apiServiceProvider)),
);

/// The project shown after sign-in while there is no project picker (lesson 10 adds one).
final defaultProjectIdProvider = Provider<String>((ref) => Config.devProjectId);
```

**File: `lib/data/repositories/task_repository.dart`**
```dart
import 'package:dio/dio.dart' show DioException;
import 'package:uuid/uuid.dart';

import '../../core/api_problem.dart';
import '../../core/result.dart';
import '../generated/tasks_api.dart' as dto;
import '../models/task.dart';
import '../services/api_service.dart';

class TaskRepository {
  TaskRepository(this._api);

  final ApiService _api;

  Future<Result<List<Task>>> loadTasks(String projectId) async {
    try {
      final page = await _api.listTasks(projectId);
      return Ok([for (final item in page.items) _toTask(item)]);
    } on DioException catch (error) {
      return Err(ApiProblem.of(error));
    }
  }

  Future<Result<Task>> getTask(String id) async {
    try {
      return Ok(_toTask(await _api.getTask(id)));
    } on DioException catch (error) {
      return Err(ApiProblem.of(error));
    }
  }

  /// A new key per call: a retry after a timeout could still create a duplicate.
  /// Lesson 08 fixes that by storing the key with the pending write.
  Future<Result<Task>> createTask(
    String projectId, {
    required String title,
    String description = '',
  }) async {
    try {
      final created = await _api.createTask(
        projectId,
        title: title,
        description: description,
        idempotencyKey: const Uuid().v4(),
      );
      return Ok(_toTask(created));
    } on DioException catch (error) {
      return Err(ApiProblem.of(error));
    }
  }

  Future<Result<Task>> completeTask(Task task) async {
    try {
      return Ok(_toTask(await _api.completeTask(task.id, task.version)));
    } on DioException catch (error) {
      return Err(ApiProblem.of(error));
    }
  }

  Task _toTask(dto.Task$Response item) {
    return Task(
      id: item.id,
      projectId: item.projectId,
      title: item.title,
      description: item.description,
      status: TaskStatus.fromWire(item.status.value),
      priority: TaskPriority.fromWire(item.priority.value),
      dueDate: item.dueDate,
      version: item.version,
      createdAt: item.createdAt,
    );
  }
}
```

### Step 6. The view model returns the failure
Replace `lib/features/tasks/view_model/tasks_view_model.dart`. Commands now return the failure object (or null), not a string: the view decides how to show it.

**File: `lib/features/tasks/view_model/tasks_view_model.dart`**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/result.dart';
import '../../../data/models/task.dart';

final tasksViewModelProvider =
    AsyncNotifierProvider.family<TasksViewModel, List<Task>, String>(
  TasksViewModel.new,
);

class TasksViewModel extends AsyncNotifier<List<Task>> {
  TasksViewModel(this.projectId);

  final String projectId;

  @override
  Future<List<Task>> build() async {
    final result = await ref.watch(taskRepositoryProvider).loadTasks(projectId);
    switch (result) {
      case Ok(value: final tasks):
        return tasks;
      case Err(error: final failure):
        throw failure;
    }
  }

  /// Returns null on success, or the failure for the view to describe.
  Future<Object?> add(String title) async {
    final result = await ref
        .read(taskRepositoryProvider)
        .createTask(projectId, title: title);
    if (!ref.mounted) {
      return null;
    }
    switch (result) {
      case Ok(value: final created):
        state = AsyncData([created, ...state.value ?? const []]);
        return null;
      case Err(error: final failure):
        return failure;
    }
  }

  Future<Object?> complete(Task task) async {
    final result = await ref.read(taskRepositoryProvider).completeTask(task);
    if (!ref.mounted) {
      return null;
    }
    switch (result) {
      case Ok(value: final updated):
        state = AsyncData([
          for (final item in state.value ?? const <Task>[])
            if (item.id == updated.id) updated else item,
        ]);
        return null;
      case Err(error: final failure):
        return failure;
    }
  }
}
```

### Step 7. The views use the messages
The composer now shows an error text under the field after a failed submit and disables the button while a request is running. Replace `lib/features/tasks/view/task_composer.dart`, then `tasks_screen.dart`, `task_detail_screen.dart` and `settings_screen.dart`.

**File: `lib/features/tasks/view/task_composer.dart`**
```dart
import 'package:material_ui/material_ui.dart';

class TaskComposer extends StatefulWidget {
  const TaskComposer({super.key, required this.onSubmit});

  /// Returns an error text to show under the field, or null when the task was added.
  final Future<String?> Function(String title) onSubmit;

  @override
  State<TaskComposer> createState() => _TaskComposerState();
}

class _TaskComposerState extends State<TaskComposer> {
  final _controller = TextEditingController();
  String? _error;
  bool _busy = false;

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
      _busy = true;
    });
    final error = await widget.onSubmit(title);
    if (!mounted) {
      return;
    }
    setState(() {
      _error = error;
      _busy = false;
    });
    if (error == null) {
      _controller.clear();
    }
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
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
```

**File: `lib/features/tasks/view/tasks_screen.dart`**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/problem_messages.dart';
import '../view_model/tasks_view_model.dart';
import 'task_composer.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key, required this.projectId});

  final String projectId;

  /// Waits for a view model command and shows its failure message, if any.
  Future<void> _run(BuildContext context, Future<Object?> command) async {
    final failure = await command;
    if (failure == null || !context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(describeError(failure))),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = tasksViewModelProvider(projectId);
    final tasks = ref.watch(provider);
    final viewModel = ref.read(provider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: Column(
        children: [
          TaskComposer(
            onSubmit: (title) async {
              final failure = await viewModel.add(title);
              if (failure == null) {
                return null;
              }
              return fieldMessage(failure, '/title') ?? describeError(failure);
            },
          ),
          Expanded(
            child: tasks.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(describeError(error), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => ref.invalidate(provider),
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text('No tasks yet.'));
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final task = items[index];
                    return ListTile(
                      title: Text(task.title),
                      subtitle: Text(task.status.label),
                      onTap: () => context.push(
                        '/tasks/${Uri.encodeComponent(task.id)}',
                      ),
                      trailing: task.isDone
                          ? null
                          : TextButton(
                              onPressed: () =>
                                  _run(context, viewModel.complete(task)),
                              child: const Text('Complete'),
                            ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

**File: `lib/features/task_detail/view/task_detail_screen.dart`**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/problem_messages.dart';
import '../view_model/task_detail_view_model.dart';

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(taskDetailProvider(taskId));
    return Scaffold(
      appBar: AppBar(title: const Text('Task')),
      body: task.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(describeError(error), textAlign: TextAlign.center),
          ),
        ),
        data: (item) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Status: ${item.status.label}'),
            Text('Priority: ${item.priority.name}'),
            Text('Due: ${item.dueDate ?? 'no due date'}'),
            Text('Version: ${item.version}'),
            const SizedBox(height: 16),
            Text(item.description.isEmpty ? 'No description.' : item.description),
          ],
        ),
      ),
    );
  }
}
```

**File: `lib/features/settings/view/settings_screen.dart`**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/problem_messages.dart';
import '../../login/view_model/auth_controller.dart';
import '../view_model/settings_view_model.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connection = ref.watch(connectionTestProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Account'),
            subtitle: Text('Signed in (demo)'),
          ),
          ListTile(
            title: const Text('Connection'),
            subtitle: Text(
              connection.when(
                loading: () => 'Testing...',
                error: (error, stackTrace) => describeError(error),
                data: (text) => text,
              ),
            ),
            trailing: TextButton(
              onPressed: () => ref.invalidate(connectionTestProvider),
              child: const Text('Test'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).signOut(),
                child: const Text('Sign out'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

## Run it
Run the app as in lesson 04 (`flutter run --dart-define-from-file=config/dev.json`) with the backend running.

Expected behaviour (described from the code and the contract, not yet seen):
- The Tasks tab, still without a token, shows "Your session ended. Please sign in again." and **Try again** (the server answers 401 `unauthorized`; lesson 06 fixes the cause).
- Stop the backend and press **Try again**: the message becomes "No connection. Check your network and try again." (no response, kind `network`).
- Open Settings: **Connection** shows the same "No connection" text while the backend is down and `API ok, database up` when it is back.
- Once lesson 06 provides a token: typing a title of 201 or more characters and pressing **Add** shows the server's field message under the text field (the contract limits titles; the exact wording comes from the server). Quickly pressing a button more than the rate limit allows would show "Too many requests. Try again in N seconds."
- In the debug console you see lines such as `GET /v1/projects/.../tasks -> 401 unauthorized trace=...`.

## How it works
**One shape for every failure.** Server problems and network failures both become `ApiProblem`. Views never look at `DioException`, status codes or header names.

**Type, not text.** The `type` URI is the stable, machine-readable part. The `title` and `detail` may change wording or language. We therefore keep our own message per type, and use `title` only as a fallback for types we do not know.

**Field errors.** `errors[]` pointers connect a server-side rule to a form field. The composer shows `fieldErrors['/title']` when present and the general message otherwise. Server validation is the truth; client-side checks (the "Enter a title" rule) only save a round trip.

**Which failures are worth retrying.** `retryable` is true for no response (status 0), 5xx, 408 (request timeout), 425 (too early) and 429 (rate limited). Other 4xx are the caller's mistake: repeating the same request will fail the same way. Lesson 08 uses this rule for the offline queue. A 429 says when to try again; we show the seconds instead of retrying blindly.

**Safe messages.** We show our own text and never the server's `detail` verbatim for unknown problems, because a `detail` can be technical. The `traceId` is logged, not shown; it is how a support person finds the request in the server log.

**Logging rules.** Method, path, status, kind and trace id only. No query string, headers, tokens or bodies, because any of them can hold personal data or secrets.

**Where authentication fits.** A 401 is handled twice: here as a message, and in lesson 06 by an interceptor that refreshes the token once and retries, and sends the user to login if that fails.

### Why this, not that
| Choice | Alternative | Why |
|---|---|---|
| Branch on problem `type` | Branch on HTTP status | Several problems share a status (409 conflict has more than one cause); the type is precise and documented in the contract. |
| Own messages per type | Show the server `detail` | Wording we control, translatable (the capstone moves them to ARB files), no internal details leaking to users. |
| One interceptor builds `ApiProblem` | Parse in each repository method | One place to fix, one place to log. |
| `network` as a problem kind with status 0 | A separate exception class | The UI and the retry rule treat it the same way as other failures. |

Common misconception: "The status code tells me what to show." It tells the category. The `type` and, for validation, the `errors` tell the user what to do.

## Try it
Use the starter with `dart run main.dart` (plain Dart): the same parsing and mapping rules without Flutter.

**File: `exercise/starter/main.dart`**
```dart
// Exercise 05: problem details. Run with: dart run main.dart

class Problem {
  const Problem({
    required this.type,
    required this.title,
    required this.status,
    this.fieldErrors = const {},
    this.retryAfter,
  });

  final String type;
  final String title;
  final int status;
  final Map<String, String> fieldErrors;
  final Duration? retryAfter;

  String get kind => type.split('/').last;

  bool get retryable {
    // TODO 3: true for status 408, 425, 429 and every status of 500 or more
    return false;
  }
}

Problem parseProblem(
  int status,
  Map<String, Object?> body, {
  String? retryAfterHeader,
}) {
  // TODO 1: build a Problem. type defaults to 'about:blank' and title to
  //         'Request failed ($status)'. Turn body['errors'] (a list of maps with
  //         'pointer' and 'detail') into fieldErrors. Turn a whole-number
  //         retryAfterHeader into a Duration in seconds.
  return Problem(type: 'about:blank', title: 'Request failed ($status)', status: status);
}

String message(Problem problem) {
  // TODO 2: return 'Please fix the highlighted fields.' for kind validation-error,
  //         'Too many requests. Try again in N seconds.' for rate-limited
  //         (N from retryAfter, or 'Too many requests. Try again in a moment.' without it),
  //         and the problem's title for any other kind.
  return problem.title;
}

void main() {
  final validation = parseProblem(422, {
    'type': 'https://code101.example/problems/validation-error',
    'title': 'Validation failed',
    'errors': [
      {'pointer': '/title', 'detail': 'Title is required'},
    ],
  });
  print(message(validation));
  print(validation.fieldErrors['/title']);
  final limited = parseProblem(
    429,
    {
      'type': 'https://code101.example/problems/rate-limited',
      'title': 'Too many requests',
    },
    retryAfterHeader: '30',
  );
  print(message(limited));
  final unknown = parseProblem(418, {
    'type': 'https://code101.example/problems/teapot',
    'title': 'I am a teapot',
  });
  print(message(unknown));
  print(parseProblem(502, {}).retryable);
  print(parseProblem(404, {}).retryable);
}
```

1. **Guided:** complete the three TODOs. Expected output:
```text
Please fix the highlighted fields.
Title is required
Too many requests. Try again in 30 seconds.
I am a teapot
true
false
```
2. **Change:** make `parseProblem` also accept a `Retry-After` header that is an HTTP date (hint: `HttpDate.parse` from `dart:io`), and return `Duration.zero` when the date is in the past.
3. **Stretch (optional):** add a `kind` for `unauthorized` and decide what a caller should do with it. Which layer owns that decision, repository or view model? Write your reasoning.

<details><summary>Solution</summary>

**File: `exercise/solution/main.dart`**
```dart
// Exercise 05: problem details. Run with: dart run main.dart

class Problem {
  const Problem({
    required this.type,
    required this.title,
    required this.status,
    this.fieldErrors = const {},
    this.retryAfter,
  });

  final String type;
  final String title;
  final int status;
  final Map<String, String> fieldErrors;
  final Duration? retryAfter;

  String get kind => type.split('/').last;

  bool get retryable {
    return status == 408 || status == 425 || status == 429 || status >= 500;
  }
}

Problem parseProblem(
  int status,
  Map<String, Object?> body, {
  String? retryAfterHeader,
}) {
  final errors = body['errors'];
  final seconds = int.tryParse(retryAfterHeader ?? '');
  return Problem(
    type: body['type'] as String? ?? 'about:blank',
    title: body['title'] as String? ?? 'Request failed ($status)',
    status: status,
    fieldErrors: {
      if (errors is List)
        for (final entry in errors)
          if (entry is Map && entry['pointer'] is String && entry['detail'] is String)
            entry['pointer'] as String: entry['detail'] as String,
    },
    retryAfter: seconds == null ? null : Duration(seconds: seconds),
  );
}

String message(Problem problem) {
  switch (problem.kind) {
    case 'validation-error':
      return 'Please fix the highlighted fields.';
    case 'rate-limited':
      final wait = problem.retryAfter;
      if (wait == null) {
        return 'Too many requests. Try again in a moment.';
      }
      return 'Too many requests. Try again in ${wait.inSeconds} seconds.';
    default:
      return problem.title;
  }
}

void main() {
  final validation = parseProblem(422, {
    'type': 'https://code101.example/problems/validation-error',
    'title': 'Validation failed',
    'errors': [
      {'pointer': '/title', 'detail': 'Title is required'},
    ],
  });
  print(message(validation));
  print(validation.fieldErrors['/title']);
  final limited = parseProblem(
    429,
    {
      'type': 'https://code101.example/problems/rate-limited',
      'title': 'Too many requests',
    },
    retryAfterHeader: '30',
  );
  print(message(limited));
  final unknown = parseProblem(418, {
    'type': 'https://code101.example/problems/teapot',
    'title': 'I am a teapot',
  });
  print(message(unknown));
  print(parseProblem(502, {}).retryable);
  print(parseProblem(404, {}).retryable);
}
```

The map literal with nested `if` and `for` builds `fieldErrors` only from entries that have both a text pointer and a text detail, so malformed items are skipped instead of crashing.

</details>

## Check yourself
1. Why branch on `type` and not on `title`? <details><summary>Answer</summary>`type` is stable and documented; `title` can change wording or language.</details>
2. What status does a network failure get in `ApiProblem`, and why? <details><summary>Answer</summary>0, because no HTTP answer exists; it lets all failures share one type.</details>
3. Which of 400, 408, 429, 503 are retryable? <details><summary>Answer</summary>408, 429 and 503; 400 is a mistake in the request itself.</details>
4. What must never go into the debug log line of the interceptor? <details><summary>Answer</summary>Headers, tokens, request or response bodies, and the query string.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| Message always "Something went wrong" | The error object is neither `ApiProblem` nor `DioException` | Return `Err(ApiProblem.of(error))` in every repository `catch` |
| Field message never appears | Pointer compared with the wrong text (`title` vs `/title`) | JSON Pointers start with `/`; use `fieldMessage(failure, '/title')` |
| `type 'List<dynamic>' is not a subtype of type 'List<Object?>'` (typical wording) | Unchecked cast of `errors` | Test `value is List` and each entry `is Map`, as in `_fieldErrors` |
| Users see the raw Dio text | A view prints `error.toString()` | Use `describeError(error)` |
| Retry button hammers the server on a 429 | Retrying without honoring `Retry-After` | Show the wait time; do not retry automatically for 429 |

## Best practice
Handle errors by machine-readable type in one place and keep user text under your control. Source: [RFC 9457: Problem Details for HTTP APIs](https://www.rfc-editor.org/rfc/rfc9457.html) and the [platform TDD](../../../../capstones/platform/TDD.md)

## Going further
- Lesson 08 uses `retryable` and `Retry-After` for exponential backoff with jitter in the sync queue.
- The capstone adds a conflict sheet for 412 so users can choose "mine" or "theirs".

## Summary
- You read problem details and parsed them once, in an interceptor, into `ApiProblem`.
- You mapped each problem type to one message and kept a safe fallback.
- You showed server field errors under the right field and classified retryable failures.

## Next lesson
06. OIDC PKCE login with flutter_appauth and secure storage: get the token that turns this 401 into data.
