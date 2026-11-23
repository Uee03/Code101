---
track: kotlin
level: 201
phase: 3
phase_name: offline-and-quality
lesson: 09
title: Accessibility and performance basics
time: 75-90 min
prerequisites: [201-03, 201-08]
versions: { compose-bom: "2026.11.01", kotlin: "2.4.21", compileSdk: "37" }
verified: not yet run
source: source/kotlin/201-hero-to-super-hero/phase-3-offline-and-quality/09-accessibility-and-performance/
assets: []
---

# 09. Accessibility and performance basics

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- test a screen with TalkBack, the Accessibility Scanner and a 200 percent font size, and record what you find;
- fix common problems: unmerged rows, missing click labels, pluralised counts, colour-only state, too-small touch targets;
- apply four basic Compose performance habits: stable keys, `contentType`, `derivedStateOf`, and measuring before changing;
- explain what a baseline profile is and how Android Studio creates one.

## Recap
1. Which elements of the sync banner help a screen-reader user in lesson 08? <details><summary>Answer</summary>It is a polite live region, and its count and the "Sync now" button are real text.</details>
2. Why is sync state shown in words as well as in an error colour? <details><summary>Answer</summary>Colour alone fails for colour-blind users and screen readers.</details>

## Why it matters
A staircase is useful for most people, but a building without a ramp, a handrail or readable signs locks some people out. Roughly speaking, accessibility is the ramp of an app: screen-reader users, people with low vision, motor difficulties or large-text settings can only use what you built if the screen *says* what it contains and can be *operated* by touch targets they can hit. Performance is the same kind of invisible quality: nobody praises a smooth list, everybody leaves a jerky one. The capstone makes accessibility a requirement (M-22: TalkBack order, 48 x 48 dp targets, 200 percent font, 4.5:1 contrast, status never by colour alone).

## What you will build
Small, targeted fixes to Tasks Mini: tasks and teams read as single, clearly labelled items; the banner has correct singular and plural text; the add button's enabled state is computed without extra recomposition; lazy lists declare a `contentType`. You also run the three manual checks and write down the results (we do not invent any numbers: measure on your own device).

## Before you start
- The project from lesson 08. Time: about 75 to 90 minutes.
- An emulator or phone. TalkBack: **Settings > Accessibility > TalkBack**. Font size: **Settings > Display > Font size**, plus **Display size** (some devices also offer a larger scale in **Developer options**). The Accessibility Scanner is a free Google app on Google Play (it needs a device or emulator image with Google Play).
- Source pack (optional): https://github.com/Uee03/Code101 under `source/kotlin/201-hero-to-super-hero/phase-3-offline-and-quality/09-accessibility-and-performance/` (**Code, Download ZIP**, or `git clone https://github.com/Uee03/Code101.git`).

**Files that stay as in lesson 08:** everything not listed. Changed: `TasksScreen.kt`, `OfflineBanner.kt`, `strings.xml` (region), `TeamsScreen.kt` (region). New: `TaskRow.kt`, `plurals.xml`.

New words: semantics, merged semantics, content description, click label, touch target, live region, contrast ratio, font scale, recomposition, skipping, `derivedStateOf`, baseline profile.

## Steps

### Step 1. Measure first: three manual checks
Do this *before* you change code and write down what you hear and see.
1. **TalkBack.** Turn it on, open Teams. Swipe right through the screen. Does each team read as *one* item ("Platform Team, Services and tooling, 4 members")? Does the title read as a heading? Is the connection line announced when it changes? On Tasks: how many swipes does one task take? (Lesson 08 has three stops per task.)
2. **Font scale.** Set the font to the largest setting (200 percent in the capstone's target). Open Tasks. Is any text cut off or overlapping? Can you still reach the Add button?
3. **Accessibility Scanner.** Enable it, open each screen and press its button. It lists touch targets smaller than 48 x 48 dp, low contrast text and missing labels.

Write the findings in three bullet lines per screen. The fixes below address the likeliest ones.

### Step 2. One row, one TalkBack item
**File: `app/src/main/kotlin/com/code101/tasks/ui/tasks/TaskRow.kt`**
```kotlin
package com.code101.tasks.ui.tasks

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.code101.tasks.R
import com.code101.tasks.domain.model.TaskItem
import com.code101.tasks.ui.components.statusLabel

@Composable
fun TaskRow(task: TaskItem, modifier: Modifier = Modifier) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .semantics(mergeDescendants = true) { },
    ) {
        Column(
            modifier = Modifier
                .heightIn(min = 48.dp)
                .padding(16.dp),
        ) {
            Text(task.title, style = MaterialTheme.typography.titleMedium)
            Text(stringResource(statusLabel(task.status)))
            when (task.syncState) {
                "pending" -> Text(stringResource(R.string.waiting_to_sync))
                "failed" -> Text(
                    text = stringResource(R.string.sync_failed),
                    color = MaterialTheme.colorScheme.error,
                )
            }
        }
    }
}
```
- `semantics(mergeDescendants = true)` merges the texts into **one** node, so TalkBack reads "Draw the login screen, To do, Waiting to sync" with a single swipe instead of three. Compose's `clickable`, `toggleable` and `Card(onClick = ...)` merge automatically; a plain `Card` does not, so we ask.
- `heightIn(min = 48.dp)`: Android recommends touch targets of at least 48 x 48 dp (Material uses 48). This row is not clickable yet, but the rule is applied to anything that will be.
- No fixed height: a row must grow with the font. Fixed `height(56.dp)` is the classic way to cut text off at 200 percent.
- The state is **words** ("To do", "Waiting to sync") and an error colour for failure: never colour alone.

### Step 3. The screen uses the row and computes less
**File: `app/src/main/kotlin/com/code101/tasks/ui/tasks/TasksScreen.kt`**
```kotlin
package com.code101.tasks.ui.tasks

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.repeatOnLifecycle
import com.code101.tasks.R
import com.code101.tasks.domain.model.TaskItem
import com.code101.tasks.ui.common.UiState
import com.code101.tasks.ui.components.AppScaffold
import com.code101.tasks.ui.components.UiStateContent
import kotlinx.coroutines.flow.Flow

@Composable
fun TasksScreen(
    state: UiState<List<TaskItem>>,
    events: Flow<TasksEvent>,
    titleError: Int?,
    onTitleEdited: () -> Unit,
    onRetry: () -> Unit,
    onAdd: (String) -> Unit,
    onBack: () -> Unit,
) {
    var draft by rememberSaveable { mutableStateOf("") }
    val canAdd by remember { derivedStateOf { draft.isNotBlank() } }
    val snackbarHostState = remember { SnackbarHostState() }
    val lifecycleOwner = LocalLifecycleOwner.current
    val context = LocalContext.current
    val addedText = stringResource(R.string.task_added)

    LaunchedEffect(events, lifecycleOwner) {
        lifecycleOwner.lifecycle.repeatOnLifecycle(Lifecycle.State.STARTED) {
            events.collect { event ->
                val message = when (event) {
                    TasksEvent.Added -> addedText
                    is TasksEvent.Message -> context.getString(event.messageRes)
                }
                snackbarHostState.showSnackbar(message)
            }
        }
    }

    AppScaffold(
        titleRes = R.string.tasks,
        onBack = onBack,
        snackbarHost = { SnackbarHost(snackbarHostState) },
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.Top,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                OutlinedTextField(
                    value = draft,
                    onValueChange = {
                        draft = it
                        onTitleEdited()
                    },
                    label = { Text(stringResource(R.string.new_task)) },
                    isError = titleError != null,
                    supportingText = {
                        if (titleError != null) Text(stringResource(titleError))
                    },
                    singleLine = true,
                    modifier = Modifier.weight(1f),
                )
                Button(
                    onClick = {
                        onAdd(draft)
                        draft = ""
                    },
                    enabled = canAdd,
                ) {
                    Text(stringResource(R.string.add))
                }
            }
            UiStateContent(
                state = state,
                onRetry = onRetry,
                modifier = Modifier.weight(1f),
            ) { tasks ->
                if (tasks.isEmpty()) {
                    Text(text = stringResource(R.string.empty))
                } else {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        verticalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        items(tasks, key = { it.id }, contentType = { "task" }) { task ->
                            TaskRow(task)
                        }
                    }
                }
            }
        }
    }
}
```
- `derivedStateOf { draft.isNotBlank() }` recomputes only when `draft` changes and notifies readers only when the *result* (`true`/`false`) changes. Typing a second letter does not recompose the button. Use it when a state is derived from a state that changes more often than the result.
- `contentType = { "task" }` tells `LazyColumn` which rows are the same kind, so scrolled-away row compositions can be reused. It matters when a list mixes kinds (header, row, footer).
- The `key` from lesson 08 of this level stays: stable identity keeps state with the right row when the list changes.

### Step 4. Correct singular and plural text
**File: `app/src/main/res/values/plurals.xml`**
```xml
<resources>
    <plurals name="pending_banner">
        <item quantity="one">%1$d change is waiting to sync</item>
        <item quantity="other">%1$d changes are waiting to sync</item>
    </plurals>
</resources>
```
**File: `app/src/main/kotlin/com/code101/tasks/ui/components/OfflineBanner.kt`**
```kotlin
package com.code101.tasks.ui.components

import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.code101.tasks.R

@Composable
fun OfflineBanner(
    pendingCount: Int,
    onSyncNow: () -> Unit,
    modifier: Modifier = Modifier,
) {
    if (pendingCount > 0) {
        Surface(
            color = MaterialTheme.colorScheme.secondaryContainer,
            contentColor = MaterialTheme.colorScheme.onSecondaryContainer,
            modifier = modifier
                .fillMaxWidth()
                .statusBarsPadding()
                .semantics { liveRegion = LiveRegionMode.Polite },
        ) {
            Row(
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = pluralStringResource(R.plurals.pending_banner, pendingCount, pendingCount),
                    modifier = Modifier.weight(1f),
                )
                TextButton(onClick = onSyncNow) {
                    Text(stringResource(R.string.sync_now))
                }
            }
        }
    }
}
```
- A **plural resource** picks the right sentence for the number and the language ("1 change is", "2 changes are"). Languages like Polish or Arabic have more plural forms; hard-coded "changes" would be wrong. `pluralStringResource(id, count, formatArgs)` takes the count twice: once to choose the form, once as the `%1$d` argument.
- `contentColor = onSecondaryContainer` pairs text with its container colour as the Material theme defines, which keeps contrast within the theme's design (check with the Scanner after changing colours).
- Delete the old `pending_banner` `<string>` from `strings.xml` (a string and a plural may share a name, but keep one).

**File: `app/src/main/res/values/strings.xml`** (changed lines: the old `pending_banner` string is gone; two new lines are added next to `sync_now`)
```xml
    <string name="open_team">Open team</string>
    <string name="open_project">Open project</string>
    <string name="sync_now">Sync now</string>
```

### Step 5. A click label for the team card
**File: `app/src/main/kotlin/com/code101/tasks/ui/teams/TeamsScreen.kt`** (changed region)
```kotlin
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(vertical = 4.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        items(teams, key = { it.id }, contentType = { "team" }) { team ->
                            val openLabel = stringResource(R.string.open_team)
                            Card(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clickable(onClickLabel = openLabel) { onOpenTeam(team.id) },
                            ) {
```
Without a label, TalkBack says "double tap to activate". With `onClickLabel` it says "double tap to open team": the action is named. The card's children are merged because `clickable` merges them. (Every other line of the file is unchanged.)

Predict before you run: with TalkBack on, how many swipes does it take to move from the first task to the second, now compared with lesson 08? And with the font at 200 percent, does the row get taller or does the text get cut?

## Run it
Rerun the three checks of Step 1 and compare with your notes.

Expected result (described, not yet seen): on Tasks each task is one TalkBack stop that reads title, status and sync note together; the banner reads "1 change is waiting to sync" for one item and "2 changes ..." for two; Teams cards announce "double tap to open team"; at the largest font the rows grow in height and nothing is cut off; the Accessibility Scanner should list no target-size or label items for the screens you changed (it may still report others, such as contrast of a theme colour; record them).

## How it works
**Semantics.** Compose builds a *semantics tree* beside the UI tree: every node may carry a role, text, state and actions. Screen readers, the Scanner and UI tests read that tree, not the pixels. `contentDescription` describes an image-like node, `stateDescription` a state, `onClickLabel` the click action, `heading()` marks a title, `liveRegion` announces changes. **Merging** collapses a node's children into one so a *row* is one stop.

**Targets and text.** 48 x 48 dp touch targets help everyone, not only people with motor difficulties. Text in `sp` follows the user's font setting; layout must follow it too (`heightIn(min)`, wrapping text, scrollable columns). Contrast of body text should be at least 4.5:1 against its background (WCAG 2.x); Material's default colour pairs are designed for that, custom colours need a check.

**Order.** TalkBack reads in the order of the tree, which usually follows layout order. If a design shows things in a different order than it lays them out, fix the order, do not rely on the visual position.

**Performance habits.**
| Habit | Why |
|---|---|
| stable `key` and `contentType` in lazy lists | keeps state with the right row; allows reuse of compositions |
| `derivedStateOf` for derived booleans | fewer recompositions when the derived value stays the same |
| hoist state, pass small immutable data | Compose can *skip* a composable whose parameters did not change (Kotlin 2.x enables "strong skipping": lambdas with stable captures are remembered automatically) |
| measure, then change | Layout Inspector shows recomposition counts per composable (**Tools > Layout Inspector**, enable recomposition counts); profile before guessing |
| no work in composition | no I/O, no sorting of large lists directly in the composable; do it in the ViewModel or `remember(key)` |

**Baseline profiles (introduction).** The first time an app runs, its code is interpreted or compiled on the fly, which makes first launch and first scroll slower than later. A **baseline profile** is a list of classes and methods used at startup and in critical journeys; Android installs it with the app and compiles them ahead of time. It is *generated* by running a scripted journey in a **Macrobenchmark** module and is *measured* with the same module. In Android Studio: **File > New > Module**, choose the **Baseline Profile Generator** template, follow the wizard, run the generated test on a suitable device or emulator, and compare "startup with and without the profile" in the benchmark output. Do this on a **release-like** build, because debug builds are not representative. We do not give numbers: they depend on device, app and journey, and you must measure your own. Official guide: https://developer.android.com/topic/performance/baselineprofiles/overview

**Why this, not that.**
| Choice | Alternative | Why |
|---|---|---|
| Merge a row into one semantics node | leave three nodes | fewer swipes, a complete sentence per item |
| Plural resources | `if (count == 1) ... else ...` in code | translatable and correct for many languages |
| Manual TalkBack pass + Scanner | rely on the Scanner alone | the Scanner finds mechanical issues; only listening finds confusing order or wording |
| Measure with Layout Inspector or Macrobenchmark | optimise by instinct | most Compose slowness is somewhere else than where you expect |

**Where this reappears.** Capstone requirement M-22, chapter 03 (labels on controls, 48 dp, status not by colour) and chapter 04 (the banner live region). The 301 level covers modularisation and measured performance budgets.

## Try it
1. **Guided:** make the project card one TalkBack item with a click label. The starter has two TODOs (merge the semantics, make the card clickable with `onClickLabel = stringResource(R.string.open_project)`); then use `ProjectCard` in `ProjectsScreen` instead of the inline `Card`.

**File: `app/src/main/kotlin/com/code101/tasks/ui/projects/ProjectCard.kt`**
```kotlin
package com.code101.tasks.ui.projects

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.code101.tasks.domain.model.Project

@Composable
fun ProjectCard(project: Project, onOpen: () -> Unit, modifier: Modifier = Modifier) {
    // TODO 1: make the whole card one TalkBack item: merge the descendants' semantics
    // TODO 2: make the whole card clickable with onClickLabel = stringResource(R.string.open_project)
    Card(modifier = modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(project.name, style = MaterialTheme.typography.titleMedium)
            Text(project.key)
        }
    }
}
```
Expected: with TalkBack the card reads "Tasks app, MOB" and "double tap to open project" in one stop.
2. **Change:** add a `stateDescription` ("Waiting to sync") to `TaskRow` via `Modifier.semantics { stateDescription = ... }` and decide whether it duplicates the text. When is a state description better than visible text?
3. **Stretch (optional):** run Layout Inspector with recomposition counts on the Tasks screen, type in the text field, and note which composables recompose per key press. Is `TaskRow` among them? Why (or why not)?

<details><summary>Solution</summary>

**File: `app/src/main/kotlin/com/code101/tasks/ui/projects/ProjectCard.kt`**
```kotlin
package com.code101.tasks.ui.projects

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.code101.tasks.R
import com.code101.tasks.domain.model.Project

@Composable
fun ProjectCard(project: Project, onOpen: () -> Unit, modifier: Modifier = Modifier) {
    val openLabel = stringResource(R.string.open_project)
    Card(
        modifier = modifier
            .fillMaxWidth()
            .semantics(mergeDescendants = true) { }
            .clickable(onClickLabel = openLabel, onClick = onOpen),
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(project.name, style = MaterialTheme.typography.titleMedium)
            Text(project.key)
        }
    }
}
```
</details>

## Check yourself
1. What does merging semantics change for a TalkBack user? <details><summary>Answer</summary>A row becomes one stop that reads all its texts together.</details>
2. Why is a fixed row height a problem? <details><summary>Answer</summary>At large font sizes the text no longer fits and is cut off; use `heightIn(min = ...)`.</details>
3. When is `derivedStateOf` useful? <details><summary>Answer</summary>When a value is computed from state that changes more often than the computed result does.</details>
4. Why is the scanner not enough? <details><summary>Answer</summary>It finds mechanical problems; only a real screen-reader pass shows confusing order, wording and missing context.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| TalkBack reads every text of a card separately | No merged semantics on a non-clickable container | `semantics(mergeDescendants = true) { }` or make it clickable |
| TalkBack says "unlabelled" for a button (typical) | An icon-only button without `contentDescription` | Add a description or visible text |
| The plural shows the wrong word for 1 (typical) | A single `<string>` with "changes" | Use `<plurals>` and `pluralStringResource` |
| Text is cut off at the largest font | A fixed `height` | Use `heightIn(min)` and let rows grow |
| A blank first frame in the Scanner report | It scanned the loading state | Wait for the data, then scan |
| A resource error "duplicate resources" (typical) | `pending_banner` exists as both `string` and `plurals` in the same file set, or twice | Remove the old string |

## Best practice
Test with a screen reader and large fonts as part of every screen's definition of done, merge row semantics, label actions, use plural resources, and measure before optimising. Source: Accessibility in Compose https://developer.android.com/develop/ui/compose/accessibility and Jetpack Compose performance https://developer.android.com/develop/ui/compose/performance

## Going further
- Testing accessibility: https://developer.android.com/guide/topics/ui/accessibility/testing
- Macrobenchmark: https://developer.android.com/topic/performance/benchmarking/macrobenchmark-overview

## Summary
- You ran TalkBack, font-scale and Scanner checks and recorded findings.
- You merged row semantics, labelled actions, pluralised the banner and kept layouts flexible.
- You applied `contentType`, `derivedStateOf` and the measure-first rule, and know how a baseline profile is made.

## Next lesson
10. Project: a task app against the platform contract: complete tasks with `If-Match`, a settings screen, and where to go next.
