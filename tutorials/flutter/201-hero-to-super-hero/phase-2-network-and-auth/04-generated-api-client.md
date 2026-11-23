---
track: flutter
level: 201
phase: 2
phase_name: network-and-auth
lesson: "04"
title: "A generated API client (swagger_parser) with dio"
time: "80-100 min"
prerequisites: ["flutter-201-03"]
versions: { flutter: "3.50.1", dart: "3.14.0", dio: "5.11.1", swagger_parser: "2.3.0", json_serializable: "6.15.2", build_runner: "2.17.1", uuid: "4.6.0" }
verified: not yet run
source: source/flutter/201-hero-to-super-hero/phase-2-network-and-auth/04-generated-api-client/
assets: [ui/list, ui/settings]
---

# 04. A generated API client (swagger_parser) with dio

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Generate a typed Dart client from an OpenAPI file with one command, and keep generated code out of hand-written code.
- Replace a fake service by a real one behind the same repository, changing only the repository mapping.
- Pass build-time configuration with `--dart-define-from-file` and refuse unsafe URLs with a `UrlPolicy`.
- Reach a backend on the host machine from the Android emulator, and allow cleartext HTTP in debug builds only.
- Send `If-Match` and `Idempotency-Key` headers correctly.

## Recap
1. In lesson 01, which layer mapped DTOs to models? <details><summary>Answer</summary>The repository.</details>
2. Why is the detail route outside the shell route in lesson 03? <details><summary>Answer</summary>A detail page is full screen and must cover the bottom bar.</details>
3. What does `Result` replace in the repository's signature? <details><summary>Answer</summary>Throwing exceptions upward.</details>

## Why it matters
The platform contract (`openapi.yaml`, 27 operations) is the single source of truth for the server. Writing 27 request functions and 20 JSON classes by hand means typos, drift and boring work; the compiler cannot tell you the server renamed a field. A generator turns the contract into Dart code, so a contract change becomes a compile error that points at the exact line to update. The rule that makes it work: **generated files are never edited and never imported outside one file** (`ApiService`).

## What you will build
The Tasks app talks to the real Tasks and Teams API. The fake service and its DTO are deleted; `ApiService` wraps the generated client; the repository maps the generated DTOs; Settings gets a **Connection** test that calls the unauthenticated `/health` operation. Listing tasks will answer **401** until lesson 06 adds sign-in, which is the point of lessons 05 and 06.

## Before you start
- Lesson 03 finished: continue in `tasks_app`.
- Time: 80-100 minutes. The first generation and the first Android build with new plugins are slow.
- A running backend is only needed for the last part ("Run it"). Generation and the build need none. To start one, follow the disposable-backend procedure in [mobile-flutter chapter 05, section "Start a disposable backend session"](../../../../capstones/mobile-flutter/tutorials/phase-5-ship/05-build-run-ship.md) (platform plus one backend on port 8000, Docker only for the backend). Stop it again afterwards as that chapter says.
- Source pack (optional): every file except the OpenAPI file is shown in full in this lesson. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/flutter/201-hero-to-super-hero/phase-2-network-and-auth/04-generated-api-client/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Unchanged from lesson 03 and not repeated: `lib/app/app.dart`, `lib/app/app_shell.dart`, `lib/app/router.dart`, `lib/core/result.dart`, `lib/core/widgets/art_icon.dart`, `lib/data/models/task.dart`, the login, task detail and tasks feature files, `lib/features/tasks/view_model/tasks_view_model.dart`, and the icons.
- Deleted from lesson 03: `lib/data/services/fake_task_service.dart` and `lib/data/services/task_dto.dart`. Delete them in your project now.
- `pubspec.lock` and `lib/data/generated/` are not in the pack: `flutter pub get` creates the lock and the generator creates the folder.
- Capstone link: this is [mobile-flutter chapter 01](../../../../capstones/mobile-flutter/tutorials/phase-1-setup/01-setup.md), section by section.

## Steps
### Step 1. Add the contract
Create the folder `contract` next to `lib` and copy the platform's OpenAPI file into it **unchanged**:

**File: `terminal (Windows PowerShell, from the Code101 repository root)`**
```powershell
Copy-Item capstones\platform\source\phase-1-contract\01-openapi-contract\code\openapi.yaml `
  "$HOME\code101\flutter201\tasks_app\contract\openapi.yaml"
```

**File: `terminal (macOS or Linux, from the Code101 repository root)`**
```bash
cp capstones/platform/source/phase-1-contract/01-openapi-contract/code/openapi.yaml \
  ~/code101/flutter201/tasks_app/contract/openapi.yaml
```
If you did not clone the repository, download that file from https://github.com/Uee03/Code101 (path in the command). It is about 1,200 lines and is the one file this course does not print in full: the platform capstone explains it section by section. Treat it as read-only.

### Step 2. `pubspec.yaml`
Replace the file. Runtime packages: `dio` (the HTTP client), `json_annotation` (annotations the generated classes use), `uuid` (idempotency keys). Dev-only tools: `swagger_parser` (the generator), `json_serializable` and `build_runner` (they write the `*.g.dart` JSON code). Run `flutter pub get`.

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
  go_router: 18.1.4
  flutter_svg: 2.5.0
  dio: 5.11.1
  json_annotation: 4.12.0
  uuid: 4.6.0

dev_dependencies:
  flutter_lints: 6.0.0
  swagger_parser: 2.3.0
  json_serializable: 6.15.2
  build_runner: 2.17.1

flutter:
  uses-material-design: false
  assets:
    - assets/icons/list.svg
    - assets/icons/settings.svg
```

### Step 3. Configure the generator
`swagger_parser.yaml` tells the generator where the contract is and what to produce. `http_client: dio` and `serializer: json_serializable` select the Dio client and generated JSON code; `root_api_class_name: TasksApi` gives the entry class; `response_mode: first_success` makes each method return the first success response type.

**File: `swagger_parser.yaml`**
```yaml
swagger_parser:
  schema_path: contract/openapi.yaml
  output_directory: lib/data/generated
  generation:
    root_api_class_name: TasksApi
    http_client: dio
    serializer: json_serializable
    response_mode: first_success
    generate_docs: true
```

### Step 4. Generate
**File: `terminal (folder tasks_app)`**
```text
dart run swagger_parser
dart run build_runner build
```
The first command writes Dart sources into `lib/data/generated/`: one client class per tag (`tasks`, `teams`, `projects`, `comments`, `platform`, ...), model classes such as `Task$Response`, `TaskCreate` and `TaskPage$Response`, and an entry class `TasksApi`. The second command writes the `*.g.dart` files with the JSON code. Expected result (typical, count differs): the first prints a line saying it generated files; the second ends with a message that the build finished. Open `lib/data/generated/tasks/tasks_client.dart` and look at `listTasks`: required `projectId`, optional `limit`, `cursor`, `sort`, repeated `status`. Do **not** edit these files; change the contract and regenerate.

Generated code is output of a tool: whether you commit it is a team decision. The capstone commits it so a fresh checkout builds without the generator; this pack does not include it, so you generate it yourself.

### Step 5. Configuration without literals
Create `config/dev.json` (a **dart-define file**: key-value pairs compiled into the app, not secrets, because the app is a public client). `10.0.2.2` is the emulator's alias for your computer's loopback. The project id is the seeded "Mobile App" project of the platform; lesson 10 replaces it by a project picker.

**File: `config/dev.json`**
```json
{
  "API_BASE_URL": "http://10.0.2.2:8000",
  "DEV_PROJECT_ID": "9a000000-0000-4000-8000-000000000003"
}
```

Create `lib/core/config.dart`. `String.fromEnvironment` reads a value defined at build time; it must be `static const`.

**File: `lib/core/config.dart`**
```dart
abstract final class Config {
  static const apiBase = String.fromEnvironment('API_BASE_URL');
  static const devProjectId = String.fromEnvironment('DEV_PROJECT_ID');
}
```

Create `lib/core/url_policy.dart`: a rule that only HTTPS URLs are accepted, with plain HTTP allowed only in debug builds and only for development hosts. A configuration mistake then fails at start-up instead of sending data in clear text.

**File: `lib/core/url_policy.dart`**
```dart
abstract final class UrlPolicy {
  static const _devHosts = {'10.0.2.2', 'localhost', '127.0.0.1'};

  /// Accepts https URLs, and http only for development hosts in debug builds.
  static Uri validate(String value, {required bool debug}) {
    final uri = Uri.parse(value);
    final httpAllowed =
        debug && uri.scheme == 'http' && _devHosts.contains(uri.host);
    final badParts =
        uri.userInfo.isNotEmpty || uri.hasFragment || uri.hasQuery || uri.host.isEmpty;
    if (badParts || (uri.scheme != 'https' && !httpAllowed)) {
      throw const FormatException('Use HTTPS, or a debug-only loopback host.');
    }
    return uri;
  }
}
```

### Step 6. Android network settings
Android 9 and newer block cleartext HTTP unless allowed. Our local backend speaks HTTP, so the **debug** build gets a network security config that allows it for three hosts only; the **release** build allows none. The `main` manifest also needs the `INTERNET` permission (the generated debug manifest has it, a release build would not). Replace `android/app/src/main/AndroidManifest.xml`:

**File: `android/app/src/main/AndroidManifest.xml`**
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <application
        android:label="Tasks and Teams"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:allowBackup="false"
        android:usesCleartextTraffic="false">
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

Replace `android/app/src/debug/AndroidManifest.xml` and create `android/app/src/debug/res/xml/network_security_config.xml` (create the folders):

**File: `android/app/src/debug/AndroidManifest.xml`**
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:networkSecurityConfig="@xml/network_security_config" />
</manifest>
```

**File: `android/app/src/debug/res/xml/network_security_config.xml`**
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="false" />
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="false">10.0.2.2</domain>
        <domain includeSubdomains="false">localhost</domain>
        <domain includeSubdomains="false">127.0.0.1</domain>
    </domain-config>
</network-security-config>
```

`android:allowBackup="false"` keeps Android from copying the app's data to the cloud (matters from lesson 06 on). `base-config cleartextTrafficPermitted="false"` is the default for everything else.

### Step 7. `ApiService`: the only door to the generated code
The service imports the generated entry file with a prefix (`as dto`), because the generated enums `TaskStatus` and `TaskPriority` have the same names as our domain enums. Each method forwards to a generated client method. Note `completeTask` sends `If-Match: "<version>"` (optimistic concurrency: the server rejects the call with 412 if the task changed), and `createTask` requires an `Idempotency-Key`.

**File: `lib/data/services/api_service.dart`**
```dart
import 'package:dio/dio.dart';

import '../generated/tasks_api.dart' as dto;

/// The only file that knows the generated client. It returns generated DTOs.
class ApiService {
  ApiService(this._dio) : _api = dto.TasksApi(_dio);

  final Dio _dio;
  final dto.TasksApi _api;

  Future<dto.Health> health() => _api.platform.getHealth();

  Future<dto.TaskPage$Response> listTasks(String projectId, {String? cursor}) {
    return _api.tasks.listTasks(
      projectId: projectId,
      limit: 25,
      cursor: cursor,
      sort: dto.ListTasksSort.createdAt,
    );
  }

  Future<dto.Task$Response> getTask(String taskId) {
    return _api.tasks.getTask(taskId: taskId);
  }

  Future<dto.Task$Response> createTask(
    String projectId, {
    required String title,
    required String description,
    required String idempotencyKey,
  }) {
    return _api.tasks.createTask(
      projectId: projectId,
      idempotencyKey: idempotencyKey,
      body: dto.TaskCreate(title: title, description: description),
    );
  }

  Future<dto.Task$Response> completeTask(String taskId, int version) {
    return _api.tasks.completeTask(taskId: taskId, ifMatch: '"$version"');
  }

  void close() => _dio.close();
}
```

### Step 8. The repository now maps generated DTOs
Only the repository changes: it takes an `ApiService`, catches `DioException` (Dio's error type) and maps `Task$Response` to `Task`. The view model and views are untouched.

**File: `lib/data/repositories/task_repository.dart`**
```dart
import 'package:dio/dio.dart' show DioException;
import 'package:uuid/uuid.dart';

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
      return Err(error);
    }
  }

  Future<Result<Task>> getTask(String id) async {
    try {
      return Ok(_toTask(await _api.getTask(id)));
    } on DioException catch (error) {
      return Err(error);
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
      return Err(error);
    }
  }

  Future<Result<Task>> completeTask(Task task) async {
    try {
      return Ok(_toTask(await _api.completeTask(task.id, task.version)));
    } on DioException catch (error) {
      return Err(error);
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

### Step 9. Providers
Replace `lib/app/providers.dart`: a `Dio` built from configuration, `ApiService`, the repository and the default project.

**File: `lib/app/providers.dart`**
```dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config.dart';
import '../core/url_policy.dart';
import '../data/repositories/task_repository.dart';
import '../data/services/api_service.dart';

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

### Step 10. The connection test
`lib/features/settings/view_model/settings_view_model.dart` calls `/health` (which needs no sign-in) and `lib/features/settings/view/settings_screen.dart` shows the answer.

**File: `lib/features/settings/view_model/settings_view_model.dart`**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';

/// Calls the unauthenticated /health operation, so it works before sign-in exists.
final connectionTestProvider = FutureProvider.autoDispose<String>((ref) async {
  final health = await ref.watch(apiServiceProvider).health();
  final database = health.database?.value ?? 'not reported';
  return 'API ${health.status.value}, database $database';
});
```

**File: `lib/features/settings/view/settings_screen.dart`**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

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
                error: (error, stackTrace) => 'Failed: $error',
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

### Step 11. Fail early when unconfigured
Replace `lib/main.dart`: it validates the base URL before building the app.

**File: `lib/main.dart`**
```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'core/config.dart';
import 'core/url_policy.dart';

void main() {
  try {
    UrlPolicy.validate(Config.apiBase, debug: kDebugMode);
  } on FormatException {
    runApp(const ConfigErrorApp());
    return;
  }
  runApp(
    ProviderScope(
      retry: (retryCount, error) => null,
      child: const TasksApp(),
    ),
  );
}

class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'The app is not configured. Start it with '
                '--dart-define-from-file=config/dev.json',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

## Run it
Start the platform and one backend (see "Before you start"), start an emulator, then:

**File: `terminal (folder tasks_app)`**
```text
flutter run --dart-define-from-file=config/dev.json
```
Expected behaviour (described from the code and the contract, not yet seen): the app opens on the splash, then login. Tap **Sign in (demo)**. The **Tasks** tab shows an error: the request reached the server and was refused because there is no bearer token yet (HTTP 401); the screen text is Dio's raw error message. That is correct for this lesson. Open **Settings**: **Connection** shows `API ok, database up` (the contract's healthy answer). If it shows `Failed: ...`, the backend is not reachable at `10.0.2.2:8000` or is not running. Without `--dart-define-from-file` you get the "The app is not configured" screen.

## How it works
**Contract first.** The server team owns `openapi.yaml`. A client generated from it can only call operations that exist, with the right parameter names and types. When the contract changes you regenerate and fix compile errors; you do not discover the change at run time.

**What the generator produced.** For each tagged group of operations a client class holding a `Dio`; for each schema a class with `fromJson`; for each enum a Dart enum with `.value` (the wire text, as in `item.status.value` in the repository). `TasksApi(dio)` assembles the clients; `_api.tasks.listTasks(projectId: ...)` is the typed call.

**The rule that protects you.** Only `ApiService` imports `generated/`; only `TaskRepository` imports `ApiService`. If the generator is replaced or the contract changes shape, one file changes. A view that imported a generated class would be coupled to the server's wire format.

**Mapping.** Generated classes mirror the wire (`status` enum, `dueDate` as text). The domain model mirrors the app. `_toTask` is the bridge; keep it boring.

**Headers with meaning.** `If-Match` carries the version the user saw. If someone else changed the task, the server answers `412 Precondition Failed` instead of overwriting: lost updates are impossible. `Idempotency-Key` lets a retry of the same create be recognised: same key and same body return the first response instead of creating a duplicate. In this lesson the key is new on every call, which still leaves a window (a timeout, then the user taps again). Lesson 08 closes it by storing the key with the pending write.

**Merge patch is hand-written.** The generated `TaskUpdate` cannot express "this field is absent" versus "this field is explicitly `null`" (a JSON Merge Patch needs both: absent keeps the value, `null` clears the due date). Lesson 10 adds one small hand-written `PATCH` for that, still inside `ApiService`. The exercise below practises exactly this difference.

**Reaching the host.** In the emulator `127.0.0.1` means the emulator itself; `10.0.2.2` is the alias of your computer ([emulator networking](https://developer.android.com/studio/run/emulator-networking)). The API is reached through the alias. Keycloak (lesson 06) has a fixed `localhost` issuer and is reached with `adb reverse` instead; the capstone explains why.

**Safety nets.** `UrlPolicy` stops a production build from ever talking HTTP; the debug network config is a second, separate gate. Neither is a substitute for HTTPS in production.

### Why this, not that
| Choice | Alternative | Why |
|---|---|---|
| `swagger_parser` | `openapi_generator` | Pure Dart (no Java needed), reads OpenAPI 3.1, emits Dio clients. The alternative wraps the Java generator and needs a JVM. |
| Generated client | Hand-written client with `http` | Compile-time drift detection and no boilerplate; hand-written code is kept for the one case the generator cannot express. |
| `dio` | `http` | Interceptors (lesson 05 problem details, lesson 06 bearer and refresh), timeouts and cancel tokens. |
| Config by `--dart-define-from-file` | Flavors or a `.env` package | Official, no extra package, nothing secret is needed in a public client. |
| Generated files not edited | Patch generated files | Edits are lost at the next generation. |

Common misconception: "A generated client means no thinking about the API." You still decide mapping, errors, retries and headers; the generator removes the typing, not the design.

## Try it
Make a folder `try04` and use the starter below with `dart run main.dart` (plain Dart). It rehearses three rules from this lesson: the `If-Match` header text, mapping wire status text to an enum, and a merge patch that tells "absent" from "null".

**File: `exercise/starter/main.dart`**
```dart
// Exercise 04: header and payload rules of the API. Run with: dart run main.dart
import 'dart:convert';

enum Status {
  todo('todo'),
  inProgress('in_progress'),
  done('done');

  const Status(this.wire);

  final String wire;
}

class TaskResponse {
  const TaskResponse(this.id, this.title, this.status, this.version);

  final String id;
  final String title;
  final String status;
  final int version;
}

class Task {
  const Task(this.id, this.title, this.status, this.version);

  final String id;
  final String title;
  final Status status;
  final int version;
}

String ifMatch(int version) {
  // TODO 1: return the version inside double quotes, for example "3"
  //         (the quote characters are part of the header value)
  return '';
}

Task toTask(TaskResponse response) {
  // TODO 2: build a Task. Find the Status whose wire text equals response.status;
  //         when none matches use Status.todo.
  return Task(response.id, response.title, Status.todo, response.version);
}

Map<String, Object?> mergePatch({
  String? title,
  String? dueDate,
  bool clearDueDate = false,
}) {
  // TODO 3: build the JSON Merge Patch map. Include only the fields that were given.
  //         When clearDueDate is true include 'dueDate' with the value null.
  return {};
}

void main() {
  print(ifMatch(3));
  print(toTask(const TaskResponse('t1', 'Write notes', 'in_progress', 2)).status.name);
  print(jsonEncode(mergePatch(title: 'New title')));
  print(jsonEncode(mergePatch(clearDueDate: true)));
  print(jsonEncode(mergePatch(title: 'A', dueDate: '2026-12-01')));
}
```

1. **Guided:** complete the three TODOs. Expected output:
```text
"3"
inProgress
{"title":"New title"}
{"dueDate":null}
{"title":"A","dueDate":"2026-12-01"}
```
2. **Change:** make `toTask` reject an unknown status by returning `null` instead of `todo`. What would the repository do with that?
3. **Stretch (optional):** which header does the platform require for `PATCH`, and what does the server answer when it is missing? Look in the platform TDD (concurrency section) before you answer.

<details><summary>Solution</summary>

**File: `exercise/solution/main.dart`**
```dart
// Exercise 04: header and payload rules of the API. Run with: dart run main.dart
import 'dart:convert';

enum Status {
  todo('todo'),
  inProgress('in_progress'),
  done('done');

  const Status(this.wire);

  final String wire;
}

class TaskResponse {
  const TaskResponse(this.id, this.title, this.status, this.version);

  final String id;
  final String title;
  final String status;
  final int version;
}

class Task {
  const Task(this.id, this.title, this.status, this.version);

  final String id;
  final String title;
  final Status status;
  final int version;
}

String ifMatch(int version) {
  return '"$version"';
}

Task toTask(TaskResponse response) {
  final status = Status.values.firstWhere(
    (value) => value.wire == response.status,
    orElse: () => Status.todo,
  );
  return Task(response.id, response.title, status, response.version);
}

Map<String, Object?> mergePatch({
  String? title,
  String? dueDate,
  bool clearDueDate = false,
}) {
  return {
    if (title != null) 'title': title,
    if (dueDate != null) 'dueDate': dueDate,
    if (clearDueDate) 'dueDate': null,
  };
}

void main() {
  print(ifMatch(3));
  print(toTask(const TaskResponse('t1', 'Write notes', 'in_progress', 2)).status.name);
  print(jsonEncode(mergePatch(title: 'New title')));
  print(jsonEncode(mergePatch(clearDueDate: true)));
  print(jsonEncode(mergePatch(title: 'A', dueDate: '2026-12-01')));
}
```

The `if (...) key: value` entries in a map literal include a key only when the condition is true; `'dueDate': null` is an *explicit* null, which is how a merge patch clears a field.

</details>

## Check yourself
1. Which file may import `lib/data/generated`? <details><summary>Answer</summary>Only `api_service.dart`.</details>
2. What does `If-Match: "3"` mean? <details><summary>Answer</summary>"Apply my change only if the task is still at version 3"; otherwise the server answers 412.</details>
3. Why is the release build safe from cleartext even though debug allows it for `10.0.2.2`? <details><summary>Answer</summary>The network security config is in `src/debug`; release uses the main manifest with cleartext off, and `UrlPolicy` rejects `http` in release.</details>
4. Predict: you run without `--dart-define-from-file`. What do you see? <details><summary>Answer</summary>The "The app is not configured" screen, because `UrlPolicy.validate('')` throws a `FormatException`.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `The following ... Could not find a file named "lib/data/generated/tasks_api.dart"` or `Target of URI doesn't exist` (typical wording) | The generator was not run | Run both generation commands from Step 4 |
| `Failed host lookup` or `Connection refused` on the emulator (typical wording) | Backend not running, or the URL uses `localhost` | Use `http://10.0.2.2:8000` in the emulator and start the backend |
| `Cleartext HTTP traffic to 10.0.2.2 not permitted` (typical message) | Debug network config missing, or a release build | Check `src/debug/res/xml/network_security_config.xml` and the debug manifest; run a debug build |
| `The app is not configured` screen | Missing `--dart-define-from-file` | Add the flag, or set it in your IDE's run configuration |
| A generated class name clashes with a model (`'TaskStatus' is imported from both ...`) | Imported generated code without a prefix | Import with `as dto` as in the lesson |

## Best practice
Keep generated code isolated behind one service, and make contract changes the first step of every API change. Source: [swagger_parser 2.3.0](https://pub.dev/packages/swagger_parser/versions/2.3.0), [dio 5.11.1](https://pub.dev/packages/dio/versions/5.11.1) and the [Android network security configuration](https://developer.android.com/privacy-and-security/security-config)

## Going further
- The capstone adds the other clients (teams, projects, comments) behind the same service. [mobile-flutter VERSION-NOTES](../../../../capstones/mobile-flutter/VERSION-NOTES.md) explains the generator options.

## Summary
- You generated a typed client from the contract and isolated it behind `ApiService`.
- You swapped the fake service for the real one, changing only the repository.
- You configured the app at build time, enforced a URL policy and set up debug-only cleartext access.
- You sent `If-Match` and `Idempotency-Key` and know why a merge patch is hand-written.

## Next lesson
05. Errors and RFC 9457 problem details: turn the server's structured errors into messages a person can act on.
