---
track: flutter
level: 101
phase: 2
phase_name: building
lesson: "06"
title: "Lists, forms and input"
time: "75-90 min"
prerequisites: ["flutter-101-05"]
versions: { flutter: "3.50.1", dart: "3.14.0", material_ui: "1.11.1" }
verified: not yet run
source: source/flutter/101-zero-to-hero/phase-2-building/06-lists-forms-and-input/
assets: []
---

# 06. Lists, forms and input

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Show a long list efficiently with `ListView.builder`.
- Read what the user types with a `TextEditingController` and check it with a `Form` and validators.
- Update a list with immutable items and `copyWith`.
- Let the user check off and swipe away list items.

## Recap
1. What must you call to make the screen update after changing a variable? <details><summary>Answer</summary>`setState`.</details>
2. What does a `StatefulWidget`'s State object hold? <details><summary>Answer</summary>The data that changes.</details>

## Why it matters
Think of a paper shopping list. You write an item, tick it when bought, strike it out when you no longer need it. Almost every app has this pattern: type something, check it is sensible, add it to a list, change or remove it. This lesson builds that pattern and it becomes the backbone of the course project.

## What you will build
A shopping list: a form with an item name and a quantity, an **Add** button that rejects bad input, a scrolling list with check boxes, and swipe-to-delete. The title shows how many items are left.

## Before you start
- Lesson 05 finished.
- Time: 75-90 minutes. Five ideas: `ListView.builder`, controllers, `Form` validation, immutable items with `copyWith`, `Dismissible`.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/flutter/101-zero-to-hero/phase-2-building/06-lists-forms-and-input/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- This lesson starts the `shopping_list` project that lessons 07, 08, 10 and 11 extend.

## Steps
### Step 1. Create the project
**File: `terminal (Windows PowerShell)`**
```powershell
Set-Location "$HOME\code101\flutter101"
flutter create --platforms=android shopping_list
Set-Location shopping_list
Remove-Item -Recurse -Force test
```

**File: `terminal (macOS or Linux)`**
```bash
cd ~/code101/flutter101
flutter create --platforms=android shopping_list
cd shopping_list
rm -rf test
```

### Step 2. Replace `pubspec.yaml`, then run `flutter pub get`
**File: `pubspec.yaml`**
```yaml
name: shopping_list
description: A shopping list app for Code101.
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

### Step 3. Create the item model
Create a new file `lib/shopping_item.dart`. A **model** is a class that describes one thing of your app's world. This one is **immutable**: its fields are `final`, so an item never changes after creation. To "change" it we make a modified copy with `copyWith`.

**File: `lib/shopping_item.dart`**
```dart
class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.bought = false,
  });

  final int id;
  final String name;
  final int quantity;
  final bool bought;

  ShoppingItem copyWith({String? name, int? quantity, bool? bought}) {
    return ShoppingItem(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      bought: bought ?? this.bought,
    );
  }
}
```

### Step 4. Write the screen
Replace `lib/main.dart`.

**File: `lib/main.dart`**
```dart
import 'package:material_ui/material_ui.dart';

import 'shopping_item.dart';

void main() {
  runApp(const ShoppingApp());
}

class ShoppingApp extends StatelessWidget {
  const ShoppingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shopping list',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      ),
      home: const ShoppingListScreen(),
    );
  }
}

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final List<ShoppingItem> _items = [];
  int _nextId = 1;

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a name';
    }
    return null;
  }

  String? _validateQuantity(String? value) {
    final number = int.tryParse(value?.trim() ?? '');
    if (number == null || number < 1 || number > 99) {
      return 'Use 1 to 99';
    }
    return null;
  }

  void _addItem() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _items.add(
        ShoppingItem(
          id: _nextId++,
          name: _nameController.text.trim(),
          quantity: int.parse(_quantityController.text.trim()),
        ),
      );
    });
    _nameController.clear();
    _quantityController.text = '1';
  }

  void _setBought(int index, bool bought) {
    setState(() {
      _items[index] = _items[index].copyWith(bought: bought);
    });
  }

  void _removeAt(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _items.where((item) => !item.bought).length;
    return Scaffold(
      appBar: AppBar(title: Text('Shopping list ($remaining left)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Item',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: _validateName,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 90,
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Qty',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: _validateQuantity,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _addItem,
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('Nothing to buy yet.'))
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Theme.of(context).colorScheme.errorContainer,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Text('Delete'),
                        ),
                        onDismissed: (_) => _removeAt(index),
                        child: CheckboxListTile(
                          value: item.bought,
                          title: Text(
                            item.name,
                            style: TextStyle(
                              decoration: item.bought
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          subtitle: Text('Quantity: ${item.quantity}'),
                          onChanged: (value) =>
                              _setBought(index, value ?? false),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
```

## Run it
**File: `terminal (folder shopping_list)`**
```text
flutter run
```
Expected behaviour (described from the code, not yet seen): the title says "Shopping list (0 left)" and the body says "Nothing to buy yet." Typing `Milk` with quantity `2` and tapping **Add** adds a row "Milk / Quantity: 2" and the title changes to "(1 left)". Ticking the box strikes the name through and the title returns to "(0 left)". Swiping a row to the left deletes it. Tapping **Add** with an empty name shows the red message "Enter a name" under the field; the quantity `0` or `abc` shows "Use 1 to 99".

## How it works
**ListView.builder.** It builds rows only for the part of the list on screen. `itemCount` tells how many items exist; `itemBuilder` is a function that Flutter calls with an `index` to build row number `index`. A list with thousands of rows stays fast. A `Column` would build all rows at once and cannot scroll.

**Controllers.** A `TextEditingController` is an object connected to a text field: `.text` reads or sets what is typed and `.clear()` empties it. Controllers must be released: `dispose()` runs when the screen is removed, and we call `dispose` on each controller there.

**Forms and validators.** A `Form` groups fields. Each `TextFormField` has a `validator`: a function that receives the text and returns an error message or `null` for "fine". `_formKey.currentState!.validate()` runs all validators, shows the messages and returns `false` if any failed. The `!` says "I know this is not null": it is safe because the key is attached to the `Form` below it. `int.tryParse` returns `null` instead of crashing when the text is not a number, which is why we use it instead of `int.parse` for user input. `keyboardType: TextInputType.number` shows a number keyboard.

**Immutable items.** `_items[index] = _items[index].copyWith(bought: bought)` replaces the old item with a changed copy. Each item has an `id` so Flutter can tell items apart even when their text is equal; the `Dismissible` uses `ValueKey(item.id)` as its identity.

**Dismissible.** Wraps a row so it can be swiped away. `direction: endToStart` allows right-to-left only, `background` is what is revealed behind the row, and `onDismissed` runs when the swipe completes.

**`_nextId++`.** Uses the current number and then adds one. The first item gets id 1, the next id 2.

**Computed values.** `remaining` is not stored; it is calculated in `build` from the list with `where`. Store the minimum and calculate the rest so values can never disagree.

Common misconception: "I can change the list and the screen follows." Only `setState` triggers a rebuild, so every change to `_items` is inside a `setState`.

## Try it
Make a project `try06` as in Step 1 (use this lesson's `pubspec.yaml` with `name: try06`), delete nothing else, and replace `lib/main.dart` with the starter:

**File: `exercise/starter/lib/main.dart`**
```dart
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick notes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
      ),
      home: const NotesScreen(),
    );
  }
}

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final List<String> _notes = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    // TODO 1: return 'Write something' when the value is null or empty after trim(),
    //         and 'Keep it under 40 characters' when it is longer than 40; otherwise null
    return null;
  }

  void _addNote() {
    // TODO 2: stop when the form is not valid, then add the trimmed text to _notes
    //         inside setState and clear the controller
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quick notes (${_notes.length})')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                ),
                validator: _validate,
                onFieldSubmitted: (_) => _addNote(),
              ),
            ),
          ),
          FilledButton(onPressed: _addNote, child: const Text('Add note')),
          Expanded(
            // TODO 3: show a ListView.builder of ListTile widgets with the note text,
            //         or the text 'No notes yet.' when the list is empty
            child: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
```

1. **Guided:** complete the three TODOs. Empty input shows "Write something"; a note longer than 40 characters shows the other message; valid notes appear in the list and the title counter grows.
2. **Change:** make a long press on a note remove it (`onLongPress` on `ListTile`).
3. **Stretch (optional):** reject a note that is already in the list (ignoring upper or lower case). Which function do you put it in?

<details><summary>Solution</summary>

**File: `exercise/solution/lib/main.dart`**
```dart
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quick notes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
      ),
      home: const NotesScreen(),
    );
  }
}

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final List<String> _notes = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Write something';
    }
    if (text.length > 40) {
      return 'Keep it under 40 characters';
    }
    return null;
  }

  void _addNote() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _notes.add(_controller.text.trim());
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quick notes (${_notes.length})')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                ),
                validator: _validate,
                onFieldSubmitted: (_) => _addNote(),
              ),
            ),
          ),
          FilledButton(onPressed: _addNote, child: const Text('Add note')),
          Expanded(
            child: _notes.isEmpty
                ? const Center(child: Text('No notes yet.'))
                : ListView.builder(
                    itemCount: _notes.length,
                    itemBuilder: (context, index) {
                      return ListTile(title: Text(_notes[index]));
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
```

`validate()` returns false when a validator returned text, so the note is not added.

</details>

## Check yourself
1. Why use `ListView.builder` for long lists? <details><summary>Answer</summary>It builds only the visible rows, so scrolling stays fast.</details>
2. What does a validator return when the input is fine? <details><summary>Answer</summary>`null`.</details>
3. What happens if you forget `dispose` for a controller? <details><summary>Answer</summary>The controller stays in memory after the screen is gone (a leak).</details>
4. Why is `ShoppingItem` immutable? <details><summary>Answer</summary>Changing a copy with `copyWith` makes changes explicit and keeps Flutter's rebuilds predictable.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Null check operator used on a null value` (typical message) | `_formKey.currentState!` while the key is not attached to a `Form` | Pass `key: _formKey` to the `Form` that contains the fields |
| `FormatException: Invalid radix-10 number` (typical message) | `int.parse` on text such as `abc` | Use `int.tryParse` or validate first |
| `Vertical viewport was given unbounded height.` (typical message) | A `ListView` inside a `Column` without `Expanded` | Wrap the `ListView` in `Expanded` |
| `A dismissed Dismissible widget is still part of the tree.` (typical message) | The item stays in the list after `onDismissed` | Remove it from the list inside `setState` |
| The keyboard hides the field | Small screen | Scroll the form or use `resizeToAvoidBottomInset` (default true) and enough space |

## Best practice
Validate input where it enters the app, give a message that says how to fix it, and dispose controllers. Source: [Flutter: Build a form with validation](https://docs.flutter.dev/cookbook/forms/validation)

## Going further
- [Work with long lists](https://docs.flutter.dev/cookbook/lists/long-lists) and [Swipe to dismiss](https://docs.flutter.dev/cookbook/gestures/dismissible).

## Summary
- You built a scrolling list with `ListView.builder`.
- You read input with controllers and checked it with validators.
- You updated immutable items with `copyWith` and removed items by swiping.

## Next lesson
07. Navigation: tapping an item opens a second screen and brings the result back.
