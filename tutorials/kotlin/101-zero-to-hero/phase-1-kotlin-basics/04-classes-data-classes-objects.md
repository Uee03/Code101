---
track: kotlin
level: 101
phase: 1
phase_name: kotlin-basics
lesson: 04
title: Classes, data classes and objects
time: 50-60 min
prerequisites: [01, 02, 03]
versions: { kotlin: "2.4.21", gradle: "9.6.0" }
verified: not yet run
source: source/kotlin/101-zero-to-hero/phase-1-kotlin-basics/04-classes-data-classes-objects/
assets: []
---

# 04. Classes, data classes and objects

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- write a `class` with properties and functions and create objects from it;
- use a `data class` and explain what `copy` and `==` do;
- model a fixed set of choices with `enum class` and `sealed interface`;
- use an `object` for one shared helper.

## Recap
1. How do you get a default value into a function parameter? <details><summary>Answer</summary>Write `= value` after the type: `greeting: String = "Hello"`.</details>
2. What does `list.filter { it > 3 }` return? <details><summary>Answer</summary>A new list with only the items bigger than 3.</details>

## Why it matters
A house plan (blueprint) describes rooms, doors and windows; many houses can be built from one plan. A **class** is the plan, and each **object** (instance) is a house built from it. Your task app will have a plan called `Task`: a title, a priority and a done flag. A class lets you keep these pieces together and give them behaviour.

## What you will build
A small task list: a `Task` type, a `TaskList` that adds and completes tasks, a helper that cleans titles, and a `LoadState` type that you will meet again in the app lessons.

## Before you start
- The `KotlinBasics` project from lessons 01 to 03.
- Time: about 50 to 60 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/kotlin/101-zero-to-hero/phase-1-kotlin-basics/04-classes-data-classes-objects/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).

New words: class, object (instance), property, method, constructor, `data class`, `copy`, `enum class`, `object` declaration, `const`, `sealed interface`, exhaustive `when`.

## Steps

### Step 1. Create the folder and the two files
New directory `src/main/kotlin/lesson04`, and inside it two files: `Task.kt` and `Main.kt`. Splitting the types (`Task.kt`) from the program that uses them (`Main.kt`) is normal; both files are in package `lesson04`, so they can see each other.

### Step 2. The types
**File: `src/main/kotlin/lesson04/Task.kt`**
```kotlin
package lesson04

enum class Priority { LOW, MEDIUM, HIGH }

data class Task(
    val id: Int,
    val title: String,
    val priority: Priority = Priority.MEDIUM,
    val done: Boolean = false,
)

class TaskList {
    private val tasks = mutableListOf<Task>()

    fun add(title: String, priority: Priority = Priority.MEDIUM): Task {
        val task = Task(id = tasks.size + 1, title = title, priority = priority)
        tasks.add(task)
        return task
    }

    fun complete(id: Int) {
        val index = tasks.indexOfFirst { it.id == id }
        if (index >= 0) {
            tasks[index] = tasks[index].copy(done = true)
        }
    }

    fun all(): List<Task> = tasks.toList()

    fun openCount(): Int = tasks.count { !it.done }
}

object Defaults {
    const val MAX_TITLE_LENGTH = 40

    fun clean(title: String): String = title.trim().take(MAX_TITLE_LENGTH)
}

sealed interface LoadState {
    data object Loading : LoadState
    data class Done(val tasks: List<Task>) : LoadState
    data class Failed(val message: String) : LoadState
}
```

### Step 3. The program
**File: `src/main/kotlin/lesson04/Main.kt`**
```kotlin
package lesson04

fun describe(state: LoadState): String = when (state) {
    LoadState.Loading -> "Loading..."
    is LoadState.Done -> "Loaded ${state.tasks.size} tasks"
    is LoadState.Failed -> "Problem: ${state.message}"
}

fun main() {
    val list = TaskList()
    list.add(Defaults.clean("  Buy milk  "))
    list.add("Call dentist", Priority.HIGH)
    val rent = list.add("Pay rent")
    list.complete(rent.id)

    for (task in list.all()) {
        println(task)
    }
    println("Open tasks: ${list.openCount()}")

    val first = list.all().first()
    val renamed = first.copy(title = "Buy oat milk")
    println(first == renamed)
    println(first == first.copy())
    println(renamed)

    println(describe(LoadState.Loading))
    println(describe(LoadState.Done(list.all())))
    println(describe(LoadState.Failed("no network")))
}
```
Predict before you run: what does `println(task)` print for a data class, and will `first == renamed` be `true` or `false`?

## Run it
Run `main` in `Main.kt` with the green triangle.

Expected output:
```text
Task(id=1, title=Buy milk, priority=MEDIUM, done=false)
Task(id=2, title=Call dentist, priority=HIGH, done=false)
Task(id=3, title=Pay rent, priority=MEDIUM, done=true)
Open tasks: 2
false
true
Task(id=1, title=Buy oat milk, priority=MEDIUM, done=false)
Loading...
Loaded 3 tasks
Problem: no network
```

## How it works
**Class and object.** `class TaskList { ... }` is the plan. `TaskList()` builds one object from it and `val list = TaskList()` keeps it. The values inside a class are **properties** (`tasks`), the functions inside are **methods** (`add`, `complete`). `private` hides `tasks` from the outside, so only the class's own methods can change it. That protects the list from accidental changes.

**Data class.** `data class Task(val id: Int, ...)` is a class whose job is to hold data. The text in brackets is the **constructor**: how an object is built, and the `val`s become its properties. A data class gets, for free:
- a readable `toString()`, so `println(task)` prints `Task(id=1, ...)`;
- `==` that compares the contents, not the identity: two tasks with equal fields are equal;
- `copy(...)`, which builds a new object with some fields changed. Data classes are best kept unchangeable (`val`), and `copy` is how you "change" one. That fact matters from lesson 07 on.

**Default values.** `priority: Priority = Priority.MEDIUM` lets `Task(id = 1, title = "x")` skip the rest.

**Enum.** `enum class Priority { LOW, MEDIUM, HIGH }` is a fixed list of allowed values. Nobody can invent a fourth priority by accident.

**Object.** `object Defaults { ... }` creates exactly one object, ready to use, without `Defaults()`. It suits shared helpers and constants. `const val` is a value known while the program is compiled.

**Sealed interface.** `LoadState` says "a load is in exactly one of these states: loading, done (with tasks) or failed (with a message)". Because the list of states is closed, `when (state)` does not need an `else`: the compiler checks that you covered every case, and warns you when you add a state and forget one. `data object Loading` is a single state that carries no data. You will use this idea for screens in lessons 09 and 10.

## Try it
1. **Guided:** create `src/main/kotlin/exercise04/Shelf.kt` from this starter and fill both TODOs.

**File: `src/main/kotlin/exercise04/Shelf.kt`**
```kotlin
package exercise04

data class Book(val title: String, val pages: Int, val read: Boolean = false)

class Shelf {
    private val books = mutableListOf<Book>()

    fun add(book: Book) {
        // TODO 1: put the book into the books list
    }

    fun unreadTitles(): List<String> {
        // TODO 2: return the titles of the books that are not read yet
        return emptyList()
    }
}

fun main() {
    val shelf = Shelf()
    shelf.add(Book("Dune", 612))
    shelf.add(Book("Emma", 474, read = true))
    shelf.add(Book("Kim", 320))
    println(shelf.unreadTitles())
}
```
Expected output:
```text
[Dune, Kim]
```
2. **Change:** add a method `totalPages()` to `Shelf` that adds up the pages of all books (hint: `sumOf`).
3. **Stretch (optional):** add an `enum class Genre` and a `genre` property with a default.

<details><summary>Solution</summary>

**File: `src/main/kotlin/exercise04/Shelf.kt`**
```kotlin
package exercise04

data class Book(val title: String, val pages: Int, val read: Boolean = false)

class Shelf {
    private val books = mutableListOf<Book>()

    fun add(book: Book) {
        books.add(book)
    }

    fun unreadTitles(): List<String> {
        return books.filter { !it.read }.map { it.title }
    }
}

fun main() {
    val shelf = Shelf()
    shelf.add(Book("Dune", 612))
    shelf.add(Book("Emma", 474, read = true))
    shelf.add(Book("Kim", 320))
    println(shelf.unreadTitles())
}
```
`filter` keeps unread books, and `map` takes only their titles.

</details>

## Check yourself
1. What does `copy` do on a data class? <details><summary>Answer</summary>It creates a new object with the same fields except the ones you pass, and leaves the old one unchanged.</details>
2. Why is `private val tasks` useful? <details><summary>Answer</summary>Code outside the class cannot change the list directly, only through the class's functions.</details>
3. What is the advantage of a `sealed interface` in `when`? <details><summary>Answer</summary>The compiler checks that all cases are handled, so no `else` is needed and a forgotten case becomes an error.</details>
4. Predict: `Task(1, "a") == Task(1, "a")`? <details><summary>Answer</summary>`true`: a data class compares its contents.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Cannot access 'tasks': it is private in 'TaskList'` (typical message) | You used a `private` property from outside the class | Add a function to the class that does the job |
| `'when' expression must be exhaustive` (typical) | A new state was added, or a case is missing, and there is no `else` | Add the missing branch |
| `Val cannot be reassigned` (typical) on `task.done = true` | Data class properties are `val` | Use `task.copy(done = true)` |
| `No value passed for parameter 'title'` (typical) | A constructor argument without a default was left out | Pass it, or give the property a default value |

## Best practice
Keep data classes small and unchangeable (`val`), and make the set of states closed with `sealed` types. Source: Kotlin data classes https://kotlinlang.org/docs/data-classes.html and sealed classes https://kotlinlang.org/docs/sealed-classes.html

## Going further
- Kotlin classes: https://kotlinlang.org/docs/classes.html
- Objects: https://kotlinlang.org/docs/object-declarations.html. Lesson 05 starts the app, which reuses `Task` in `com.code101.taskstart.model`.

## Summary
- You wrote a class and created objects from it.
- You used a data class with `copy` and `==`.
- You modelled choices with `enum class` and `sealed interface`.
- You used an `object` for shared helpers.

## Next lesson
05. Your first Compose app: a real Android app on an emulator or phone, built from composable functions.
