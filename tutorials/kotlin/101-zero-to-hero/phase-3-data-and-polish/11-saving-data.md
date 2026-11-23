---
track: kotlin
level: 101
phase: 3
phase_name: data-and-polish
lesson: 11
title: Saving data (DataStore, intro to Room)
time: 75-90 min
prerequisites: [09, 10]
versions: { room: "2.8.5", datastore-preferences: "1.3.0", ksp: "2.3.14", kotlin: "2.4.21", lifecycle: "2.11.1" }
verified: not yet run
source: source/kotlin/101-zero-to-hero/phase-3-data-and-polish/11-saving-data/
assets: []
---

# 11. Saving data (DataStore, intro to Room)

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- choose between **DataStore** (a few settings) and **Room** (lists of records);
- write a Room `@Entity`, `@Dao` and `@Database` and read a table as a `Flow`;
- save a setting with Preferences DataStore;
- explain why a **repository** sits between the ViewModel and the storage.

## Recap
1. Why does a ViewModel lose its data when the app is closed? <details><summary>Answer</summary>It lives in memory, and the app's process ends.</details>
2. What is a `suspend` function? <details><summary>Answer</summary>A function that can pause and resume; it is called from a coroutine.</details>
3. What does `collectAsStateWithLifecycle` do? <details><summary>Answer</summary>It turns a flow into Compose state and pauses while the app is not visible.</details>

## Why it matters
A notebook keeps what you wrote after you close it; a whiteboard does not. Until now your tasks lived on a whiteboard (memory). To keep them you write them in a notebook (storage). Android has two good notebooks for apps: **DataStore** is a sticky note for a few small preferences ("hide done tasks: yes"), and **Room** is a proper table with rows and columns that you can search, for real data such as tasks.

## What you will build
Tasks are stored in a Room database and survive closing the app, and "Hide done tasks" is stored in DataStore. The screen shows what is in the database, whatever changes it.

## Before you start
- The project from lesson 10.
- Time: about 75 to 90 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/kotlin/101-zero-to-hero/phase-3-data-and-polish/11-saving-data/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).

Files that stay **exactly as in lesson 10**: `settings.gradle.kts`, `gradle.properties`, `gradle/wrapper/gradle-wrapper.properties`, `.gitignore`, `Theme.kt`, `model/Task.kt`, `AddTaskBar.kt`, `TaskCard.kt`, `DetailScreen.kt`, `MainActivity.kt`, `data/TodoDto.kt`, `data/TodoApi.kt`, `data/TodoClient.kt`, the four icons and the licence file. Everything else listed in the steps is new or changed.

New words: persistence, preference, DataStore, key, Room, entity, DAO, SQL, database, `@Query`, `Flow`, KSP, repository, singleton, `Application`.

## Steps

### Step 1. Libraries and the KSP plugin
**KSP** (Kotlin Symbol Processing) is a build tool that reads your annotations (`@Entity`, `@Dao`) and writes the database code for you.

**File: `build.gradle.kts`**
```kotlin
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.kotlin.compose) apply false
    alias(libs.plugins.kotlin.serialization) apply false
    alias(libs.plugins.ksp) apply false
}
```
**File: `gradle/libs.versions.toml`**
```toml
[versions]
agp = "9.5.1"
kotlin = "2.4.21"
ksp = "2.3.14"
compose = "2026.11.01"
activity = "1.13.0"
navigation = "2.10.2"
lifecycle = "2.11.1"
coroutines = "1.11.0"
retrofit = "3.0.0"
okhttp = "5.5.1"
serialization = "1.13.0"
room = "2.8.5"
datastore = "1.3.0"

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
room-runtime = { module = "androidx.room:room-runtime", version.ref = "room" }
room-ktx = { module = "androidx.room:room-ktx", version.ref = "room" }
room-compiler = { module = "androidx.room:room-compiler", version.ref = "room" }
datastore = { module = "androidx.datastore:datastore-preferences", version.ref = "datastore" }

[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }
kotlin-compose = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
kotlin-serialization = { id = "org.jetbrains.kotlin.plugin.serialization", version.ref = "kotlin" }
ksp = { id = "com.google.devtools.ksp", version.ref = "ksp" }
```
**File: `app/build.gradle.kts`**
```kotlin
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.serialization)
    alias(libs.plugins.ksp)
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
    implementation(libs.room.runtime)
    implementation(libs.room.ktx)
    ksp(libs.room.compiler)
    implementation(libs.datastore)
    debugImplementation(libs.compose.ui.tooling)
}
```
New compared with lesson 10: the `ksp` plugin, and `room-runtime`, `room-ktx`, `ksp(room-compiler)` and `datastore`. `ksp(...)` runs `room-compiler` while building. Sync Gradle.

### Step 2. Manifest and strings
The manifest names our own `Application` class (created in Step 6).

**File: `app/src/main/AndroidManifest.xml`**
```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <application
        android:name=".TasksApplication"
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
    <string name="hide_done">Hide done tasks</string>
</resources>
```
New: `android:name=".TasksApplication"` and the string `hide_done`. `allowBackup="false"` means the database is not copied to cloud backups.

### Step 3. The table: entity, DAO and database
Create the folder `app/src/main/kotlin/com/code101/taskstart/data` (it exists from lesson 10).

**File: `app/src/main/kotlin/com/code101/taskstart/data/TaskEntity.kt`**
```kotlin
package com.code101.taskstart.data

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.code101.taskstart.model.Task

@Entity(tableName = "tasks")
data class TaskEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val title: String,
    val done: Boolean = false,
)

fun TaskEntity.toTask() = Task(id = id, title = title, done = done)
```
**File: `app/src/main/kotlin/com/code101/taskstart/data/TaskDao.kt`**
```kotlin
package com.code101.taskstart.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface TaskDao {
    @Query("SELECT * FROM tasks ORDER BY id")
    fun observeAll(): Flow<List<TaskEntity>>

    @Insert
    suspend fun insert(task: TaskEntity)

    @Insert
    suspend fun insertAll(tasks: List<TaskEntity>)

    @Query("UPDATE tasks SET done = NOT done WHERE id = :id")
    suspend fun toggle(id: Int)

    @Query("DELETE FROM tasks WHERE id = :id")
    suspend fun delete(id: Int)
}
```
**File: `app/src/main/kotlin/com/code101/taskstart/data/TasksDatabase.kt`**
```kotlin
package com.code101.taskstart.data

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(entities = [TaskEntity::class], version = 1, exportSchema = false)
abstract class TasksDatabase : RoomDatabase() {
    abstract fun taskDao(): TaskDao
}
```

### Step 4. The setting in DataStore
**File: `app/src/main/kotlin/com/code101/taskstart/data/SettingsStore.kt`**
```kotlin
package com.code101.taskstart.data

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.settingsDataStore by preferencesDataStore(name = "settings")

class SettingsStore(private val context: Context) {
    private val hideDoneKey = booleanPreferencesKey("hide_done")

    val hideDone: Flow<Boolean> = context.settingsDataStore.data
        .map { preferences -> preferences[hideDoneKey] ?: false }

    suspend fun setHideDone(value: Boolean) {
        context.settingsDataStore.edit { preferences ->
            preferences[hideDoneKey] = value
        }
    }
}
```

### Step 5. The repository
**File: `app/src/main/kotlin/com/code101/taskstart/data/TasksRepository.kt`**
```kotlin
package com.code101.taskstart.data

import com.code101.taskstart.model.Task
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

class TasksRepository(
    private val dao: TaskDao,
    private val settings: SettingsStore,
    private val api: TodoApi,
) {
    val tasks: Flow<List<Task>> = dao.observeAll().map { rows -> rows.map { it.toTask() } }
    val hideDone: Flow<Boolean> = settings.hideDone

    suspend fun add(title: String) = dao.insert(TaskEntity(title = title))

    suspend fun toggle(id: Int) = dao.toggle(id)

    suspend fun delete(id: Int) = dao.delete(id)

    suspend fun setHideDone(value: Boolean) = settings.setHideDone(value)

    suspend fun importSamples(limit: Int): Int {
        val todos = api.todos(limit)
        dao.insertAll(todos.map { TaskEntity(title = it.title, done = it.completed) })
        return todos.size
    }
}
```

### Step 6. One place that builds the pieces
**File: `app/src/main/kotlin/com/code101/taskstart/TasksApplication.kt`**
```kotlin
package com.code101.taskstart

import android.app.Application
import androidx.room.Room
import com.code101.taskstart.data.SettingsStore
import com.code101.taskstart.data.TasksDatabase
import com.code101.taskstart.data.TasksRepository
import com.code101.taskstart.data.TodoClient

class TasksApplication : Application() {
    private val database by lazy {
        Room.databaseBuilder(this, TasksDatabase::class.java, "tasks.db").build()
    }

    val repository by lazy {
        TasksRepository(database.taskDao(), SettingsStore(this), TodoClient.api)
    }
}
```

### Step 7. The ViewModel reads from the repository
**File: `app/src/main/kotlin/com/code101/taskstart/ui/TasksViewModel.kt`**
```kotlin
package com.code101.taskstart.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider.AndroidViewModelFactory.Companion.APPLICATION_KEY
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.initializer
import androidx.lifecycle.viewmodel.viewModelFactory
import com.code101.taskstart.TasksApplication
import com.code101.taskstart.data.TasksRepository
import com.code101.taskstart.model.Task
import java.io.IOException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
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
    val allTasks: List<Task> = emptyList(),
    val hideDone: Boolean = false,
    val draft: String = "",
    val importState: ImportState = ImportState.Idle,
) {
    val visibleTasks: List<Task>
        get() = if (hideDone) allTasks.filterNot { it.done } else allTasks
}

class TasksViewModel(private val repository: TasksRepository) : ViewModel() {
    private val draft = MutableStateFlow("")
    private val importState = MutableStateFlow<ImportState>(ImportState.Idle)

    val uiState: StateFlow<TasksUiState> = combine(
        repository.tasks,
        repository.hideDone,
        draft,
        importState,
    ) { tasks, hideDone, draftText, importValue ->
        TasksUiState(
            allTasks = tasks,
            hideDone = hideDone,
            draft = draftText,
            importState = importValue,
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = TasksUiState(),
    )

    fun onDraftChange(text: String) {
        draft.value = text
    }

    fun addTask() {
        val title = draft.value.trim()
        if (title.isEmpty()) return
        draft.value = ""
        viewModelScope.launch { repository.add(title) }
    }

    fun toggle(id: Int) {
        viewModelScope.launch { repository.toggle(id) }
    }

    fun delete(id: Int) {
        viewModelScope.launch { repository.delete(id) }
    }

    fun onHideDoneChange(value: Boolean) {
        viewModelScope.launch { repository.setHideDone(value) }
    }

    fun importSamples() {
        if (importState.value == ImportState.Loading) return
        viewModelScope.launch {
            importState.value = ImportState.Loading
            importState.value = try {
                ImportState.Done(repository.importSamples(limit = 5))
            } catch (e: IOException) {
                ImportState.Failed
            } catch (e: HttpException) {
                ImportState.Failed
            } catch (e: SerializationException) {
                ImportState.Failed
            }
        }
    }

    companion object {
        val Factory = viewModelFactory {
            initializer {
                val app = this[APPLICATION_KEY] as TasksApplication
                TasksViewModel(app.repository)
            }
        }
    }
}
```

### Step 8. The screens
**File: `app/src/main/kotlin/com/code101/taskstart/ui/HomeScreen.kt`**
```kotlin
package com.code101.taskstart.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.selection.toggleable
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.Role
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
    onHideDoneChange: (Boolean) -> Unit,
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
                text = stringResource(R.string.open_count, state.allTasks.count { !it.done }),
                style = MaterialTheme.typography.titleMedium,
            )
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .toggleable(
                        value = state.hideDone,
                        role = Role.Switch,
                        onValueChange = onHideDoneChange,
                    ),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Switch(checked = state.hideDone, onCheckedChange = null)
                Text(stringResource(R.string.hide_done))
            }
            OutlinedButton(
                onClick = onLoadSamples,
                enabled = state.importState != ImportState.Loading,
            ) {
                Text(stringResource(R.string.load_samples))
            }
            ImportStatus(state.importState)
            if (state.visibleTasks.isEmpty()) {
                Text(text = stringResource(R.string.empty_list))
            }
            LazyColumn(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                items(state.visibleTasks, key = { it.id }) { task ->
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
                allTasks = listOf(Task(1, "Buy milk"), Task(2, "Pay rent", done = true)),
                hideDone = true,
            ),
            onDraftChange = { },
            onAdd = { },
            onToggle = { },
            onOpen = { },
            onLoadSamples = { },
            onHideDoneChange = { },
        )
    }
}
```
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
fun TasksApp(viewModel: TasksViewModel = viewModel(factory = TasksViewModel.Factory)) {
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
                onHideDoneChange = viewModel::onHideDoneChange,
            )
        }
        composable(
            route = "detail/{taskId}",
            arguments = listOf(navArgument("taskId") { type = NavType.IntType }),
        ) { entry ->
            val taskId = entry.arguments?.getInt("taskId")
            DetailScreen(
                task = state.allTasks.firstOrNull { it.id == taskId },
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
Predict before you run: you add "Walk dog", toggle "Hide done tasks", and force-stop the app (**Settings > Apps > Tasks Start > Force stop**). What do you expect to see when you open it again?

## Run it
Run the app. Add two tasks, mark one done, switch on **Hide done tasks**, then force-stop the app and open it again.

Expected result (described, not yet seen): the first start shows the empty message. After adding tasks, they are still there after a force stop, the done one is hidden because the switch is still on, and "Load sample tasks" adds five more rows that also persist. You can look inside the database in Android Studio: **View > Tool Windows > App Inspection > Database Inspector**, choose your running app and its `tasks.db`, and open the `tasks` table.

## How it works
**Two stores, two jobs.** *Preferences DataStore* keeps key-value pairs (`hide_done` = true) and exposes them as a `Flow`; it is for small settings. *Room* is a layer over **SQLite**, the database built into Android, and is for lists of records.

**Room's three parts.**
- `@Entity` marks a class as a table. Each property is a column: `id`, `title`, `done`. `@PrimaryKey(autoGenerate = true)` lets the database number the rows (`id = 0` means "new").
- `@Dao` (data access object) is an interface of questions you ask the table. `@Query("SELECT * FROM tasks ORDER BY id")` is **SQL**, the language of databases. `:id` in a query takes the function parameter `id`. KSP writes the code behind each function when you build.
- `@Database` ties the entities and the DAO together. `version = 1` is the schema version; when you change a table later you raise it and write a migration (level 201, lesson 07). `exportSchema = false` skips writing a schema file, which we do not need yet.

**Flow from Room.** `fun observeAll(): Flow<List<TaskEntity>>` returns a flow that **emits a new list every time the table changes**. So the screen needs no "refresh" call: add, toggle or import changes the table and the list recomposes. Room's `suspend` functions and flows run off the main thread by themselves.

**Repository.** `TasksRepository` is the one class that knows where data comes from (Room, DataStore, the network). The ViewModel asks it and does not care. If you change the database later, only the repository changes. This is the first step of the layers in level 201.

**`combine`.** `combine(a, b, c, d) { ... }` builds one new value from the latest values of four flows. `TasksUiState` is rebuilt whenever the tasks, the setting, the draft or the import status changes. `stateIn(... WhileSubscribed(5_000))` turns it into a `StateFlow` that keeps running for five seconds after the last listener leaves (it survives a rotation) and then stops, which saves work. `initialValue = TasksUiState()` is shown for a moment while the first database read is under way.

**Application and `lazy`.** The `Application` object lives as long as the app process. We build the database once there (`by lazy` means "build it the first time it is used"), and a **singleton** is exactly that: one shared instance. Two databases open on the same file would be a bug. The `Factory` tells Android how to create `TasksViewModel` with its repository: `viewModelFactory { initializer { ... } }`. A manual setup like this is what level 201 replaces with Hilt.

**Where is the file?** The database sits in the app's private storage, which other apps cannot read. DataStore is also private but not encrypted; never keep passwords or tokens in it (level 201, lesson 06).

## Try it
1. **Guided:** in the starter `TaskDao.kt` two functions are missing, shown as TODO comments. Add them.

**File: `app/src/main/kotlin/com/code101/taskstart/data/TaskDao.kt`**
```kotlin
package com.code101.taskstart.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface TaskDao {
    @Query("SELECT * FROM tasks ORDER BY id")
    fun observeAll(): Flow<List<TaskEntity>>

    @Insert
    suspend fun insert(task: TaskEntity)

    @Insert
    suspend fun insertAll(tasks: List<TaskEntity>)

    @Query("UPDATE tasks SET done = NOT done WHERE id = :id")
    suspend fun toggle(id: Int)

    @Query("DELETE FROM tasks WHERE id = :id")
    suspend fun delete(id: Int)

    // TODO 1: add a suspend function deleteDone() with a @Query that removes every task whose done column is 1

    // TODO 2: add a function observeOpenCount(): Flow<Int> with a @Query that counts the tasks whose done column is 0
}
```
Expected: the project still builds. (Room checks your SQL while building: a typo in a table or column name is a build error.)
2. **Change:** use `deleteDone()` through the repository and the ViewModel, and add a button "Clear done tasks" to `HomeScreen`, as you did with `clearDone` in lesson 09.
3. **Stretch (optional):** use `observeOpenCount()` for the heading instead of counting in the screen. What is better about asking the database?

<details><summary>Solution</summary>

**File: `app/src/main/kotlin/com/code101/taskstart/data/TaskDao.kt`**
```kotlin
package com.code101.taskstart.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface TaskDao {
    @Query("SELECT * FROM tasks ORDER BY id")
    fun observeAll(): Flow<List<TaskEntity>>

    @Insert
    suspend fun insert(task: TaskEntity)

    @Insert
    suspend fun insertAll(tasks: List<TaskEntity>)

    @Query("UPDATE tasks SET done = NOT done WHERE id = :id")
    suspend fun toggle(id: Int)

    @Query("DELETE FROM tasks WHERE id = :id")
    suspend fun delete(id: Int)

    @Query("DELETE FROM tasks WHERE done = 1")
    suspend fun deleteDone()

    @Query("SELECT COUNT(*) FROM tasks WHERE done = 0")
    fun observeOpenCount(): Flow<Int>
}
```
Room stores a `Boolean` as the integer 1 or 0, so `done = 1` means "done".

</details>

## Check yourself
1. When would you use DataStore, and when Room? <details><summary>Answer</summary>DataStore for a few small settings; Room for lists of records you want to query.</details>
2. Why does the screen update without a "refresh" call? <details><summary>Answer</summary>The DAO's query returns a `Flow` that emits a new list whenever the table changes.</details>
3. What does the repository do for the ViewModel? <details><summary>Answer</summary>It hides where the data comes from, so storage can change without touching the UI layer.</details>
4. Find the bug: `@Query("SELECT * FROM task")` while the table is called `tasks`. <details><summary>Answer</summary>Room reports an unknown table at build time; the name must match `tableName = "tasks"`.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| A Room build error that names a table or column that does not exist (typical) | A typo in a `@Query` | Match the names in `@Entity` |
| `Unresolved reference 'ksp'` in `build.gradle.kts` (typical) | The plugin alias is missing in the root file or catalog | Add `ksp` to the catalog and `apply false` to the root plugins |
| The app crashes at start with a message about the `Application` class not found (typical) | `android:name=".TasksApplication"` does not match the file | Check the class name and package |
| Tasks vanish on every start | A new database is created in memory, for example `Room.inMemoryDatabaseBuilder` | Use `Room.databaseBuilder(...)` with a file name |
| `Unresolved reference 'Factory'` | The `companion object` is missing | Add it inside `TasksViewModel` |
| An error after changing an entity (typical: Room cannot verify the data integrity) | The table changed but `version` did not | During development, uninstall the app; real apps use a migration (level 201) |

## Best practice
Use Room for structured local data and DataStore for small settings, put them behind a repository, and expose observable flows so the UI always shows what is stored. Source: Room https://developer.android.com/training/data-storage/room and DataStore https://developer.android.com/topic/libraries/architecture/datastore

## Going further
- Save data with Room: https://developer.android.com/training/data-storage/room
- Level 201 lesson 07 adds relations, schema export and migrations, and lesson 08 adds an offline queue.

## Summary
- You stored tasks in a Room database and a setting in DataStore.
- You read the table as a `Flow` and combined flows into one UI state.
- You put the storage behind a repository and built it once in the `Application`.
- Your tasks now survive closing the app.

## Next lesson
12. Project: a task list app: finish the app with filters, editing, and a TalkBack pass.
