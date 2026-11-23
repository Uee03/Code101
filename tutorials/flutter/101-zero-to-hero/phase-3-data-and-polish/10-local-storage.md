---
track: flutter
level: 101
phase: 3
phase_name: data-and-polish
lesson: "10"
title: "Local storage with shared_preferences"
time: "60-80 min"
prerequisites: ["flutter-101-08", "flutter-101-09"]
versions: { flutter: "3.50.1", dart: "3.14.0", material_ui: "1.11.1", shared_preferences: "2.5.6" }
verified: not yet run
source: source/flutter/101-zero-to-hero/phase-3-data-and-polish/10-local-storage/
assets: [ui/plus, files/trash, ui/list]
---

# 10. Local storage with shared_preferences

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Explain why variables in memory vanish when an app closes.
- Save and load small values with `shared_preferences`.
- Store a whole list by turning it into JSON text.
- Load data in `initState` and show a loading state until it arrives.

## Recap
1. What does `jsonDecode` return for the text `[1, 2]`? <details><summary>Answer</summary>A Dart list containing 1 and 2.</details>
2. Which method of a model class builds an object from a map? <details><summary>Answer</summary>The factory constructor `fromJson`.</details>

## Why it matters
A whiteboard is erased at night; a notebook is not. Variables are the whiteboard: they disappear when the app is closed. To keep the shopping list until tomorrow it must be written to the phone's storage, the notebook. For small things (settings, a short list) `shared_preferences` is the simplest notebook.

## What you will build
The shopping list from lesson 08 that remembers its items: close the app completely, open it again, and everything is still there.

## Before you start
- Lessons 08 and 09 finished; continue in the `shopping_list` project.
- Time: 60-80 minutes. Four ideas: persistence, key/value storage, JSON round trip, loading on start.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/flutter/101-zero-to-hero/phase-3-data-and-polish/10-local-storage/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Unchanged from lesson 08 and not repeated: `lib/app_theme.dart`, `lib/art_icon.dart`, `lib/item_detail_screen.dart` and the files in `assets/`.
- Honest limit: the package documentation says writes may reach the disk later and that it must not hold critical data. It is right for preferences and small lists, wrong for passwords (level 201 uses secure storage) or large data (level 201 uses a database).

## Steps
### Step 1. Add the package
Replace `pubspec.yaml`. Compared with lesson 08 it adds `shared_preferences`. Then run `flutter pub get`.

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
  flutter_svg: 2.5.0
  shared_preferences: 2.5.6

dev_dependencies:
  flutter_lints: 6.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/icons/plus.svg
    - assets/icons/trash.svg
    - assets/icons/list.svg
```

### Step 2. Teach the model to turn into JSON and back
Replace `lib/shopping_item.dart`. New compared with lesson 07: `fromJson` and `toJson`. `toJson` returns a map the JSON encoder understands; `fromJson` tolerates missing optional fields with `?? default`.

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

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as int,
      name: json['name'] as String,
      quantity: json['quantity'] as int? ?? 1,
      note: json['note'] as String? ?? '',
      bought: json['bought'] as bool? ?? false,
    );
  }

  final int id;
  final String name;
  final int quantity;
  final String note;
  final bool bought;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'note': note,
      'bought': bought,
    };
  }

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

### Step 3. Create the store
A **store** class hides how data is saved, so the screen only says `load` and `save`. Create `lib/item_store.dart`.

**File: `lib/item_store.dart`**
```dart
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'shopping_item.dart';

class ItemStore {
  ItemStore({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'shopping_items';

  final SharedPreferencesAsync _preferences;

  Future<List<ShoppingItem>> load() async {
    final raw = await _preferences.getString(_key);
    if (raw == null) {
      return [];
    }
    try {
      final data = jsonDecode(raw) as List<dynamic>;
      return [
        for (final entry in data)
          ShoppingItem.fromJson(entry as Map<String, dynamic>),
      ];
    } on FormatException {
      return [];
    } on TypeError {
      return [];
    }
  }

  Future<void> save(List<ShoppingItem> items) async {
    final raw = jsonEncode([for (final item in items) item.toJson()]);
    await _preferences.setString(_key, raw);
  }
}
```

### Step 4. Use the store in the screen
Replace `lib/main.dart`. Compared with lesson 08: the imports `dart:async` and `item_store.dart`, the `_store`, `_loaded` and `_load()`/`_save()` code, a `_save()` call after every change, and a spinner until the data is loaded.

**File: `lib/main.dart`**
```dart
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import 'app_theme.dart';
import 'art_icon.dart';
import 'item_detail_screen.dart';
import 'item_store.dart';
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
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
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
  final _store = ItemStore();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final List<ShoppingItem> _items = [];
  int _nextId = 1;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final saved = await _store.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _items.addAll(saved);
      for (final item in saved) {
        if (item.id >= _nextId) {
          _nextId = item.id + 1;
        }
      }
      _loaded = true;
    });
  }

  void _save() {
    unawaited(_store.save(List.of(_items)));
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
    _save();
    _nameController.clear();
    _quantityController.text = '1';
  }

  void _setBought(int index, bool bought) {
    setState(() {
      _items[index] = _items[index].copyWith(bought: bought);
    });
    _save();
  }

  void _removeAt(int index) {
    setState(() {
      _items.removeAt(index);
    });
    _save();
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
    _save();
  }

  String _subtitle(ShoppingItem item) {
    if (item.note.isEmpty) {
      return 'Quantity: ${item.quantity}';
    }
    return 'Quantity: ${item.quantity} - ${item.note}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final remaining = _items.where((item) => !item.bought).length;
    return Scaffold(
      appBar: AppBar(
        title: Text('Shopping list ($remaining left)'),
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                        FilledButton.icon(
                          onPressed: _addItem,
                          icon: const ArtIcon('plus', size: 18),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: _items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ArtIcon('list', size: 48, color: colors.outline),
                              const SizedBox(height: 8),
                              const Text('Nothing to buy yet.'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return Dismissible(
                              key: ValueKey(item.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: colors.errorContainer,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 16),
                                child: ArtIcon(
                                  'trash',
                                  color: colors.onErrorContainer,
                                ),
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
Expected behaviour (described from the code, not yet seen): add "Milk" and "Bread" and tick Milk. Stop the app with `q` in the terminal, press **Run** again (or `flutter run`). Both items are back, and Milk is still ticked. If you instead press `R` (hot restart) the data also stays, because it is on the phone, not in the running program.

To start from empty again, open the app's info on the phone (long press the icon, **App info > Storage > Clear storage**) or uninstall it.

## How it works
**Persistence** is keeping data after the program stops. `SharedPreferencesAsync` wraps Android's own small key-value storage: each value is stored under a **key** (a name, here `shopping_items`). It supports `String`, `int`, `double`, `bool` and a list of strings, so we encode our list as one JSON string with `jsonEncode`, and decode it with `jsonDecode` when loading: a **round trip**.

**All calls are async.** Reading from storage takes a moment, so `getString` returns a `Future`. That is why the screen has `_loaded`: until the data arrived it shows a spinner instead of an empty list that would flash "Nothing to buy yet." and could be overwritten by mistake.

**`initState` + `_load`.** The State starts loading once when it is created. `if (!mounted) return;` guards the gap after `await`, as in lesson 07. We also compute `_nextId` from the largest saved id so new items never reuse an id.

**Saving after each change.** `_save()` runs after adding, ticking, deleting and editing. `unawaited(...)` says "I know this returns a Future and I choose not to wait"; the UI should not freeze for a disk write. `List.of(_items)` saves a copy of the list as it is right now.

**Bad data.** `load` returns an empty list when the stored text is not valid JSON or has an unexpected shape, so the app starts instead of crashing. Old data from a previous app version is the usual source of such surprises: read stored data defensively.

**Where is this data?** Only on this phone, inside the app's private storage. Other apps cannot read it, but it is not encrypted and is not backed up as a secret. Never store passwords or tokens here.

Common misconception: "Saving is automatic." Nothing is saved until your code writes it; you chose to write after every change.

## Try it
Make a project `try10` as in lesson 05 (this lesson's `pubspec.yaml`, `name: try10`, and remove the `assets:` lines) and replace `lib/main.dart` with the starter, a visit counter.

**File: `exercise/starter/lib/main.dart`**
```dart
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const VisitsApp());
}

class VisitsApp extends StatelessWidget {
  const VisitsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Visit counter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
      ),
      home: const VisitsScreen(),
    );
  }
}

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  final _preferences = SharedPreferencesAsync();
  int? _visits;

  @override
  void initState() {
    super.initState();
    _countVisit();
  }

  Future<void> _countVisit() async {
    // TODO 1: read the saved number with getInt('visits') (it can be null, use 0 then),
    //         add one, save it with setInt('visits', ...)
    // TODO 2: when the screen is still mounted, store the new number in _visits inside setState
  }

  Future<void> _reset() async {
    // TODO 3: remove the key 'visits', then (if mounted) set _visits to 0 inside setState
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visit counter')),
      body: Center(
        child: _visits == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('You opened this app $_visits times'),
                  TextButton(onPressed: _reset, child: const Text('Reset')),
                ],
              ),
      ),
    );
  }
}
```

1. **Guided:** complete the three TODOs. The first start shows "You opened this app 1 times", the next start 2, and so on. **Reset** shows 0.
2. **Change:** also store the date of the last visit as text and show it.
3. **Stretch (optional):** what should the app show if a stored value had the wrong type? Look up what `getInt` does when the key holds text.

<details><summary>Solution</summary>

**File: `exercise/solution/lib/main.dart`**
```dart
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const VisitsApp());
}

class VisitsApp extends StatelessWidget {
  const VisitsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Visit counter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
      ),
      home: const VisitsScreen(),
    );
  }
}

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  final _preferences = SharedPreferencesAsync();
  int? _visits;

  @override
  void initState() {
    super.initState();
    _countVisit();
  }

  Future<void> _countVisit() async {
    final previous = await _preferences.getInt('visits') ?? 0;
    final next = previous + 1;
    await _preferences.setInt('visits', next);
    if (!mounted) {
      return;
    }
    setState(() {
      _visits = next;
    });
  }

  Future<void> _reset() async {
    await _preferences.remove('visits');
    if (!mounted) {
      return;
    }
    setState(() {
      _visits = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visit counter')),
      body: Center(
        child: _visits == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('You opened this app $_visits times'),
                  TextButton(onPressed: _reset, child: const Text('Reset')),
                ],
              ),
      ),
    );
  }
}
```

`await ... ?? 0` reads the saved value and uses 0 when nothing was saved yet.

</details>

## Check yourself
1. Why can't you keep the list only in a variable? <details><summary>Answer</summary>Variables live in memory and are lost when the app process ends.</details>
2. How do you store a list of objects with `shared_preferences`? <details><summary>Answer</summary>Convert it to a JSON string with `jsonEncode` and store the string under a key.</details>
3. Why show a spinner while loading? <details><summary>Answer</summary>The data arrives asynchronously; the spinner prevents showing a wrong empty state.</details>
4. Should an access token go into `shared_preferences`? <details><summary>Answer</summary>No. It is not encrypted; use secure storage (level 201).</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `MissingPluginException(No implementation found for method ...)` (typical message) | The plugin was added while the app was running | Stop the app and run again (a full restart, not hot reload) |
| List is empty after restart | `_save()` is missing after a change | Call `_save()` after every change |
| `type 'List<dynamic>' is not a subtype ...` (typical wording) | Casting JSON to the wrong type | Cast with `as List<dynamic>` and each entry `as Map<String, dynamic>` as in the store |
| New items overwrite old ones | `_nextId` starts at 1 after load | Compute it from the loaded ids as in `_load` |
| Spinner never stops | `_load` threw before `_loaded = true` | Read the error in the terminal; keep `load()` safe with `try`/`on` |

## Best practice
Hide storage behind a small class and read stored data defensively. Source: [Flutter: Store key-value data on disk](https://docs.flutter.dev/cookbook/persistence/key-value) and [shared_preferences on pub.dev](https://pub.dev/packages/shared_preferences)

## Going further
- Level 201 lesson 07 stores structured data in a local SQL database with `drift`, and lesson 06 stores tokens in secure storage.

## Summary
- You explained why memory is temporary and saved a list as JSON with `shared_preferences`.
- You loaded data in `initState` with a loading state and guarded the async gap with `mounted`.
- You read stored data defensively.

## Next lesson
11. Accessibility and adaptive layout: making the app usable by everyone and on any screen size.
