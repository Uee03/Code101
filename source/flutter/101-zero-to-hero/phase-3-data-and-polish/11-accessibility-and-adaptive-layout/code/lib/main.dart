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
