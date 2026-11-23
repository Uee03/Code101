---
track: kotlin
level: 101
phase: 2
phase_name: compose-basics
lesson: 06
title: Layouts and Material 3
time: 60-75 min
prerequisites: [05]
versions: { compose-bom: "2026.11.01", kotlin: "2.4.21", compileSdk: "37", minSdk: "26" }
verified: not yet run
source: source/kotlin/101-zero-to-hero/phase-2-compose-basics/06-layouts-and-material-3/
assets: [ui/plus, ui/check, files/trash, ui/list]
---

# 06. Layouts and Material 3

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- arrange composables with `Column`, `Row` and `Modifier`;
- build a screen from Material 3 parts: `Scaffold`, `TopAppBar`, `Card`, `FloatingActionButton`;
- convert a course SVG icon into an Android vector drawable and show it with `Icon`;
- explain why an icon needs a description, or none.

## Recap
1. What does `@Composable` mean? <details><summary>Answer</summary>The function describes part of the screen and can only be called from other composables.</details>
2. Where do user-visible texts belong? <details><summary>Answer</summary>In `res/values/strings.xml`, read with `stringResource`.</details>

## Why it matters
Furnishing a room starts with a plan: shelves in rows, a table in the middle, a lamp on top. Compose has the same three building blocks: `Column` (stack things top to bottom), `Row` (side by side) and `Box` (on top of each other). With those and a few ready-made Material parts, nearly every screen you have used on a phone can be described.

## What you will build
The home screen of the task app with a top bar, a heading, three task cards (one done) and a round "+" button. It is still static: nothing reacts yet (that is lesson 07).

## Before you start
- The `TasksStart` project from lesson 05 (copy it, or keep editing the same one).
- Time: about 60 to 75 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/kotlin/101-zero-to-hero/phase-2-compose-basics/06-layouts-and-material-3/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).

Files that stay **exactly as in lesson 05**: `settings.gradle.kts`, `build.gradle.kts`, `gradle.properties`, `gradle/libs.versions.toml`, `gradle/wrapper/gradle-wrapper.properties`, `.gitignore`, `app/build.gradle.kts`, `app/src/main/AndroidManifest.xml` and `ui/theme/Theme.kt`. Four things change: the icons (new), `strings.xml`, and the Kotlin files below.

New words: `Column`, `Row`, `Box`, `Arrangement`, `Alignment`, `dp`, `Card`, `TopAppBar`, `FloatingActionButton`, vector drawable, `contentDescription`, decorative image.

## Steps

### Step 1. Convert four icons from the course art library
The course keeps free icons (CC0, public domain) in `assets/art/icons` of the repository (https://github.com/Uee03/Code101). We need four: `ui/plus.svg`, `ui/check.svg`, `files/trash.svg` and `ui/list.svg`. An **SVG** is a picture described by text. Android cannot use SVG files directly; it uses **vector drawables**, an XML form of the same idea. Here is the whole conversion for `plus.svg`.

The source file `assets/art/icons/ui/plus.svg` contains:
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" role="img" aria-label="Plus">
  <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
</svg>
```
It draws two lines on a 24 by 24 grid, in a 2 unit pen, with round ends, no fill.

**Way A: Vector Asset Studio (the Studio wizard).**
1. In the Project panel right-click `app/src/main/res` and choose **New > Vector Asset**.
2. Set **Asset type** to **Local file (SVG, PSD)** and choose the `.svg` file with the folder button.
3. Name the asset `ic_plus` (lowercase letters, digits and underscores only). Keep the size 24 dp by 24 dp.
4. Press **Next**, then **Finish**. Studio writes `app/src/main/res/drawable/ic_plus.xml`.
5. Repeat for `ic_check` (check.svg), `ic_trash` (trash.svg) and `ic_list` (list.svg).

These icons use the colour word `currentColor` (meaning "the colour of the surrounding text"). If the importer warns about it or the result looks empty, use Way B.

**Way B: convert by hand.** Every SVG shape becomes a `<path>` with a path description (`pathData`):

| SVG | Becomes `pathData` |
|---|---|
| `<line x1="12" y1="5" x2="12" y2="19"/>` | `M12,5 L12,19` (M = move to, L = line to) |
| `<polyline points="20 6 9 17 4 12"/>` | `M20,6 L9,17 L4,12` |
| `<path d="M19 6v14..."/>` | copy `d` unchanged |
| `stroke="currentColor"` | `android:strokeColor="#FF000000"` (black; the app recolours it) |
| `stroke-width="2"`, `stroke-linecap="round"`, `stroke-linejoin="round"`, `fill="none"` | `android:strokeWidth="2"`, `android:strokeLineCap="round"`, `android:strokeLineJoin="round"`, `android:fillColor="#00000000"` |
| `viewBox="0 0 24 24"` | `android:viewportWidth="24"` and `android:viewportHeight="24"` |

Create the folder `app/src/main/res/drawable` and these four files.

**File: `app/src/main/res/drawable/ic_plus.xml`**
```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#00000000"
        android:pathData="M12,5 L12,19"
        android:strokeColor="#FF000000"
        android:strokeLineCap="round"
        android:strokeLineJoin="round"
        android:strokeWidth="2" />
    <path
        android:fillColor="#00000000"
        android:pathData="M5,12 L19,12"
        android:strokeColor="#FF000000"
        android:strokeLineCap="round"
        android:strokeLineJoin="round"
        android:strokeWidth="2" />
</vector>
```

**File: `app/src/main/res/drawable/ic_check.xml`**
```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#00000000"
        android:pathData="M20,6 L9,17 L4,12"
        android:strokeColor="#FF000000"
        android:strokeLineCap="round"
        android:strokeLineJoin="round"
        android:strokeWidth="2" />
</vector>
```

**File: `app/src/main/res/drawable/ic_trash.xml`**
```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#00000000"
        android:pathData="M3,6 L5,6 L21,6"
        android:strokeColor="#FF000000"
        android:strokeLineCap="round"
        android:strokeLineJoin="round"
        android:strokeWidth="2" />
    <path
        android:fillColor="#00000000"
        android:pathData="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"
        android:strokeColor="#FF000000"
        android:strokeLineCap="round"
        android:strokeLineJoin="round"
        android:strokeWidth="2" />
</vector>
```

**File: `app/src/main/res/drawable/ic_list.xml`**
```xml
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#00000000"
        android:pathData="M8,6 L21,6"
        android:strokeColor="#FF000000"
        android:strokeLineCap="round"
        android:strokeLineJoin="round"
        android:strokeWidth="2" />
    <path
        android:fillColor="#00000000"
        android:pathData="M8,12 L21,12"
        android:strokeColor="#FF000000"
        android:strokeLineCap="round"
        android:strokeLineJoin="round"
        android:strokeWidth="2" />
    <path
        android:fillColor="#00000000"
        android:pathData="M8,18 L21,18"
        android:strokeColor="#FF000000"
        android:strokeLineCap="round"
        android:strokeLineJoin="round"
        android:strokeWidth="2" />
    <path
        android:fillColor="#00000000"
        android:pathData="M3,6 L3.01,6"
        android:strokeColor="#FF000000"
        android:strokeLineCap="round"
        android:strokeLineJoin="round"
        android:strokeWidth="2" />
    <path
        android:fillColor="#00000000"
        android:pathData="M3,12 L3.01,12"
        android:strokeColor="#FF000000"
        android:strokeLineCap="round"
        android:strokeLineJoin="round"
        android:strokeWidth="2" />
    <path
        android:fillColor="#00000000"
        android:pathData="M3,18 L3.01,18"
        android:strokeColor="#FF000000"
        android:strokeLineCap="round"
        android:strokeLineJoin="round"
        android:strokeWidth="2" />
</vector>
```
The six paths in `ic_list` are the three bars and three bullet dots (a line from `3,6` to `3.01,6` is so short that the round pen end makes a dot).

Add the licence note: copy `assets/art/LICENSE-ICONS-CC0.txt` from the repository next to your project's `.gitignore` as `LICENSE-ICONS-CC0.txt`. CC0 does not require it, but keeping the file records where the icons came from.

### Step 2. The strings
**File: `app/src/main/res/values/strings.xml`**
```xml
<resources>
    <string name="app_name">Tasks Start</string>
    <string name="my_tasks">My tasks</string>
    <string name="add_task">Add task</string>
    <string name="status_done">Done</string>
    <string name="status_open">Open</string>
</resources>
```
The old `greeting` text is gone because we replace the greeting screen.

### Step 3. The task type
Create the folder `app/src/main/kotlin/com/code101/taskstart/model`.

**File: `app/src/main/kotlin/com/code101/taskstart/model/Task.kt`**
```kotlin
package com.code101.taskstart.model

data class Task(
    val id: Int,
    val title: String,
    val done: Boolean = false,
)
```
It is the `Task` from lesson 04, smaller.

### Step 4. One card per task
Create the folder `app/src/main/kotlin/com/code101/taskstart/ui`.

**File: `app/src/main/kotlin/com/code101/taskstart/ui/TaskCard.kt`**
```kotlin
package com.code101.taskstart.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.code101.taskstart.R
import com.code101.taskstart.model.Task

@Composable
fun TaskCard(task: Task, modifier: Modifier = Modifier) {
    Card(modifier = modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Icon(
                painter = painterResource(if (task.done) R.drawable.ic_check else R.drawable.ic_list),
                contentDescription = null,
            )
            Text(
                text = task.title,
                style = MaterialTheme.typography.titleMedium,
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

### Step 5. The home screen
**File: `app/src/main/kotlin/com/code101/taskstart/ui/HomeScreen.kt`**
```kotlin
package com.code101.taskstart.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
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
fun HomeScreen(modifier: Modifier = Modifier) {
    val tasks = listOf(
        Task(1, "Buy milk"),
        Task(2, "Call dentist"),
        Task(3, "Pay rent", done = true),
    )
    Scaffold(
        modifier = modifier,
        topBar = {
            TopAppBar(title = { Text(stringResource(R.string.app_name)) })
        },
        floatingActionButton = {
            FloatingActionButton(onClick = { }) {
                Icon(
                    painter = painterResource(R.drawable.ic_plus),
                    contentDescription = stringResource(R.string.add_task),
                )
            }
        },
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .padding(innerPadding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text(
                text = stringResource(R.string.my_tasks),
                style = MaterialTheme.typography.headlineMedium,
            )
            tasks.forEach { task ->
                TaskCard(task = task)
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

### Step 6. Point the activity at the home screen
**File: `app/src/main/kotlin/com/code101/taskstart/MainActivity.kt`**
```kotlin
package com.code101.taskstart

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.ui.Modifier
import com.code101.taskstart.ui.HomeScreen
import com.code101.taskstart.ui.theme.TasksTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            TasksTheme {
                HomeScreen(modifier = Modifier.fillMaxSize())
            }
        }
    }
}
```
Predict before you run: which of the three cards shows the check icon, and where is the round button?

## Run it
Sync Gradle if Studio asks, choose your device and press **Run**. You can also open `HomeScreen.kt` in **Split** mode and look at the preview.

Expected result (described, not yet seen): a top bar with "Tasks Start", the heading "My tasks", three cards "Buy milk", "Call dentist" and "Pay rent" with the words Open, Open and Done at their right edge, a list icon on the first two cards and a check icon on the third, and a round button with a plus in the bottom right corner.

## How it works
**Column, Row, Box.** `Column { A; B }` puts B under A, `Row { A; B }` puts B to the right of A, `Box { A; B }` draws B on top of A. Inside a `Row`, `verticalAlignment = Alignment.CenterVertically` lines the items up; `horizontalArrangement = Arrangement.spacedBy(12.dp)` puts 12 units of space between them. `Modifier.weight(1f)` says "take all the space that is left", which pushes the "Open/Done" text to the right.

**dp.** `16.dp` is a size in **density-independent pixels**, a unit that looks about the same size on every phone screen. Text sizes use `sp` (scaled pixels) which also follow the user's font size setting; `MaterialTheme.typography` already uses them.

**Modifier order matters.** Modifiers apply from left to right. `Modifier.padding(innerPadding).padding(16.dp)` first keeps clear of the bars, then adds a margin of 16. In the reverse order the bars could overlap the margin.

**Material 3 parts.** `Scaffold` holds a `topBar`, a `floatingActionButton` and the main content. `TopAppBar` is the title strip (marked experimental, hence `@OptIn`: it means "I know this API may still change"). `Card` is a raised box. `FloatingActionButton` is the round main action; its `onClick = { }` does nothing yet. Colours and text styles come from `MaterialTheme`, so that parts match and dark mode works.

**Icons.** `painterResource(R.drawable.ic_plus)` loads the vector drawable and `Icon` draws it in the current text colour. Because the vector is black, Compose recolours it with the theme's colour, which is why it also works in dark mode.

**contentDescription.** A person who cannot see the screen uses a screen reader such as TalkBack, which reads every element aloud. The "+" button has no text, so its description "Add task" is what TalkBack says. The icon beside a task title is decoration (the title and the "Open/Done" text already say everything), so its description is `null`: TalkBack skips it. Notice also that done is shown with the word "Done" as well as the icon, never with colour alone.

## Try it
1. **Guided:** add a new file `ui/ProfileCard.kt` from this starter, finish the three TODOs, and check the result in the preview (no need to run the app).

**File: `app/src/main/kotlin/com/code101/taskstart/ui/ProfileCard.kt`**
```kotlin
package com.code101.taskstart.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.code101.taskstart.R
import com.code101.taskstart.ui.theme.TasksTheme

@Composable
fun ProfileCard(name: String, role: String, modifier: Modifier = Modifier) {
    // TODO 1: wrap everything in a Card that fills the width (modifier.fillMaxWidth())
    // TODO 2: inside it put a Row with an Icon (R.drawable.ic_check, contentDescription = null) and a Column
    // TODO 3: the Column shows name with MaterialTheme.typography.titleMedium and role with bodyMedium
}

@Preview(showBackground = true)
@Composable
fun ProfileCardPreview() {
    TasksTheme {
        ProfileCard(name = "Ana", role = "Team lead")
    }
}
```
Expected preview: a card with a check icon on the left and, to its right, "Ana" in larger text and "Team lead" below.
2. **Change:** make `TaskCard` show the trash icon at the right end of the card instead of the "Open/Done" text, and keep a text for the state.
3. **Stretch (optional):** which is better for the user: a coloured background for done tasks, or the word "Done"? Write two sentences.

<details><summary>Solution</summary>

**File: `app/src/main/kotlin/com/code101/taskstart/ui/ProfileCard.kt`**
```kotlin
package com.code101.taskstart.ui

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.code101.taskstart.R
import com.code101.taskstart.ui.theme.TasksTheme

@Composable
fun ProfileCard(name: String, role: String, modifier: Modifier = Modifier) {
    Card(modifier = modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(
                painter = painterResource(R.drawable.ic_check),
                contentDescription = null,
                modifier = Modifier.padding(end = 12.dp),
            )
            Column {
                Text(text = name, style = MaterialTheme.typography.titleMedium)
                Text(text = role, style = MaterialTheme.typography.bodyMedium)
            }
        }
    }
}

@Preview(showBackground = true)
@Composable
fun ProfileCardPreview() {
    TasksTheme {
        ProfileCard(name = "Ana", role = "Team lead")
    }
}
```
</details>

## Check yourself
1. Which layout puts items side by side? <details><summary>Answer</summary>`Row`.</details>
2. Why does the plus button have a `contentDescription` while the list icon has `null`? <details><summary>Answer</summary>The button has no text, so a screen reader needs a description; the list icon is decoration next to a text that already says what it is.</details>
3. What does `Modifier.weight(1f)` do inside a `Row`? <details><summary>Answer</summary>It gives the item all the remaining width.</details>
4. Predict: what changes if a task has `done = true`? <details><summary>Answer</summary>The card shows the check icon instead of the list icon and the word "Done" instead of "Open".</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Unresolved reference 'ic_plus'` (typical message) on `R.drawable.ic_plus` | The file is not in `res/drawable` or its name has a capital letter | Create `app/src/main/res/drawable/ic_plus.xml` and sync |
| The icon is invisible | A different stroke or fill colour or a wrong path | Compare with the files above; make sure `strokeColor` is `#FF000000` |
| An error about an experimental API on `TopAppBar` (typical) | Missing `@OptIn(ExperimentalMaterial3Api::class)` | Add it above the function and import `ExperimentalMaterial3Api` |
| Text is hidden under the top bar | `innerPadding` was not applied | Use `Modifier.padding(innerPadding)` on the content |
| `Unresolved reference 'weight'` (typical) | `weight` was used outside a `Row` or `Column` | Use it only on a direct child of a `Row` or `Column` |

## Best practice
Give images that carry meaning a content description and mark pure decoration with `null`; never show state by colour alone. Source: Accessibility in Compose https://developer.android.com/develop/ui/compose/accessibility

## Going further
- Compose layout basics: https://developer.android.com/develop/ui/compose/layouts/basics
- Material 3 in Compose: https://developer.android.com/develop/ui/compose/designsystems/material3

## Summary
- You arranged a screen with `Column`, `Row` and `Modifier`.
- You used Scaffold, TopAppBar, Card and a floating action button.
- You converted four CC0 icons to vector drawables and showed them.
- You gave the plus button a description and the decorative icon none.

## Next lesson
07. State and recomposition: making the screen react when something changes, with `remember`.
