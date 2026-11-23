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
