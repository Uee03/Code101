---
track: flutter
level: 101
phase: 1
phase_name: first-app
lesson: "02"
title: "Dart basics: types, null safety and functions"
time: "60-80 min"
prerequisites: ["flutter-101-01"]
versions: { dart: "3.14.0" }
verified: not yet run
source: source/flutter/101-zero-to-hero/phase-1-first-app/02-dart-basics/
assets: []
---

# 02. Dart basics: types, null safety and functions

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Store values in typed variables and combine them in text with string interpolation.
- Write and call functions with positional, optional and named parameters.
- Explain what a nullable type such as `String?` means and use `??`, `?.` and an `if` check on it.
- Predict what a small Dart program prints before you run it.

## Recap
1. What does `flutter doctor` do? <details><summary>Answer</summary>It checks your installation and lists what is missing.</details>
2. What is a widget? <details><summary>Answer</summary>One building block of the screen, such as text or a row.</details>

## Why it matters
A recipe card says "3 eggs" and "bake 20 minutes": amounts and steps. Dart variables are the amounts, functions are the steps. Flutter apps are made of exactly these pieces, so we practise them on a screen-free program where mistakes are easy to read. If you did Python 101 or C# 101 you will recognise most of it; the new part is that Dart checks types and `null` (the value "nothing here") before your program runs.

## What you will build
A tiny coffee-shop receipt program that prints prices, tax and a few messages in the terminal.

## Before you start
- Flutter and Dart are installed (lesson 01). The `dart` command comes with Flutter, so no extra install is needed. Check with `dart --version` in a new terminal.
- Time: 60-80 minutes. Five ideas: variables and types, string interpolation, functions, decisions and loops, null safety.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/flutter/101-zero-to-hero/phase-1-first-app/02-dart-basics/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).

## Steps
### Step 1. Make a folder and open it
**File: `terminal (Windows PowerShell)`**
```powershell
New-Item -ItemType Directory -Force "$HOME\code101\flutter101\dart_basics"
Set-Location "$HOME\code101\flutter101\dart_basics"
```

**File: `terminal (macOS or Linux)`**
```bash
mkdir -p ~/code101/flutter101/dart_basics
cd ~/code101/flutter101/dart_basics
```
The prompt now ends with `dart_basics`. This is a plain folder, not a Flutter project: Dart can run a single file by itself.

Open the folder in Android Studio (**File > Open**) or any text editor. Create a new file named exactly `main.dart`. On Windows turn on **View > Show > File name extensions** in File Explorer so it does not become `main.dart.txt`.

### Step 2. Write the program
Type this file into `main.dart`. It is long because it shows every idea once. Save it (a dot on the tab means unsaved).

**File: `main.dart`**
```dart
// Lesson 02: Dart basics. Run with: dart run main.dart

const double taxRate = 0.1;

double lineTotal(int quantity, double unitPrice) {
  return quantity * unitPrice;
}

double addTax(double amount, {double rate = taxRate}) => amount * (1 + rate);

String describeCups(int cups) {
  if (cups == 0) {
    return 'no cups';
  } else if (cups == 1) {
    return 'one cup';
  } else {
    return '$cups cups';
  }
}

String greet(String name, [String? nickname]) {
  final shown = nickname ?? name;
  return 'Hello, $shown!';
}

String? findNote(bool hasNote) => hasNote ? 'extra foam' : null;

void main() {
  // Variables and types
  String shop = 'Bean There';
  final String city = 'Lisbon';
  int cups = 3;
  double price = 2.5;
  bool isOpen = true;
  var motto = 'Fresh every hour';

  print('Shop: $shop in $city');
  print('Motto: $motto (${motto.length} characters)');
  print('Open now: $isOpen');

  // Numbers and functions
  double subtotal = lineTotal(cups, price);
  print('Subtotal: ${subtotal.toStringAsFixed(2)}');
  print('With tax: ${addTax(subtotal).toStringAsFixed(2)}');
  print('With 20% tax: ${addTax(subtotal, rate: 0.2).toStringAsFixed(2)}');
  int orders = 10;
  print('${orders ~/ 4} full boxes, ${orders % 4} cups left over');

  // Decisions
  print(describeCups(0));
  print(describeCups(1));
  print(describeCups(cups));
  if (isOpen && cups > 2) {
    print('Big order, shop is open');
  } else {
    print('Small order or closed');
  }

  // Loops
  for (var i = 1; i <= cups; i++) {
    print('Cup $i of $cups');
  }
  var left = cups;
  while (left > 0) {
    left--;
  }
  print('Cups left: $left');

  // Null safety
  String? note = findNote(false);
  print(note ?? 'no note');
  print(note?.length);
  note = findNote(true);
  if (note != null) {
    print('Note has ${note.length} characters');
  }
  print(greet('Maria'));
  print(greet('Maria', 'Mia'));
}
```

### Step 3. Read it before running
Cover the output below and answer: what will the first `print` write? Which line prints `null`? Then run it.

## Run it
**File: `terminal (folder dart_basics)`**
```text
dart run main.dart
```
Expected output (derived from the code, not yet run):
```text
Shop: Bean There in Lisbon
Motto: Fresh every hour (16 characters)
Open now: true
Subtotal: 7.50
With tax: 8.25
With 20% tax: 9.00
2 full boxes, 2 cups left over
no cups
one cup
3 cups
Big order, shop is open
Cup 1 of 3
Cup 2 of 3
Cup 3 of 3
Cups left: 0
no note
null
Note has 10 characters
Hello, Maria!
Hello, Mia!
```

## How it works
**Everything starts in `main`.** A **function** is a named list of steps. `void main()` is the one Dart calls first; `void` means it gives nothing back.

**Variables and types.** A **variable** is a labelled box that holds a value. A **type** says what kind of value: `String` (text), `int` (whole number), `double` (number with a decimal point), `bool` (`true` or `false`). `var motto = '...'` lets Dart work out the type from the value (it becomes a `String`). `final` means "set once, never change this box"; `const` means the value is known before the program even starts and never changes (like `taxRate`).

**String interpolation.** Inside quotes, `$name` inserts a variable and `${expression}` inserts the result of a small calculation, for example `${motto.length}`. A **property** such as `.length` is a fact about a value; a **method** such as `.toStringAsFixed(2)` is an action on it (here: write the number with exactly two decimals).

**Numbers.** `+ - *` and `/` work as in school. `~/` divides and drops the decimals (10 ~/ 4 is 2), and `%` gives the remainder (10 % 4 is 2). A comparison such as `cups > 2` gives a `bool`; `&&` means "and".

**Functions with parameters.** A **parameter** is a value a function receives. `lineTotal(int quantity, double unitPrice)` has two positional parameters: you pass them in order. `addTax(double amount, {double rate = taxRate})` has a **named** parameter in braces with a **default** value, so you may write `addTax(subtotal)` or `addTax(subtotal, rate: 0.2)`. `greet(String name, [String? nickname])` has an **optional positional** parameter in square brackets. `=>` is the short form for a function that is a single `return`.

**Decisions and loops.** `if / else if / else` runs the first block whose condition is true. `for (var i = 1; i <= cups; i++)` repeats while the condition holds (`i++` adds one each time). `while (left > 0)` repeats until the condition is false.

**Null safety.** `null` means "there is no value". A normal type such as `String` can never be `null`; a type with a question mark, `String?`, may be. Dart makes you handle that before it lets you use the value:
- `note ?? 'no note'` means "use `note`, but if it is null use the text instead".
- `note?.length` means "ask for the length only if `note` is not null; otherwise the answer is null". That is why the program prints the word `null`.
- `if (note != null) { ... }` proves to Dart that inside the block the value is not null, so `note.length` is allowed there.

Common misconception: "null checks are Dart being annoying." They remove the most common crash in apps: using a value that is not there.

## Try it
Make a new folder `try02` next to `dart_basics`, copy the starter's `main.dart` into it and run it from there. The starter:

**File: `exercise/starter/main.dart`**
```dart
// Exercise 02: tip calculator. Run with: dart run main.dart

double tipAmount(double bill, {double percent = 10}) {
  // TODO 1: return the tip: the bill times percent divided by 100
  return 0;
}

String? pickName(bool known) => known ? 'Sam' : null;

void main() {
  final double bill = 80;
  print('Tip (10%): ${tipAmount(bill).toStringAsFixed(2)}');
  // TODO 2: print the 15% tip in the same format, using the named argument percent
  final String? name = pickName(false);
  // TODO 3: print 'Table for ' followed by the name, or the word guest when there is no name
  // TODO 4: print 'Total with 15% tip: ' followed by the bill plus the 15% tip, 2 decimals
}
```

1. **Guided:** fill in the four TODOs so the program prints the tips and the total. The 10% tip of 80 is 8.00.
2. **Change:** also print what each of four people pays.
3. **Stretch (optional):** add a function `String tipMessage(double percent)` that returns a different sentence for small, normal and generous tips. Decide your own limits.

Expected output of the finished exercise (the first four lines are fixed; the last line belongs to rung 2):
```text
Tip (10%): 8.00
Tip (15%): 12.00
Table for guest
Total with 15% tip: 92.00
Per person (4): 23.00
```

<details><summary>Solution</summary>

**File: `exercise/solution/main.dart`**
```dart
// Exercise 02: tip calculator. Run with: dart run main.dart

double tipAmount(double bill, {double percent = 10}) {
  return bill * percent / 100;
}

String? pickName(bool known) => known ? 'Sam' : null;

void main() {
  final double bill = 80;
  print('Tip (10%): ${tipAmount(bill).toStringAsFixed(2)}');
  print('Tip (15%): ${tipAmount(bill, percent: 15).toStringAsFixed(2)}');
  final String? name = pickName(false);
  print('Table for ${name ?? 'guest'}');
  final double total = bill + tipAmount(bill, percent: 15);
  print('Total with 15% tip: ${total.toStringAsFixed(2)}');
  print('Per person (4): ${(total / 4).toStringAsFixed(2)}');
}
```

The tip is `bill * percent / 100`. `name ?? 'guest'` picks the fallback because `pickName(false)` returns null.

</details>

## Check yourself
1. What is the difference between `final` and `const`? <details><summary>Answer</summary>`final` is set once while the program runs; `const` is fixed before it runs.</details>
2. What does `print(10 ~/ 4)` write? <details><summary>Answer</summary>`2`.</details>
3. `String? s = null;` then `print(s?.length);` What is printed? <details><summary>Answer</summary>`null`: the `?.` skips the call when `s` is null.</details>
4. Find the bug: `int cups = 'three';` <details><summary>Answer</summary>A text value cannot be stored in an `int` variable; Dart reports a type error before running.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Expected ';' after this.` (typical message) | A statement does not end with a semicolon | Add `;` at the end of the line the message points to |
| `A value of type 'String' can't be assigned to a variable of type 'int'.` (typical message) | Wrong type in an assignment such as `int cups = 'three';` | Use a value of the declared type |
| `A value of type 'String?' can't be assigned to a variable of type 'String'.` (typical message) | A nullable value was used where null is not allowed | Handle null with `??` or an `if (x != null)` check |
| `Undefined name 'chups'.` (typical message) | Misspelled variable; Dart is case sensitive | Use the exact spelling and capitals |
| `Error: Can't find 'main.dart'` or `Could not find file` (typical wording) | Terminal is in another folder, or the file is named `main.dart.txt` | `cd` into `dart_basics` and show file extensions |
| Output shows `7.5` instead of `7.50` | `toStringAsFixed(2)` was left out | Add it; it forces two decimals |

## Best practice
Prefer `final` for values that do not change and give functions clear names and types. Source: [Effective Dart: Design](https://dart.dev/effective-dart/design) and [Dart language tour](https://dart.dev/language)

## Going further
- Read the [null safety guide](https://dart.dev/null-safety) on dart.dev.
- Try the free [DartPad](https://dartpad.dev/) in a browser to test small snippets.

## Summary
- You declared typed variables, used `final` and `const`, and built text with interpolation.
- You wrote functions with positional, optional and named parameters.
- You used `if`, `for` and `while`, and handled `String?` with `??`, `?.` and a null check.

## Next lesson
03. Dart collections, classes and async basics: lists, maps, your own types and waiting for slow work.
