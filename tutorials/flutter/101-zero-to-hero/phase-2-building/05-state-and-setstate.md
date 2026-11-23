---
track: flutter
level: 101
phase: 2
phase_name: building
lesson: "05"
title: "StatelessWidget, StatefulWidget and setState"
time: "60-75 min"
prerequisites: ["flutter-101-04"]
versions: { flutter: "3.50.1", dart: "3.14.0", material_ui: "1.11.1" }
verified: not yet run
source: source/flutter/101-zero-to-hero/phase-2-building/05-state-and-setstate/
assets: []
---

# 05. StatelessWidget, StatefulWidget and setState

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Choose between a `StatelessWidget` and a `StatefulWidget`.
- Change what is on screen with `setState`.
- Pass data to a child widget through its constructor.
- Explain why changing a variable without `setState` does not update the screen.

## Recap
1. What does `Expanded` do inside a `Row`? <details><summary>Answer</summary>It gives the child the leftover space.</details>
2. Why is `const` added in front of widgets such as `const Text('Hi')`? <details><summary>Answer</summary>The widget is created once and can be reused, which saves work.</details>

## Why it matters
A kitchen timer face is a **picture**; what the numbers show is the **state**. If the state changes, you need a new picture. In Flutter, a widget that never changes is `Stateless`; a widget that remembers something that changes (a counter, a typed word, a switch) is `Stateful`. Almost every real screen has some state.

## What you will build
A tea-cup counter with `-1`, `+1` and `Reset` buttons, a switch that shows or hides a hint, and a message that changes with the count.

## Before you start
- Lesson 04 finished.
- Time: 60-75 minutes. Four ideas: state, `StatefulWidget`, `setState`, passing data down.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/flutter/101-zero-to-hero/phase-2-building/05-state-and-setstate/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).

## Steps
### Step 1. Create the project
**File: `terminal (Windows PowerShell)`**
```powershell
Set-Location "$HOME\code101\flutter101"
flutter create --platforms=android state_lab
Set-Location state_lab
Remove-Item -Recurse -Force test
```

**File: `terminal (macOS or Linux)`**
```bash
cd ~/code101/flutter101
flutter create --platforms=android state_lab
cd state_lab
rm -rf test
```

### Step 2. Replace `pubspec.yaml`, then run `flutter pub get`
**File: `pubspec.yaml`**
```yaml
name: state_lab
description: State and setState practice for Code101.
publish_to: none
version: 1.0.0+1

environment:
  sdk: ^3.14.0

dependencies:
  flutter:
    sdk: flutter
  material_ui: 1.11.1

dev_dependencies:
  flutter_lints: 6.0.0

flutter:
  uses-material-design: true
```

### Step 3. Replace `lib/main.dart`
**File: `lib/main.dart`**
```dart
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const StateLabApp());
}

class StateLabApp extends StatelessWidget {
  const StateLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'State lab',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const CounterScreen(),
    );
  }
}

class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  int _count = 0;
  bool _showHint = true;

  void _increment() {
    setState(() {
      _count++;
    });
  }

  void _decrement() {
    if (_count > 0) {
      setState(() {
        _count--;
      });
    }
  }

  void _reset() {
    setState(() {
      _count = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('State lab')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Cups of tea today',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            CountDisplay(count: _count),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: _count > 0 ? _decrement : null,
                  child: const Text('-1'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _increment,
                  child: const Text('+1'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _reset,
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SwitchListTile(
                title: const Text('Show hint'),
                value: _showHint,
                onChanged: (value) {
                  setState(() {
                    _showHint = value;
                  });
                },
              ),
            ),
            if (_showHint) const Text('Tap +1 after every cup.'),
          ],
        ),
      ),
    );
  }
}

class CountDisplay extends StatelessWidget {
  const CountDisplay({super.key, required this.count});

  final int count;

  String get _message {
    if (count == 0) {
      return 'Start counting';
    } else if (count < 3) {
      return 'Nice and calm';
    } else {
      return 'Time for a break';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$count', style: Theme.of(context).textTheme.displayMedium),
        Text(_message),
      ],
    );
  }
}
```

## Run it
**File: `terminal (folder state_lab)`**
```text
flutter run
```
Predict first: after tapping `+1` three times, what does the screen say? Then check. Expected behaviour (described from the code, not yet seen): the screen starts with "Cups of tea today", a big `0`, the message "Start counting", three buttons and a switch that is on with the hint "Tap +1 after every cup." The `-1` button is greyed out at 0. After one tap on `+1` the number is 1 and the message "Nice and calm"; after three taps it is 3 and "Time for a break". `Reset` returns to 0. Turning the switch off hides the hint line.

## How it works
**State** is data that can change while the app runs and that the screen depends on. Here: `_count` and `_showHint`.

**Two kinds of widget.**
- A `StatelessWidget` has no changing data of its own. Its `build` method depends only on the values given to its constructor. `CountDisplay` is stateless: it shows whatever `count` it receives.
- A `StatefulWidget` is split in two classes. The widget (`CounterScreen`) is immutable configuration. Its **State** object (`_CounterScreenState`) lives on and holds the changing variables. `createState()` links the two. The underscore at the start of `_CounterScreenState` makes the class private to this file.

**`setState`.** Changing `_count++` alone changes the variable but Flutter does not know the picture is out of date. `setState(() { _count++; })` changes the variable *and* tells Flutter to call `build` again. Flutter then compares the new tree with the old one and redraws only what differs. Keep the code inside `setState` tiny: just the assignments.

**Data flows down.** `CounterScreen` owns the count and passes it to `CountDisplay(count: _count)`. The child cannot change it; it only displays it. When the count changes, the parent rebuilds and hands the child a new number. This one-way flow is the habit that keeps larger apps understandable.

**Disabled buttons.** `onPressed: null` makes a button inactive. `_count > 0 ? _decrement : null` means "allow it only when it makes sense".

**Conditional widgets.** `if (_showHint) const Text(...)` inside a list adds the widget only when the condition is true.

**Where to put state.** Put it in the lowest widget that needs it. If two widgets far apart need the same data, move it to a common parent, or use a state tool such as Riverpod (level 201).

Common misconception: "`setState` is slow, so avoid it." It is the normal tool; just keep `build` methods small and do not do slow work inside them.

## Try it
Create a project `try05` like Step 1 (with the lesson's `pubspec.yaml`, `name:` changed to `try05`) and replace `lib/main.dart` with the starter:

**File: `exercise/starter/lib/main.dart`**
```dart
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const WaterApp());
}

class WaterApp extends StatelessWidget {
  const WaterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Water tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const WaterScreen(),
    );
  }
}

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  static const int goal = 8;
  int _glasses = 0;

  void _drink() {
    // TODO 1: increase _glasses by one inside setState
  }

  void _reset() {
    // TODO 2: set _glasses back to 0 inside setState
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Water tracker')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$_glasses of $goal glasses'),
            const SizedBox(height: 16),
            // TODO 3: add a LinearProgressIndicator whose value is _glasses divided by goal
            const SizedBox(height: 16),
            // TODO 4: show the text 'Goal reached!' only when _glasses is at least goal
            const SizedBox(height: 16),
            FilledButton(onPressed: _drink, child: const Text('Drink a glass')),
            TextButton(onPressed: _reset, child: const Text('Reset')),
          ],
        ),
      ),
    );
  }
}
```

1. **Guided:** complete TODO 1 to 4. After eight taps on **Drink a glass** the bar is full and "Goal reached!" appears; `Reset` clears everything.
2. **Change:** stop counting above the goal (a ninth tap does nothing) and disable the button when the goal is reached.
3. **Stretch (optional):** turn the goal into a setting the user can raise or lower with two buttons. Where must that value live?

<details><summary>Solution</summary>

**File: `exercise/solution/lib/main.dart`**
```dart
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const WaterApp());
}

class WaterApp extends StatelessWidget {
  const WaterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Water tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const WaterScreen(),
    );
  }
}

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  static const int goal = 8;
  int _glasses = 0;

  void _drink() {
    setState(() {
      _glasses++;
    });
  }

  void _reset() {
    setState(() {
      _glasses = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Water tracker')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$_glasses of $goal glasses'),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: (_glasses / goal).clamp(0, 1).toDouble()),
            const SizedBox(height: 16),
            if (_glasses >= goal) const Text('Goal reached!'),
            const SizedBox(height: 16),
            FilledButton(onPressed: _drink, child: const Text('Drink a glass')),
            TextButton(onPressed: _reset, child: const Text('Reset')),
          ],
        ),
      ),
    );
  }
}
```

`clamp(0, 1)` keeps the bar value inside the range the indicator accepts.

</details>

## Check yourself
1. Which widget type do you choose for a label that never changes? <details><summary>Answer</summary>`StatelessWidget`.</details>
2. You write `_count++;` in a button handler without `setState`. What happens? <details><summary>Answer</summary>The variable changes but the screen does not rebuild, so it still shows the old number.</details>
3. Who owns the count: `CounterScreen`'s State or `CountDisplay`? <details><summary>Answer</summary>The State object of `CounterScreen`; `CountDisplay` only receives it.</details>
4. What does `onPressed: null` do? <details><summary>Answer</summary>The button is disabled and drawn greyed out.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| Number does not change on tap | `setState` is missing | Wrap the change in `setState(() { ... })` |
| `setState() called after dispose()` (typical message) | `setState` runs after an async wait when the screen is gone | Check `if (!mounted) return;` first (lesson 10 uses it) |
| `Undefined name '_count'` (typical message) | Variable declared in the widget class instead of the State class | Declare it in `_CounterScreenState` |
| `The argument for the named parameter 'count' was not provided.` (typical message) | Missing `required` argument in `CountDisplay()` | Pass `count: _count` |
| Hot reload keeps the old count | Hot reload keeps state on purpose | Press `R` (hot restart) to reset the state |

## Best practice
Keep state as local and small as possible and treat widgets as read-only descriptions of the current state. Source: [Flutter: Adding interactivity](https://docs.flutter.dev/ui/interactivity)

## Going further
- [State management introduction](https://docs.flutter.dev/data-and-backend/state-mgmt/intro). Level 201 uses Riverpod for larger apps.

## Summary
- You separated stateless from stateful widgets and built both.
- You changed the screen with `setState` and passed data to a child through its constructor.
- You disabled a button and showed a widget conditionally.

## Next lesson
06. Lists, forms and input: a scrolling shopping list with a form that checks what you type.
