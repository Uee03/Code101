---
track: kotlin
level: 101
phase: 1
phase_name: kotlin-basics
lesson: 02
title: Variables, types and null safety
time: 45-60 min
prerequisites: [01]
versions: { kotlin: "2.4.21", gradle: "9.6.0" }
verified: not yet run
source: source/kotlin/101-zero-to-hero/phase-1-kotlin-basics/02-variables-types-null-safety/
assets: []
---

# 02. Variables, types and null safety

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
By the end of this lesson you will be able to:
- store values in `val` and `var` and say when each is right;
- pick the basic types `Int`, `Double`, `Boolean`, `Char` and `String`;
- build text with string templates and choose a value with `if`;
- predict what happens when a value can be `null`, and handle it safely.

## Recap
1. What does `println("Hi")` print? <details><summary>Answer</summary>`Hi`, followed by a new line.</details>
2. Where must a Kotlin file be, so that the green triangle appears? <details><summary>Answer</summary>Inside `src/main/kotlin` of a project that Gradle has synced.</details>

## Why it matters
A kitchen has labelled jars: "sugar", "flour". The label tells you what is inside, and some jars you refill while others stay as they are. A **variable** is a labelled jar for a value. And sometimes a jar is simply empty. Many real bugs in other languages come from using an empty jar as if it were full; Kotlin makes you deal with the empty jar before the program runs.

## What you will build
A tiny café report that stores a shop name, a count and a price, prints a total, and then shows what Kotlin does with missing values.

## Before you start
- The `KotlinBasics` project from lesson 01, opened in Android Studio (use **File > Open Recent**).
- Time: about 45 to 60 minutes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/kotlin/101-zero-to-hero/phase-1-kotlin-basics/02-variables-types-null-safety/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).

New words: variable, `val`, `var`, type, `Int`, `Double`, `Boolean`, `Char`, `String`, type inference, string template, expression, `null`, nullable type, safe call, Elvis operator.

## Steps

### Step 1. Create the file
Right-click `src/main/kotlin` and choose **New > Directory**: `lesson02`. Then right-click `lesson02` and choose **New > File**: `Main.kt`. (All other project files stay as they are, from lesson 01.)

Why `Main.kt`, not `Hello.kt` again? Two top-level `main` functions in the same package would clash, so every lesson gets its own package and folder.

### Step 2. Values with `val` and `var`
Type this first part into `Main.kt`:

```kotlin
package lesson02

fun main() {
    val shopName = "Corner Cafe"
    var cupsSold = 12
    val pricePerCup = 2.5

    cupsSold = cupsSold + 3
    val total = cupsSold * pricePerCup

    println("$shopName sold $cupsSold cups")
    println("Total: $total")
}
```
Predict before you run: what number does `Total:` show? Work it out: 12 plus 3, times 2.5.

Run it with the green triangle. Expected output:
```text
Corner Cafe sold 15 cups
Total: 37.5
```

### Step 3. The whole file, with types, `if` and null safety
Replace the content of `Main.kt` by this complete file:

**File: `src/main/kotlin/lesson02/Main.kt`**
```kotlin
package lesson02

fun main() {
    val shopName = "Corner Cafe"
    var cupsSold = 12
    val pricePerCup = 2.5
    val isOpen = true
    val grade = 'A'

    cupsSold = cupsSold + 3
    val total = cupsSold * pricePerCup

    println("$shopName is open: $isOpen")
    println("Cups sold: $cupsSold")
    println("Total: $total")
    println("Whole cups per pair: ${cupsSold / 2}")
    println("Exact cups per pair: ${cupsSold / 2.0}")
    println("Shop name has ${shopName.length} letters")
    println("Grade: $grade")

    val dayType = if (cupsSold >= 10) "busy" else "quiet"
    println("Today was $dayType")

    showNullSafety()
}

fun showNullSafety() {
    val typedAge: String? = "42"
    val missingAge: String? = null

    println(typedAge?.length)
    println(missingAge?.length)
    println(missingAge ?: "no age given")

    val age = typedAge?.toIntOrNull() ?: 0
    println("Age plus one: ${age + 1}")

    val notANumber = "forty".toIntOrNull()
    println(notANumber)

    if (typedAge != null) {
        println("Typed age uses ${typedAge.length} characters")
    }
}
```
Predict before you run: the lines `15 / 2` and `15 / 2.0` give different answers. What are they?

## Run it
Press the green triangle next to `fun main()`.

Expected output:
```text
Corner Cafe is open: true
Cups sold: 15
Total: 37.5
Whole cups per pair: 7
Exact cups per pair: 7.5
Shop name has 11 letters
Grade: A
Today was busy
2
null
no age given
Age plus one: 43
null
Typed age uses 2 characters
```

## How it works
**`val` and `var`.** `val` makes a value you cannot replace later ("value"), like a jar with a sealed lid. `var` makes a variable you can change ("variable"). Prefer `val`; use `var` only when the value really changes, such as `cupsSold`. Trying to assign to a `val` is a compile error.

**Types.** Every value has a **type**, which tells what kind of thing it is.

| Type | Holds | Example |
|---|---|---|
| `Int` | whole numbers | `15` |
| `Double` | numbers with a decimal point | `2.5` |
| `Boolean` | `true` or `false` | `true` |
| `Char` | one character, in single quotes | `'A'` |
| `String` | text, in double quotes | `"Corner Cafe"` |

You did not write the types: Kotlin works them out from the value. This is **type inference**. You may also write them, as in `val typedAge: String? = "42"`.

**Arithmetic.** `Int` divided by `Int` stays whole: `15 / 2` is `7`, the remainder is dropped. Divide by `2.0` (a `Double`) and you get `7.5`. Misconception: "the computer made a mistake". No, whole-number division is exactly defined that way.

**String templates.** `"$cupsSold"` puts the value of `cupsSold` into the text. For anything longer than a name use braces: `"${cupsSold / 2}"`.

**`if` is an expression.** `if (cupsSold >= 10) "busy" else "quiet"` produces a value, so you can store it in `dayType`. An **expression** is a piece of code that has a value.

**`null`.** `null` means "no value". A normal type such as `String` can never hold `null`. A type with a question mark, `String?`, may. That is a **nullable type**. Kotlin refuses `missingAge.length` because the jar might be empty. Three safe tools:
- `?.` the **safe call**: `missingAge?.length` gives `null` instead of failing.
- `?:` the **Elvis operator** (turn your head sideways): `missingAge ?: "no age given"` means "use the left side, or the right side if it is null".
- `if (typedAge != null) { ... }`: inside the braces Kotlin knows the value is not null, so `typedAge.length` is allowed (a **smart cast**).

`toIntOrNull()` turns text into a number, or `null` when the text is not a number; that is why `"forty".toIntOrNull()` prints `null`.

There is also `!!`, which means "I promise it is not null" and crashes if you are wrong. Avoid it in this course.

## Try it
1. **Guided:** create `src/main/kotlin/exercise02/Stock.kt` (new directory `exercise02` first) with the starter below and replace each TODO.

**File: `src/main/kotlin/exercise02/Stock.kt`**
```kotlin
package exercise02

fun main() {
    val itemName = "tea bags"
    var stock = 40
    val sold = 7

    // TODO 1: take the sold amount away from stock
    // TODO 2: print the line "tea bags left: 33" using a string template with $itemName and $stock
    // TODO 3: declare nickname as a String? that holds null, then print nickname, or the text "no nickname" if it is null
}
```
Expected output:
```text
tea bags left: 33
no nickname
```
2. **Change:** add a `val price = 1.5` and print the value of the remaining stock.
3. **Stretch (optional):** what should happen if `sold` is larger than `stock`? Decide on a rule and write it with `if`.

<details><summary>Solution</summary>

**File: `src/main/kotlin/exercise02/Stock.kt`**
```kotlin
package exercise02

fun main() {
    val itemName = "tea bags"
    var stock = 40
    val sold = 7

    stock = stock - sold
    println("$itemName left: $stock")

    val nickname: String? = null
    println(nickname ?: "no nickname")
}
```
`stock` is a `var` because it changes; the Elvis operator supplies the text when `nickname` is `null`.

</details>

## Check yourself
1. When do you use `var` instead of `val`? <details><summary>Answer</summary>When the value has to change later; otherwise use `val`.</details>
2. What is `7 / 2` and what is `7 / 2.0`? <details><summary>Answer</summary>`3` (whole-number division) and `3.5`.</details>
3. What does `missingAge ?: "no age given"` do? <details><summary>Answer</summary>It gives the text when `missingAge` is `null`, otherwise the value of `missingAge`.</details>
4. Find the bug: `val count = 3` then later `count = count + 1`. <details><summary>Answer</summary>A `val` cannot be reassigned; declare it with `var`.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Val cannot be reassigned` (typical message) | You changed a `val` | Use `var` if the value must change |
| `Type mismatch` message naming `String` and `Int` (typical) | You put text where a number is expected, or the opposite, for example `val n: Int = "5"` | Convert with `toInt()` or `toIntOrNull()` |
| A message that only safe calls (`?.`) or non-null asserted calls (`!!.`) are allowed on a nullable receiver (typical) | You used `.length` on a `String?` | Use `?.`, `?:` or an `if (x != null)` check |
| Output says `Cups sold: $cupsSold` | The text is not in a double-quoted string, or you used single quotes | Use double quotes for strings |
| `Unresolved reference` for `lesson02` | The file is in the wrong folder or the package line does not match | Put the file under `src/main/kotlin/lesson02` and keep `package lesson02` |

## Best practice
Prefer `val` over `var`, and avoid `!!`; model "maybe missing" with `?` types and handle them explicitly. Source: Kotlin null safety https://kotlinlang.org/docs/null-safety.html and coding conventions https://kotlinlang.org/docs/coding-conventions.html

## Going further
- Kotlin basic types: https://kotlinlang.org/docs/basic-types.html
- In lesson 10 a missing network response is modelled as a type too, instead of `null`.

## Summary
- You declared values with `val` and `var` and explained the difference.
- You used `Int`, `Double`, `Boolean`, `Char` and `String`, and string templates.
- You wrote an `if` expression.
- You handled `null` with `?.`, `?:` and an `if` check.

## Next lesson
03. Functions, collections and lambdas: reusable named instructions, lists and maps, and short lambdas.
