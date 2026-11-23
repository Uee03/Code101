---
track: kotlin
level: 101
phase: 1
phase_name: kotlin-basics
lesson: 03
title: Functions, collections and lambdas
time: 50-60 min
prerequisites: [01, 02]
versions: { kotlin: "2.4.21", gradle: "9.6.0" }
verified: not yet run
source: source/kotlin/101-zero-to-hero/phase-1-kotlin-basics/03-functions-collections-lambdas/
assets: []
---

# 03. Functions, collections and lambdas

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- write a function with parameters, a default value and a result;
- keep several values in a `List` or a `Map`, and loop over them;
- choose between cases with `when`;
- use a **lambda** with `filter` and `map` to pick or change list items.

## Recap
1. What is the difference between `val` and `var`? <details><summary>Answer</summary>A `val` cannot be reassigned; a `var` can.</details>
2. What does `name?.length` give when `name` is `null`? <details><summary>Answer</summary>`null`, without a crash.</details>
3. What is `9 / 2`? <details><summary>Answer</summary>`4`, because both numbers are `Int`.</details>

## Why it matters
A recipe card has a name ("Pancakes"), ingredients you pass in ("2 eggs"), and a result (pancakes). You use the card again and again instead of rewriting the steps. A **function** is that card. A shopping **list** and a stock **map** (item and amount, like a price board) store many values at once. A **lambda** is a short card without a name that you hand to another function: "from this list, keep only the long names".

## What you will build
One program that calls small functions, loops over a list of task titles, reads a map of stock counts, and filters and transforms numbers.

## Before you start
- The `KotlinBasics` project from lessons 01 and 02.
- Time: about 50 to 60 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/kotlin/101-zero-to-hero/phase-1-kotlin-basics/03-functions-collections-lambdas/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).

New words: function, parameter, argument, default value, named argument, return value, `List`, `MutableList`, `Map`, `for` loop, `when`, lambda, `it`.

## Steps

### Step 1. Create the file
New directory `src/main/kotlin/lesson03`, then a new file `Main.kt` inside it.

### Step 2. Functions
Start with this top part of the file (it is shown again, complete, in Step 4):

```kotlin
package lesson03

fun greet(name: String, greeting: String = "Hello"): String {
    return "$greeting, $name!"
}

fun twice(n: Int) = n * 2

fun describePriority(level: Int): String = when (level) {
    1 -> "low"
    2 -> "medium"
    3 -> "high"
    else -> "unknown"
}
```
Predict: what do `greet("Ana")` and `describePriority(3)` return?

### Step 3. Lists, maps and lambdas
The `main` function (also in Step 4) uses the functions above and then collections. Read it slowly before you type it in the next step.

### Step 4. Type the complete file
**File: `src/main/kotlin/lesson03/Main.kt`**
```kotlin
package lesson03

fun greet(name: String, greeting: String = "Hello"): String {
    return "$greeting, $name!"
}

fun twice(n: Int) = n * 2

fun describePriority(level: Int): String = when (level) {
    1 -> "low"
    2 -> "medium"
    3 -> "high"
    else -> "unknown"
}

fun main() {
    println(greet("Ana"))
    println(greet("Ben", greeting = "Welcome"))
    println(twice(21))
    println(describePriority(3))

    val titles = listOf("Buy milk", "Call dentist", "Water plants", "Pay rent")
    println(titles.size)
    println(titles[1])
    for (title in titles) {
        println("- $title")
    }

    val shopping = mutableListOf("tea", "sugar")
    shopping.add("lemons")
    shopping.remove("sugar")
    println(shopping)

    val stock = mapOf("tea" to 40, "sugar" to 12)
    println(stock["tea"])
    println(stock["salt"] ?: 0)
    for ((item, count) in stock) {
        println("$item: $count")
    }

    val numbers = listOf(5, 12, 8, 21, 3)
    val big = numbers.filter { it > 7 }
    val doubled = numbers.map { it * 2 }
    val sorted = numbers.sortedBy { it }
    println(big)
    println(doubled)
    println(sorted)
    println(numbers.sum())

    val shouted = titles.map { title -> title.uppercase() }
    println(shouted)
    val long = titles.filter { it.length > 10 }
    println(long)
}
```
Predict before you run: what does `println(stock["salt"] ?: 0)` print, and why? And which numbers stay in `big`?

## Run it
Run `main` with the green triangle.

Expected output:
```text
Hello, Ana!
Welcome, Ben!
42
high
4
Call dentist
- Buy milk
- Call dentist
- Water plants
- Pay rent
[tea, lemons]
40
0
tea: 40
sugar: 12
[12, 8, 21]
[10, 24, 16, 42, 6]
[3, 5, 8, 12, 21]
49
[BUY MILK, CALL DENTIST, WATER PLANTS, PAY RENT]
[Call dentist, Water plants]
```

## How it works
**Functions.** `fun greet(name: String, greeting: String = "Hello"): String` has two **parameters** (the slots), each with a type after a colon. `= "Hello"` is a **default value**: if you give nothing, `"Hello"` is used. When you call `greet("Ben", greeting = "Welcome")` the values you pass are **arguments**, and `greeting = ...` is a **named argument**. `: String` after the brackets is the type of the **return value**, the thing the function hands back with `return`. When the body is one expression you may write `fun twice(n: Int) = n * 2`.

**`when`.** `when (level) { ... }` compares `level` with each line in turn; `else` catches everything else. It is also an expression: the function returns the matching text.

**List.** `listOf(...)` makes a read-only list: you can read `titles[1]` (counting starts at **0**, so `[1]` is the second item) but not add. `mutableListOf(...)` makes a list you can change with `add` and `remove`. Misconception: `val shopping` is a `val`, yet it changes. The `val` jar always holds the same list object, while the list inside gets items added.

**`for`.** `for (title in titles) { ... }` runs the braces once per item.

**Map.** `mapOf("tea" to 40, ...)` pairs a **key** (the item) with a **value** (the amount). `stock["tea"]` returns `40`. A missing key gives `null`, which is why `stock["salt"] ?: 0` is `0`. `for ((item, count) in stock)` takes each pair apart.

**Lambdas.** `{ it > 7 }` is a lambda: a small function without a name. `filter` keeps the items for which the lambda gives `true`; `map` builds a new list from what the lambda returns for each item. Inside a one-parameter lambda the item is called `it`; or you name it yourself, `{ title -> title.uppercase() }`. When a lambda is the last argument, it goes after the brackets.

## Try it
1. **Guided:** create `src/main/kotlin/exercise03/ShortTitles.kt` from this starter and write the missing line.

**File: `src/main/kotlin/exercise03/ShortTitles.kt`**
```kotlin
package exercise03

fun shortTitles(titles: List<String>, maxLength: Int): List<String> {
    // TODO: return only the titles whose length is at most maxLength
    return emptyList()
}

fun main() {
    val titles = listOf("Buy milk", "Call dentist", "Pay rent")
    println(shortTitles(titles, 9))
}
```
Expected output:
```text
[Buy milk, Pay rent]
```
2. **Change:** write a second function `countLong(titles: List<String>): Int` that returns how many titles have more than 10 letters.
3. **Stretch (optional):** make the `maxLength` parameter optional with a default value of 20.

<details><summary>Solution</summary>

**File: `src/main/kotlin/exercise03/ShortTitles.kt`**
```kotlin
package exercise03

fun shortTitles(titles: List<String>, maxLength: Int): List<String> {
    return titles.filter { it.length <= maxLength }
}

fun main() {
    val titles = listOf("Buy milk", "Call dentist", "Pay rent")
    println(shortTitles(titles, 9))
}
```
`filter` keeps each title whose length is 9 or less: "Buy milk" has 8 letters, "Call dentist" has 12, "Pay rent" has 8.

</details>

## Check yourself
1. What does `listOf("a", "b")[1]` give? <details><summary>Answer</summary>`"b"`, because counting starts at 0.</details>
2. What is the difference between `listOf` and `mutableListOf`? <details><summary>Answer</summary>You cannot add to or remove from a `listOf` list; you can with a `mutableListOf` list.</details>
3. What does `numbers.map { it * 2 }` return for `[1, 2, 3]`? <details><summary>Answer</summary>A new list `[2, 4, 6]`; the original is unchanged.</details>
4. Find the bug: `fun twice(n: Int) = n * "2"`. <details><summary>Answer</summary>An `Int` cannot be multiplied by a `String`; use `n * 2`.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Unresolved reference 'add'` (typical message) on a `listOf` list | `listOf` is read-only | Use `mutableListOf` when you need to add |
| `Type mismatch` mentioning `Int?` and `Int` (typical) | A map lookup such as `stock["tea"]` can be `null` | Add `?: 0` or an `if (... != null)` check |
| `IndexOutOfBoundsException` when you run (typical name) | You asked for `titles[4]` in a list of four items | The last index is `size - 1` |
| A lambda result is ignored (nothing changes) | `filter` and `map` return a **new** list | Store it: `val big = numbers.filter { ... }` |
| `Conflicting overloads: fun main()` (typical) | Two files in the same package both define `main` | Give each lesson its own package and folder |

## Best practice
Give functions and variables names that say what they do, in `camelCase` (first word lowercase, later words start with a capital). Source: Kotlin coding conventions https://kotlinlang.org/docs/coding-conventions.html

## Going further
- Kotlin collections overview: https://kotlinlang.org/docs/collections-overview.html
- Lambdas and higher-order functions: https://kotlinlang.org/docs/lambdas.html. In lesson 05 the screens of an app are built from lambdas too.

## Summary
- You wrote functions with parameters, defaults and return values.
- You used lists, maps, `for` and `when`.
- You used `filter` and `map` with lambdas.

## Next lesson
04. Classes, data classes and objects: your own types, such as a `Task`.
