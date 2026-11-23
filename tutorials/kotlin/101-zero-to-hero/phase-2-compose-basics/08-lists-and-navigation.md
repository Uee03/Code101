---
track: kotlin
level: 101
phase: 2
phase_name: compose-basics
lesson: 08
title: Lists (LazyColumn) and navigation
time: 60-75 min
prerequisites: [05, 06, 07]
versions: { navigation-compose: "2.10.2", compose-bom: "2026.11.01", kotlin: "2.4.21" }
verified: not yet run
source: source/kotlin/101-zero-to-hero/phase-2-compose-basics/08-lists-and-navigation/
assets: [ui/list, ui/check, files/trash]
---

# 08. Lists (LazyColumn) and navigation

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- show many items with `LazyColumn` and explain why it is better than a `Column` of cards;
- give list items stable keys;
- move between two screens with a `NavHost` and pass an argument;
- delete a task from a detail screen and return to the list.

## Recap
1. What is state hoisting? <details><summary>Answer</summary>The state lives in a parent; children receive values and report events with lambdas.</details>
2. Why does a task disappear on rotation in lesson 07? <details><summary>Answer</summary>The list is kept with `remember`, which does not survive an activity recreation.</details>

## Why it matters
A phone book has thousands of names, but you only ever see a page at a time. A `Column` with a thousand cards would build all thousand, even the ones nobody scrolls to. A `LazyColumn` builds only what is on the screen, like turning to the right page. And most apps have more than one screen: a list, and a detail page you tap through to. **Navigation** is the system that remembers where you are and where *Back* goes.

## What you will build
The list becomes a `LazyColumn`. Tapping a task title opens a **Task details** screen with a *Delete task* button and a *Back* button. A `NavHost` holds both screens.

## Before you start
- The project from lesson 07.
- Time: about 60 to 75 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/kotlin/101-zero-to-hero/phase-2-compose-basics/08-lists-and-navigation/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).

Files that stay **exactly as in lesson 07**: `settings.gradle.kts`, `build.gradle.kts`, `gradle.properties`, `gradle/wrapper/gradle-wrapper.properties`, `.gitignore`, the manifest, `Theme.kt`, `model/Task.kt`, `AddTaskBar.kt`, the four `ic_*.xml` drawables and `LICENSE-ICONS-CC0.txt`. **Delete** `ClickCounter.kt`: we are done with it. Changed or new: `libs.versions.toml`, `app/build.gradle.kts`, `strings.xml`, `TaskCard.kt`, `HomeScreen.kt`, `DetailScreen.kt`, `TasksApp.kt` and `MainActivity.kt`.

New words: `LazyColumn`, `items`, `key`, `NavHost`, `NavController`, route, argument, back stack, `popBackStack`.

## Steps

### Step 1. Add the navigation library
**File: `gradle/libs.versions.toml`**
```toml
[versions]
agp = "9.5.1"
kotlin = "2.4.21"
compose = "2026.11.01"
activity = "1.13.0"
navigation = "2.10.2"

[libraries]
compose-bom = { module = "androidx.compose:compose-bom", version.ref = "compose" }
compose-material3 = { module = "androidx.compose.material3:material3" }
compose-ui = { module = "androidx.compose.ui:ui" }
compose-ui-tooling = { module = "androidx.compose.ui:ui-tooling" }
compose-ui-tooling-preview = { module = "androidx.compose.ui:ui-tooling-preview" }
activity-compose = { module = "androidx.activity:activity-compose", version.ref = "activity" }
navigation = { module = "androidx.navigation:navigation-compose", version.ref = "navigation" }

[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }
kotlin-compose = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
```
Two new lines compared with lesson 07: `navigation = "2.10.2"` and the `navigation` library.

**File: `app/build.gradle.kts`**
```kotlin
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.compose)
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
    debugImplementation(libs.compose.ui.tooling)
}
```
One new line: `implementation(libs.navigation)`. Sync Gradle.

### Step 2. Strings
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
</resources>
```

### Step 3. The task card opens details
**File: `app/src/main/kotlin/com/code101/taskstart/ui/TaskCard.kt`**
```kotlin
package com.code101.taskstart.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.Checkbox
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import com.code101.taskstart.R
import com.code101.taskstart.model.Task

@Composable
fun TaskCard(
    task: Task,
    onToggle: () -> Unit,
    onOpen: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val toggleLabel = stringResource(R.string.toggle_task, task.title)
    val openLabel = stringResource(R.string.open_details)
    Card(modifier = modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.padding(end = 16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Checkbox(
                checked = task.done,
                onCheckedChange = { onToggle() },
                modifier = Modifier.semantics { contentDescription = toggleLabel },
            )
            Text(
                text = task.title,
                style = MaterialTheme.typography.titleMedium,
                textDecoration = if (task.done) TextDecoration.LineThrough else TextDecoration.None,
                modifier = Modifier
                    .weight(1f)
                    .clickable(onClickLabel = openLabel, onClick = onOpen)
                    .padding(vertical = 16.dp),
            )
            Text(
                text = stringResource(if (task.done) R.string.status_done else R.string.status_open),
                style = MaterialTheme.typography.labelLarge,
            )
        }
    }
}
```
New: the `onOpen` parameter and `.clickable(onClickLabel = ..., onClick = onOpen)` on the title. `onClickLabel` is what a screen reader says for the tap action ("double tap to open details").

### Step 4. The home screen with a LazyColumn
`HomeScreen` no longer owns the tasks: its caller passes the list and the events (state hoisting, one level higher).

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
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.code101.taskstart.R
import com.code101.taskstart.model.Task
import com.code101.taskstart.ui.theme.TasksTheme

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    tasks: List<Task>,
    onAdd: (String) -> Unit,
    onToggle: (Int) -> Unit,
    onOpen: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    var draft by rememberSaveable { mutableStateOf("") }

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
                draft = draft,
                onDraftChange = { draft = it },
                onAdd = {
                    val title = draft.trim()
                    if (title.isNotEmpty()) {
                        onAdd(title)
                        draft = ""
                    }
                },
            )
            Text(
                text = stringResource(R.string.open_count, tasks.count { !it.done }),
                style = MaterialTheme.typography.titleMedium,
            )
            if (tasks.isEmpty()) {
                Text(text = stringResource(R.string.empty_list))
            }
            LazyColumn(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                items(tasks, key = { it.id }) { task ->
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

@Preview(showBackground = true)
@Composable
fun HomeScreenPreview() {
    TasksTheme {
        HomeScreen(
            tasks = listOf(Task(1, "Buy milk"), Task(2, "Pay rent", done = true)),
            onAdd = { },
            onToggle = { },
            onOpen = { },
        )
    }
}
```
Notes: the draft text is still local UI state (it only matters to this screen). `items(tasks, key = { it.id })` gives each row an identity.

### Step 5. The detail screen
**File: `app/src/main/kotlin/com/code101/taskstart/ui/DetailScreen.kt`**
```kotlin
package com.code101.taskstart.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.code101.taskstart.R
import com.code101.taskstart.model.Task
import com.code101.taskstart.ui.theme.TasksTheme

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DetailScreen(
    task: Task?,
    onBack: () -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Scaffold(
        modifier = modifier,
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.details)) },
                navigationIcon = {
                    TextButton(onClick = onBack) {
                        Text(stringResource(R.string.back))
                    }
                },
            )
        },
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .padding(innerPadding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            if (task == null) {
                Text(text = stringResource(R.string.task_not_found))
            } else {
                Text(text = task.title, style = MaterialTheme.typography.headlineMedium)
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Icon(
                        painter = painterResource(if (task.done) R.drawable.ic_check else R.drawable.ic_list),
                        contentDescription = null,
                    )
                    Text(
                        text = stringResource(if (task.done) R.string.status_done else R.string.status_open),
                        style = MaterialTheme.typography.titleMedium,
                    )
                }
                OutlinedButton(onClick = onDelete) {
                    Icon(
                        painter = painterResource(R.drawable.ic_trash),
                        contentDescription = null,
                        modifier = Modifier.padding(end = 8.dp),
                    )
                    Text(stringResource(R.string.delete_task))
                }
            }
        }
    }
}

@Preview(showBackground = true)
@Composable
fun DetailScreenPreview() {
    TasksTheme {
        DetailScreen(task = Task(1, "Buy milk"), onBack = { }, onDelete = { })
    }
}
```
`task` is nullable (`Task?`): the screen can be asked for a task that is already gone, and the lesson 02 null tools handle it.

### Step 6. The navigation host
**File: `app/src/main/kotlin/com/code101/taskstart/ui/TasksApp.kt`**
```kotlin
package com.code101.taskstart.ui

import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.remember
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.code101.taskstart.model.Task

@Composable
fun TasksApp() {
    val navController = rememberNavController()
    val tasks = remember {
        mutableStateListOf(
            Task(1, "Buy milk"),
            Task(2, "Call dentist"),
            Task(3, "Pay rent", done = true),
        )
    }

    NavHost(navController = navController, startDestination = "home") {
        composable("home") {
            HomeScreen(
                tasks = tasks,
                onAdd = { title ->
                    val nextId = (tasks.maxOfOrNull { it.id } ?: 0) + 1
                    tasks.add(Task(nextId, title))
                },
                onToggle = { id ->
                    val index = tasks.indexOfFirst { it.id == id }
                    if (index >= 0) {
                        tasks[index] = tasks[index].copy(done = !tasks[index].done)
                    }
                },
                onOpen = { id -> navController.navigate("detail/$id") },
            )
        }
        composable(
            route = "detail/{taskId}",
            arguments = listOf(navArgument("taskId") { type = NavType.IntType }),
        ) { entry ->
            val taskId = entry.arguments?.getInt("taskId")
            DetailScreen(
                task = tasks.firstOrNull { it.id == taskId },
                onBack = { navController.popBackStack() },
                onDelete = {
                    tasks.removeAll { it.id == taskId }
                    navController.popBackStack()
                },
            )
        }
    }
}
```

### Step 7. Start the app from the new entry point
**File: `app/src/main/kotlin/com/code101/taskstart/MainActivity.kt`**
```kotlin
package com.code101.taskstart

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.code101.taskstart.ui.TasksApp
import com.code101.taskstart.ui.theme.TasksTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            TasksTheme {
                TasksApp()
            }
        }
    }
}
```
Predict before you run: you open the details of "Call dentist", press Delete task. Which screen do you see next, and how many tasks are in the list?

## Run it
Sync, then run the app.

Expected result (described, not yet seen): the home screen as before. Tapping a task title opens **Task details** with the title in large text, its state, a "Delete task" button and a "Back" button in the top bar. "Back" (or the system back gesture) returns to the list. "Delete task" removes the task and returns to a list that has one task fewer; the heading's count updates.

## How it works
**LazyColumn.** Instead of `Column { tasks.forEach { ... } }` we write `LazyColumn { items(tasks) { ... } }`. The words *lazy* means "only when needed": it composes the rows currently visible plus a few around them, and recycles the rest, so a list of ten thousand tasks stays fast. `Column` composes everything immediately.

**Keys.** `key = { it.id }` tells Compose which row is which. When a task is inserted or removed, Compose can keep each remaining row's state and animate correctly, instead of guessing by position. The key must be unique and stable, so use an id, never the title.

**NavHost.** A `NavHost` is a frame that shows one **destination** at a time. `rememberNavController()` creates the **NavController**, the object that knows the **back stack** (the pile of screens you have visited, like a stack of plates: back removes the top one). Each `composable("route") { ... }` registers a destination under a route, a text address such as `home` or `detail/2`.

**Arguments.** The route `"detail/{taskId}"` has a placeholder. `navController.navigate("detail/$id")` fills it. `navArgument("taskId") { type = NavType.IntType }` declares it as a number, and `entry.arguments?.getInt("taskId")` reads it; the `?` is the safe call from lesson 02, because `arguments` can be `null`.

**Why the list lives in `TasksApp`.** Both screens need the same tasks, so the state is hoisted above the `NavHost`. Misconception: a screen does not "own" the app's data; it shows what it is given. The list still lives only in memory: rotate the phone and it resets. Lesson 09 fixes this.

**Back.** `popBackStack()` removes the top destination. Android's system back button does the same without any code.

## Try it
1. **Guided:** create `ui/EmptyState.kt` from this starter and finish the TODOs, then check it in the preview. Afterwards replace the plain `Text(text = stringResource(R.string.empty_list))` in `HomeScreen` by `EmptyState(message = stringResource(R.string.empty_list))`.

**File: `app/src/main/kotlin/com/code101/taskstart/ui/EmptyState.kt`**
```kotlin
package com.code101.taskstart.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.code101.taskstart.R
import com.code101.taskstart.ui.theme.TasksTheme

@Composable
fun EmptyState(message: String, modifier: Modifier = Modifier) {
    // TODO 1: show a Row (padding 16.dp, centred vertically, 8.dp between items)
    // TODO 2: first child: Icon with R.drawable.ic_list and contentDescription = null
    // TODO 3: second child: Text with the message
}

@Preview(showBackground = true)
@Composable
fun EmptyStatePreview() {
    TasksTheme {
        EmptyState(message = stringResource(R.string.empty_list))
    }
}
```
Expected preview: a list icon followed by "No tasks yet. Add one above.".
2. **Change:** delete every task and check that the empty message appears; then add one again.
3. **Stretch (optional):** add a third route `about` with a screen of your choice and a text button on the home screen that navigates to it.

<details><summary>Solution</summary>

**File: `app/src/main/kotlin/com/code101/taskstart/ui/EmptyState.kt`**
```kotlin
package com.code101.taskstart.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.code101.taskstart.R
import com.code101.taskstart.ui.theme.TasksTheme

@Composable
fun EmptyState(message: String, modifier: Modifier = Modifier) {
    Row(
        modifier = modifier.padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Icon(
            painter = painterResource(R.drawable.ic_list),
            contentDescription = null,
        )
        Text(text = message)
    }
}

@Preview(showBackground = true)
@Composable
fun EmptyStatePreview() {
    TasksTheme {
        EmptyState(message = stringResource(R.string.empty_list))
    }
}
```
</details>

## Check yourself
1. Why is `LazyColumn` faster than `Column` for 5,000 items? <details><summary>Answer</summary>It composes only the visible rows (plus a few), while `Column` builds all of them.</details>
2. What is a good key for a task row and why? <details><summary>Answer</summary>Its `id`: unique and stable. A title may repeat or change.</details>
3. What does `navController.navigate("detail/2")` do? <details><summary>Answer</summary>It opens the destination whose route matches `detail/{taskId}` with `taskId` = 2 and puts it on the back stack.</details>
4. Find the bug: the route is `"detail/{taskId}"` but the code calls `navigate("details/2")`. <details><summary>Answer</summary>The text does not match any route, so navigation fails; route texts must match exactly.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| A crash that mentions "Navigation destination ... cannot be found in the navigation graph" (typical) | The text passed to `navigate` does not match a registered route | Make the text identical to the route pattern |
| `Unresolved reference 'LazyColumn'` (typical) | Missing import or `items` from the wrong package | Import `androidx.compose.foundation.lazy.LazyColumn` and `androidx.compose.foundation.lazy.items` |
| A crash mentioning a duplicate key (typical) | Two items have the same key | Use a unique id; here `nextId` is max plus one |
| Back closes the app | There is only one destination on the back stack | Expected on the home screen |
| Nothing happens when tapping the card | Only the title is clickable | Tap the title text |

## Best practice
Always give `LazyColumn` items a stable `key`, and keep the `NavController` in the top-level composable so that screens receive lambdas, not the controller. Source: Lists and grids in Compose https://developer.android.com/develop/ui/compose/lists and Navigation with Compose https://developer.android.com/develop/ui/compose/navigation

## Going further
- Type-safe routes with `@Serializable` classes (used in the 201 level and the capstone): https://developer.android.com/guide/navigation/design/type-safety
- Lesson 09 moves the list into a ViewModel so it survives a rotation.

## Summary
- You replaced a column of cards with a `LazyColumn` with stable keys.
- You added a `NavHost` with two routes and an argument.
- You deleted a task from the detail screen and went back.

## Next lesson
09. ViewModel and StateFlow: keeping state alive across rotation, outside the composables.
