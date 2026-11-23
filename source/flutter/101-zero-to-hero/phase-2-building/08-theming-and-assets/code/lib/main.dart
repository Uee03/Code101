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
