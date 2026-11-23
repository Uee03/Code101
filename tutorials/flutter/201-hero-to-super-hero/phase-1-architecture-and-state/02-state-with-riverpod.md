---
track: flutter
level: 201
phase: 1
phase_name: architecture-and-state
lesson: "02"
title: "State with Riverpod"
time: "70-90 min"
prerequisites: ["flutter-201-01"]
versions: { flutter: "3.50.1", dart: "3.14.0", material_ui: "1.11.1", flutter_riverpod: "3.5.0" }
verified: not yet run
source: source/flutter/201-hero-to-super-hero/phase-1-architecture-and-state/02-state-with-riverpod/
assets: []
---

# 02. State with Riverpod

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Explain what a provider is and choose between `Provider`, `NotifierProvider` and `AsyncNotifierProvider`.
- Replace hand-written wiring and `ChangeNotifier` with Riverpod while the repository, model and service stay untouched.
- Use `ref.watch`, `ref.read` and `ref.invalidate` correctly, and render `AsyncValue` with `when`.
- Say what changed in Riverpod 3 that affects you: automatic retry, `ref.mounted`, notifier families with constructor arguments.

## Recap
1. Which object in lesson 01 created the repository and the view model, and who disposed the view model? <details><summary>Answer</summary>`_TasksAppState` created them in `initState` and disposed the view model in `dispose`.</details>
2. What does `Result` make impossible? <details><summary>Answer</summary>Ignoring failure: a `switch` must handle `Err`.</details>
3. Which layers did lesson 01 say can change without touching the views? <details><summary>Answer</summary>Repository and service.</details>

## Why it matters
In lesson 01 the wiring was in one widget. With ten screens you would either pass objects through every constructor, or build a global lookup yourself and get its lifetime wrong. Riverpod gives one tool for three jobs: it creates and shares objects (dependency injection), it holds state and tells widgets when it changes, and it models "loading, data, error" with one type, `AsyncValue`. It is the choice of the capstone because one tool covers state and wiring, it makes repositories easy to replace, and it needs no code generator.

## What you will build
The same Tasks screen as lesson 01, now driven by Riverpod. You will delete `_TasksAppState`, the manual `dispose` and the `ListenableBuilder`, and the repository, model, service and composer files will not change at all.

## Before you start
- Lesson 01 finished: continue in the same `tasks_app` project.
- Time: 70-90 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/flutter/201-hero-to-super-hero/phase-1-architecture-and-state/02-state-with-riverpod/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Unchanged from lesson 01 and not repeated: `lib/core/result.dart`, `lib/data/models/task.dart`, `lib/data/services/task_dto.dart`, `lib/data/services/fake_task_service.dart`, `lib/data/repositories/task_repository.dart`, `lib/features/tasks/view/task_composer.dart`.
- Capstone link: Riverpod providers are the dependency container of [mobile-flutter chapter 03](../../../../capstones/mobile-flutter/tutorials/phase-3-screens/03-screens.md).

## Steps
### Step 1. Add the package
Replace `pubspec.yaml` (the only change: `flutter_riverpod: 3.5.0`) and run `flutter pub get`.

**File: `pubspec.yaml`**
```yaml
name: tasks
description: Tasks and Teams phone client built step by step in Flutter 201.
publish_to: none
version: 1.0.0+1

environment:
  sdk: ^3.14.0

dependencies:
  flutter:
    sdk: flutter
  material_ui: 1.11.1
  flutter_riverpod: 3.5.0

dev_dependencies:
  flutter_lints: 6.0.0

flutter:
  uses-material-design: false
```

### Step 2. Create the providers
A **provider** is a recipe for creating one object, declared once at the top level of a file. Providers are global *declarations*, but the objects they create live inside a `ProviderScope` and are created on first use, so there is no global mutable state to leak between runs. Create `lib/app/providers.dart`:

**File: `lib/app/providers.dart`**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/task_repository.dart';
import '../data/services/fake_task_service.dart';

final taskServiceProvider = Provider<FakeTaskService>(
  (ref) => FakeTaskService(),
);

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(ref.watch(taskServiceProvider)),
);
```

`taskRepositoryProvider` uses `ref.watch(taskServiceProvider)`: Riverpod builds the service first and rebuilds the repository if the service ever changes. This is the dependency injection: nothing calls `new` on a repository except this one line.

### Step 3. Rewrite the view model as a notifier
Replace `lib/features/tasks/view_model/tasks_view_model.dart`. A **notifier** is a class that owns state and exposes commands. `AsyncNotifier<List<Task>>` has the state `AsyncValue<List<Task>>`: loading, data or error. The first load is `build()`. `family` gives one notifier per `projectId`, passed to the constructor (this is the Riverpod 3 way).

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

  /// Returns null on success, or a message for the view to show.
  Future<String?> add(String title) async {
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
        return failure.toString();
    }
  }

  Future<String?> complete(Task task) async {
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
        return failure.toString();
    }
  }
}
```

Read it carefully:
- `build` returns the list, or throws; Riverpod turns that into `AsyncData` or `AsyncError` and starts in `AsyncLoading`. There is no `_loading` flag to forget.
- `ref.watch` inside `build` re-runs `build` when the watched provider changes. `ref.read` inside a command reads once and does not subscribe. **Rule: watch in `build`, read in event handlers.**
- After each `await` in a command we check `ref.mounted`: the provider may have been disposed meanwhile. Riverpod 3 throws if you use `ref` after disposal.
- Commands set `state = AsyncData(...)`. The new list is a new object, so listeners are notified.

### Step 4. Rewrite the screen
`ConsumerWidget` is a stateless widget whose `build` also receives a `WidgetRef`, used to watch providers. Replace `lib/features/tasks/view/tasks_screen.dart`:

**File: `lib/features/tasks/view/tasks_screen.dart`**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../view_model/tasks_view_model.dart';
import 'task_composer.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key, required this.projectId});

  final String projectId;

  /// Waits for a view model command and shows its failure message, if any.
  Future<void> _run(BuildContext context, Future<String?> command) async {
    final message = await command;
    if (message == null || !context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
            onSubmit: (title) => _run(context, viewModel.add(title)),
          ),
          Expanded(
            child: tasks.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error.toString()),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref.invalidate(provider),
                      child: const Text('Try again'),
                    ),
                  ],
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

`tasks.when(loading:, error:, data:)` forces you to render all three states. `ref.invalidate(provider)` throws away the state: the notifier rebuilds and `build` loads again (the "Try again" button).

### Step 5. Rewrite the app widget and the entry point
`TasksApp` becomes stateless: no wiring, no dispose. `main` wraps it in a `ProviderScope`, the container that holds all provider state. We turn off Riverpod 3's automatic retry (`retry: (retryCount, error) => null`) because we want an error screen with a button, not silent retries with growing delays.

**File: `lib/app/app.dart`**
```dart
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
```

**File: `lib/main.dart`**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';

void main() {
  runApp(
    ProviderScope(
      // Riverpod 3 retries failed providers by default. We show errors and let the user retry.
      retry: (retryCount, error) => null,
      child: const TasksApp(),
    ),
  );
}
```

## Run it
**File: `terminal (folder tasks_app)`**
```text
flutter run
```
Expected behaviour (described from the code, not yet seen): identical to lesson 01: a spinner, three tasks, adding and completing work. The difference is in the code, not on the screen. To see the error branch, temporarily make `FakeTaskService.listTasks` start with `throw Exception('offline');`, hot restart (`R`): the screen shows `Exception: offline` and a **Try again** button; remove the line and tap the button to see the list return.

## How it works
**Provider kinds you need.**

| Provider | State | Use for |
|---|---|---|
| `Provider<T>` | read-only value | services, repositories, config |
| `NotifierProvider<N, T>` | synchronous state with commands | settings, form state, a counter |
| `AsyncNotifierProvider<N, T>` | state that starts with a Future | data loaded from a repository, with commands |
| `StreamNotifierProvider<N, T>` | state fed by a Stream | database watches (lesson 07) |
| `.family` | one instance per argument | per project, per task id |

**`ref.watch`, `ref.read`, `ref.listen`.** `watch` subscribes and rebuilds when the value changes: use it in `build`. `read` takes the current value once: use it in callbacks (`onPressed`). `listen` runs a side effect (a snackbar, navigation) when a value changes: use it in `build` too, never to compute UI.

**Lifecycle.** A provider's state lives while something listens to it. In Riverpod 3 a provider whose listeners are all in screens that are no longer visible is paused. If you add `.autoDispose` the state is deleted when nothing listens. For our list we keep the default: leaving and returning shows the last data at once.

**What changed in Riverpod 3 that touches this lesson.** (1) Failed providers retry automatically with a backoff (up to 10 times); we disable it globally with `retry`. (2) `ref.mounted` exists, and using `ref` after disposal throws. (3) `Notifier` and `FamilyNotifier` merged: family arguments go to the notifier's constructor. (4) `StateProvider`, `StateNotifierProvider` and `ChangeNotifierProvider` moved to `package:flutter_riverpod/legacy.dart`: we use none. Source: [migration guide](https://riverpod.dev/docs/3.0_migration).

**Why the layers did not change.** `TasksViewModel` still depends only on `TaskRepository`, and that class is the file from lesson 01. That is the payoff of lesson 01's rule.

### Why this, not that
| Choice | Alternative | Why |
|---|---|---|
| Riverpod | Bloc | Bloc's strict events and states give an audit trail this app does not need and cost about twice the files per screen. `AsyncValue` models loading, data and error with no state classes. |
| Riverpod | Provider + `ChangeNotifier` | Provider is Riverpod's predecessor: widget-tree-scoped lookups and no compile-time safety for missing providers; Riverpod providers are declared globally and checked by the compiler. |
| Riverpod | `get_it` | A service locator creates objects but has no state, caching or rebuild model: you would still need a state tool. |
| `Notifier` classes, no code generator | `@riverpod` annotations with `riverpod_generator` | One less build step (`build_runner` is already used by the API client and database); the hand-written syntax is two lines longer per provider. |

Common misconception: "Providers are global variables, so state is global." The *declaration* is global and immutable; the *state* lives in the `ProviderScope`, and tests or a second scope get their own copy.

## Try it
Make a Flutter project `try02` (same `flutter create` command as lesson 01, with `flutter_riverpod` added to its `pubspec.yaml`, see the lesson's) and replace `lib/main.dart` with the starter:

**File: `exercise/starter/lib/main.dart`**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const ProviderScope(child: CounterApp()));
}

class CounterNotifier extends Notifier<int> {
  @override
  int build() => 0;

  // TODO 1: make increment() add one to state, and reset() set it back to 0
  void increment() {}

  void reset() {}
}

final counterProvider = NotifierProvider<CounterNotifier, int>(
  CounterNotifier.new,
);

// TODO 2: return true when the counter is even (use ref.watch(counterProvider))
final isEvenProvider = Provider<bool>((ref) => false);

class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Riverpod counter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const CounterScreen(),
    );
  }
}

class CounterScreen extends ConsumerWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    // TODO 3: also watch isEvenProvider and show 'even' or 'odd' under the number
    return Scaffold(
      appBar: AppBar(title: const Text('Riverpod counter')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$count', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.read(counterProvider.notifier).increment(),
              child: const Text('Add one'),
            ),
            TextButton(
              onPressed: () => ref.read(counterProvider.notifier).reset(),
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}
```

1. **Guided:** complete the three TODOs. The number grows with **Add one**, **Reset** sets 0, and the word `even` or `odd` follows the number. Which provider rebuilds when you tap?
2. **Change:** in the real project, override the repository for development: wrap the app with `ProviderScope(overrides: [taskServiceProvider.overrideWithValue(FakeTaskService())], ...)` and explain what it changes (hint: nothing visible, but a different service could be put there).
3. **Stretch (optional):** add `.autoDispose` to `tasksViewModelProvider` and observe: leave the screen and return later. What do you lose and what do you gain?

<details><summary>Solution</summary>

**File: `exercise/solution/lib/main.dart`**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const ProviderScope(child: CounterApp()));
}

class CounterNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void increment() {
    state = state + 1;
  }

  void reset() {
    state = 0;
  }
}

final counterProvider = NotifierProvider<CounterNotifier, int>(
  CounterNotifier.new,
);

final isEvenProvider = Provider<bool>((ref) {
  return ref.watch(counterProvider).isEven;
});

class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Riverpod counter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const CounterScreen(),
    );
  }
}

class CounterScreen extends ConsumerWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    final even = ref.watch(isEvenProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Riverpod counter')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$count', style: Theme.of(context).textTheme.displayMedium),
            Text(even ? 'even' : 'odd'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.read(counterProvider.notifier).increment(),
              child: const Text('Add one'),
            ),
            TextButton(
              onPressed: () => ref.read(counterProvider.notifier).reset(),
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }
}
```

`isEvenProvider` watches `counterProvider`; it is recomputed whenever the counter changes, and widgets watching `isEvenProvider` rebuild only if the boolean changes.

</details>

## Check yourself
1. When do you use `ref.read` and when `ref.watch`? <details><summary>Answer</summary>`watch` in `build` to react to changes; `read` in event handlers to take the current value once.</details>
2. Why check `ref.mounted` after an `await` in a notifier? <details><summary>Answer</summary>The provider may have been disposed; Riverpod 3 throws when `ref` is used after that.</details>
3. What states does `AsyncValue` model? <details><summary>Answer</summary>Loading, data and error (`AsyncLoading`, `AsyncData`, `AsyncError`).</details>
4. Predict: you leave out `retry: (retryCount, error) => null` and `listTasks` fails. What does the user see first? <details><summary>Answer</summary>The loading spinner for longer: Riverpod retries with growing delays before the error state is shown.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Bad state: No ProviderScope found` (typical message) | `ProviderScope` missing above the app | Wrap `runApp` content in `ProviderScope` |
| Spinner stays long on error | Automatic retry is active | Pass `retry: (retryCount, error) => null` or set `retry` on the provider |
| `Tried to use Ref after it has been disposed` (typical wording) | `ref` used after an `await` when the provider was gone | Check `ref.mounted` first |
| `The getter 'valueOrNull' isn't defined` (typical message) | Riverpod 2 API | In Riverpod 3 use `state.value` (nullable) |
| Screen does not update after `state = ...` | The same list object was mutated and reassigned | Always create a new list: `[created, ...old]` |

## Best practice
Watch providers in `build`, read them in callbacks, and keep commands in the notifier, not the widget. Source: [Riverpod documentation](https://riverpod.dev/docs/introduction/why_riverpod) and [flutter_riverpod 3.5.0](https://pub.dev/packages/flutter_riverpod/versions/3.5.0)

## Going further
- Riverpod 3 also has experimental *mutations* for side effects and offline persistence; we do not use them because they are experimental.
- Lesson 07 turns this notifier into a `StreamNotifier` that watches a local database.

## Summary
- You replaced hand-written wiring with providers and `ProviderScope`.
- You rewrote a view model as an `AsyncNotifier` family and rendered it with `AsyncValue.when`.
- You applied the watch/read rule and the `ref.mounted` check, and you disabled automatic retry on purpose.
- Repository, service and model did not change.

## Next lesson
03. Navigation with go_router: more than one screen, a bottom bar and a sign-in guard.
