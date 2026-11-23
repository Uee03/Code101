---
track: kotlin
level: 101
phase: 2
phase_name: compose-basics
lesson: 07
title: State and recomposition (remember)
time: 60-75 min
prerequisites: [05, 06]
versions: { compose-bom: "2026.11.01", kotlin: "2.4.21" }
verified: not yet run
source: source/kotlin/101-zero-to-hero/phase-2-compose-basics/07-state-and-recomposition/
assets: [ui/plus]
---

# 07. State and recomposition (remember)

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- explain what **state** is and what **recomposition** means;
- use `remember`, `mutableStateOf` and `rememberSaveable`, and say what each keeps alive;
- add a task, toggle a task and see the screen update;
- explain **state hoisting**: why `AddTaskBar` gets its text from its caller.

## Recap
1. What does `Modifier.weight(1f)` do in a `Row`? <details><summary>Answer</summary>It gives the item the remaining width.</details>
2. Why does a decorative icon get `contentDescription = null`? <details><summary>Answer</summary>A screen reader should skip it, because nearby text already says what it means.</details>
3. What does `copy(done = true)` return for a data class? <details><summary>Answer</summary>A new object with `done` changed; the old one is untouched.</details>

## Why it matters
A whiteboard shows what was written on it. If you wipe it and redraw, it shows the new text. The screen of an app is the whiteboard, and **state** is the information the screen is drawn from (the list of tasks, the text typed so far). In Compose you never poke the screen; you change the state, and Compose redraws everything that used it. That redraw is called **recomposition**.

## What you will build
The home screen becomes interactive: a text field and an "Add" button put a new task into the list, a checkbox on each card toggles done, and a heading counts the open tasks. You also try a small click counter in the preview.

## Before you start
- The project from lesson 06.
- Time: about 60 to 75 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/kotlin/101-zero-to-hero/phase-2-compose-basics/07-state-and-recomposition/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).

Files that stay **exactly as in lesson 06**: all build files, the manifest, `Theme.kt`, `MainActivity.kt`, `model/Task.kt`, the four `ic_*.xml` drawables and `LICENSE-ICONS-CC0.txt`. Changed or new: `strings.xml`, `TaskCard.kt`, `AddTaskBar.kt`, `HomeScreen.kt` and `ClickCounter.kt`.

New words: state, recomposition, `remember`, `mutableStateOf`, `by` delegate, `rememberSaveable`, `mutableStateListOf`, state hoisting, `Checkbox`, `OutlinedTextField`.

## Steps

### Step 1. Update the strings
**File: `app/src/main/res/values/strings.xml`**
```xml
<resources>
    <string name="app_name">Tasks Start</string>
    <string name="new_task_label">New task</string>
    <string name="add">Add</string>
    <string name="open_count">%1$d open</string>
    <string name="toggle_task">Mark %1$s as done or open</string>
    <string name="status_done">Done</string>
    <string name="status_open">Open</string>
    <string name="taps">Taps: %1$d</string>
</resources>
```
`%1$d` is a placeholder for a whole number (`d`). `toggle_task` is the sentence a screen reader speaks for each checkbox.

### Step 2. Meet state with a click counter
Create `ui/ClickCounter.kt` in `app/src/main/kotlin/com/code101/taskstart/ui`.

**File: `app/src/main/kotlin/com/code101/taskstart/ui/ClickCounter.kt`**
```kotlin
package com.code101.taskstart.ui

import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import com.code101.taskstart.R
import com.code101.taskstart.ui.theme.TasksTheme

@Composable
fun ClickCounter(modifier: Modifier = Modifier) {
    var count by remember { mutableStateOf(0) }
    Button(onClick = { count += 1 }, modifier = modifier) {
        Text(stringResource(R.string.taps, count))
    }
}

@Preview(showBackground = true)
@Composable
fun ClickCounterPreview() {
    TasksTheme {
        ClickCounter()
    }
}
```
Open the file in **Split** view and press **Start Interactive Mode** (the hand icon above the preview). Click the button a few times.

Predict first: what does the button show after three clicks? And what would it show if `count` were a plain `var count = 0` without `remember`?

Expected result (described, not yet seen): the button text changes to `Taps: 1`, `Taps: 2`, `Taps: 3`.

Try the experiment: change line `var count by remember { mutableStateOf(0) }` into `var count = 0` and see that clicking changes nothing (and `count` cannot be seen by Compose). Put it back before you go on.

### Step 3. The task card with a checkbox
**File: `app/src/main/kotlin/com/code101/taskstart/ui/TaskCard.kt`**
```kotlin
package com.code101.taskstart.ui

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
    modifier: Modifier = Modifier,
) {
    val toggleLabel = stringResource(R.string.toggle_task, task.title)
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
                modifier = Modifier.weight(1f),
            )
            Text(
                text = stringResource(if (task.done) R.string.status_done else R.string.status_open),
                style = MaterialTheme.typography.labelLarge,
            )
        }
    }
}
```
`TaskCard` has **no state of its own**. It receives `task` (what to show) and `onToggle` (what to call when the user taps). It is a **stateless** composable, so it is easy to reuse and preview.

### Step 4. The add bar, also stateless
**File: `app/src/main/kotlin/com/code101/taskstart/ui/AddTaskBar.kt`**
```kotlin
package com.code101.taskstart.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.code101.taskstart.R

@Composable
fun AddTaskBar(
    draft: String,
    onDraftChange: (String) -> Unit,
    onAdd: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier = modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        OutlinedTextField(
            value = draft,
            onValueChange = onDraftChange,
            label = { Text(stringResource(R.string.new_task_label)) },
            singleLine = true,
            modifier = Modifier.weight(1f),
        )
        Button(onClick = onAdd) {
            Icon(
                painter = painterResource(R.drawable.ic_plus),
                contentDescription = null,
                modifier = Modifier.padding(end = 8.dp),
            )
            Text(stringResource(R.string.add))
        }
    }
}
```

### Step 5. The home screen owns the state
**File: `app/src/main/kotlin/com/code101/taskstart/ui/HomeScreen.kt`**
```kotlin
package com.code101.taskstart.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
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
fun HomeScreen(modifier: Modifier = Modifier) {
    val tasks = remember {
        mutableStateListOf(
            Task(1, "Buy milk"),
            Task(2, "Call dentist"),
            Task(3, "Pay rent", done = true),
        )
    }
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
                        val nextId = (tasks.maxOfOrNull { it.id } ?: 0) + 1
                        tasks.add(Task(nextId, title))
                        draft = ""
                    }
                },
            )
            Text(
                text = stringResource(R.string.open_count, tasks.count { !it.done }),
                style = MaterialTheme.typography.titleMedium,
            )
            tasks.forEachIndexed { index, task ->
                TaskCard(
                    task = task,
                    onToggle = { tasks[index] = task.copy(done = !task.done) },
                )
            }
        }
    }
}

@Preview(showBackground = true)
@Composable
fun HomeScreenPreview() {
    TasksTheme {
        HomeScreen()
    }
}
```
Predict before you run: you type "Walk dog", press Add, then rotate the emulator (**Ctrl+Left** or the rotate buttons in the emulator toolbar). Which of these survive the rotation: the three original tasks, the new task, the text still in the field?

## Run it
Run the app. Type a task name and press **Add**. Tick a checkbox. Then rotate the device.

Expected result (described, not yet seen):
- the new card appears at the bottom and the heading changes, for example from `2 open` to `3 open`;
- ticking a box strikes the title through, changes "Open" to "Done" and lowers the open count by one;
- after the rotation the list is back to the three original tasks (the new task is lost), but text you had typed and not yet added is still in the field.

The loss of the new task is not a mistake in your typing: it is exactly what lesson 09 fixes.

## How it works
**State and recomposition.** `mutableStateOf(0)` creates an object that holds a value and **tells Compose when the value changes**. Every composable that read it is run again (recomposed) with the new value. Compose may re-run a composable many times, in any order, so a composable must not do work that you would not want repeated.

**`remember`.** Recomposition runs your function again from the top, and a normal local variable would be created fresh each time (0 again). `remember { ... }` stores the object once and hands back the same one on later recompositions. Misconception: `remember` does not make the value permanent. If the screen leaves the composition, or the activity is recreated by a rotation, the remembered value is gone.

**`by` and `getValue`/`setValue`.** `var count by remember { mutableStateOf(0) }` uses a **delegate** so that you can write `count` and `count += 1` instead of `count.value`. The imports `getValue` and `setValue` make the delegate work.

**`rememberSaveable`.** It also writes simple values (text, numbers, booleans) into the bundle Android keeps through a rotation, so `draft` survives. The task list does not survive because `remember` was used.

**`mutableStateListOf`.** A list whose changes are observed. `tasks.add(...)` and `tasks[index] = ...` recompose the screen. A plain `mutableListOf` would change silently and nothing would redraw.

**Immutable data, new copies.** We never edit a `Task`; we write `task.copy(done = !task.done)` and put the new object in the list. Compose can see that the item changed.

**State hoisting.** `AddTaskBar` and `TaskCard` do not own state. They receive values and report events upward (`onDraftChange`, `onAdd`, `onToggle`). `HomeScreen` owns the state. This "state down, events up" pattern is called **state hoisting**. It makes each part testable and reusable, and gives one place that decides what the data is.

## Try it
1. **Guided:** replace `ClickCounter.kt` by this starter, make the three TODOs work, and add `<string name="reset">Reset</string>` to `strings.xml`. Check it in interactive preview.

**File: `app/src/main/kotlin/com/code101/taskstart/ui/ClickCounter.kt`**
```kotlin
package com.code101.taskstart.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import com.code101.taskstart.R
import com.code101.taskstart.ui.theme.TasksTheme

@Composable
fun ClickCounter(modifier: Modifier = Modifier) {
    // TODO 1: make count a state value that survives a rotation (by delegate, rememberSaveable and mutableStateOf)
    var count = 0
    Column(modifier = modifier) {
        Button(onClick = { /* TODO 2: increase count by one */ }) {
            Text(stringResource(R.string.taps, count))
        }
        // TODO 3: add a Button with the text stringResource(R.string.reset) that sets count back to 0
    }
}

@Preview(showBackground = true)
@Composable
fun ClickCounterPreview() {
    TasksTheme {
        ClickCounter()
    }
}
```
Expected: a `Taps: 0` button that counts up, and a `Reset` button below it that sets it back to `Taps: 0`.
2. **Change:** in `HomeScreen`, make the heading say how many tasks there are in total as well, for example "2 open, 3 in total" (you need a new string with two placeholders).
3. **Stretch (optional):** make `HomeScreen` ignore an empty name and also a name that already exists in the list.

<details><summary>Solution</summary>

**File: `app/src/main/kotlin/com/code101/taskstart/ui/ClickCounter.kt`**
```kotlin
package com.code101.taskstart.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.tooling.preview.Preview
import com.code101.taskstart.R
import com.code101.taskstart.ui.theme.TasksTheme

@Composable
fun ClickCounter(modifier: Modifier = Modifier) {
    var count by rememberSaveable { mutableStateOf(0) }
    Column(modifier = modifier) {
        Button(onClick = { count += 1 }) {
            Text(stringResource(R.string.taps, count))
        }
        Button(onClick = { count = 0 }) {
            Text(stringResource(R.string.reset))
        }
    }
}

@Preview(showBackground = true)
@Composable
fun ClickCounterPreview() {
    TasksTheme {
        ClickCounter()
    }
}
```
**File: `app/src/main/res/values/strings.xml`**
```xml
<resources>
    <string name="app_name">Tasks Start</string>
    <string name="new_task_label">New task</string>
    <string name="add">Add</string>
    <string name="open_count">%1$d open</string>
    <string name="toggle_task">Mark %1$s as done or open</string>
    <string name="status_done">Done</string>
    <string name="status_open">Open</string>
    <string name="taps">Taps: %1$d</string>
    <string name="reset">Reset</string>
</resources>
```
</details>

## Check yourself
1. What happens to a plain `var count = 0` inside a composable on every recomposition? <details><summary>Answer</summary>It is created again as 0, so the change is lost; use `remember`.</details>
2. What is the difference between `remember` and `rememberSaveable`? <details><summary>Answer</summary>`rememberSaveable` also survives an activity recreation such as a rotation (for simple types); `remember` does not.</details>
3. Why does `TaskCard` receive `onToggle` instead of changing the task itself? <details><summary>Answer</summary>It is stateless; the owner of the state (`HomeScreen`) decides how the data changes (state hoisting).</details>
4. Predict: you change `mutableStateListOf` to `mutableListOf` in `HomeScreen`. What happens when you press Add? <details><summary>Answer</summary>The list changes but Compose is not told, so the screen does not update (and the value is also lost on recomposition).</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| Nothing changes on screen when you click | The value is a normal variable or a normal list | Use `mutableStateOf` / `mutableStateListOf` inside `remember` |
| Red `by` with a message about `getValue` (typical) | The imports `androidx.compose.runtime.getValue` and `setValue` are missing | Add them (Alt+Enter) |
| The counter shows 0 again after rotating | `remember` was used | Use `rememberSaveable` |
| `Unresolved reference 'rememberSaveable'` (typical) | Missing import `androidx.compose.runtime.saveable.rememberSaveable` | Add it |
| Tasks are lost after rotating | State held in `remember` | Expected in this lesson; lesson 09 moves it into a ViewModel |

## Best practice
Keep state as low as possible but as high as needed: hoist it to the lowest common parent of the composables that use it, and pass down values and events. Source: State and Jetpack Compose https://developer.android.com/develop/ui/compose/state

## Going further
- State hoisting: https://developer.android.com/develop/ui/compose/state-hoisting
- Lesson 09 replaces `remember` for the task list by a ViewModel, and lesson 11 saves the tasks in a database.

## Summary
- You explained state and recomposition with a counter.
- You used `remember`, `rememberSaveable` and `mutableStateListOf`.
- You added tasks and toggled them, with stateless `TaskCard` and `AddTaskBar`.
- You saw why the list is lost on rotation, which prepares lesson 09.

## Next lesson
08. Lists (LazyColumn) and navigation: a scrolling list that stays fast, and a second screen.
