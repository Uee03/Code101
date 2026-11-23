---
track: flutter
level: 101
phase: 3
phase_name: data-and-polish
lesson: "11"
title: "Accessibility and adaptive layout"
time: "60-80 min"
prerequisites: ["flutter-101-10"]
versions: { flutter: "3.50.1", dart: "3.14.0", material_ui: "1.11.1" }
verified: not yet run
source: source/flutter/101-zero-to-hero/phase-3-data-and-polish/11-accessibility-and-adaptive-layout/
assets: [ui/plus, files/trash, ui/list]
---

# 11. Accessibility and adaptive layout

> **Draft: written but not yet run.** The code and the expected output in this lesson were prepared by reading the code and the official documentation. They have not been executed yet. If something does not behave as described, trust your tool's real output and report it.

## What you will be able to do
- Give controls spoken labels and tooltips so a screen reader can describe them.
- Make touch targets large enough and not rely on colour alone.
- Make a layout survive large text.
- Switch between a one-column and a two-column layout with `LayoutBuilder`.

## Recap
1. When does an icon need a `semanticLabel`? <details><summary>Answer</summary>When it carries meaning without visible text beside it.</details>
2. Why does the app show a spinner at start? <details><summary>Answer</summary>The saved list loads asynchronously; the spinner avoids showing a false empty state.</details>

## Why it matters
Your app will be used by people who cannot see the screen well or at all (they use **TalkBack**, Android's screen reader that speaks what is under the finger), people with shaky hands who need big buttons, people who set the system font to very large, and people holding a tablet or a phone sideways. A building with a ramp and a wide door helps everyone; so does an accessible app. Building it in from the start costs a few lines; adding it later costs a rewrite.

## What you will build
The persistent shopping list from lesson 10 improved in four ways: spoken labels, a delete button that does not depend on a swipe, a status that is also written as text, and a layout that stacks fields under large text and shows form and list side by side on wide screens.

## Before you start
- Lesson 10 finished; continue in `shopping_list`.
- Time: 60-80 minutes. Five ideas: semantics, tooltips, target size, text scale, `LayoutBuilder`.
- Source pack (optional): every file is shown in full in this lesson, so you can follow without it. The finished code, the exercise starter and the solution are in the
  course repository https://github.com/Uee03/Code101 under `source/flutter/101-zero-to-hero/phase-3-data-and-polish/11-accessibility-and-adaptive-layout/` (on that page choose **Code, Download ZIP**, or run
  `git clone https://github.com/Uee03/Code101.git`).
- Unchanged from lesson 10 and not repeated: `pubspec.yaml`, `lib/app_theme.dart`, `lib/art_icon.dart`, `lib/item_detail_screen.dart`, `lib/item_store.dart`, `lib/shopping_item.dart` and the files in `assets/`.

## Steps
### Step 1. Replace `lib/main.dart`
Compared with lesson 10: the form and the list moved into helper methods `_buildForm` and `_buildList`; `build` uses `LayoutBuilder`; list rows got `semanticLabel`, a delete `IconButton` with a tooltip, and a "Bought." status in the text.

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
    final status = item.bought ? 'Bought. ' : '';
    if (item.note.isEmpty) {
      return '${status}Quantity: ${item.quantity}';
    }
    return '${status}Quantity: ${item.quantity} - ${item.note}';
  }

  Widget _buildForm({required bool stacked}) {
    final nameField = TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Item',
        border: OutlineInputBorder(),
      ),
      textInputAction: TextInputAction.next,
      validator: _validateName,
    );
    final quantityField = TextFormField(
      controller: _quantityController,
      decoration: const InputDecoration(
        labelText: 'Qty',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: _validateQuantity,
    );
    final addButton = FilledButton.icon(
      onPressed: _addItem,
      icon: const ArtIcon('plus', size: 18),
      label: const Text('Add'),
    );
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  nameField,
                  const SizedBox(height: 12),
                  quantityField,
                  const SizedBox(height: 12),
                  addButton,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: nameField),
                  const SizedBox(width: 8),
                  SizedBox(width: 90, child: quantityField),
                  const SizedBox(width: 8),
                  addButton,
                ],
              ),
      ),
    );
  }

  Widget _buildList(ColorScheme colors) {
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ArtIcon('list', size: 48, color: colors.outline),
            const SizedBox(height: 8),
            const Text('Nothing to buy yet.'),
          ],
        ),
      );
    }
    return ListView.builder(
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
            child: ArtIcon('trash', color: colors.onErrorContainer),
          ),
          onDismissed: (_) => _removeAt(index),
          child: ListTile(
            leading: Checkbox(
              value: item.bought,
              semanticLabel: 'Bought ${item.name}',
              onChanged: (value) => _setBought(index, value ?? false),
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
            trailing: IconButton(
              tooltip: 'Delete ${item.name}',
              onPressed: () => _removeAt(index),
              icon: ArtIcon('trash', color: colors.onSurfaceVariant),
            ),
            onTap: () => _openDetail(index),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final remaining = _items.where((item) => !item.bought).length;
    final largeText = MediaQuery.textScalerOf(context).scale(14) >= 21;
    return Scaffold(
      appBar: AppBar(
        title: Text('Shopping list ($remaining left)'),
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
      ),
      body: SafeArea(
        child: !_loaded
            ? const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Loading your list',
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 720;
                  final list = _buildList(colors);
                  if (wide) {
                    return Row(
                      children: [
                        SizedBox(
                          width: 360,
                          child: SingleChildScrollView(
                            child: _buildForm(stacked: true),
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: list),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _buildForm(stacked: largeText),
                      Expanded(child: list),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
```

### Step 2. Turn on the tools and test
Run the app (`flutter run`) and test on the phone or emulator:

1. **Large text:** Settings > Display > Font size (or Accessibility > Font size), choose the largest. Return to the app. Nothing should be cut off, and the form should stack its fields.
2. **Screen reader:** Settings > Accessibility > TalkBack, switch it on. Touch the list rows and buttons: TalkBack should speak "Bought Milk, checkbox" and "Delete Milk, button". Switch TalkBack off again afterwards (the settings screen shows how; touching twice quickly activates).
3. **Rotation:** turn the emulator sideways (rotate button in the emulator toolbar). A wide enough screen shows the form on the left and the list on the right.

## Run it
**File: `terminal (folder shopping_list)`**
```text
flutter run
```
Expected behaviour (described from the code, not yet seen): on a normal phone in portrait the screen looks like lesson 10, with a small trash button at the end of each row. A bought item reads "Bought. Quantity: 2" and is struck through. At the largest font size the three input widgets are stacked in a column. In landscape on a screen at least 720 logical pixels wide the form sits in a 360-wide left panel, a thin vertical line and the list takes the rest.

## How it works
**Semantics.** Flutter builds a second tree beside the widgets: the **semantics tree**, which accessibility services read. Most Material widgets fill it automatically (a button says "button", a text field has its label). You add information where the widget alone says too little: `Checkbox(semanticLabel: 'Bought Milk')` tells which item the box belongs to; a spinner gets `semanticsLabel: 'Loading your list'` so it is not just "progress".

**Tooltips on icon buttons.** An icon-only button has no words. `IconButton(tooltip: 'Delete Milk')` shows a text on long press and gives TalkBack its name. Rule: every icon-only control needs a text alternative.

**Target size.** Fingers are big. Material guidance (and WCAG) ask for about 48 by 48 logical pixels. `IconButton` is 48 by 48 by default even though the icon is 24, so prefer it to a bare `GestureDetector` around a small image.

**Not by colour alone.** A colour-blind person may not notice a colour change. We show "bought" with a check mark (the box), a strike-through and the written word "Bought." The theme's `ColorScheme` pairs (for example `onPrimaryContainer` on `primaryContainer`) are designed for readable contrast; keep using them instead of picking grey on grey.

**An alternative to gestures.** Swipe-to-delete is invisible and hard for some users, so the delete button gives the same action. A good rule: every gesture needs a visible equivalent.

**Text scale.** People can raise the system font size. `MediaQuery.textScalerOf(context).scale(14)` tells how large a 14-point text really renders; we switch to stacked fields at 1.5 times or more. Avoid fixed heights around text, and let widgets grow or wrap. `Wrap` and `Expanded` help.

**Adaptive layout.** `LayoutBuilder` gives the space the parent offers (`constraints.maxWidth`). Below 720 logical pixels we use one column, above it two panes. "Logical pixels" are Flutter's size unit, roughly the same physical size on every phone, so 720 is about a small tablet or a phone on its side. `SafeArea` keeps content out of notches and system bars. Prefer asking the available space (`LayoutBuilder`) over asking the device type.

**Testing.** Automated checks catch some issues, but only a manual pass with TalkBack, large fonts and rotation shows the real experience. Android's free **Accessibility Scanner** app can also point out small targets and low contrast.

Common misconception: "Accessibility is only for blind users." Large text, contrast, target size and not relying on colour or gestures help many people, including everyone in bright sunlight with one hand.

## Try it
Make a project `try11` as in lesson 05 and replace `lib/main.dart` with the starter:

**File: `exercise/starter/lib/main.dart`**
```dart
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const ProfileApp());
}

class ProfileApp extends StatelessWidget {
  const ProfileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adaptive profile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const ProfileScreen(),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const tags = ['Flutter', 'Dart', 'Accessibility', 'Hiking', 'Tea'];
  int _likes = 0;

  void _like() {
    setState(() {
      _likes++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adaptive profile')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 600;
          final info = Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sam Lee', style: Theme.of(context).textTheme.headlineSmall),
                Text('Likes: $_likes'),
                // TODO 1: give this IconButton the tooltip 'Like this profile'
                IconButton(onPressed: _like, icon: const Text('+1')),
              ],
            ),
          );
          final skills = Padding(
            padding: const EdgeInsets.all(16),
            // TODO 2: this Row of fixed-width boxes overflows on narrow screens;
            //         replace it with a Wrap that has spacing 8 and runSpacing 8
            child: Row(
              children: [
                for (final tag in tags)
                  Container(
                    width: 120,
                    padding: const EdgeInsets.all(8),
                    child: Text(tag),
                  ),
              ],
            ),
          );
          // TODO 3: when wide is true show info and skills side by side in a Row,
          //         each in an Expanded; otherwise keep the Column
          return Column(children: [info, skills]);
        },
      ),
    );
  }
}
```

1. **Guided:** complete the three TODOs: a tooltip on the icon-style button, a `Wrap` for the tags, and a two-column layout when the width is 600 or more.
2. **Change:** make the likes text announce itself: wrap it in `Semantics` with `liveRegion: true` (look up what a live region does).
3. **Stretch (optional):** run the finished app with the largest font and write down two things that still look cramped.

<details><summary>Solution</summary>

**File: `exercise/solution/lib/main.dart`**
```dart
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const ProfileApp());
}

class ProfileApp extends StatelessWidget {
  const ProfileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adaptive profile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const ProfileScreen(),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const tags = ['Flutter', 'Dart', 'Accessibility', 'Hiking', 'Tea'];
  int _likes = 0;

  void _like() {
    setState(() {
      _likes++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Adaptive profile')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 600;
          final info = Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sam Lee', style: Theme.of(context).textTheme.headlineSmall),
                Text('Likes: $_likes'),
                IconButton(
                  tooltip: 'Like this profile',
                  onPressed: _like,
                  icon: const Text('+1'),
                ),
              ],
            ),
          );
          final skills = Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in tags)
                  Container(
                    width: 120,
                    padding: const EdgeInsets.all(8),
                    child: Text(tag),
                  ),
              ],
            ),
          );
          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: info),
                Expanded(child: skills),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [info, skills],
          );
        },
      ),
    );
  }
}
```

`Wrap` moves children to a new line when the line is full, so five fixed-width tags never overflow.

</details>

## Check yourself
1. Why does an icon-only button need a tooltip? <details><summary>Answer</summary>It gives the button a name for screen readers and shows a hint for sighted users.</details>
2. What is the recommended minimum touch target? <details><summary>Answer</summary>About 48 by 48 logical pixels.</details>
3. Why is "Bought." also written as text? <details><summary>Answer</summary>Status must not rely on colour or a strike-through alone.</details>
4. Which widget tells you how much width you have? <details><summary>Answer</summary>`LayoutBuilder` (its `constraints.maxWidth`).</details>

## Common mistakes
| Symptom or error text | Cause | Fix |
|---|---|---|
| `A RenderFlex overflowed by ... pixels on the right.` at large font (typical message) | Fixed widths around text | Use `Expanded`, `Wrap`, or stack the widgets at large text scale |
| TalkBack reads only "button" for the trash | No tooltip or label | Add `tooltip:` or `Semantics(label: ...)` |
| Two-pane layout never appears | Screen narrower than 720 | Rotate or use a tablet emulator; lower the breakpoint while testing |
| Text too small to tap targets | Using `GestureDetector` around a tiny icon | Use `IconButton` (48 dp) |
| `The named parameter 'semanticLabel' isn't defined.` (typical message) | Older widget API | Wrap the widget in `Semantics(label: ...)` instead |

## Best practice
Add labels and tooltips while you build each widget, and test with the largest font and a screen reader before you call a screen done. Source: [Flutter: Accessibility](https://docs.flutter.dev/ui/accessibility) and [Adaptive and responsive design](https://docs.flutter.dev/ui/adaptive-responsive)

## Going further
- [Accessibility testing and design](https://docs.flutter.dev/ui/accessibility) and the [Material target size guidance](https://m3.material.io/foundations/designing/structure).
- Level 201 lesson 09 repeats this with an accessibility checklist for the capstone.

## Summary
- You added spoken labels and tooltips and replaced a gesture-only action with a button.
- You wrote status as text and kept colours from the theme.
- You made the layout survive large text and switch to two panes on wide screens.

## Next lesson
12. Project: a task list app that combines everything from this track.
