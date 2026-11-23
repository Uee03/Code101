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
