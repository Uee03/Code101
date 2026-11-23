---
track: flutter
level: 101
phase: 2
phase_name: building
lesson: "08"
title: "Theming and assets"
time: "60-80 min"
prerequisites: ["flutter-101-07"]
versions: { flutter: "3.50.1", dart: "3.14.0", material_ui: "1.11.1", flutter_svg: "2.5.0" }
verified: not yet run
source: source/flutter/101-zero-to-hero/phase-2-building/08-theming-and-assets/
assets: [ui/plus, files/trash, ui/list]
---

# 08. Theming and assets

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Define one light and one dark theme from a seed colour and use it everywhere.
- Read colours and text styles from the theme instead of typing them in each widget.
- Declare assets in `pubspec.yaml` and show an SVG icon with `flutter_svg`.
- Tint an icon so it follows the theme and give it an accessible label when it carries meaning.

## Recap
1. How does a screen return a value to the screen that opened it? <details><summary>Answer</summary>`Navigator.pop(context, value)`; the opener gets it from `await Navigator.push(...)`.</details>
2. Why do we check `mounted` after an `await`? <details><summary>Answer</summary>The State may be gone; `setState` would then be a bug.</details>

## Why it matters
Think of a company's brand sheet: it says "our colour is green, our headings are bold, our icons look like this", so every page looks like it belongs together. A Flutter **theme** is that brand sheet for your app. Change it in one place and every screen follows, including dark mode.

## What you will build
The shopping list from lesson 07 with a green theme in light and dark mode (it follows the phone's setting) and three SVG icons: a plus on the Add button, a trash can behind a swiped row, and a list picture on the empty screen.

## Before you start
- Lesson 07 finished; work in the same `shopping_list` project.
- Time: 60-80 minutes. Four ideas: `ThemeData`, colour scheme, assets, `flutter_svg`.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/flutter/101-zero-to-hero/phase-2-building/08-theming-and-assets/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Unchanged from lesson 07 and not repeated: `lib/shopping_item.dart` and `lib/item_detail_screen.dart`. The three icons come from the course art library (CC0, public domain), so you may copy them freely.

## Steps
### Step 1. Add the icon files
Create the folders `assets` and `assets/icons` inside `shopping_list` (next to `lib`). Create these three files. They are small text files in the SVG format (a picture described by lines and curves, so it stays sharp at any size). `stroke="currentColor"` means "draw the lines in whatever colour the program asks for", which is how we will tint them.

**File: `assets/icons/plus.svg`**
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" role="img" aria-label="Plus">
  <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
</svg>
```

**File: `assets/icons/trash.svg`**
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" role="img" aria-label="Trash">
  <polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
</svg>
```

**File: `assets/icons/list.svg`**
```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" role="img" aria-label="List">
  <line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/><line x1="8" y1="18" x2="21" y2="18"/><line x1="3" y1="6" x2="3.01" y2="6"/><line x1="3" y1="12" x2="3.01" y2="12"/><line x1="3" y1="18" x2="3.01" y2="18"/>
</svg>
```

### Step 2. Register the assets and add the package
An **asset** is a file bundled into the app (an image, an icon, a font). Flutter only includes assets that `pubspec.yaml` lists. Replace the file; compared with lesson 07 it adds `flutter_svg` and the `assets:` list.

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

dev_dependencies:
  flutter_lints: 6.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/icons/plus.svg
    - assets/icons/trash.svg
    - assets/icons/list.svg
```

Run `flutter pub get`. Indentation matters in YAML: use spaces, never tabs, and keep each `-` aligned.

### Step 3. Write the theme
Create `lib/app_theme.dart`.

**File: `lib/app_theme.dart`**
```dart
import 'package:material_ui/material_ui.dart';

abstract final class AppTheme {
  static const Color seed = Color(0xFF2E7D32);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final base = ThemeData(colorScheme: scheme);
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
```

### Step 4. Write a tiny icon widget
Create `lib/art_icon.dart`. It loads one of our SVG files, tints it with a colour and optionally gives it a spoken label.

**File: `lib/art_icon.dart`**
```dart
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

class ArtIcon extends StatelessWidget {
  const ArtIcon(
    this.name, {
    super.key,
    this.size = 24,
    this.color,
    this.semanticLabel,
  });

  final String name;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tint = color ??
        IconTheme.of(context).color ??
        Theme.of(context).colorScheme.onSurface;
    return SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
```

### Step 5. Use theme and icons in the screen
Replace `lib/main.dart`. Compared with lesson 07: two new imports, `MaterialApp` uses `AppTheme`, the AppBar takes theme colours, the Add button, empty state and swipe background use `ArtIcon`.

**File: `lib/main.dart`**
```dart
import 'package:material_ui/material_ui.dart';

import 'item_detail_screen.dart';
import 'shopping_item.dart';
import 'app_theme.dart';
import 'art_icon.dart';

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
    final colors = Theme.of(context).colorScheme;
    final remaining = _items.where((item) => !item.bought).length;
    return Scaffold(
      appBar: AppBar(
        title: Text('Shopping list ($remaining left)'),
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
      ),
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
Expected behaviour (described from the code, not yet seen): the app bar is a light green; the **Add** button shows a plus icon and the word Add; with no items you see a grey list picture above "Nothing to buy yet."; swiping a row left reveals a trash icon on a reddish background. Now change the phone's setting to dark theme (swipe down the quick settings, or Settings > Display > Dark theme): the app switches to a dark green palette without any code change, because `themeMode: ThemeMode.system` follows the phone.

## How it works
**`ThemeData`** bundles colours, text styles and widget defaults. `MaterialApp(theme: ..., darkTheme: ..., themeMode: ...)` provides them to every widget below. `themeMode` is `system` (follow the phone), `light` or `dark`.

**`ColorScheme.fromSeed`** builds a full, matching palette (primary, secondary, surface, error and their "on" colours) from a single seed colour, in light or dark brightness. The "on" colours (`onPrimaryContainer`) are the readable text colour for the matching background, so contrast stays good. `AppTheme` is an `abstract final class`: a class that only holds static members and cannot be created or extended.

**Reading the theme.** `Theme.of(context).colorScheme` and `.textTheme` look the current theme up in the tree. Using `colors.errorContainer` instead of `Colors.red` means the colour is right in both modes. Rule of thumb: never write a colour in a widget if the theme already has a role for it.

**`copyWith`** returns a copy of an object with a few values changed; here we make titles semi-bold. Many Flutter classes offer it, as does our `ShoppingItem`.

**Assets and `flutter_svg`.** Flutter does not draw SVG on its own. The `flutter_svg` package does: `SvgPicture.asset('assets/icons/plus.svg')` loads a bundled file. `colorFilter: ColorFilter.mode(tint, BlendMode.srcIn)` paints every drawn pixel in `tint`, replacing `currentColor`. If the path in code and the path in `pubspec.yaml` differ by one letter (case counts), the app fails to find the file.

**Accessibility of icons.** A decorative icon (the plus beside the word "Add") should be skipped by screen readers, which is `excludeFromSemantics: true` when no label is given. An icon that carries meaning alone needs `semanticLabel`. Lesson 11 returns to this.

**`FilledButton.icon`** puts an icon before the label. The button gives the icon a colour through `IconTheme`, which `ArtIcon` reads when we do not pass a colour.

Common misconception: "Dark mode means a second app design." It is the same widgets with a second colour scheme.

## Try it
Make a new project `try08` like in lesson 05 (use the lesson `pubspec.yaml` without the flutter_svg parts, or simply that of lesson 05 with `name: try08`) and replace `lib/main.dart` with the starter:

**File: `exercise/starter/lib/main.dart`**
```dart
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const ThemeSwitcherApp());
}

class ThemeSwitcherApp extends StatefulWidget {
  const ThemeSwitcherApp({super.key});

  @override
  State<ThemeSwitcherApp> createState() => _ThemeSwitcherAppState();
}

class _ThemeSwitcherAppState extends State<ThemeSwitcherApp> {
  // TODO 1: add a bool field _dark that starts as false

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Theme switcher',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      // TODO 2: use ThemeMode.dark when _dark is true, otherwise ThemeMode.light
      themeMode: ThemeMode.system,
      home: Scaffold(
        appBar: AppBar(title: const Text('Theme switcher')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Switch the theme below.'),
              // TODO 3: add a SwitchListTile titled 'Dark mode' whose value is _dark
              //         and whose onChanged stores the new value inside setState
            ],
          ),
        ),
      ),
    );
  }
}
```

1. **Guided:** complete the three TODOs so the switch toggles dark mode.
2. **Change:** change the seed colour in both themes to another colour and watch the whole screen follow.
3. **Stretch (optional):** add a third choice "Follow the phone" using a `SegmentedButton<ThemeMode>` with all three modes.

<details><summary>Solution</summary>

**File: `exercise/solution/lib/main.dart`**
```dart
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const ThemeSwitcherApp());
}

class ThemeSwitcherApp extends StatefulWidget {
  const ThemeSwitcherApp({super.key});

  @override
  State<ThemeSwitcherApp> createState() => _ThemeSwitcherAppState();
}

class _ThemeSwitcherAppState extends State<ThemeSwitcherApp> {
  bool _dark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Theme switcher',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        appBar: AppBar(title: const Text('Theme switcher')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Switch the theme below.'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: SwitchListTile(
                  title: const Text('Dark mode'),
                  value: _dark,
                  onChanged: (value) {
                    setState(() {
                      _dark = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

The State class belongs to `ThemeSwitcherApp`, which wraps `MaterialApp`, so `setState` rebuilds the whole app with the new `themeMode`.

</details>

## Check yourself
1. What does `ColorScheme.fromSeed` give you? <details><summary>Answer</summary>A complete matching palette generated from one colour, for light or dark.</details>
2. Why use `colors.errorContainer` rather than `Colors.red`? <details><summary>Answer</summary>It adapts to light and dark mode and keeps readable contrast with its "on" colour.</details>
3. The icon does not appear and the console says it could not find the asset. What do you check? <details><summary>Answer</summary>That the file exists, the path matches exactly, and `pubspec.yaml` lists it with correct indentation (then `flutter pub get` or a hot restart).</details>
4. When does an icon need a `semanticLabel`? <details><summary>Answer</summary>When it carries meaning on its own with no visible text next to it.</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `Unable to load asset: "assets/icons/plus.svg".` (typical message) | Not listed in `pubspec.yaml`, wrong path, or missing hot restart | Fix the path or list, run `flutter pub get`, stop and run again |
| `Error on line 15: ... mapping values are not allowed here` (typical wording) | Bad YAML indentation or a tab in `pubspec.yaml` | Use two spaces per level and no tabs |
| Icons are black in dark mode | `color` was not applied or a fixed colour was passed | Let `ArtIcon` pick the theme colour or pass `colors.onSurface` |
| `The method 'copyWith' isn't defined for the type 'TextStyle?'` (typical message) | Using `copyWith` on a nullable value without `?.` | Write `titleLarge?.copyWith(...)` as in the lesson |
| Theme change not visible after hot reload | `main()`-level values did not rebuild | Press `R` for a hot restart |

## Best practice
Define colours and text styles once in the theme and read them with `Theme.of(context)`. Source: [Flutter: Use themes to share colors and font styles](https://docs.flutter.dev/cookbook/design/themes)

## Going further
- [Adding assets and images](https://docs.flutter.dev/ui/assets/assets-and-images) and the [flutter_svg package](https://pub.dev/packages/flutter_svg).
- The course art library `assets/art` holds more CC0 icons; level 201 uses ten of them in the capstone.

## Summary
- You built a light and a dark theme from one seed colour and read theme roles in widgets.
- You declared assets in `pubspec.yaml` and drew tinted SVG icons with `flutter_svg`.
- You decided when an icon needs a spoken label.

## Next lesson
09. HTTP and JSON: loading real data from the internet.
