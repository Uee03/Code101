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
