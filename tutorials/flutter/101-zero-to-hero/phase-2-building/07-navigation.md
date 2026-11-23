---
track: flutter
level: 101
phase: 2
phase_name: building
lesson: "07"
title: "Navigation"
time: "60-75 min"
prerequisites: ["flutter-101-06"]
versions: { flutter: "3.50.1", dart: "3.14.0", material_ui: "1.11.1" }
verified: not yet run
source: source/flutter/101-zero-to-hero/phase-2-building/07-navigation/
assets: []
---

# 07. Navigation

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Open a second screen with `Navigator.push` and go back with `Navigator.pop`.
- Pass data to a new screen through its constructor.
- Return a result from a screen and use it in the previous one.
- Explain what the "back stack" is.

## Recap
1. How do you make a list row that can be swiped away? <details><summary>Answer</summary>Wrap it in a `Dismissible` with a key and an `onDismissed` that removes the item.</details>
2. Why is `ShoppingItem` immutable? <details><summary>Answer</summary>Changes are made by creating a modified copy with `copyWith`.</details>

## Why it matters
A phone app is like a pile of cards on a table: opening a screen puts a new card on top, pressing Back lifts it off to show the card below. Apps with only one screen are rare; moving between screens, and carrying data there and back, is basic.

## What you will build
The shopping list from lesson 06, extended: tapping an item opens a detail screen where you change the quantity and add a note; **Save** returns the changed item to the list and **Cancel** changes nothing.

## Before you start
- Lesson 06 finished. Continue in the same `shopping_list` project.
- Time: 60-75 minutes. Four ideas: the `Navigator` stack, constructor data, returning a result, `async` after a screen closes.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/flutter/101-zero-to-hero/phase-2-building/07-navigation/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- `pubspec.yaml` is unchanged from lesson 06 and not repeated.

## Steps
### Step 1. Change the model: add a note
Replace `lib/shopping_item.dart`. The only difference from lesson 06: a new `note` field and `copyWith` parameter.

**File: `lib/shopping_item.dart`**
```dart
class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.note = '',
    this.bought = false,
  });

  final int id;
  final String name;
  final int quantity;
  final String note;
  final bool bought;

  ShoppingItem copyWith({
    String? name,
    int? quantity,
    String? note,
    bool? bought,
  }) {
    return ShoppingItem(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
      bought: bought ?? this.bought,
    );
  }
}
```

### Step 2. Create the detail screen
Create `lib/item_detail_screen.dart`.

**File: `lib/item_detail_screen.dart`**
```dart
import 'package:material_ui/material_ui.dart';

import 'shopping_item.dart';

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({super.key, required this.item});

  final ShoppingItem item;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late int _quantity;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _quantity = widget.item.quantity;
    _noteController = TextEditingController(text: widget.item.note);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _changeQuantity(int delta) {
    setState(() {
      _quantity += delta;
    });
  }

  void _save() {
    Navigator.of(context).pop(
      widget.item.copyWith(
        quantity: _quantity,
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.item.name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quantity', style: Theme.of(context).textTheme.titleMedium),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _quantity > 1 ? () => _changeQuantity(-1) : null,
                  child: const Text('-'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '$_quantity',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                OutlinedButton(
                  onPressed: _quantity < 99 ? () => _changeQuantity(1) : null,
                  child: const Text('+'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note',
                border: OutlineInputBorder(),
              ),
              maxLength: 80,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton(onPressed: _save, child: const Text('Save')),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### Step 3. Open it from the list
Replace `lib/main.dart`. Compared with lesson 06: a new import, the methods `_openDetail` and `_subtitle`, and a `ListTile` (with a `Checkbox` on its left and an `onTap`) instead of the `CheckboxListTile`.

**File: `lib/main.dart`**
```dart
import 'package:material_ui/material_ui.dart';

import 'item_detail_screen.dart';
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

  Future<void> _openDetail(int index) async {
    final updated = await Navigator.of(context).push<ShoppingItem>(
      MaterialPageRoute(
        builder: (context) => ItemDetailScreen(item: _items[index]),
      ),
    );
    if (updated == null || !mounted) {
      return;
    }
    setState(() {
      _items[index] = updated;
    });
  }

  String _subtitle(ShoppingItem item) {
    if (item.note.isEmpty) {
      return 'Quantity: ${item.quantity}';
    }
    return 'Quantity: ${item.quantity} - ${item.note}';
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
                        child: ListTile(
                          leading: Checkbox(
                            value: item.bought,
                            onChanged: (value) =>
                                _setBought(index, value ?? false),
                          ),
                          title: Text(
                            item.name,
                            style: TextStyle(
                              decoration: item.bought
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          subtitle: Text(_subtitle(item)),
                          onTap: () => _openDetail(index),
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
Expected behaviour (described from the code, not yet seen): add "Tea" with quantity 2. Tap the row (not the checkbox). A new screen titled "Tea" slides in, showing Quantity with `-`, `2` and `+` buttons and a Note field. Tap `+` twice and type "green". **Save** closes the screen and the row now reads "Quantity: 4 - green". Tapping a row, changing the number and pressing **Cancel** (or the Back arrow) leaves the row unchanged.

## How it works
**The back stack.** `Navigator` keeps a stack of screens ("routes"). `push` puts a new route on top; `pop` removes the top one and shows the one below. The Android Back button and the back arrow in the `AppBar` call `pop` for you.

**`MaterialPageRoute`** is the standard route with the platform's transition. Its `builder` is a function that builds the new screen's widget. `Navigator.of(context)` finds the navigator above the current widget.

**Data in: the constructor.** `ItemDetailScreen(item: _items[index])` hands the item over like any widget parameter. The detail screen reads it as `widget.item`. Inside a State class, `widget` is the owning widget.

**Data out: the result of `pop`.** `Navigator.of(context).pop(updatedItem)` closes the screen and delivers the value to the code that called `push`. `push<ShoppingItem>` declares the result type. `await` waits until the screen closes. If the user taps Back or Cancel the result is `null`, so we check `updated == null` first.

**Why `mounted`?** After an `await`, the original screen may have been removed. `mounted` is true only while the State is still in the tree; calling `setState` when it is false would be a bug, so we return early.

**`initState`, `late`.** `initState` runs once when the State is created; it is the place to copy the starting values from `widget.item`. `late` tells Dart "this variable is set before it is used, just not at its declaration".

**A local copy.** The detail screen edits `_quantity` and the note text, not the item itself. Only **Save** builds a changed copy with `copyWith` and returns it. That is what makes Cancel safe.

Common misconception: "I should change the list inside the second screen." The second screen only hands back a value; the first screen owns the list and decides what to do with it.

## Try it
Make a project `try07` as before (lesson 06 `pubspec.yaml` with `name: try07`) and use this starter for `lib/main.dart`:

**File: `exercise/starter/lib/main.dart`**
```dart
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const MoodApp());
}

class MoodApp extends StatelessWidget {
  const MoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood picker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _mood = 'not chosen';

  Future<void> _pickMood() async {
    // TODO 1: push a MaterialPageRoute that builds PickScreen and await the String? result
    // TODO 2: when the result is not null and the screen is still mounted,
    //         store it in _mood inside setState
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mood picker')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Your mood: $_mood'),
            const SizedBox(height: 16),
            FilledButton(onPressed: _pickMood, child: const Text('Pick a mood')),
          ],
        ),
      ),
    );
  }
}

class PickScreen extends StatelessWidget {
  const PickScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const moods = ['happy', 'calm', 'tired'];
    return Scaffold(
      appBar: AppBar(title: const Text('How do you feel?')),
      body: ListView(
        children: [
          for (final mood in moods)
            ListTile(
              title: Text(mood),
              // TODO 3: close this screen and hand the mood back to the previous screen
              onTap: () {},
            ),
        ],
      ),
    );
  }
}
```

1. **Guided:** complete the three TODOs so that choosing a mood on the second screen shows it on the first.
2. **Change:** add a fourth mood and a title on the first screen that says "Your mood: ..." in the AppBar.
3. **Stretch (optional):** add a **Clear** button on the first screen that sets the mood back to "not chosen". Does it need navigation at all?

<details><summary>Solution</summary>

**File: `exercise/solution/lib/main.dart`**
```dart
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const MoodApp());
}

class MoodApp extends StatelessWidget {
  const MoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood picker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _mood = 'not chosen';

  Future<void> _pickMood() async {
    final mood = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const PickScreen()),
    );
    if (mood == null || !mounted) {
      return;
    }
    setState(() {
      _mood = mood;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mood picker')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Your mood: $_mood'),
            const SizedBox(height: 16),
            FilledButton(onPressed: _pickMood, child: const Text('Pick a mood')),
          ],
        ),
      ),
    );
  }
}

class PickScreen extends StatelessWidget {
  const PickScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const moods = ['happy', 'calm', 'tired'];
    return Scaffold(
      appBar: AppBar(title: const Text('How do you feel?')),
      body: ListView(
        children: [
          for (final mood in moods)
            ListTile(
              title: Text(mood),
              onTap: () => Navigator.of(context).pop(mood),
            ),
        ],
      ),
    );
  }
}
```

`ListTile.onTap` calls `pop(mood)`, which completes the `await` in `_pickMood` with that text.

</details>

## Check yourself
1. What does `Navigator.pop(context, value)` do with `value`? <details><summary>Answer</summary>It becomes the result of the `await Navigator.push(...)` in the previous screen.</details>
2. What is the result when the user presses the Android Back button? <details><summary>Answer</summary>`null`.</details>
3. Why check `mounted` after `await`? <details><summary>Answer</summary>The screen may be gone; `setState` on a removed State is a bug.</details>
4. Why does Cancel not change the item? <details><summary>Answer</summary>The detail screen edits local copies and only returns a new item on Save.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Navigator operation requested with a context that does not include a Navigator.` (typical message) | `Navigator.of(context)` used with a context above `MaterialApp` | Call it from a widget below `MaterialApp`, as in `ShoppingListScreen` |
| Row does not update after Save | The result was ignored or `setState` is missing | `await` the push and assign the result inside `setState` |
| `The following _CastError ... type 'Null' is not a subtype` (typical wording) | Using the pop result without a `null` check | Check `updated == null` first |
| `LateInitializationError: Field '_noteController' has not been initialized.` (typical message) | `late` variable used before `initState` set it | Assign it in `initState` |
| Back arrow missing on the second screen | Screen was shown without `Scaffold`/`AppBar`, or replaced instead of pushed | Use `push`, and an `AppBar` |

## Best practice
Pass only the data a screen needs and return a result instead of letting the second screen modify the first screen's state. Source: [Flutter: Navigation and routing](https://docs.flutter.dev/ui/navigation)

## Going further
- [Return data from a screen](https://docs.flutter.dev/cookbook/navigation/returning-data). Level 201 lesson 03 replaces `Navigator.push` by `go_router` for web-style routes, deep links and sign-in redirects.

## Summary
- You pushed and popped screens and explained the back stack.
- You passed an item to a new screen and returned a changed copy.
- You guarded the code after `await` with `mounted`.

## Next lesson
08. Theming and assets: give the app a consistent look, dark mode and SVG icons from the course art library.
