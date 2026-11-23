---
track: kotlin
level: 101
phase: 3
phase_name: data-and-polish
lesson: 10
title: Coroutines intro and calling an HTTP API
time: 75-90 min
prerequisites: [04, 09]
versions: { retrofit: "3.0.0", okhttp: "5.5.1", kotlinx-serialization-json: "1.13.0", kotlinx-coroutines: "1.11.0", kotlin: "2.4.21" }
verified: not yet run
source: source/kotlin/101-zero-to-hero/phase-3-data-and-polish/10-coroutines-and-http-api/
assets: []
---

# 10. Coroutines intro and calling an HTTP API

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- explain what a **coroutine** and a `suspend` function are, and why the screen must never wait on the network;
- describe an HTTP API call with **Retrofit** and read its JSON answer into Kotlin objects;
- model *loading*, *done* and *failed* as a `sealed interface` and show each in the UI;
- handle a lost connection without crashing.

## Recap
1. Why is `_uiState` private? <details><summary>Answer</summary>Only the ViewModel may change the state; the screens read it and call functions.</details>
2. What does `sealed interface` give you in a `when`? <details><summary>Answer</summary>The compiler checks that every case is handled.</details>

## Why it matters
Ordering a parcel online: you press "order" and the shop does not freeze the whole shop-window until the parcel arrives. You get a receipt, and you carry on browsing; the parcel arrives later. A phone app talking to a server is the same. The network can take a fraction of a second or ten seconds, and if the screen waited, the app would freeze. **Coroutines** are Kotlin's way to write "start this, carry on, and continue here when it is done" in a straight, readable way.

## What you will build
A button **Load sample tasks** that downloads five to-do items from a free practice server (https://jsonplaceholder.typicode.com) and adds them to the list, with a status line: loading, done, or an error message if you are offline. The app uses Retrofit and OkHttp, the same networking libraries as the capstone.

## Before you start
- The project from lesson 09, and an emulator or phone with internet.
- Time: about 75 to 90 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/kotlin/101-zero-to-hero/phase-3-data-and-polish/10-coroutines-and-http-api/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).

Files that stay **exactly as in lesson 09**: `settings.gradle.kts`, `gradle.properties`, `gradle/wrapper/gradle-wrapper.properties`, `.gitignore`, `Theme.kt`, `model/Task.kt`, `AddTaskBar.kt`, `TaskCard.kt`, `DetailScreen.kt`, `MainActivity.kt`, the four icons and the licence file. Changed or new: `build.gradle.kts` (root), `libs.versions.toml`, `app/build.gradle.kts`, the manifest, `strings.xml`, `TodoDto.kt`, `TodoApi.kt`, `TodoClient.kt` (new), `TasksViewModel.kt`, `HomeScreen.kt` and `TasksApp.kt`.

New words: coroutine, `suspend`, `launch`, `viewModelScope`, dispatcher, HTTP, API, endpoint, JSON, Retrofit, OkHttp, serialization, DTO, permission, `try`/`catch`.

## Steps

### Step 1. Understand the call you are about to make
**HTTP** is the language browsers and apps use to talk to servers. An **API** (application programming interface) is a server's menu of things you may ask for; one item on the menu is an **endpoint**. We use `GET https://jsonplaceholder.typicode.com/todos?_limit=5`, which answers with a list in **JSON** (text that looks like `[{"userId":1,"id":1,"title":"...","completed":false}, ...]`). You can open that address in a browser to see it. At the time of writing the first title is `delectus aut autem`; it is a public practice server, so its data may change.

### Step 2. Add the libraries and the serialization plugin
**File: `build.gradle.kts`** (the one in the project root)
```kotlin
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.kotlin.compose) apply false
    alias(libs.plugins.kotlin.serialization) apply false
}
```
**File: `gradle/libs.versions.toml`**
```toml
[versions]
agp = "9.5.1"
kotlin = "2.4.21"
compose = "2026.11.01"
activity = "1.13.0"
navigation = "2.10.2"
lifecycle = "2.11.1"
coroutines = "1.11.0"
retrofit = "3.0.0"
okhttp = "5.5.1"
serialization = "1.13.0"

[libraries]
compose-bom = { module = "androidx.compose:compose-bom", version.ref = "compose" }
compose-material3 = { module = "androidx.compose.material3:material3" }
compose-ui = { module = "androidx.compose.ui:ui" }
compose-ui-tooling = { module = "androidx.compose.ui:ui-tooling" }
compose-ui-tooling-preview = { module = "androidx.compose.ui:ui-tooling-preview" }
activity-compose = { module = "androidx.activity:activity-compose", version.ref = "activity" }
navigation = { module = "androidx.navigation:navigation-compose", version.ref = "navigation" }
lifecycle-runtime = { module = "androidx.lifecycle:lifecycle-runtime-compose", version.ref = "lifecycle" }
lifecycle-viewmodel = { module = "androidx.lifecycle:lifecycle-viewmodel-compose", version.ref = "lifecycle" }
coroutines = { module = "org.jetbrains.kotlinx:kotlinx-coroutines-android", version.ref = "coroutines" }
retrofit = { module = "com.squareup.retrofit2:retrofit", version.ref = "retrofit" }
retrofit-converter = { module = "com.squareup.retrofit2:converter-kotlinx-serialization", version.ref = "retrofit" }
okhttp = { module = "com.squareup.okhttp3:okhttp", version.ref = "okhttp" }
serialization = { module = "org.jetbrains.kotlinx:kotlinx-serialization-json", version.ref = "serialization" }

[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }
kotlin-compose = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
kotlin-serialization = { id = "org.jetbrains.kotlin.plugin.serialization", version.ref = "kotlin" }
```
- **Retrofit** turns an interface into a working HTTP client; **OkHttp** is the engine under it that really sends the request. **kotlinx.serialization** converts JSON text to Kotlin objects; its Gradle plugin `kotlin-serialization` must have the same version as Kotlin.

**File: `app/build.gradle.kts`**
```kotlin
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.serialization)
}

android {
    namespace = "com.code101.taskstart"
    compileSdk { version = release(37) }

    defaultConfig {
        applicationId = "com.code101.taskstart"
        minSdk = 26
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
    }

    buildFeatures {
        compose = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

dependencies {
    implementation(platform(libs.compose.bom))
    implementation(libs.compose.material3)
    implementation(libs.compose.ui)
    implementation(libs.compose.ui.tooling.preview)
    implementation(libs.activity.compose)
    implementation(libs.navigation)
    implementation(libs.lifecycle.runtime)
    implementation(libs.lifecycle.viewmodel)
    implementation(libs.coroutines)
    implementation(libs.retrofit)
    implementation(libs.retrofit.converter)
    implementation(libs.okhttp)
    implementation(libs.serialization)
    debugImplementation(libs.compose.ui.tooling)
}
```
Sync Gradle.

### Step 3. Permission to use the internet
Android apps may not use the network unless the manifest asks for it.

**File: `app/src/main/AndroidManifest.xml`**
```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <application
        android:allowBackup="false"
        android:label="@string/app_name"
        android:theme="@android:style/Theme.Material.Light.NoActionBar">
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```
Only the `<uses-permission ... INTERNET />` line is new. Without it every network call fails with an exception. Traffic to `https://` addresses is allowed by default; plain `http://` is blocked by Android unless an app opts in, which is a good thing.

### Step 4. New strings
**File: `app/src/main/res/values/strings.xml`**
```xml
<resources>
    <string name="app_name">Tasks Start</string>
    <string name="new_task_label">New task</string>
    <string name="add">Add</string>
    <string name="open_count">%1$d open</string>
    <string name="toggle_task">Mark %1$s as done or open</string>
    <string name="open_details">Open details</string>
    <string name="status_done">Done</string>
    <string name="status_open">Open</string>
    <string name="details">Task details</string>
    <string name="back">Back</string>
    <string name="delete_task">Delete task</string>
    <string name="task_not_found">This task no longer exists.</string>
    <string name="empty_list">No tasks yet. Add one above.</string>
    <string name="load_samples">Load sample tasks</string>
    <string name="loading_samples">Loading sample tasks...</string>
    <string name="samples_done">Added %1$d sample tasks.</string>
    <string name="samples_failed">Could not load the sample tasks. Check your connection and try again.</string>
</resources>
```
Four new texts at the end.

### Step 5. The data classes, the API and the client
Create the folder `app/src/main/kotlin/com/code101/taskstart/data`.

**File: `app/src/main/kotlin/com/code101/taskstart/data/TodoDto.kt`**
```kotlin
package com.code101.taskstart.data

import kotlinx.serialization.Serializable

@Serializable
data class TodoDto(
    val id: Int,
    val title: String,
    val completed: Boolean,
)
```
A **DTO** (data transfer object) is a class that mirrors what travels over the wire. We keep it apart from our `Task`, so that a change on the server does not ripple through the whole app. The names must match the JSON keys; the server also sends `userId`, which we ignore.

**File: `app/src/main/kotlin/com/code101/taskstart/data/TodoApi.kt`**
```kotlin
package com.code101.taskstart.data

import retrofit2.http.GET
import retrofit2.http.Query

interface TodoApi {
    @GET("todos")
    suspend fun todos(@Query("_limit") limit: Int): List<TodoDto>
}
```
This is the whole description of the endpoint: `@GET("todos")` is the path, `@Query("_limit")` adds `?_limit=5` to the address, and the return type says what the JSON becomes. `suspend` marks a function that may pause (more below). You write no code in the body: Retrofit creates it.

**File: `app/src/main/kotlin/com/code101/taskstart/data/TodoClient.kt`**
```kotlin
package com.code101.taskstart.data

import java.util.concurrent.TimeUnit
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import retrofit2.Retrofit
import retrofit2.converter.kotlinx.serialization.asConverterFactory

object TodoClient {
    private val json = Json { ignoreUnknownKeys = true }

    private val client = OkHttpClient.Builder()
        .callTimeout(15, TimeUnit.SECONDS)
        .build()

    val api: TodoApi = Retrofit.Builder()
        .baseUrl("https://jsonplaceholder.typicode.com/")
        .client(client)
        .addConverterFactory(json.asConverterFactory("application/json".toMediaType()))
        .build()
        .create(TodoApi::class.java)
}
```
- `object TodoClient` is the single shared helper from lesson 04.
- `Json { ignoreUnknownKeys = true }` is the JSON reader; it skips keys such as `userId` that our DTO does not list.
- `OkHttpClient` with `callTimeout(15, SECONDS)` gives up after 15 seconds, so a dead connection cannot hang forever.
- `baseUrl` ends with `/`; Retrofit requires that. It is `https`, so the traffic is encrypted.
- `create(TodoApi::class.java)` makes the working implementation of your interface.

### Step 6. The ViewModel gets an import function
**File: `app/src/main/kotlin/com/code101/taskstart/ui/TasksViewModel.kt`**
```kotlin
package com.code101.taskstart.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.code101.taskstart.data.TodoClient
import com.code101.taskstart.model.Task
import java.io.IOException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.serialization.SerializationException
import retrofit2.HttpException

sealed interface ImportState {
    data object Idle : ImportState
    data object Loading : ImportState
    data class Done(val count: Int) : ImportState
    data object Failed : ImportState
}

data class TasksUiState(
    val tasks: List<Task> = listOf(
        Task(1, "Buy milk"),
        Task(2, "Call dentist"),
        Task(3, "Pay rent", done = true),
    ),
    val draft: String = "",
    val importState: ImportState = ImportState.Idle,
)

class TasksViewModel : ViewModel() {
    private val _uiState = MutableStateFlow(TasksUiState())
    val uiState: StateFlow<TasksUiState> = _uiState.asStateFlow()

    fun onDraftChange(text: String) {
        _uiState.update { it.copy(draft = text) }
    }

    fun addTask() {
        _uiState.update { state ->
            val title = state.draft.trim()
            if (title.isEmpty()) {
                state
            } else {
                val nextId = (state.tasks.maxOfOrNull { it.id } ?: 0) + 1
                state.copy(tasks = state.tasks + Task(nextId, title), draft = "")
            }
        }
    }

    fun toggle(id: Int) {
        _uiState.update { state ->
            state.copy(
                tasks = state.tasks.map { task ->
                    if (task.id == id) task.copy(done = !task.done) else task
                },
            )
        }
    }

    fun delete(id: Int) {
        _uiState.update { state ->
            state.copy(tasks = state.tasks.filterNot { it.id == id })
        }
    }

    fun importSamples() {
        if (_uiState.value.importState == ImportState.Loading) return
        viewModelScope.launch {
            _uiState.update { it.copy(importState = ImportState.Loading) }
            try {
                val todos = TodoClient.api.todos(limit = 5)
                _uiState.update { state ->
                    val start = (state.tasks.maxOfOrNull { it.id } ?: 0) + 1
                    val added = todos.mapIndexed { index, todo ->
                        Task(start + index, todo.title, todo.completed)
                    }
                    state.copy(
                        tasks = state.tasks + added,
                        importState = ImportState.Done(added.size),
                    )
                }
            } catch (e: IOException) {
                _uiState.update { it.copy(importState = ImportState.Failed) }
            } catch (e: HttpException) {
                _uiState.update { it.copy(importState = ImportState.Failed) }
            } catch (e: SerializationException) {
                _uiState.update { it.copy(importState = ImportState.Failed) }
            }
        }
    }
}
```

### Step 7. Show the button and the status
**File: `app/src/main/kotlin/com/code101/taskstart/ui/HomeScreen.kt`**
```kotlin
package com.code101.taskstart.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.code101.taskstart.R
import com.code101.taskstart.model.Task
import com.code101.taskstart.ui.theme.TasksTheme

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    state: TasksUiState,
    onDraftChange: (String) -> Unit,
    onAdd: () -> Unit,
    onToggle: (Int) -> Unit,
    onOpen: (Int) -> Unit,
    onLoadSamples: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Scaffold(
        modifier = modifier,
        topBar = {
            TopAppBar(title = { Text(stringResource(R.string.app_name)) })
        },
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .padding(innerPadding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            AddTaskBar(
                draft = state.draft,
                onDraftChange = onDraftChange,
                onAdd = onAdd,
            )
            Text(
                text = stringResource(R.string.open_count, state.tasks.count { !it.done }),
                style = MaterialTheme.typography.titleMedium,
            )
            OutlinedButton(
                onClick = onLoadSamples,
                enabled = state.importState != ImportState.Loading,
            ) {
                Text(stringResource(R.string.load_samples))
            }
            ImportStatus(state.importState)
            if (state.tasks.isEmpty()) {
                Text(text = stringResource(R.string.empty_list))
            }
            LazyColumn(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                items(state.tasks, key = { it.id }) { task ->
                    TaskCard(
                        task = task,
                        onToggle = { onToggle(task.id) },
                        onOpen = { onOpen(task.id) },
                    )
                }
            }
        }
    }
}

@Composable
private fun ImportStatus(importState: ImportState) {
    val text = when (importState) {
        ImportState.Idle -> null
        ImportState.Loading -> stringResource(R.string.loading_samples)
        is ImportState.Done -> stringResource(R.string.samples_done, importState.count)
        ImportState.Failed -> stringResource(R.string.samples_failed)
    }
    if (text != null) {
        Text(
            text = text,
            modifier = Modifier.semantics { liveRegion = LiveRegionMode.Polite },
        )
    }
}

@Preview(showBackground = true)
@Composable
fun HomeScreenPreview() {
    TasksTheme {
        HomeScreen(
            state = TasksUiState(
                tasks = listOf(Task(1, "Buy milk"), Task(2, "Pay rent", done = true)),
                importState = ImportState.Failed,
            ),
            onDraftChange = { },
            onAdd = { },
            onToggle = { },
            onOpen = { },
            onLoadSamples = { },
        )
    }
}
```
The `liveRegion` tells a screen reader to announce the status text when it changes ("polite" waits until it has finished speaking).

**File: `app/src/main/kotlin/com/code101/taskstart/ui/TasksApp.kt`**
```kotlin
package com.code101.taskstart.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument

@Composable
fun TasksApp(viewModel: TasksViewModel = viewModel()) {
    val navController = rememberNavController()
    val state by viewModel.uiState.collectAsStateWithLifecycle()

    NavHost(navController = navController, startDestination = "home") {
        composable("home") {
            HomeScreen(
                state = state,
                onDraftChange = viewModel::onDraftChange,
                onAdd = viewModel::addTask,
                onToggle = viewModel::toggle,
                onOpen = { id -> navController.navigate("detail/$id") },
                onLoadSamples = viewModel::importSamples,
            )
        }
        composable(
            route = "detail/{taskId}",
            arguments = listOf(navArgument("taskId") { type = NavType.IntType }),
        ) { entry ->
            val taskId = entry.arguments?.getInt("taskId")
            DetailScreen(
                task = state.tasks.firstOrNull { it.id == taskId },
                onBack = { navController.popBackStack() },
                onDelete = {
                    if (taskId != null) {
                        viewModel.delete(taskId)
                    }
                    navController.popBackStack()
                },
            )
        }
    }
}
```
Only one line is new: `onLoadSamples = viewModel::importSamples`.

Predict before you run: if you press the button twice quickly, how many sets of five tasks arrive, and which line of `importSamples` guards that? What does the status line show with airplane mode on?

## Run it
Run the app with internet access and press **Load sample tasks**. Then switch the emulator to airplane mode (swipe down the quick settings) and press the button again.

Expected result (described, not yet seen): the status shows "Loading sample tasks..." briefly, then "Added 5 sample tasks." and five new cards appear below your tasks (their titles come from the server's practice text). In airplane mode the status shows "Could not load the sample tasks. Check your connection and try again." and the app keeps running.

## How it works
**Why not just call it?** If the screen thread (the **main thread**, which draws 60 times a second) waited for the network, the app would freeze; Android even forbids network calls on it. The old fix was callbacks, which become unreadable when stacked.

**Coroutine.** A coroutine is a piece of work that can **pause** and later **resume** without blocking a thread, like a cook who puts a pot on to boil and cuts vegetables meanwhile. The code still reads top to bottom:
```kotlin
val todos = TodoClient.api.todos(limit = 5)   // pauses here until the server answers
val added = todos.mapIndexed { ... }          // continues here
```
**`suspend`.** A function marked `suspend` is allowed to pause, and can only be called from a coroutine or another `suspend` function. Retrofit's `suspend` functions do their waiting off the main thread for you, so you can call them directly from the screen's coroutine.

**`launch` and `viewModelScope`.** `viewModelScope.launch { ... }` starts a coroutine that lives as long as the ViewModel. When the ViewModel is cleared, Android **cancels** the coroutine, so a request never outlives its screen. This is called **structured concurrency**: every coroutine belongs to a scope.

**The three states.** `ImportState` is a `sealed interface` (lesson 04): `Idle`, `Loading`, `Done(count)` and `Failed`. `HomeScreen` uses `when` over it, so adding a state later forces you to show it. That removes a whole class of "forgot to handle the error" bugs.

**Errors.** Networks fail. `IOException` means the connection failed or timed out; `HttpException` means the server answered with an error status such as 404 or 500; `SerializationException` means the JSON was not what the DTO expected. Each is caught and turned into `Failed` rather than crashing. Misconception: a `try`/`catch` around `launch` would also work. It would not: errors inside a coroutine must be caught inside it, as here.

**Retrofit and OkHttp.** Retrofit reads the annotations of `TodoApi`, OkHttp sends the request, and the converter turns the JSON text into `List<TodoDto>`. We then map each `TodoDto` into our own `Task`.

**Privacy and safety.** This request sends no personal data and no password. Never put secrets (keys, passwords) into an app's source code; level 201 shows sign-in done properly.

## Try it
1. **Guided:** add `Countdown.kt` from the starter below next to `TasksViewModel.kt`, add `<string name="countdown">Countdown: %1$d</string>` to `strings.xml`, and fill the two TODOs. Then put `CountdownButton()` into the `Column` of `HomeScreen` (temporarily) to try it.

**File: `app/src/main/kotlin/com/code101/taskstart/ui/Countdown.kt`**
```kotlin
package com.code101.taskstart.ui

import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import com.code101.taskstart.R
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

class CountdownViewModel : ViewModel() {
    private val _seconds = MutableStateFlow(3)
    val seconds: StateFlow<Int> = _seconds.asStateFlow()

    fun start() {
        // TODO 1: launch a coroutine in viewModelScope
        // TODO 2: while seconds is above 0: wait one second with delay(1000), then subtract one with update
    }
}

@Composable
fun CountdownButton(
    modifier: Modifier = Modifier,
    viewModel: CountdownViewModel = viewModel(),
) {
    val seconds by viewModel.seconds.collectAsStateWithLifecycle()
    Button(onClick = viewModel::start, modifier = modifier) {
        Text(stringResource(R.string.countdown, seconds))
    }
}
```
Expected: the button reads `Countdown: 3`; after you press it the number counts 2, 1, 0 once per second and stops at 0.
2. **Change:** make the countdown start from 5, and show the text "Go!" when it reaches 0 (a new string).
3. **Stretch (optional):** change `limit = 5` in the ViewModel to 10 and discuss: which part of the app decides how many tasks arrive, and who should decide it?

<details><summary>Solution</summary>

**File: `app/src/main/kotlin/com/code101/taskstart/ui/Countdown.kt`**
```kotlin
package com.code101.taskstart.ui

import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import com.code101.taskstart.R
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

class CountdownViewModel : ViewModel() {
    private val _seconds = MutableStateFlow(3)
    val seconds: StateFlow<Int> = _seconds.asStateFlow()

    fun start() {
        viewModelScope.launch {
            while (_seconds.value > 0) {
                delay(1000)
                _seconds.update { it - 1 }
            }
        }
    }
}

@Composable
fun CountdownButton(
    modifier: Modifier = Modifier,
    viewModel: CountdownViewModel = viewModel(),
) {
    val seconds by viewModel.seconds.collectAsStateWithLifecycle()
    Button(onClick = viewModel::start, modifier = modifier) {
        Text(stringResource(R.string.countdown, seconds))
    }
}
```
`delay(1000)` pauses the coroutine for a second without blocking any thread; `update` changes the state, and the button text recomposes.

</details>

## Check yourself
1. Why must a network call not run on the main thread? <details><summary>Answer</summary>The main thread draws the screen; waiting there freezes the app (and Android forbids it).</details>
2. What does `suspend` mean? <details><summary>Answer</summary>The function can pause and resume later; it can only be called from a coroutine or another `suspend` function.</details>
3. Name two exceptions you handled and what each means. <details><summary>Answer</summary>`IOException`: connection failed or timed out. `HttpException`: the server answered with an error status. (`SerializationException`: unexpected JSON.)</details>
4. Predict: you forget `<uses-permission ... INTERNET />`. What happens when you press the button? <details><summary>Answer</summary>The call fails with a security exception, which this code does not catch, so the app crashes; the permission is required.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| The app closes when you press the button (typical: a log line mentioning permission denied for internet) | Missing `INTERNET` permission | Add the `uses-permission` line to the manifest |
| `Unresolved reference 'Serializable'` (typical) | The serialization plugin or dependency is missing | Add the plugin (root and app) and the `kotlinx-serialization-json` library, then sync |
| An exception about a base URL not ending in `/` (typical) | The Retrofit `baseUrl` lacks a trailing slash | End it with `/` |
| Status always shows the failure text | No internet in the emulator, or a blocked network | Open a web page in the emulator; fix its connection |
| `Suspend function 'todos' should be called only from a coroutine or another suspend function` (typical) | The call is outside `launch` | Call it inside `viewModelScope.launch { ... }` |

## Best practice
Do network and other slow work in coroutines tied to a lifecycle scope, expose the result as a state, and handle every failure path. Source: Kotlin coroutines on Android https://developer.android.com/kotlin/coroutines and Retrofit https://square.github.io/retrofit/

## Going further
- Coroutines guide: https://kotlinlang.org/docs/coroutines-guide.html
- Level 201 lesson 03 goes deep into coroutines and Flow; lesson 05 parses structured server errors; lesson 06 signs in properly.

## Summary
- You explained coroutines, `suspend`, `launch` and `viewModelScope`.
- You described an API with Retrofit and read JSON through a DTO.
- You modelled idle, loading, done and failed with a sealed interface and showed each in the UI.
- You handled network errors instead of crashing.

## Next lesson
11. Saving data (DataStore, intro to Room): keeping the tasks after the app closes.
