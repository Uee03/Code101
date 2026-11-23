---
track: flutter
level: 101
phase: 1
phase_name: first-app
lesson: "03"
title: "Dart collections, classes and async basics"
time: "75-90 min"
prerequisites: ["flutter-101-02"]
versions: { dart: "3.14.0" }
verified: not yet run
source: source/flutter/101-zero-to-hero/phase-1-first-app/03-dart-collections-classes-async/
assets: []
---

# 03. Dart collections, classes and async basics

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Create and change lists, maps and sets and loop over them.
- Describe your own data with a class, a constructor and an enum.
- Filter and transform a list with `where` and `map`.
- Explain what `Future`, `async` and `await` do, and handle a failure with `try` and `catch`.

## Recap
1. What does `String?` mean and which operator gives a fallback for it? <details><summary>Answer</summary>The value may be null; `??` gives a fallback.</details>
2. How do you call `addTax(100, rate: 0.2)`: is `rate` positional or named? <details><summary>Answer</summary>Named, because it is written in braces in the function header.</details>

## Why it matters
A shopping list is a **list**, a phone book is a **map** (name to number), a stamp collection without duplicates is a **set**. Apps are mostly collections of things (tasks, messages, products). And almost everything interesting, such as a network request, takes time, so apps must be able to wait without freezing. This lesson gives you both tools.

## What you will build
A console program with a list of titles, a map of scores, a set of tags, a `Task` class with a priority, and a pretend slow download that sometimes fails.

## Before you start
- Lesson 02 finished; `dart --version` works in a new terminal.
- Time: 75-90 minutes. Five ideas: collections, classes and enums, `where`/`map`, `Future` and `await`, `try`/`catch`.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/flutter/101-zero-to-hero/phase-1-first-app/03-dart-collections-classes-async/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).

## Steps
### Step 1. Make a folder
**File: `terminal (Windows PowerShell)`**
```powershell
New-Item -ItemType Directory -Force "$HOME\code101\flutter101\dart_collections"
Set-Location "$HOME\code101\flutter101\dart_collections"
```

**File: `terminal (macOS or Linux)`**
```bash
mkdir -p ~/code101/flutter101/dart_collections
cd ~/code101/flutter101/dart_collections
```
Create `main.dart` in that folder with your editor.

### Step 2. Write the program
**File: `main.dart`**
```dart
// Lesson 03: collections, classes and async. Run with: dart run main.dart

enum Priority { low, normal, high }

class Task {
  Task(this.title, {this.priority = Priority.normal, this.done = false});

  final String title;
  final Priority priority;
  bool done;

  void complete() {
    done = true;
  }

  @override
  String toString() => '${done ? '[x]' : '[ ]'} $title (${priority.name})';
}

Future<String> fetchTitle(int id) async {
  await Future.delayed(const Duration(milliseconds: 100));
  if (id < 0) {
    throw ArgumentError('id must be positive');
  }
  return 'Task #$id';
}

Future<void> main() async {
  // Lists
  final titles = ['Buy milk', 'Write notes', 'Call Sam'];
  titles.add('Plan trip');
  print('First: ${titles.first}, count: ${titles.length}');
  print(titles);

  // Maps and sets
  final points = {'Ana': 3, 'Ben': 5};
  points['Cy'] = 2;
  points.forEach((name, score) {
    print('$name has $score');
  });
  final tags = {'home', 'work', 'home'};
  print('Distinct tags: ${tags.length}');

  // Classes
  final tasks = [
    Task('Buy milk'),
    Task('Write notes', priority: Priority.high),
    Task('Call Sam'),
  ];
  tasks[0].complete();
  for (final task in tasks) {
    print(task);
  }
  final open = tasks.where((task) => !task.done).toList();
  print('Open tasks: ${open.length}');
  final names = tasks.map((task) => task.title.toUpperCase()).toList();
  print(names);
  tasks.sort((a, b) => b.priority.index.compareTo(a.priority.index));
  print('Most urgent: ${tasks.first}');

  // Async
  print('Loading...');
  final title = await fetchTitle(7);
  print(title);
  try {
    await fetchTitle(-1);
  } catch (error) {
    print('Failed: $error');
  }
  final results = await Future.wait([fetchTitle(1), fetchTitle(2)]);
  print(results);
  print('Done');
}
```

### Step 3. Predict, then run
Before running, answer: how many lines mention `Task #`? In which order will `Ana`, `Ben` and `Cy` print?

## Run it
**File: `terminal (folder dart_collections)`**
```text
dart run main.dart
```
Expected output (derived from the code, not yet run). The three lines after `Loading...` appear one after another with a short pause:
```text
First: Buy milk, count: 4
[Buy milk, Write notes, Call Sam, Plan trip]
Ana has 3
Ben has 5
Cy has 2
Distinct tags: 2
[x] Buy milk (normal)
[ ] Write notes (high)
[ ] Call Sam (normal)
Open tasks: 2
[BUY MILK, WRITE NOTES, CALL SAM]
Most urgent: [ ] Write notes (high)
Loading...
Task #7
Failed: Invalid argument(s): id must be positive
[Task #1, Task #2]
Done
```

## How it works
**List.** An ordered collection written in square brackets. `add` appends, `first` and `length` read facts about it. `final titles = [...]` means the variable always points at the same list, but you may still add to the list itself. Dart works out that this is a `List<String>`; the angle brackets name the type of the items.

**Map.** Pairs of **key** and **value** in braces: `{'Ana': 3}`. `points['Cy'] = 2` adds or replaces a pair. `forEach` calls a small function for each pair. A map remembers the order you added the pairs.

**Set.** Like a list but without duplicates and without a position: `'home'` was written twice and counts once.

**Class.** A **class** is a blueprint for your own kind of value. `Task` has three **fields** (data each task carries): `title`, `priority`, `done`. The **constructor** `Task(this.title, {this.priority = Priority.normal, this.done = false})` creates one task; `this.title` is the short way to store the argument in the field. A **method** such as `complete()` is a function that belongs to the class. `toString()` is the method `print` uses to turn a task into text; `@override` says "I am replacing the default one". An **enum** (`Priority`) is a fixed list of allowed names; `priority.name` gives the text and `priority.index` the position (low 0, normal 1, high 2).

**Transforming lists.** `where((task) => !task.done)` keeps the tasks for which the small function returns true; `map((task) => ...)` makes a new value for each task; `toList()` turns the result back into a list. The part `(task) => ...` is an **anonymous function**: a function with no name written right where it is used. `sort` takes a function that compares two items; comparing `b` with `a` gives biggest first.

**Async.** Waiting for a server must not freeze the screen. A function marked `async` returns a **Future**, a promise of a value that arrives later. `await` pauses *this* function until the Future finishes, while the rest of the app keeps running. `Future.delayed` pretends to be a slow download. `main` is also `async` here so it can use `await`. `try { ... } catch (error) { ... }` runs the risky code and, if it throws (raises an error), jumps to `catch` instead of crashing. `Future.wait([...])` starts several Futures together and gives all results as a list.

Common misconception: "await blocks the whole program." It only pauses the function it is in; Flutter keeps drawing the screen meanwhile.

## Try it
Make a folder `try03` next to `dart_collections` and put the starter's `main.dart` in it.

**File: `exercise/starter/main.dart`**
```dart
// Exercise 03: a small shop. Run with: dart run main.dart

class Product {
  Product(this.name, this.price);

  final String name;
  final double price;

  // TODO 1: override toString so it returns the name, a colon and the price with 2 decimals
}

Future<double> loadDiscount() async {
  await Future.delayed(const Duration(milliseconds: 100));
  return 0.1;
}

Future<void> main() async {
  final products = [
    Product('Pen', 1.5),
    Product('Book', 12.0),
    Product('Bag', 30.0),
  ];
  // TODO 2: print every product with a for-in loop
  // TODO 3: use where to keep the products cheaper than 20 and print how many there are
  // TODO 4: add up all prices with a loop and print the total
  // TODO 5: await loadDiscount() and print the total after that discount
}
```

1. **Guided:** complete the five TODOs. Expected output:
```text
Pen: 1.50
Book: 12.00
Bag: 30.00
Cheap products: 2
Total: 43.50
Discounted total: 39.15
```
2. **Change:** print only the names of the cheap products as one list using `map`.
3. **Stretch (optional):** make `loadDiscount` throw an error when called with a negative code, and show a friendly message with `try`/`catch`.

<details><summary>Solution</summary>

**File: `exercise/solution/main.dart`**
```dart
// Exercise 03: a small shop. Run with: dart run main.dart

class Product {
  Product(this.name, this.price);

  final String name;
  final double price;

  @override
  String toString() => '$name: ${price.toStringAsFixed(2)}';
}

Future<double> loadDiscount() async {
  await Future.delayed(const Duration(milliseconds: 100));
  return 0.1;
}

Future<void> main() async {
  final products = [
    Product('Pen', 1.5),
    Product('Book', 12.0),
    Product('Bag', 30.0),
  ];
  for (final product in products) {
    print(product);
  }
  final cheap = products.where((product) => product.price < 20).toList();
  print('Cheap products: ${cheap.length}');
  var total = 0.0;
  for (final product in products) {
    total += product.price;
  }
  print('Total: ${total.toStringAsFixed(2)}');
  final discount = await loadDiscount();
  print('Discounted total: ${(total * (1 - discount)).toStringAsFixed(2)}');
}
```

`total * (1 - discount)` takes 10 percent off 43.50.

</details>

## Check yourself
1. How many items does `{'a', 'b', 'a'}` have? <details><summary>Answer</summary>Two, because a set removes duplicates.</details>
2. What does `await` do? <details><summary>Answer</summary>Pauses the current async function until the Future is done; the rest of the app keeps running.</details>
3. What type does an `async` function that returns a `String` have? <details><summary>Answer</summary>`Future<String>`.</details>
4. Find the bug: `final tasks = [Task('a')]; tasks = [];` <details><summary>Answer</summary>A `final` variable cannot be reassigned; use `tasks.clear()` instead.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `The await expression can only be used in an async function.` (typical message) | `await` inside a function without `async` | Add `async` to the function header and `Future<...>` to its return type |
| `The argument type 'int' can't be assigned to the parameter type 'String'.` (typical message) | Wrong argument type when creating an object | Pass the type the constructor expects |
| `Constant variables can't be assigned a value.` or `... final variable ... can't be assigned` (typical wording) | Re-assigning a `final` or `const` variable | Change the contents of the collection, not the variable |
| Output prints `Instance of 'Task'` | `toString` is missing or misspelled | Add the `@override String toString()` method |
| `Unhandled exception: Invalid argument(s): ...` (typical message) | A thrown error without `try`/`catch` | Wrap the `await` in `try` and `catch` |

## Best practice
Choose the collection that matches the question: order and position (list), lookup by name (map), uniqueness (set). Source: [Dart collections](https://dart.dev/language/collections)

## Going further
- [Asynchronous programming: futures, async, await](https://dart.dev/libraries/async/async-await)
- [Dart classes](https://dart.dev/language/classes)

## Summary
- You created lists, maps and sets and looped over them.
- You wrote a `Task` class with a constructor, a method, `toString` and an enum.
- You filtered and transformed lists with `where` and `map`.
- You used `Future`, `async`, `await` and `try`/`catch`.

## Next lesson
04. Widgets and layout: back to the phone, with the Dart you now know.
