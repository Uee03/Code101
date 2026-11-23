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
